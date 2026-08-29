---
id: MGIT-CLI-005
title: Canonical-only configuration
area: CLI
theme: cli
horizon: next
status: draft
blocks: []
blocked_by: []
baseline_ref: null
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

- [ ] Remove every previous-format constant and runtime branch while preserving canonical kind validation.
- [ ] Remove previous-format fixtures and assertions from the Bats suite, retaining canonical registration and validation coverage.
- [ ] Remove migration guidance from README, changelog, guide, manual, help, and completion-facing text.
- [ ] Deprecate MGIT-WS-016 and MGIT-WS-017 without reusing their append-only identifiers.
- [ ] Run the complete shell, Bats, manual, documentation, repository, and zero-reference verification gates.

## Files touched

- `bin/mgit`
- `tests/mgit.bats`
- `README.md`
- `CHANGELOG.md`
- `docs/guides/user/README.md`
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

## Discussion

### Latest-only contract

Previous configuration files become ordinary irrelevant files. `mgit` does not read, migrate, reject, delete, synchronize, or explain them; only `.mgit.toml` participates in behavior.
