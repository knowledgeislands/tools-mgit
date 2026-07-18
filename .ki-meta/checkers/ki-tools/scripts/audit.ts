#!/usr/bin/env bun
/**
 * Read-only mechanical checker for a Knowledge Islands `tools-*` repository.
 *
 * The checker owns collection only. Its local canonical checker reporter owns
 * the JSONL transport; the aggregate owns human presentation.
 */
import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs'
import { basename, dirname, join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import {
  type CheckerFinding,
  checkerReporterExitCode,
  emitCheckerReporter,
  judgmentFindingsFromRubric
} from './vendored/ki-skills/checker-reporter.ts'

const KI_CONFIG = '.ki-config.toml'
const KI_SECTION = 'ki-tools'
const RUBRIC = 'references/rubric.md'
const KI_DEFAULT = `# ${KI_SECTION} — opt-in marker for the tools repository standard
[${KI_SECTION}]
`
const REF = {
  layout: 'references/standards.md#repository-layout',
  exec: 'references/standards.md#the-executable--bintool',
  dist: 'references/standards.md#the-distribution-contract',
  ver: 'references/standards.md#versioning--releases',
  cap: 'references/standards.md#capability-conditionals',
  marker: 'references/standards.md#the-ki-tools-marker'
} as const

const isDir = (path: string): boolean => existsSync(path) && statSync(path).isDirectory()
const isFile = (path: string): boolean => existsSync(path) && statSync(path).isFile()
const isExecutable = (path: string): boolean => existsSync(path) && (statSync(path).mode & 0o111) !== 0
const TOML = (globalThis as unknown as { Bun: { TOML: { parse(text: string): unknown } } }).Bun.TOML

const mk = () => {
  const findings: CheckerFinding[] = []
  const push =
    (level: CheckerFinding['level']) =>
    (code: string, message: string, ref?: string, file?: string): void =>
      void findings.push({ type: 'M', level, code, message, ref, file })
  return { findings, fail: push('FAIL'), warn: push('WARN'), note: push('INFO'), advisory: push('ADVISORY') }
}

type KiToolsParse = { keys: string[] | null; malformed: boolean }
function parseKiTools(text: string): KiToolsParse {
  try {
    const document = TOML.parse(text) as Record<string, unknown>
    const value = document[KI_SECTION]
    return !value || typeof value !== 'object' || Array.isArray(value)
      ? { keys: null, malformed: false }
      : { keys: Object.keys(value as Record<string, unknown>), malformed: false }
  } catch {
    return { keys: null, malformed: true }
  }
}

function binFiles(repo: string): string[] {
  const directory = join(repo, 'bin')
  return !isDir(directory)
    ? []
    : readdirSync(directory, { withFileTypes: true })
        .filter((entry) => entry.isFile())
        .map((entry) => entry.name)
        .sort()
}

function workflowFiles(repo: string): string[] {
  const directory = join(repo, '.github', 'workflows')
  return !isDir(directory)
    ? []
    : readdirSync(directory)
        .filter((name) => name.endsWith('.yml') || name.endsWith('.yaml'))
        .map((name) => join(directory, name))
}

function primaryBin(repo: string, names: string[]): string | null {
  const expected = basename(repo).replace(/^tools-/, '')
  return names.find((name) => name === expected) ?? names[0] ?? null
}

function auditTools(repo: string, config: KiToolsParse): CheckerFinding[] {
  const { findings, fail, warn, note } = mk()
  const bins = binFiles(repo)
  const binDirectory = join(repo, 'bin')
  if (!isDir(binDirectory)) {
    fail('TOOL-BIN', 'tool executable directory is missing', REF.layout, 'bin/')
    return findings
  }
  if (bins.length === 0) {
    fail('TOOL-BIN', 'no executable files found — add the tool executable', REF.layout, 'bin/')
    return findings
  }
  note('TOOL-BIN', `contains ${bins.length} executable candidate(s): ${bins.join(', ')}`, REF.layout, 'bin/')

  const notExecutable = bins.filter((name) => !isExecutable(join(binDirectory, name)))
  if (notExecutable.length) fail('TOOL-EXEC', `missing the executable bit (chmod +x): ${notExecutable.join(', ')}`, REF.exec, 'bin/')
  else note('TOOL-EXEC', 'every bin/ file is executable', REF.exec, 'bin/')

  const primary = primaryBin(repo, bins) as string
  const primaryPath = join(binDirectory, primary)
  const primaryFile = `bin/${primary}`
  const primaryText = readFileSync(primaryPath, 'utf8')
  const shebang = primaryText.split(/\r?\n/, 1)[0] ?? ''
  const isShell = /^#!.*\b(bash|sh|dash|zsh|ksh)\b/.test(shebang)

  const installPath = join(repo, 'install.sh')
  if (!isFile(installPath)) warn('TOOL-INSTALL', 'no install.sh at the repository root', REF.dist, 'install.sh')
  else if (!isExecutable(installPath)) warn('TOOL-INSTALL', 'is present but lacks the executable bit', REF.dist, 'install.sh')
  else note('TOOL-INSTALL', 'is present and executable', REF.dist, 'install.sh')

  if (primaryText.includes('--version')) note('TOOL-VERSION', 'primary executable handles --version', REF.ver, primaryFile)
  else warn('TOOL-VERSION', 'primary executable has no visible --version handling', REF.ver, primaryFile)

  if (isFile(join(repo, 'CHANGELOG.md'))) note('TOOL-CHANGELOG', 'release history file is present', REF.ver, 'CHANGELOG.md')
  else warn('TOOL-CHANGELOG', 'release history file is absent', REF.ver, 'CHANGELOG.md')

  const workflows = workflowFiles(repo)
  if (workflows.length) note('TOOL-CI', `${workflows.length} CI workflow file(s) present`, REF.layout, '.github/workflows/')
  else warn('TOOL-CI', 'no .github/workflows/*.yml workflow', REF.layout, '.github/workflows/')

  const testsDirectory = join(repo, 'tests')
  if (isDir(testsDirectory)) note('TOOL-TESTS', 'tests/ directory present', REF.layout, 'tests/')
  else warn('TOOL-TESTS', 'tests/ directory absent', REF.layout, 'tests/')

  const workflowText = workflows.map((path) => readFileSync(path, 'utf8')).join('\n')
  if (isShell) {
    if (/shellcheck/i.test(workflowText)) note('SHELL-LINT', 'a CI workflow references shellcheck', REF.cap, primaryFile)
    else warn('SHELL-LINT', 'shell entrypoint has no CI shellcheck reference', REF.cap, primaryFile)
    const hasBats = isDir(testsDirectory) && readdirSync(testsDirectory).some((name) => name.endsWith('.bats'))
    if (!hasBats) warn('SHELL-TEST', 'shell entrypoint has no *.bats suite', REF.cap, 'tests/')
    else if (!/\bbats\b/i.test(workflowText)) warn('SHELL-TEST', '*.bats suite is not referenced by CI', REF.cap, 'tests/')
    else note('SHELL-TEST', 'a *.bats suite is referenced by CI', REF.cap, 'tests/')
  } else {
    note('SHELL-LINT', 'primary executable is not a shell entrypoint; shell checks do not apply', REF.cap, primaryFile)
  }

  if (isFile(join(repo, 'package.json')))
    note('LANG-DEFER', 'package.json is present; lint and test defer to ki-engineering', REF.cap, 'package.json')

  const configPath = join(repo, KI_CONFIG)
  if (!isFile(configPath)) {
    warn('CONFIG', `configuration file is absent — add a [${KI_SECTION}] opt-in marker`, REF.marker, KI_CONFIG)
  } else if (config.keys === null) {
    warn('CONFIG', `no [${KI_SECTION}] table — add the opt-in marker`, REF.marker, KI_CONFIG)
  } else {
    note('CONFIG', `[${KI_SECTION}] table present`, REF.marker, KI_CONFIG)
    for (const key of config.keys) warn('CONFIG', `unknown key under [${KI_SECTION}]: ${key}`, REF.marker, KI_CONFIG)
  }

  return findings
}

const args = process.argv.slice(2)
if (args.includes('--educate')) {
  process.stdout.write(KI_DEFAULT)
  process.exit(0)
}
const target = resolve(args.find((arg) => !arg.startsWith('-')) ?? '.')
const rubricPath = join(dirname(fileURLToPath(import.meta.url)), '..', 'references', 'rubric.md')
let findings: CheckerFinding[]
if (!isDir(target)) {
  findings = [{ type: 'M', level: 'FAIL', code: 'TOOL-BIN', message: 'target is not a directory', ref: REF.layout, file: target }]
} else {
  const configPath = join(target, KI_CONFIG)
  const config = isFile(configPath) ? parseKiTools(readFileSync(configPath, 'utf8')) : { keys: null, malformed: false }
  if (config.keys === null && !config.malformed && !isDir(join(target, 'bin'))) {
    findings = [
      { type: 'M', level: 'NA', code: 'CONFIG', message: 'not applicable: no [ki-tools] declaration or bin/ marker', ref: REF.marker }
    ]
  } else {
    findings = auditTools(target, config)
  }
}
findings.push(...judgmentFindingsFromRubric(rubricPath, RUBRIC))
emitCheckerReporter({ mode: 'audit', concern: 'tools', target, findings })
process.exitCode = checkerReporterExitCode(findings)
