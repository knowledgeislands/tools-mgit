---
id: MGIT-CLI-003
area: CLI
title: Specify workspace dispatch
theme: cli
horizon: next
status: in-progress
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
- [ ] Audit the roadmap, Specifications corpus, Markdown, shell source, and Bats suite.

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

## Discussion

### Contract boundary

The specification is deliberately one area because repository-set construction and dispatch compose into one user-visible command surface. Requirements should state observable behavior and safety guarantees, with test names as verification hooks, rather than reproduce Bash control flow.

### Authority

The user explicitly approved adopting and applying `ki-specs` for this bounded area. Any broadened specification of mutation or release behavior requires separate work.
