# Audit Rubric

Line-by-line pass/fail items for auditing a Knowledge Islands `tools-*` repo against the [tool-repo standard](standards.md). Run [`../scripts/audit.ts`](../scripts/audit.ts) for the mechanical items (marked **[M]**), then judge the rest ( **[J]** ) by reading.

Every **[M]** item corresponds to a check in the checker (per `ki-skills`' SHAPE-9 + the checker-contract). Severity uses the shared ladder, defined in `ki-engineering`'s [`enforcement-framework.md`](../../../foundations/ki-engineering/references/enforcement-framework.md) §2: **FAIL** (ship-stopper), **WARN** (expected-but-missing / divergence), **POLISH** (consistency), **ADVISORY** (needs a human/out-of-band check), **INFO** (context).

Applicability: `[ki-tools]` or `bin/` activates the complete audit. With neither, **CONFIG [M]** emits exactly one `NA` and stops; either signal retains all existing findings. ([standard](standards.md#scope-container-not-contents))

## Contents

- [Layout & executable](#layout--executable)
- [Distribution & versioning](#distribution--versioning)
- [Capability conditionals](#capability-conditionals)
- [Config table](#config-table)
- [Releases](#releases)

## Layout & executable

- [ ] **TOOL-BIN [M]** Tool executable — `bin/` exists and holds ≥1 file. Absent ⇒ FAIL (no tool). (references/standards.md#repository-layout)
- [ ] **TOOL-EXEC [M]** Executable bit — every `bin/<file>` carries the executable bit (`statSync(mode) & 0o111`). Git tracks the exec bit; a bin file without it breaks the installer and formula. (references/standards.md#the-executable--bintool)
- [ ] **TOOL-SCOPE [J]** One command — the tool is genuinely **one** tool; a repo shipping two distinct commands is two repos.
- [ ] **TOOL-XDG [J]** XDG storage — the tool follows the XDG Base Directory spec for any config/state/cache it writes (no stray `$HOME` dotfiles).

## Distribution & versioning

- [ ] **TOOL-INSTALL [M]** Installer executable — `install.sh` is present at the repo root and executable (the `curl | bash` contract). (references/standards.md#the-distribution-contract)
- [ ] **TOOL-INSTALL-QUALITY [J]** Installer quality — `install.sh` is POSIX-ish, honours env overrides (target dir + version/ref), verifies the download, and is idempotent.
- [ ] **TOOL-VERSION [M]** Version flag — the primary bin file contains `--version` handling (grep). ADVISORY when the file can't be read. (references/standards.md#versioning--releases)
- [ ] **TOOL-VERSION-SOURCE [J]** Version source — the version marker is a single literal (one source of truth) that `--version` prints; it agrees with the latest tag and CHANGELOG entry.
- [ ] **TOOL-CHANGELOG [M]** Changelog presence — `CHANGELOG.md` is present. (README / LICENSE are `ki-repo`'s — not checked here.) (references/standards.md#versioning--releases)
- [ ] **TOOL-CHANGELOG-FORMAT [J]** Changelog format — `CHANGELOG.md` follows keep-a-changelog + semver (an `## [Unreleased]` head, dated `## [X.Y.Z]` sections, Added/Changed/Fixed/Removed groups).
- [ ] **TOOL-CI [M]** CI workflow — at least one `.github/workflows/*.yml` is present. (references/standards.md#repository-layout)
- [ ] **TOOL-TAP [J]** Companion formula — a companion Homebrew formula exists in the tap (`Formula/<name>.rb`) as the second delivery channel. The tap itself is `ki-homebrew-tap`'s to audit.

## Capability conditionals

- [ ] **TOOL-TESTS [M]** Test directory — a `tests/` directory is present (the executable test suite). (references/standards.md#repository-layout)
- [ ] **SHELL-LINT [M]** Shell lint CI — **if** the primary bin has a `bash`/`sh` shebang, a CI workflow references `shellcheck`. (references/standards.md#capability-conditionals)
- [ ] **SHELL-TEST [M]** Shell test CI — **if** shell, `tests/` holds a `*.bats` file **and** a CI workflow references `bats`. (references/standards.md#capability-conditionals)
- [ ] **LANG-DEFER [M]** JavaScript toolchain deferral — **if** a `package.json` is present, the repo is a TS/Bun tool — it defers lint/test to `ki-engineering` and MUST also declare `[ki-engineering]`. (references/standards.md#capability-conditionals)
- [ ] **TOOL-ENGINEERING [J]** Engineering declaration — a `package.json`-bearing repo actually declares `[ki-engineering]` (the checker notes the requirement; confirm the table is there).
- [ ] **TOOL-LANGUAGE [J]** Other-language toolchain — a non-shell, non-JS tool (Python, Go, …) wires its own language toolchain into CI (lint + test).

## Config table

- [ ] **CONFIG [M]** Opt-in marker — a `[ki-tools]` table is present in `.ki-config.toml` (the opt-in marker). Missing file or table ⇒ WARN. (references/standards.md#the-ki-tools-marker)
- [ ] **CONFIG [M]** Config keys — validate-down — any key inside `[ki-tools]` is unknown today and WARNs. (references/standards.md#the-ki-tools-marker)

## Releases

- [ ] **TOOL-RELEASE-CHECK [J]** Release alignment — releases are `vX.Y.Z` git tags, each with a GitHub release; the marker, tag, and CHANGELOG top entry agree. Not checkable from a path — verify tags/releases by hand (`git tag`, `gh release list`). (references/standards.md#versioning--releases)
