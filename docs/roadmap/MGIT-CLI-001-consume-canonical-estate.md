---
id: MGIT-CLI-001
title: Consume canonical estate
theme: cli
horizon: now
status: draft
transferred-from: TRD-e9dbff6e
blocks: []
blocked-by: []
baseline-ref: null
---

## Goal

Let mGit consume the canonical KI repository estate and declared store references while retaining each workspace manifest's authority over local grouping and selection.

## Context

This item adopts `TRD-e9dbff6e` from `tools-ki`. A canonical estate can provide a repository's HTTPS identity and a user-facing local key, while Knowledge Base store roles can identify notes, sources, and legacy bindings. mGit needs to determine the minimum shared contract it consumes and the local mapping it retains for workspace generation or selection.

The sender explicitly requires the Harness `ki-repo` kind and store-role contract before shared semantics are finalised. The related Harness proposal is `TRD-d2cd35f7`. The user has selected an independently executable local discovery phase, so this item may establish mGit's extension boundary without deciding or implementing shared semantics.

## Boundary

Do not decide or implement shared semantics before the Harness contract is available. Do not treat source or legacy stores as Git repositories, replace workspace-manifest authority, or write `tools-ki` as part of this work.

## Current state

The schema-1 `.mgit-workspace.toml` parser and selector use path-keyed repository and workspace members, repository structure, and optional clone sources. The workspace manifest remains the sole authority for selecting and grouping repositories. A repository-leaf `.mgit-config.toml` currently describes only cross-repository symlinks; mGit does not read KI repository identity, kind, or store-role declarations.

The adopted trade preserves the required shared boundary: canonical HTTPS home is identity, a local name is user-facing, and machine paths remain local bindings. The Harness has not yet published the contract that gives those categories final portable semantics.

## Steps

- [ ] Trace the workspace parser, selection flow, registration output, and repair preflight to identify the smallest read-only extension point for optional canonical-estate metadata without changing existing manifest selection.
- [ ] Define a local fixture matrix covering absent KI metadata, a declared canonical repository, a Knowledge Base with notes-only stores, optional sources or legacy stores, and bindings that are not Git repositories.
- [ ] Compare the published Harness `ki-repo` kind and store-role contract with the fixture matrix once available; record only the minimum mGit-specific mapping needed for workspace generation or selection.
- [ ] Decide whether the agreed mapping needs a manifest extension, a separate local binding source, or no new command surface; preserve schema-1 manifests when the contract supplies no usable optional metadata.
- [ ] Implement and test the selected mapping only after the shared contract and the local compatibility boundary are reviewable.

## Files touched

- `bin/mgit`
- `tests/mgit.bats`
- `README.md`, `man/mgit.1`, and relevant user guides when command or manifest behaviour changes
- Fixture workspace manifests and repository metadata used by the focused tests

## Verify

- Focused Bats fixtures prove that absent or malformed optional metadata leaves existing manifest selection unchanged.
- Focused Bats fixtures prove that canonical identity, local keys, and optional store bindings are consumed only at the agreed mGit boundary and never make a non-Git store a repository.
- `shellcheck bin/mgit install.sh`
- `bats tests/`

## Dependencies / blocks

The discovery and fixture design may proceed now. Final mapping and implementation are blocked until the Harness publishes a reviewable `ki-repo` kind and store-role contract from the work proposed by `TRD-d2cd35f7`.

## Discussion

### Authority model

Canonical HTTPS home remains repository identity. A local repository name is a user-facing key, while machine paths and optional store bindings remain local configuration. mGit may consume those declared facts, but each workspace manifest continues to decide its own groups and selected repositories.

### Shared-contract gate

The Harness contract must answer which repository and store facts are portable, how optional roles are represented, and what validation a consumer may rely on. mGit's local analysis should make that comparison ready, but must not choose those semantics in advance.

### Discovery boundary

Current exploration may inspect mGit's existing parser, selection, registration, and repair seams, then define fixtures that preserve the workspace manifest's authority. It must not add a speculative manifest field or make current users' repository selection depend on KI metadata.
