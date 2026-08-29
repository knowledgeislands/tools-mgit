---
id: MGIT-CLI-005
title: Canonical-only configuration
area: CLI
theme: cli
horizon: next
status: awaiting-review
blocks: []
blocked_by: []
baseline_ref: 5a8ddb6ea1ada5b5180a7e8522d6d6b4a6aee5bd
---

## Goal

`mgit` recognises only the current schema-1 `.mgit.toml` contract and carries no runtime or user-facing support for previous configuration formats.

## Context

MGIT-CLI-004 introduced the canonical discriminated configuration while the project is still pre-v1. Estate rollout is owned independently by Chezmoi, so compatibility code in `mgit` adds complexity without serving the intended latest-only product boundary.

## Boundary

This item does not modify Chezmoi state, downstream `tools-ki` readers, the release version, tags, Homebrew distribution, or published releases. Append-only specification IDs for the removed behavior remain only as deprecated tombstones.

## Current state

`bin/mgit` still names previous filenames and contains migration, conflict, diagnostic, deletion, and Chezmoi synchronization branches. Tests and user-facing documentation still describe those paths, while MGIT-WS-016 and MGIT-WS-017 specify them as active behavior.

## Steps

- [x] Remove every previous-format constant and runtime branch while preserving canonical kind validation.
- [x] Remove previous-format fixtures and assertions from the Bats suite, retaining canonical registration and validation coverage.
- [x] Remove migration guidance from README, changelog, guide, manual, help, and completion-facing text.
- [x] Deprecate MGIT-WS-016 and MGIT-WS-017 without reusing their append-only identifiers.
- [x] Run the complete shell, Bats, manual, documentation, repository, and zero-reference verification gates.

## Files touched

- `.ki.toml`
- `AGENTS.md`
- `bin/mgit`
- `tests/mgit.bats`
- `README.md`
- `CHANGELOG.md`
- `docs/guides/user/README.md`
- `docs/guides/developer/local-development.md`
- `docs/guides/user/repository-sets.md`
- `docs/specs/workspace-dispatch.md`
- `man/mgit.1`
- `docs/roadmap/MGIT-CLI-005-canonical-only-configuration.md`
- `docs/roadmap/_ISSUES.md`

## Verify

- `shellcheck bin/mgit install.sh`
- `bats tests/`
- `mandoc -T lint man/mgit.1`
- Confirm shipped runtime, tests, and user documentation contain no previous configuration filenames or migration behavior.
- Run KI audits for work, roadmap, specifications, guides, authoring, tool-repository shape, and Git policy.

## Dependencies / blocks

No local dependency remains. Chezmoi owns cross-regime configuration rollout independently, and downstream reader changes remain in `tools-ki`.

## Documentation impact

### Decision Records

No Decision Record is required: this is an explicit pre-v1 product-boundary simplification approved by the user.

### Specifications

Retire MGIT-WS-016 and MGIT-WS-017 as deprecated tombstones; keep all canonical schema and kind requirements active.

### Guides

Remove every migration procedure and previous-format reference from user-facing documentation and the manual.

### Roadmap

Retain this record through implementation review. No additional local roadmap item is expected.

## Review

### Delivered

`mgit` now recognises only schema-1 `.mgit.toml` configuration. Previous configuration filenames have no constants, parser paths, diagnostics, conflict handling, registration cleanup, or Chezmoi synchronization behavior.

### Summary of changes

- Removed previous-format branches from ordinary dispatch, parsing, registration, groups, and repair.
- Removed three obsolete compatibility tests while retaining canonical registration and discriminated-kind coverage.
- Added direct discovery coverage for `--ignore`, `--physical`, and `--follow-symlinks`.
- Removed migration guidance from the README, changelog baseline, repository-set guide, command help, and manual.
- Aligned repository metadata and contributor verification guidance with the canonical-only public surface.
- Retired MGIT-WS-016 and MGIT-WS-017 as append-only deprecated tombstones.

### Verification

- `shellcheck bin/mgit install.sh`
- `bats tests/` — 53 tests passed.
- `mandoc -T lint man/mgit.1` and rendered manual inspection.
- CLI help, register help, version, and Bash and Zsh completion smoke checks.
- Zero-reference scan across executable, tests, README, changelog, guides, and manual.
- `ki-work`, `ki-work-roadmap`, `ki-specs`, `ki-guides`, `ki-authoring`, `ki-repo-tools`, `ki-git`, and `ki-repo` audits.

### Outstanding concerns

None within the approved boundary. Cross-regime rollout remains independently owned outside this repository.

### Post-change review

The diff is limited to the canonical-only product boundary and its evidence. Canonical schema and kind validation remain active, and no release, version, installer, Homebrew, or downstream repository behavior changed.

### Mini recap

MGIT-CLI-005 is ready for human review as a net removal of pre-v1 compatibility behavior.

## Discussion

### Latest-only contract

Previous configuration files become ordinary irrelevant files. `mgit` does not read, migrate, reject, delete, synchronize, or explain them; only `.mgit.toml` participates in behavior.
