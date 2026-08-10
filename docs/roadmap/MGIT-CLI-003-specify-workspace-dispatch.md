---
id: MGIT-CLI-003
area: CLI
title: Specify workspace dispatch
theme: cli
horizon: next
status: done
blocks: []
blocked_by: []
baseline_ref: 1e9f889ac9a228251be7dc46ab562792b616a312
---

# Specify workspace dispatch

## Goal

Give maintainers and users a concise, testable description of how mgit builds a repository set and dispatches a command across it.

## Context

`tests/mgit.bats` already establishes the as-built behaviour for runtime discovery, workspace manifests, named groups, filters, Agora selection, worktree expansion, and command fan-out. The repository has no Specifications corpus yet, so these guarantees are otherwise distributed between the Bash implementation, tests, README, and manual.

## Boundary

This work does not specify release or installation behaviour, manifest generation or repair, repository-structure conversion, or worktree mutation. It documents only the existing runtime workspace-selection and multi-repository-dispatch surface.

## Current state

The repository declares `ki-specs`, but has no `docs/specs/` registry or area document. `bin/mgit` and the Bats suite are the authoritative as-built evidence.

## Steps

- [x] Declare and link the `ki-specs` capability for this repository.
- [x] Create a flat Specifications registry and a bounded workspace-dispatch area.
- [x] Record current discovery, selection, named-group, worktree-expansion, and dispatch behaviours with concrete Bats verification hooks.
- [x] Audit the roadmap, Specifications corpus, Markdown, shell source, and Bats suite.

## Files touched

- `.ki-config.toml`
- `docs/specs/index.md`
- `docs/specs/workspace-dispatch.md`
- `docs/roadmap/_ISSUES.md`
- `docs/roadmap/MGIT-CLI-003-specify-workspace-dispatch.md`

## Verify

`ki repo audit --skill ki-change-management-roadmap --skill ki-specs --skill ki-authoring --repo . && shellcheck bin/mgit install.sh && bats tests/`

## Dependencies / blocks

No implementation dependency is outstanding. The existing executable and Bats suite provide the as-built evidence; no user-facing behavior should change.

## Review

### Delivered

Adopted `ki-specs` and added one as-built area covering runtime workspace discovery, selection, named groups, repository/worktree expansion, and ordinary command dispatch.

### Summary of changes

- Declared `ki-specs` in `.ki-config.toml`.
- Added the `MGIT-WS` Specifications registry and fourteen requirements in `docs/specs/`.
- Added the retained roadmap record and advanced the CLI issue ledger through `003`.

### Verification

- `ki repo conform --skill ki-authoring --repo .` — pass; no changes required.
- `ki repo audit --skill ki-specs --repo .` — pass.
- `ki repo audit --skill ki-change-management-roadmap --repo .` — pass.
- `ki repo audit --skill ki-authoring --repo .` — pass.
- `shellcheck bin/mgit install.sh` — pass.
- `bats tests/` — pass (50 tests).
- `git diff --check` — pass.

### Outstanding concerns

The scope intentionally leaves release and installation behavior, manifest generation and repair, repository-structure conversion, and worktree mutation outside this first Specifications area. The single discovery-traversal requirement names the executable behavior; a focused Bats test for physical versus symlink-following traversal remains a Gap.

### Post-change review

Baseline: `1e9f889ac9a228251be7dc46ab562792b616a312`.

Delivery: `031a246002a5c0cdde3c9d1e8020c7471e818f63` (`docs(specs): specify workspace dispatch`).

No runtime behavior changed; the specification makes existing Bats-proven behavior and source-level safety boundaries explicit.

### Mini recap

The bounded as-built contract is now an auditable repository surface. Future changes to workspace discovery, selection, named groups, or dispatch should update the applicable `MGIT-WS` requirement and its verification hook in the same change.

## Done

Accepted by the user on 2026-08-10 after review of the recorded boundary, verification, and outstanding-scope note.

## Discussion

### Contract boundary

The specification is deliberately one area because repository-set construction and dispatch compose into one user-visible command surface. Requirements should state observable behavior and safety guarantees, with test names as verification hooks, rather than reproduce Bash control flow.

### Authority

The user explicitly approved adopting and applying `ki-specs` for this bounded area. Any broadened specification of mutation or release behavior requires separate work.
