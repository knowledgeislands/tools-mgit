#!/usr/bin/env bun
/**
 * Mechanical CONFORM for ki-tools. It makes only derivable, reversible changes;
 * the canonical checker reporter emits its JSONL result stream.
 */
import { chmodSync, existsSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs'
import { dirname, join, resolve } from 'node:path'
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
const REF = {
  layout: 'references/standards.md#repository-layout',
  exec: 'references/standards.md#the-executable--bintool',
  dist: 'references/standards.md#the-distribution-contract',
  marker: 'references/standards.md#the-ki-tools-marker'
} as const
const KI_DEFAULT = `[${KI_SECTION}]\n`

const isDir = (path: string): boolean => existsSync(path) && statSync(path).isDirectory()
const isFile = (path: string): boolean => existsSync(path) && statSync(path).isFile()
const isExecutable = (path: string): boolean => existsSync(path) && (statSync(path).mode & 0o111) !== 0
function binFiles(repo: string): string[] {
  const directory = join(repo, 'bin')
  return !isDir(directory)
    ? []
    : readdirSync(directory, { withFileTypes: true })
        .filter((entry) => entry.isFile())
        .map((entry) => entry.name)
        .sort()
}
function hasKiToolsTable(text: string): boolean {
  return /^\[ki-tools\]/m.test(text)
}

function main(): void {
  const args = process.argv.slice(2)
  const dryRun = args.includes('--dry-run')
  const target = resolve(args.find((arg) => !arg.startsWith('-')) ?? '.')
  const rubricPath = join(dirname(fileURLToPath(import.meta.url)), '..', 'references', 'rubric.md')
  const findings: CheckerFinding[] = []
  const record = (level: CheckerFinding['level'], code: string, message: string, ref?: string, file?: string): void =>
    void findings.push({ type: 'M', level, code, message, ref, file })

  if (!isDir(target)) {
    record('FAIL', 'TOOL-BIN', 'target is not a directory', REF.layout, target)
  } else {
    const binDirectory = join(target, 'bin')
    const bins = binFiles(target)
    if (!isDir(binDirectory)) {
      record('ADVISORY', 'TOOL-BIN', 'tool executable directory is missing; author it by hand', REF.layout, 'bin/')
    } else if (bins.length === 0) {
      record('ADVISORY', 'TOOL-BIN', 'no executable files found; author the tool executable by hand', REF.layout, 'bin/')
    } else {
      let changed = 0
      for (const name of bins) {
        const path = join(binDirectory, name)
        if (isExecutable(path)) continue
        record('POLISH', 'TOOL-EXEC', `${dryRun ? 'would set' : 'set'} executable bit`, REF.exec, `bin/${name}`)
        if (!dryRun) chmodSync(path, statSync(path).mode | 0o111)
        changed++
      }
      if (changed === 0) record('PASS', 'TOOL-EXEC', 'every bin/ file is already executable', REF.exec, 'bin/')
    }

    const installPath = join(target, 'install.sh')
    if (!isFile(installPath)) {
      record('ADVISORY', 'TOOL-INSTALL', 'curl installer is missing; author it by hand', REF.dist, 'install.sh')
    } else if (!isExecutable(installPath)) {
      record('POLISH', 'TOOL-INSTALL', `${dryRun ? 'would set' : 'set'} executable bit`, REF.dist, 'install.sh')
      if (!dryRun) chmodSync(installPath, statSync(installPath).mode | 0o111)
    } else {
      record('PASS', 'TOOL-INSTALL', 'install.sh is already executable', REF.dist, 'install.sh')
    }

    const configPath = join(target, KI_CONFIG)
    if (!isFile(configPath)) {
      record('ADVISORY', 'CONFIG', 'configuration file is missing; ki-repo must create it first', REF.marker, KI_CONFIG)
    } else if (hasKiToolsTable(readFileSync(configPath, 'utf8'))) {
      record('PASS', 'CONFIG', `[${KI_SECTION}] marker already present`, REF.marker, KI_CONFIG)
    } else {
      record('POLISH', 'CONFIG', `${dryRun ? 'would append' : 'appended'} the [${KI_SECTION}] marker`, REF.marker, KI_CONFIG)
      if (!dryRun) {
        const text = readFileSync(configPath, 'utf8')
        writeFileSync(configPath, `${text.replace(/\n*$/, '\n\n')}${KI_DEFAULT}`)
      }
    }
  }

  findings.push(...judgmentFindingsFromRubric(rubricPath, RUBRIC))
  emitCheckerReporter({ mode: 'conform', concern: 'tools', target, findings })
  process.exitCode = checkerReporterExitCode(findings)
}

main()
