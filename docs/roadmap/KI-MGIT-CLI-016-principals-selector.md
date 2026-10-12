---
id: KI-MGIT-CLI-016
area: CLI
title: Principals selector
kind: deliver
purpose: capability
component: cli
horizon: now
status: ready
blocks: []
blocked_by: []
baseline_ref: 825130706d5297568d068672bd376675fcc51be8
created_at: 2026-10-12T04:20:00Z
updated_at: 2026-10-12T04:20:00Z
---

# Principals selector

## Goal

`mgit --principals` selects the registered territory Capitals through `ki territory roots --null --principals`, in KI's order, and composes with `--filter` and every command exactly as `--estate` does.

## Context

Master state-of-play Decision 84 (12 October 2026, 06:03 BST) asks for `mgit --principals` after Decision 82 added the selector to `ki`. The producer contract is KI-TOOL-CLI-119 in tools-ki: a third primary scope beside `--territory` and `--estate`, with the Knowledge Islands Principal first and the other Capitals alphabetical by territory name. The decision is the delivery authority; it grants no acceptance, release or Homebrew publish.

## Boundary

- **In:** the global `--principals` selector, its exclusivity and command applicability, help, both completions, manual, README, specification, user guide, changelog and tests.
- **Out:** reimplementing Capital selection or ordering in mgit, register saved locations (`principals` is not a saved-location kind, like `estate`), version bump, release and Homebrew publication.

## Current state

`select_ki_roots` in `bin/mgit` buffers and validates `ki territory roots --null` output for `--territory HANDLE` or `--estate`, passing repeated filters to KI, and preserves the producer's order. The option parser treats `--territory` and `--estate` as one exclusive slot (`ki_selector`).

## Steps

- [ ] Add `--principals` to the exclusive selector slot and pass it to the producer unchanged; reuse every existing validation and the estate's command-applicability rules (rejected by register, repair, structure, worktree and the rest; accepted by listing, pass-through and sync).
- [ ] Update usage, Bash and Zsh completion, manual, README, workspace-dispatch specification, running-commands guide and changelog.
- [ ] Extend the strict fake producer and add Bats cases for selection, producer order, filters, conflicts and rejected commands.
- [ ] Run the complete gate.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `tests/territory-producer.bats`, `man/mgit.1`, `README.md`, `CHANGELOG.md`, `docs/specs/workspace-dispatch.md`, `docs/guides/user/running-commands.md`, `docs/roadmap/_ISSUES.md` and this record.

## Verify

`ki repo audit --repo .`, `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1`, `git diff --check`. The producer proof with `MGIT_KI_PRODUCER` runs once a `ki` with `--principals` is available.

## Dependencies / blocks

Runtime use needs a `ki` that accepts `territory roots --principals` (KI-TOOL-CLI-119). The mgit change is built against that contract and its tests use the strict protocol double.

## Documentation impact

### Decision Records

None; Decisions 82 and 84 are recorded in the Master decisions log.

### Specifications

Workspace dispatch names the third producer scope and its order.

### Guides

Running commands shows `mgit --principals`.

### Roadmap

This single record.

## Discussion

### Authority

Decision 84 grants detached local delivery, commits with the Claude co-author trailer, and a fast-forward push of the delivery. Delivery stops at awaiting-review; acceptance is the owner's.
