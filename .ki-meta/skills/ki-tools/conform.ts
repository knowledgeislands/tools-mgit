#!/usr/bin/env bun
/**
 * Mechanical CONFORM for the ki-tools standard — fixes the subset of
 * audit.ts's findings that are unambiguous and reversible, leaving
 * everything that needs a human call as a printed manual TODO.
 *
 * Scope: a single target tools-* repo (default cwd), matching the house
 * conform shape (conform.ts, conform.ts) — `bun conform.ts .`
 * / `ki:tools:conform`. bin/ discovery and the [ki-tools] marker default are
 * kept in lockstep with audit.ts (same source of truth, copied rather
 * than imported so each script stays valid standalone per the
 * composition-only rule).
 *
 *   bun scripts/conform.ts [path]   # default: cwd
 *   --dry-run                              # print the plan, mutate nothing
 *
 * Fixes:
 *   - TOOL-EXEC: chmod +x on every file under bin/ that is missing the
 *     executable bit.
 *   - TOOL-INSTALL (exec bit only): chmod +x on install.sh when present but
 *     not executable. A missing install.sh is never authored — that's a
 *     manual TODO (the curl-installer body is judgment/authoring, not a
 *     mechanical fill-in).
 *   - CONFIG: appends the `[ki-tools]` opt-in marker to .ki-config.toml when
 *     the table is absent. Never overwrites an existing table, never creates
 *     .ki-config.toml from scratch (that's ki-repo's EDUCATE/CONFORM job).
 *
 * Deliberately NEVER touches (judgment → manual TODOs):
 *   - TOOL-BIN (bin/ missing entirely) — scaffolding the tool's own
 *     executable is authoring, not a mechanical fix.
 *   - TOOL-INSTALL (install.sh missing entirely) — the curl-installer body.
 *   - TOOL-TESTS (no tests/ directory) — authoring a test suite.
 *   - TOOL-CI (no CI workflow) — authoring the workflow file.
 *   - TOOL-VERSION (no visible --version handling) — editing the tool's code.
 *   - SHELL-LINT / SHELL-TEST (shellcheck/bats not wired) — authoring CI +
 *     test-suite content.
 *   - RELEASE (git tags / GitHub releases) — not checkable from a path, and
 *     not fixable by editing files.
 *   - .ki-config.toml missing entirely — ki-repo's CONFORM scaffolds that.
 *
 * Zero npm dependencies (bun + node stdlib only). Exit code is non-zero only
 * on an unrecoverable error (target not a directory); findings/fixes never
 * fail the run.
 */
import { chmodSync, existsSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs'
import { join, resolve } from 'node:path'

// ── kept in lockstep with audit.ts ──
const KI_CONFIG = '.ki-config.toml'
const KI_SECTION = 'ki-tools'
const KI_DEFAULT = `# ${KI_SECTION} — opt-in marker: declaring this table opts the repo into the tools standard
# (ONE standalone CLI tool per repo, curl-installer + Homebrew tap). No keys today —
# a bare header is the whole contract. If the tool grows a package.json (a TS/Bun tool),
# also declare [ki-engineering] so its lint/test toolchain is governed; the tap formula
# is governed separately by [ki-homebrew-tap] in the tap repo.
[${KI_SECTION}]
`

// Collect-then-emit harness (mirrors audit.ts + the house conform shape). Each action
// records a finding; `say` prints the human line only when not in --json mode, so a direct
// run streams prose while the aggregate consumes the wrapper. area is the rubric code, ref
// its reference-doc pointer, file the path an action concerns — same (area, ref) as audit.
type Level = 'FAIL' | 'WARN' | 'POLISH' | 'ADVISORY' | 'INFO' | 'NA' | 'PASS'
type Finding = { level: Level; area: string; msg: string; ref?: string; file?: string }

// Reference-doc pointers per rubric section — kept in lockstep with audit.ts's REF.
const REF = {
  layout: 'references/tools-standard.md#repository-layout',
  exec: 'references/tools-standard.md#the-executable--bintool',
  dist: 'references/tools-standard.md#the-distribution-contract',
  ver: 'references/tools-standard.md#versioning--releases',
  cap: 'references/tools-standard.md#capability-conditionals',
  marker: 'references/tools-standard.md#the-ki-tools-marker'
} as const

const isDir = (p: string): boolean => existsSync(p) && statSync(p).isDirectory()
const isFile = (p: string): boolean => existsSync(p) && statSync(p).isFile()
const isExecutable = (p: string): boolean => existsSync(p) && (statSync(p).mode & 0o111) !== 0

function binFiles(repo: string): string[] {
  const dir = join(repo, 'bin')
  if (!isDir(dir)) return []
  return readdirSync(dir, { withFileTypes: true })
    .filter((e) => e.isFile())
    .map((e) => e.name)
    .sort()
}

// Minimal validate-DOWN read of this skill's own [ki-tools] table — mirrors
// audit.ts's parseKiTools (returns null when the table is absent).
function hasKiToolsTable(text: string): boolean {
  return /^\[ki-tools\]/m.test(text)
}

const C = { reset: '\x1b[0m', dim: '\x1b[2m', green: '\x1b[32m', yellow: '\x1b[33m', red: '\x1b[31m', cyan: '\x1b[36m' }
const paint = (c: string, s: string): string => `${c}${s}${C.reset}`

// ── entry ──
async function main() {
  const argv = process.argv.slice(2)
  const dryRun = argv.includes('--dry-run')
  const json = argv.includes('--json')
  const target = resolve(argv.find((a) => !a.startsWith('-')) ?? '.')

  const findings: Finding[] = []
  const rec = (level: Level, area: string, msg: string, ref?: string, file?: string): void =>
    void findings.push({ level, area, msg, ref, file })
  const say = (line: string): void => {
    if (!json) console.log(line)
  }

  if (!isDir(target)) {
    console.error(paint(C.red, `not a directory: ${target}`))
    process.exit(1)
    return
  }

  say(paint(C.dim, `target: ${target}${dryRun ? '   (dry run)' : ''}\n`))

  // ── a) TOOL-EXEC — chmod +x on every non-executable bin/ file ──
  say(paint(C.cyan, 'bin/ executable bit (TOOL-EXEC)'))
  const bins = binFiles(target)
  if (!isDir(join(target, 'bin'))) {
    rec('ADVISORY', 'TOOL-BIN', 'bin/ is missing entirely; scaffold the tool executable by hand (see Mode EDUCATE)', REF.layout, 'bin/')
    say(`  ${paint(C.dim, 'bin/ missing — see manual TODOs')}`)
  } else if (bins.length === 0) {
    rec('ADVISORY', 'TOOL-BIN', 'bin/ holds no files; add the tool executable by hand', REF.layout, 'bin/')
    say(`  ${paint(C.dim, 'bin/ empty — see manual TODOs')}`)
  } else {
    let fixed = 0
    for (const name of bins) {
      const path = join(target, 'bin', name)
      if (!isExecutable(path)) {
        rec('POLISH', 'TOOL-EXEC', `chmod +x bin/${name} (${dryRun ? 'would set' : 'set'} the executable bit)`, REF.exec, `bin/${name}`)
        say(`  ${paint(C.green, 'fix')}   chmod +x bin/${name}`)
        if (!dryRun) chmodSync(path, statSync(path).mode | 0o111)
        fixed++
      }
    }
    if (fixed === 0) {
      rec('PASS', 'TOOL-EXEC', 'every bin/ file is already executable', REF.exec, 'bin/')
      say(`  ${paint(C.dim, 'nothing to fix — every bin/ file is executable')}`)
    }
  }

  // ── b) TOOL-INSTALL — chmod +x on install.sh when present but not executable ──
  say(`\n${paint(C.cyan, 'install.sh executable bit (TOOL-INSTALL)')}`)
  const installPath = join(target, 'install.sh')
  if (!isFile(installPath)) {
    rec(
      'ADVISORY',
      'TOOL-INSTALL',
      'no install.sh at the repo root; author the curl-installer by hand (see Mode EDUCATE)',
      REF.dist,
      'install.sh'
    )
    say(`  ${paint(C.dim, 'install.sh missing — see manual TODOs')}`)
  } else if (!isExecutable(installPath)) {
    rec('POLISH', 'TOOL-INSTALL', `chmod +x install.sh (${dryRun ? 'would set' : 'set'} the executable bit)`, REF.dist, 'install.sh')
    say(`  ${paint(C.green, 'fix')}   chmod +x install.sh`)
    if (!dryRun) chmodSync(installPath, statSync(installPath).mode | 0o111)
  } else {
    rec('PASS', 'TOOL-INSTALL', 'install.sh is already executable', REF.dist, 'install.sh')
    say(`  ${paint(C.dim, 'nothing to fix — install.sh is already executable')}`)
  }

  // ── c) CONFIG — append the [ki-tools] opt-in marker when absent ──
  say(`\n${paint(C.cyan, `[${KI_SECTION}] config marker (CONFIG)`)}`)
  const kiPath = join(target, KI_CONFIG)
  if (!isFile(kiPath)) {
    rec(
      'ADVISORY',
      'CONFIG',
      `${KI_CONFIG} is missing entirely; run ki-repo's CONFORM/EDUCATE to scaffold it, then re-run this script`,
      REF.marker,
      KI_CONFIG
    )
    say(`  ${paint(C.dim, `${KI_CONFIG} missing — see manual TODOs`)}`)
  } else {
    const kiText = readFileSync(kiPath, 'utf8')
    if (hasKiToolsTable(kiText)) {
      rec('PASS', 'CONFIG', `[${KI_SECTION}] marker already present`, REF.marker, KI_CONFIG)
      say(`  ${paint(C.dim, `nothing to fix — [${KI_SECTION}] already present`)}`)
    } else {
      rec(
        'POLISH',
        'CONFIG',
        `${dryRun ? 'would append' : 'appended'} the [${KI_SECTION}] opt-in marker to ${KI_CONFIG}`,
        REF.marker,
        KI_CONFIG
      )
      say(`  ${paint(C.green, 'append')} [${KI_SECTION}] marker → ${KI_CONFIG}`)
      if (!dryRun) writeFileSync(kiPath, `${kiText.replace(/\n*$/, '\n\n')}${KI_DEFAULT}`)
    }
  }

  // ── judgment items — never guessed, always surfaced as ADVISORY (SKILL.md Mode CONFORM) ──
  say(`\n${paint(C.cyan, 'manual TODOs (judgment — not scripted)')}`)
  rec(
    'ADVISORY',
    'TOOL-TESTS',
    'no tests/ directory: author an executable test suite (a *.bats suite for a shell tool) by hand',
    REF.layout,
    'tests/'
  )
  rec('ADVISORY', 'TOOL-CI', 'no .github/workflows/*.yml: author the CI workflow by hand', REF.layout, '.github/workflows/')
  rec('ADVISORY', 'TOOL-VERSION', "bin/<tool> has no visible --version handling: wire it into the tool's own code", REF.ver)
  rec('ADVISORY', 'TOOL-CHANGELOG', 'no CHANGELOG.md: seed one (keep-a-changelog + semver) by hand', REF.ver, 'CHANGELOG.md')
  rec('ADVISORY', 'SHELL-LINT', 'shellcheck/bats not wired into CI: author the workflow steps by hand', REF.cap)
  rec('ADVISORY', 'RELEASE', 'vX.Y.Z git tags + a GitHub release each: not checkable from a path, not fixable by editing files', REF.ver)
  for (const r of findings.filter(
    (f) => f.level === 'ADVISORY' && f.area !== 'TOOL-BIN' && f.area !== 'TOOL-INSTALL' && f.area !== 'CONFIG'
  ))
    say(`  - ${r.area} — ${r.msg}`)
  say(`\n${paint(C.dim, 'mechanical layer applied — re-run `bun scripts/audit.ts` (or `ki:tools:audit`) to confirm findings clear.')}`)

  if (json) {
    const n = (l: Level): number => findings.filter((f) => f.level === l).length
    const summary = {
      fail: n('FAIL'),
      warn: n('WARN'),
      polish: n('POLISH'),
      advisory: n('ADVISORY'),
      info: n('INFO'),
      na: n('NA'),
      pass: n('PASS')
    }
    process.stdout.write(JSON.stringify({ concern: 'tools', target, generatedAt: new Date().toISOString(), summary, findings }))
  }
}

main().catch((err) => {
  console.error(`ERROR: ${String(err)}`)
  process.exit(1)
})
