---
id: MGIT-CLI-009
area: CLI
title: Prune manifest scaffolding
theme: cli
horizon: now
status: awaiting-review
blocks: []
blocked_by: []
baseline_ref: 780bc9272bd6e2de9961c6cc4342cc9e64391c7a
created_at: 2026-09-27T18:59:44Z
updated_at: 2026-10-02T11:08:12Z
---

## Goal

Simplify `mgit` configuration by removing schema numbering and named groups from newly written manifests.

## Context

The `locations` list records where registration searches. Existing `.mgit.toml` documents carry `schema = 1` and group tables, including a structural `default` group used by repository selection and `repair`. The live estate manifest uses only that structural group. `tools-ki` reads the format directly and must accept the replacement before it is written.

## Boundary

Keep the distinction between workspace and repository documents and preserve safe reading of existing schema-1 manifests. Do not add a new numeric schema version or change repository selection order, registration locations, or clone behavior. Do not rewrite the live estate manifest as part of this item.

## Current state

`mgit register` writes schema-1 workspace and repository documents. Workspace members live under `groups.default.members`, alternative groups have management commands and a selector, and `repair` uses structural default members. `tools-ki` requires schema 1 and groups. No live alternative group was found in the local estate manifest.

## Steps

- [x] Make `mgit` read existing schema-1 documents and new documents without a schema; write new workspace members directly under `members` and omit schema from both document kinds.
- [x] Use the direct member map for workspace selection and `repair`; remove `mgit group` and `--group` from the public command surface, completion, and tests.
- [x] Make `ki` accept documents without schema as the current manifest contract, including direct workspace members, while retaining schema-1 group parsing for existing manifests.
- [x] Align specifications, guides, README, help, manual, and changelog with the migration and removed commands.
- [x] Verify old and new manifests, malformed mixed forms, selection, repair, registration, and the `ki` repository-target CLI contract.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `README.md`, `CHANGELOG.md`, relevant user guides and specifications, plus `tools-ki/src/core/repository/mgit.ts`, its repository-target CLI tests, and its repository operations guide and specification.

## Verify

Run the complete `tools-mgit` CI-equivalent gate, focused `tools-ki` repository-target tests and its required quality gate, and disposable-manifest checks for legacy and new documents.

## Dependencies / blocks

The `tools-ki` reader change must be verified before `mgit` emits the new shape. Existing schema-1 manifests remain readable. The live estate manifest is outside both repositories and may be regenerated after the compatible tools are available.

## Documentation impact

### Decision Records

No separate decision record is needed; this item records the user-approved format and compatibility choice.

### Specifications

Update both tools' accepted manifest contracts and selection evidence.

### Guides

Replace group instructions and examples with direct membership and document the legacy read path.

### Roadmap

This item resolves the pending manifest simplification; selector-applicability work must reflect the removed `--group` option.

## Review

### Delivered

The approved group-free, unversioned manifest contract is implemented from baseline `780bc9272bd6e2de9961c6cc4342cc9e64391c7a`. New workspace and repository documents omit `schema`; workspaces write direct members. Existing schema-1 manifests remain readable. The live estate manifest was not rewritten.

### Change Summary

`bin/mgit` now reads both forms, writes the direct form, and removes group commands and selection. Tests, completion, help, manual, README, guides, specifications, and the Pre-1.0 changelog reflect that contract. The coordinated `tools-ki` reader, tests, and documents landed in local commit `de1ebd2b9ebe562df00ae110bb339fa644762286`.

### Verification

The `tools-mgit` gate passed: `ki repo audit --repo .`, `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1`, and `git diff --check`. The rendered manual was inspected. In `tools-ki`, the repository audit, TypeScript check, Biome check, and full coverage gate passed: 958 tests and 100% statements, branches, functions, and lines.

### Outstanding concerns

No delivery blocker remains. The generic `ki-repo-tools` judgment guideline recommends numeric schemas for evolving formats; this item follows the user's explicit decision to omit one from new mGit manifests while preserving strict kind and shape validation.

### Post-change review

New manifests are simpler, while legacy grouped manifests retain a read path. Registration refuses to drop alternative groups silently. The cross-tool reader is committed and verified; the local mGit change is ready for review without publication.

### Mini recap

Group management and schema fields are removed from new mGit output, the compatible KI reader is in place, and both tools pass their gates. No external manifest was rewritten; release preparation remains local.

## Discussion

### Migration questions

The user chose a group-free, unversioned new format. An absent schema is treated as the current manifest contract; explicit `schema = 1` remains a legacy read path. The direct `members` map supplies both selection and `repair` structure. `tools-ki` must accept both formats before the writer changes.
