#!/usr/bin/env bun
/**
 * Mechanical checker for a Knowledge Islands `tools-*` repo — a standalone
 * command-line tool distributed by a `curl | bash` installer and a companion
 * Homebrew tap formula.
 *
 *   bun scripts/audit.ts [repo-path]   # audit a tool repo (default: cwd)
 *   bun scripts/audit.ts --educate        # print the default [ki-tools] block
 *
 * This is the mechanical half of the skill's Mode AUDIT — the deterministic
 * layer the judgment pass (release/tag hygiene, the tool's actual behaviour)
 * builds on. It governs the CONTAINER (the tool repo's shape), language-
 * agnostically — bash today, a future Python/Go tool fits the same shape. It
 * does NOT judge the tool's internal code quality. It checks:
 *
 *   1. LAYOUT — `bin/<tool>` exists, holds ≥1 file, and every bin file carries
 *      the executable bit (git tracks it). `install.sh`, `tests/`, and a CI
 *      workflow are expected-but-optional (WARN when absent).
 *
 *   2. VERSIONING & DISTRIBUTION — the primary bin file answers `--version`;
 *      `CHANGELOG.md` is present; `install.sh` (the curl contract) is present
 *      and executable. Whether releases carry `vX.Y.Z` git tags with a GitHub
 *      release each is left to judgment (RELEASE — can't be seen from a path).
 *
 *   3. CAPABILITY CONDITIONALS — mirrors ki-engineering's pattern. A SHELL
 *      entrypoint (bash/sh shebang) requires a CI workflow that runs shellcheck
 *      and a bats suite CI runs. If a `package.json` appears the repo defers
 *      lint/test to ki-engineering (it must also declare `[ki-engineering]`).
 *
 *   4. CONFIG TABLE — the repo's `.ki-config.toml` `[ki-tools]` opt-in marker,
 *      validated DOWN (this skill's own table only) per the shared-file contract
 *      owned by ki-repo: warn on any unknown key inside it, never read another
 *      skill's table. It is a bare keyless marker today.
 *
 * README / LICENSE and the GitHub settings are ki-repo's job; the Homebrew tap
 * is ki-homebrew-tap's — this checker does not duplicate them.
 *
 * READ-ONLY: never mutates the repo. `--educate` writes nothing — it prints the
 * default block to stdout for the author to paste into the repo's config.
 * No npm dependencies — Bun/Node built-ins only. Exit code is non-zero on any FAIL.
 */
import { existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs'
import { basename, join, resolve } from 'node:path'

const KI_CONFIG = '.ki-config.toml'
const KI_SECTION = 'ki-tools'

// The default block `--educate` emits. The bare [ki-tools] header is the OPT-IN
// MARKER: its presence declares this repo governed by the tools standard
// (ki-repo's coverage cascade warns a repo that has bin/<exe> + install.sh but
// no table). There are no keys today — it is a keyless marker, exactly like
// [ki-mcp]; a language conditional (a package.json ⇒ also declare [ki-engineering])
// is declared as its own table, not a key here.
const KI_DEFAULT = `# ${KI_SECTION} — opt-in marker: declaring this table opts the repo into the tools standard
# (ONE standalone CLI tool per repo, curl-installer + Homebrew tap). No keys today —
# a bare header is the whole contract. If the tool grows a package.json (a TS/Bun tool),
# also declare [ki-engineering] so its lint/test toolchain is governed; the tap formula
# is governed separately by [ki-homebrew-tap] in the tap repo.
[${KI_SECTION}]
`

const C = { reset: '\x1b[0m', dim: '\x1b[2m', green: '\x1b[32m', yellow: '\x1b[33m', red: '\x1b[31m', cyan: '\x1b[36m' }
const paint = (c: string, s: string): string => `${c}${s}${C.reset}`

// Unified severity ladder — shared by every KI checker (enforcement-framework §2).
// area is the rubric CODE (references/audit-rubric.md); ref its reference-doc pointer;
// file the path a file-scoped finding concerns. ref/file surface as cited findings and
// serialize verbatim under --json.
type Level = 'FAIL' | 'WARN' | 'POLISH' | 'ADVISORY' | 'INFO' | 'NA' | 'PASS'
type Finding = { level: Level; area: string; msg: string; ref?: string; file?: string }
const ORDER: Level[] = ['FAIL', 'WARN', 'POLISH', 'ADVISORY', 'INFO', 'NA', 'PASS']
const ICON: Record<Level, string> = { FAIL: '❌', WARN: '⚠️', POLISH: '✨', ADVISORY: '🧭', INFO: 'ℹ️', NA: '🚫', PASS: '✅' }

// Reference-doc pointers per rubric section — the standard behind each criterion.
const REF = {
  layout: 'references/tools-standard.md#repository-layout',
  exec: 'references/tools-standard.md#the-executable--bintool',
  dist: 'references/tools-standard.md#the-distribution-contract',
  ver: 'references/tools-standard.md#versioning--releases',
  cap: 'references/tools-standard.md#capability-conditionals',
  marker: 'references/tools-standard.md#the-ki-tools-marker'
} as const

const mk = () => {
  const f: Finding[] = []
  const push =
    (level: Level) =>
    (area: string, msg: string, ref?: string, file?: string): void =>
      void f.push({ level, area, msg, ref, file })
  return {
    f,
    fail: push('FAIL'),
    warn: push('WARN'),
    note: push('INFO'),
    na: push('NA'),
    advisory: push('ADVISORY'),
    polish: push('POLISH')
  }
}

const isDir = (p: string): boolean => existsSync(p) && statSync(p).isDirectory()
const isFile = (p: string): boolean => existsSync(p) && statSync(p).isFile()
const isExecutable = (p: string): boolean => existsSync(p) && (statSync(p).mode & 0o111) !== 0
const TOML = (globalThis as unknown as { Bun: { TOML: { parse(text: string): unknown } } }).Bun.TOML

// The first line of a file (for shebang detection), or ''.
const firstLine = (p: string): string => {
  try {
    return readFileSync(p, 'utf8').split(/\r?\n/, 1)[0] ?? ''
  } catch {
    return ''
  }
}
// A bash/sh shebang on the first line.
const isShellShebang = (line: string): boolean => /^#!.*\b(bash|sh|dash|zsh|ksh)\b/.test(line)

// Every *.yml / *.yaml under .github/workflows.
function workflowFiles(repo: string): string[] {
  const dir = join(repo, '.github', 'workflows')
  if (!isDir(dir)) return []
  return readdirSync(dir)
    .filter((n) => n.endsWith('.yml') || n.endsWith('.yaml'))
    .map((n) => join(dir, n))
}
// Concatenated text of every workflow file, for feature grep.
const workflowText = (repo: string): string =>
  workflowFiles(repo)
    .map((p) => readFileSync(p, 'utf8'))
    .join('\n')

// The bin files (immediate children of bin/ that are files), sorted. The
// "primary" bin is the one matching the repo's basename (a `tools-mgit` repo →
// bin/mgit), else the first alphabetically.
function binFiles(repo: string): string[] {
  const dir = join(repo, 'bin')
  if (!isDir(dir)) return []
  return readdirSync(dir, { withFileTypes: true })
    .filter((e) => e.isFile())
    .map((e) => e.name)
    .sort()
}
function primaryBin(repo: string, names: string[]): string | null {
  if (names.length === 0) return null
  const tool = basename(repo).replace(/^tools-/, '')
  return names.find((n) => n === tool) ?? (names[0] as string)
}

// Semantic validate-DOWN read of this skill's own [ki-tools] table. Quoted
// table keys are declarations; header-shaped text inside TOML strings is not.
// A malformed document is distinguished so applicability fails closed.
type KiToolsParse = { keys: string[] | null; malformed: boolean }
function parseKiTools(text: string): KiToolsParse {
  let document: Record<string, unknown>
  try {
    document = TOML.parse(text) as Record<string, unknown>
  } catch {
    return { keys: null, malformed: true }
  }
  const value = document[KI_SECTION]
  if (!value || typeof value !== 'object' || Array.isArray(value)) return { keys: null, malformed: false }
  return { keys: Object.keys(value as Record<string, unknown>), malformed: false }
}

function auditTools(repo: string, kiTools: KiToolsParse): Finding[] {
  const { f, fail, warn, note, advisory } = mk()

  // ── TOOL-BIN [FAIL]: bin/ exists and holds ≥1 file ──
  const bins = binFiles(repo)
  if (!isDir(join(repo, 'bin'))) {
    fail('TOOL-BIN', 'bin/ is missing — a tools-* repo ships its executable at bin/<tool>', REF.layout, 'bin/')
    return f
  }
  if (bins.length === 0) {
    fail('TOOL-BIN', 'bin/ holds no files — the tool executable lives at bin/<tool>', REF.layout, 'bin/')
    return f
  }
  note('TOOL-BIN', `bin/ holds ${bins.length} file(s): ${bins.join(', ')}`, REF.layout, 'bin/')

  // ── TOOL-EXEC [FAIL]: every bin file carries the executable bit ──
  const notExec = bins.filter((n) => !isExecutable(join(repo, 'bin', n)))
  if (notExec.length)
    fail('TOOL-EXEC', `bin/ file(s) missing the executable bit (git tracks it — chmod +x): ${notExec.join(', ')}`, REF.exec, 'bin/')
  else note('TOOL-EXEC', 'every bin/ file is executable', REF.exec, 'bin/')

  const primary = primaryBin(repo, bins) as string
  const primaryPath = join(repo, 'bin', primary)
  const primaryShebang = firstLine(primaryPath)
  const isShell = isShellShebang(primaryShebang)

  // ── TOOL-INSTALL [WARN]: install.sh present at root and executable (curl contract) ──
  const installPath = join(repo, 'install.sh')
  if (!isFile(installPath))
    warn('TOOL-INSTALL', 'no install.sh at the repo root — the `curl | bash` install contract needs one', REF.dist, 'install.sh')
  else if (!isExecutable(installPath)) warn('TOOL-INSTALL', 'install.sh is present but not executable (chmod +x)', REF.dist, 'install.sh')
  else note('TOOL-INSTALL', 'install.sh present and executable', REF.dist, 'install.sh')

  // ── TOOL-VERSION [WARN/ADVISORY]: the primary bin answers --version ──
  let binText = ''
  try {
    binText = readFileSync(primaryPath, 'utf8')
  } catch {
    binText = ''
  }
  const binRel = `bin/${primary}`
  if (!binText) advisory('TOOL-VERSION', `could not read bin/${primary} to check for --version handling — verify by hand`, REF.ver, binRel)
  else if (binText.includes('--version')) note('TOOL-VERSION', `bin/${primary} handles --version`, REF.ver, binRel)
  else warn('TOOL-VERSION', `bin/${primary} has no visible --version handling — a CLI tool should answer --version`, REF.ver, binRel)

  // ── TOOL-CHANGELOG [WARN]: CHANGELOG.md present (README/LICENSE are ki-repo's) ──
  if (!isFile(join(repo, 'CHANGELOG.md')))
    warn('TOOL-CHANGELOG', 'no CHANGELOG.md — releases follow keep-a-changelog + semver', REF.ver, 'CHANGELOG.md')
  else note('TOOL-CHANGELOG', 'CHANGELOG.md present', REF.ver, 'CHANGELOG.md')

  // ── TOOL-CI [WARN]: at least one .github/workflows/*.yml ──
  const workflows = workflowFiles(repo)
  if (workflows.length === 0)
    warn('TOOL-CI', 'no .github/workflows/*.yml — CI should lint and test the tool on every push', REF.layout, '.github/workflows/')
  else note('TOOL-CI', `${workflows.length} CI workflow file(s) present`, REF.layout, '.github/workflows/')

  // ── TOOL-TESTS [WARN, capability]: tests/ present ──
  const hasTests = isDir(join(repo, 'tests'))
  if (!hasTests) warn('TOOL-TESTS', 'no tests/ directory — a CLI tool should ship an executable test suite', REF.layout, 'tests/')
  else note('TOOL-TESTS', 'tests/ directory present', REF.layout, 'tests/')

  // ── capability conditionals — mirror ki-engineering's capability-conditional pattern ──
  const wfText = workflowText(repo)
  if (isShell) {
    note('SHELL-LINT', `bin/${primary} is a SHELL entrypoint (shebang: ${primaryShebang || '—'})`, REF.cap, binRel)
    // SHELL-LINT [WARN]: a CI workflow must reference shellcheck.
    if (!/shellcheck/i.test(wfText))
      warn('SHELL-LINT', 'shell entrypoint but no CI workflow references shellcheck — a shell tool must be shellcheck-clean in CI', REF.cap)
    else note('SHELL-LINT', 'a CI workflow references shellcheck', REF.cap)
    // SHELL-TEST [WARN]: tests/ should hold a *.bats file and a CI workflow reference bats.
    const hasBats = hasTests && readdirSync(join(repo, 'tests')).some((n) => n.endsWith('.bats'))
    if (!hasBats) warn('SHELL-TEST', 'shell entrypoint but tests/ has no *.bats file — shell tools use a bats suite', REF.cap, 'tests/')
    else if (!/\bbats\b/i.test(wfText))
      warn('SHELL-TEST', 'a *.bats suite exists but no CI workflow references bats — CI must run it', REF.cap)
    else note('SHELL-TEST', 'a *.bats suite exists and a CI workflow references bats', REF.cap)
  } else {
    note(
      'SHELL-LINT',
      `bin/${primary} is not a shell entrypoint (shebang: ${primaryShebang || '—'}) — shell capability checks skipped`,
      REF.cap,
      binRel
    )
  }

  // ── LANG-DEFER [INFO]: a package.json ⇒ defer lint/test to ki-engineering ──
  if (isFile(join(repo, 'package.json')))
    note(
      'LANG-DEFER',
      'package.json present — this is a TS/Bun tool: it defers lint/test to ki-engineering, so the repo must ALSO declare [ki-engineering]',
      REF.cap,
      'package.json'
    )

  // ── CONFIG [WARN]: [ki-tools] opt-in marker, validate-down ──
  const kiPath = join(repo, KI_CONFIG)
  if (!isFile(kiPath))
    warn('CONFIG', `${KI_CONFIG} missing (ki-repo owns the contract) — add a [${KI_SECTION}] marker to opt in`, REF.marker, KI_CONFIG)
  else {
    const keys = kiTools.keys
    if (keys === null)
      warn('CONFIG', `no [${KI_SECTION}] table — add it to mark this repo as governed by the tools standard`, REF.marker, KI_CONFIG)
    else {
      note('CONFIG', `[${KI_SECTION}] table present`, REF.marker, KI_CONFIG)
      // Validate-down: there are no keys today, so any key is unknown.
      const KNOWN = new Set<string>([])
      for (const k of keys)
        KNOWN.has(k)
          ? note('CONFIG', `known key ${k}`, REF.marker, KI_CONFIG)
          : warn('CONFIG', `unknown key under [${KI_SECTION}]: ${k} (validate-down)`, REF.marker, KI_CONFIG)
    }
  }

  // ── RELEASE [ADVISORY]: git tags / GitHub releases can't be seen from a path ──
  advisory(
    'RELEASE',
    'releases are vX.Y.Z git tags with a GitHub release each — not checkable from a path; verify tags/releases exist and match CHANGELOG',
    REF.ver
  )

  return f
}

// ── run ──────────────────────────────────────────────────────────────────────
const argv = process.argv.slice(2)
if (argv.includes('--educate')) {
  process.stdout.write(KI_DEFAULT)
  process.exit(0)
}

const repo = resolve(argv.find((a) => !a.startsWith('-')) ?? '.')
if (!isDir(repo)) {
  console.error(paint(C.red, `not a directory: ${repo}`))
  process.exit(2)
}

const kiPath = join(repo, KI_CONFIG)
const kiTools = isFile(kiPath) ? parseKiTools(readFileSync(kiPath, 'utf8')) : { keys: null, malformed: false }
const declaresTools = kiTools.keys !== null
const hasToolsStructure = isDir(join(repo, 'bin'))
if (!declaresTools && !kiTools.malformed && !hasToolsStructure) {
  const { f, na } = mk()
  na('CONFIG', 'ki-tools not applicable: no [ki-tools] declaration or bin/ structural marker', REF.marker)
  emit(f, repo, 'tools', `Tool repo audit — ${repo}`, '')
}

const findings = auditTools(repo, kiTools)
emit(
  findings,
  repo,
  'tools',
  `Tool repo audit — ${repo}`,
  'mechanical checks only — apply the judgment criteria (release/tag hygiene, install.sh robustness, the tool itself) by reading.'
)

// ── report ────────────────────────────────────────────────────────────────────
// Shared emit harness — copy verbatim across KI checkers (enforcement-framework §2/§5).
// Renders the painted table by default, JSON on `--json`, and writes the latest
// report under <target>/.ki-meta/audits/<concern>.{md,json} on `--report [dir]`.
function emit(items: Finding[], target: string, concern: string, title: string, footer: string): never {
  const argv = process.argv.slice(2)
  const json = argv.includes('--json')
  const ri = argv.indexOf('--report')
  const report = ri !== -1
  const reportDir = report && argv[ri + 1] && !argv[ri + 1].startsWith('-') ? argv[ri + 1] : join(target, '.ki-meta', 'audits')

  const n = (l: Level): number => items.filter((f) => f.level === l).length
  const summary = {
    fail: n('FAIL'),
    warn: n('WARN'),
    polish: n('POLISH'),
    advisory: n('ADVISORY'),
    info: n('INFO'),
    na: n('NA'),
    pass: n('PASS')
  }
  const tally = `FAIL=${summary.fail} WARN=${summary.warn} POLISH=${summary.polish} PASS=${summary.pass} ADVISORY=${summary.advisory} NA=${summary.na}`
  const stamp = new Date().toISOString()

  if (report) {
    mkdirSync(reportDir, { recursive: true })
    const body = ORDER.flatMap((l) => {
      const rows = items.filter((f) => f.level === l)
      return rows.length
        ? [
            '',
            `## ${ICON[l]} ${l} (${rows.length})`,
            ...rows.map((r) => `- [${r.area}]${r.file ? ` ${r.file}` : ''} ${r.msg}${r.ref ? ` (${r.ref})` : ''}`)
          ]
        : []
    })
    writeFileSync(join(reportDir, `${concern}.md`), [`# ${concern} audit — ${target}`, '', `_${stamp}_`, '', tally, ...body, ''].join('\n'))
    writeFileSync(
      join(reportDir, `${concern}.json`),
      `${JSON.stringify({ concern, target, generatedAt: stamp, summary, findings: items }, null, 2)}\n`
    )
  }

  if (json) {
    process.stdout.write(`${JSON.stringify({ concern, target, generatedAt: stamp, summary, findings: items }, null, 2)}\n`)
  } else {
    console.log(`\n${title}\n${'─'.repeat(60)}`)
    for (const l of ORDER) {
      const rows = items.filter((f) => f.level === l)
      if (!rows.length) continue
      console.log(`\n${ICON[l]} ${l} (${rows.length})`)
      for (const r of rows) console.log(`   [${r.area}]${r.file ? ` ${r.file}` : ''} ${r.msg}${r.ref ? ` (${r.ref})` : ''}`)
    }
    console.log(`\n${'─'.repeat(60)}\n${tally}`)
    if (footer) console.log(footer)
    if (summary.fail + summary.warn + summary.polish > 0)
      console.log('→ to address: run /ki-tools CONFORM   (judgment criteria: references/audit-rubric.md)')
    if (report) console.log(`report → ${join(reportDir, `${concern}.{md,json}`)}`)
    console.log('')
  }
  process.exit(summary.fail ? 1 : 0)
}
