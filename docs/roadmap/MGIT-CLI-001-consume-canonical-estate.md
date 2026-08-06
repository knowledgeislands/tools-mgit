---
id: MGIT-CLI-001
title: Map canonical estate
theme: cli
horizon: now
status: in-progress
transferred-from: TRD-e9dbff6e
blocks: [MGIT-CLI-002]
blocked-by: []
baseline-ref: 1bf33a2cd6a6673063091247595493c24cc11498
---

## Goal

Produce the mGit-side discovery evidence needed to consume canonical KI repository and store references later, without changing current workspace selection. The result identifies the smallest safe integration boundary and a fixture matrix for the eventual implementation.

## Context

This item adopts `TRD-e9dbff6e` from `tools-ki`. A canonical estate can provide a repository's HTTPS identity and a user-facing local key, while Knowledge Base store roles can identify notes, sources, and legacy bindings. mGit needs to determine the minimum shared contract it consumes and the local mapping it retains for workspace generation or selection.

The sender explicitly requires the Harness `ki-repo` kind and store-role contract before shared semantics are finalised. The related Harness proposal is `TRD-d2cd35f7`. The user has selected this independently executable local discovery phase; `MGIT-CLI-002` holds the later implementation.

## Boundary

Do not decide or implement shared semantics, add a manifest field, or change mGit runtime behaviour. Do not treat source or legacy stores as Git repositories, replace workspace-manifest authority, or write `tools-ki` as part of this work.

## Current state

The schema-1 `.mgit-workspace.toml` parser and selector use path-keyed repository and workspace members, repository structure, and optional clone sources. The workspace manifest remains the sole authority for selecting and grouping repositories. A repository-leaf `.mgit-config.toml` currently describes only cross-repository symlinks; mGit does not read KI repository identity, kind, or store-role declarations.

The adopted trade preserves the required shared boundary: canonical HTTPS home is identity, a local name is user-facing, and machine paths remain local bindings. The Harness has not yet published the contract that gives those categories final portable semantics.

## Steps

- [x] Trace the workspace parser, selection flow, registration output, and repair preflight to identify the smallest read-only extension point for optional canonical-estate metadata without changing existing manifest selection.
- [x] Define a local fixture matrix covering absent KI metadata, a declared canonical repository, a Knowledge Base with notes-only stores, optional sources or legacy stores, and bindings that are not Git repositories.
- [x] Record the resulting local boundary, including why no current command or schema change is justified before the shared contract.
- [x] Hand the implementation boundary to `MGIT-CLI-002` without selecting a speculative manifest or command surface.

## Files touched

- `docs/roadmap/MGIT-CLI-001-consume-canonical-estate.md`
- Read-only inspection of `bin/mgit`, `tests/mgit.bats`, `README.md`, and `man/mgit.1`

## Verify

- The recorded parser, selection, registration, and repair seams are traceable to the inspected source and tests.
- The fixture matrix explicitly preserves schema-1 selection when KI metadata is absent or malformed, and never classifies a non-Git store as a repository.
- `ki repo audit --skill ki-roadmap --repo .`

## Dependencies / blocks

This discovery is ready and has no external blocker. `MGIT-CLI-002` remains blocked until this discovery is complete and the Harness publishes a reviewable `ki-repo` kind and store-role contract from the work proposed by `TRD-d2cd35f7`.

## Discussion

### Authority model

Canonical HTTPS home remains repository identity. A local repository name is a user-facing key, while machine paths and optional store bindings remain local configuration. mGit may consume those declared facts, but each workspace manifest continues to decide its own groups and selected repositories.

### Implementation handoff

The discovery must name the existing mGit seams and fixtures, but must not choose a manifest extension, a separate local binding, or a new command surface. The implementation record may make that choice only after it compares the published Harness contract with this local evidence.

### Discovery findings

`parse_workspace` is a strict schema-1 parser. It accepts only `schema`, `default`, and member `kind`, `type`, and `source` fields, rejects unknown tables and fields, and stores only those five record values. `select_workspace` consumes member kind and path to select existing Git repositories; `repair_preflight` and `repair_tree` additionally consume structural type and optional clone source for default-group repository members. Optional KI metadata cannot enter this pipeline without a deliberate schema and parser change, and it must not reach repair as a repository member.

`register_tree` regenerates every structural default group and retains non-default groups only as kind and path. It would therefore discard any speculative schema-1 extension. Repository-leaf `.mgit-config.toml` files are likewise regenerated by `register_repo` for cross-repository symlinks. Although `parse_mgit` can emit legacy keyed member records, current set assembly consumes only symlink records; that file is not a stable canonical-estate input or selection surface.

The smallest current boundary is consequently read-only discovery only: retain workspace manifests as the sole grouping and selection authority, and wait for the Harness contract before choosing a separate local binding source, a versioned schema extension, or no mGit input at all.

### Fixture matrix

- **Absent or malformed KI metadata** — existing schema-1 selection and `register` output stay unchanged; parser rejection remains explicit rather than partially accepting an extension.
- **Declared canonical repository** — any future identity and local-key mapping must be optional and must not alter the path-keyed selected repository set without an explicit manifest or binding decision.
- **Knowledge Base with notes-only stores** — a notes store is not a repository member, is not selected, and does not enter repair.
- **Sources or legacy stores** — these remain optional local bindings, never clone targets or structural default-group repository members.
- **Non-Git binding** — mGit must not pass it to `repo_type`, add it to the final repository set, or attempt to replace or repair it.

### Discovery boundary

Current exploration may inspect mGit's existing parser, selection, registration, and repair seams, then define fixtures that preserve the workspace manifest's authority. It must not add a speculative manifest field or make current users' repository selection depend on KI metadata.
