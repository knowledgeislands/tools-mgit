---
id: MGIT-CLI-011
area: CLI
title: Consistent command output
theme: cli
horizon: now
status: ready
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-09-28T09:22:45Z
updated_at: 2026-10-02T11:09:21Z
---

## Goal

Make repository identity and action progress easy to read consistently across ordinary commands and `sync`, both in a terminal and in captured output.

## Context

Ordinary command headers use checkout labels that hide worktree storage paths, while `sync` prints physical paths. Ordinary headers also emit ANSI color codes even when output is redirected. `sync` now announces each repository and its pull or push, but the command families do not share an output convention.

## Boundary

Keep repository selection and Git actions unchanged. This item does not create an interactive interface or a machine-readable output format.

## Current state

Ordinary command headers use checkout labels but always emit ANSI escapes. `sync` prints execution paths, exposing external worktree storage instead of the checkout label.

## Steps

- [ ] Emit ANSI styling only when standard output is a terminal and color is not disabled.
- [ ] Use the existing checkout labels for `sync` progress, confirmation, failure, and summary messages while retaining physical execution paths for Git operations.
- [ ] Test captured output and representative standard, nested, and external worktree labels; align the manual and running-commands guide.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `docs/guides/user/running-commands.md`, and `CHANGELOG.md`.

## Verify

Run focused Bats cases for redirected output and external worktrees, then the complete `tools-mgit` gate.

## Dependencies / blocks

The existing checkout label array supplies identity; no build-order dependency remains.

## Documentation impact

### Decision Records

No separate decision record is needed for the presentation convention.

### Specifications

Specify visible checkout identity and captured-output styling.

### Guides

Describe the output convention only where it helps users read command results.

### Roadmap

No follow-on roadmap item is expected.

## Discussion

### Presentation contract

Decide which messages need a checkout label versus a physical path, and when color should appear. Keep failure details visible and verify representative standard, nested, and external worktree output with and without a terminal.
