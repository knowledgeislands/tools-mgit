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
 *     .ki-config.toml from scratch (that's ki-repo's INIT/CONFORM job).
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
  const target = resolve(argv.find((a) => !a.startsWith('-')) ?? '.')

  if (!isDir(target)) {
    console.error(paint(C.red, `not a directory: ${target}`))
    process.exit(1)
    return
  }

  console.log(paint(C.dim, `target: ${target}${dryRun ? '   (dry run)' : ''}\n`))

  const manualTodos: string[] = []

  // ── a) TOOL-EXEC — chmod +x on every non-executable bin/ file ──
  console.log(paint(C.cyan, 'bin/ executable bit (TOOL-EXEC)'))
  const bins = binFiles(target)
  if (!isDir(join(target, 'bin'))) {
    manualTodos.push('TOOL-BIN — bin/ is missing entirely; scaffold the tool executable by hand (see Mode INIT)')
    console.log(`  ${paint(C.dim, 'bin/ missing — see manual TODOs')}`)
  } else if (bins.length === 0) {
    manualTodos.push('TOOL-BIN — bin/ holds no files; add the tool executable by hand')
    console.log(`  ${paint(C.dim, 'bin/ empty — see manual TODOs')}`)
  } else {
    let fixed = 0
    for (const name of bins) {
      const path = join(target, 'bin', name)
      if (!isExecutable(path)) {
        console.log(`  ${paint(C.green, 'fix')}   chmod +x bin/${name}`)
        if (!dryRun) chmodSync(path, statSync(path).mode | 0o111)
        fixed++
      }
    }
    if (fixed === 0) console.log(`  ${paint(C.dim, 'nothing to fix — every bin/ file is executable')}`)
  }

  // ── b) TOOL-INSTALL — chmod +x on install.sh when present but not executable ──
  console.log(`\n${paint(C.cyan, 'install.sh executable bit (TOOL-INSTALL)')}`)
  const installPath = join(target, 'install.sh')
  if (!isFile(installPath)) {
    manualTodos.push('TOOL-INSTALL — no install.sh at the repo root; author the curl-installer by hand (see Mode INIT)')
    console.log(`  ${paint(C.dim, 'install.sh missing — see manual TODOs')}`)
  } else if (!isExecutable(installPath)) {
    console.log(`  ${paint(C.green, 'fix')}   chmod +x install.sh`)
    if (!dryRun) chmodSync(installPath, statSync(installPath).mode | 0o111)
  } else {
    console.log(`  ${paint(C.dim, 'nothing to fix — install.sh is already executable')}`)
  }

  // ── c) CONFIG — append the [ki-tools] opt-in marker when absent ──
  console.log(`\n${paint(C.cyan, `[${KI_SECTION}] config marker (CONFIG)`)}`)
  const kiPath = join(target, KI_CONFIG)
  if (!isFile(kiPath)) {
    manualTodos.push(`CONFIG — ${KI_CONFIG} is missing entirely; run ki-repo's CONFORM/INIT to scaffold it, then re-run this script`)
    console.log(`  ${paint(C.dim, `${KI_CONFIG} missing — see manual TODOs`)}`)
  } else {
    const kiText = readFileSync(kiPath, 'utf8')
    if (hasKiToolsTable(kiText)) {
      console.log(`  ${paint(C.dim, `nothing to fix — [${KI_SECTION}] already present`)}`)
    } else {
      console.log(`  ${paint(C.green, 'append')} [${KI_SECTION}] marker → ${KI_CONFIG}`)
      if (!dryRun) writeFileSync(kiPath, `${kiText.replace(/\n*$/, '\n\n')}${KI_DEFAULT}`)
    }
  }

  // ── judgment items — never guessed, always surfaced ──
  console.log(`\n${paint(C.cyan, 'manual TODOs (judgment — not scripted)')}`)
  for (const todo of manualTodos) console.log(`  - ${todo}`)
  console.log('  - TOOL-TESTS — no tests/ directory: author an executable test suite (a *.bats suite for a shell tool) by hand.')
  console.log('  - TOOL-CI — no .github/workflows/*.yml: author the CI workflow by hand.')
  console.log("  - TOOL-VERSION — bin/<tool> has no visible --version handling: wire it into the tool's own code.")
  console.log('  - TOOL-CHANGELOG — no CHANGELOG.md: seed one (keep-a-changelog + semver) by hand.')
  console.log('  - SHELL-LINT / SHELL-TEST — shellcheck/bats not wired into CI: author the workflow steps by hand.')
  console.log('  - RELEASE — vX.Y.Z git tags + a GitHub release each: not checkable from a path, not fixable by editing files.')
  console.log(
    `\n${paint(C.dim, 'mechanical layer applied — re-run `bun scripts/audit.ts` (or `ki:tools:audit`) to confirm findings clear.')}`
  )
}

main().catch((err) => {
  console.error(`ERROR: ${String(err)}`)
  process.exit(1)
})
