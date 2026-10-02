---
id: MGIT-CLI-009
area: CLI
title: Prune manifest scaffolding
theme: cli
horizon: now
status: ready
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-09-27T18:59:44Z
updated_at: 2026-10-02T10:47:29Z
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

- [ ] Make `mgit` read existing schema-1 documents and new documents without a schema; write new workspace members directly under `members` and omit schema from both document kinds.
- [ ] Use the direct member map for workspace selection and `repair`; remove `mgit group` and `--group` from the public command surface, completion, and tests.
- [ ] Make `ki` accept documents without schema as the current manifest contract, including direct workspace members, while retaining schema-1 group parsing for existing manifests.
- [ ] Align specifications, guides, README, help, manual, and changelog with the migration and removed commands.
- [ ] Verify old and new manifests, malformed mixed forms, selection, repair, registration, and the `ki` repository-target CLI contract.

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

## Discussion

### Migration questions

The user chose a group-free, unversioned new format. An absent schema is treated as the current manifest contract; explicit `schema = 1` remains a legacy read path. The direct `members` map supplies both selection and `repair` structure. `tools-ki` must accept both formats before the writer changes.
