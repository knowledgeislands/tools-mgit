---
id: MGIT-CLI-010
area: CLI
title: Report fan-out failures
theme: cli
horizon: now
status: awaiting-review
blocks: []
blocked_by: []
baseline_ref: f87f17297e5bdd0730de5cc604336de8366b536c
created_at: 2026-09-28T09:21:04Z
updated_at: 2026-10-02T11:12:47Z
---

## Goal

Make a command run across repositories report failure when any selected repository fails, while still reporting the outcome for every repository.

## Context

Ordinary Git and `-B` command dispatch currently returns the last repository command's exit status. An earlier failure followed by a successful last repository therefore appears successful to a caller. The manual documents this behavior, so changing it also changes a published CLI contract.

## Boundary

Keep the current repository selection, execution order, and continue-through-the-set behavior. This item does not change the exit rules for `mgit` management commands.

## Current state

Ordinary Git and `-B` fan-out return the final child status even when an earlier repository failed. Dispatch continues through all selected repositories.

## Steps

- [x] Track whether any selected child command fails while continuing through every checkout.
- [x] Return status 1 when any child fails and 0 only when all succeed, for both Git and `-B` dispatch.
- [x] Update the manual and accepted behavior specification, then test early failure followed by final success.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `docs/specs/workspace-dispatch.md`, and `CHANGELOG.md`.

## Verify

Run focused Bats tests for ordinary and bare dispatch, then the complete `tools-mgit` gate.

## Dependencies / blocks

No build-order dependency remains. Continue-through-the-set behavior and repository order stay unchanged.

## Documentation impact

### Decision Records

No separate decision record is needed; this item records the status-1 contract.

### Specifications

Define the aggregate failure result for ordinary and bare dispatch.

### Guides

Explain the caller-visible exit result in the running-commands guide.

### Roadmap

No follow-on roadmap item is expected.

## Review

### Delivered

From baseline `f87f17297e5bdd0730de5cc604336de8366b536c`, ordinary Git and `-B` dispatch continue across every selected checkout and return status `1` if any child fails. Management command results remain outside this item.

### Change Summary

`bin/mgit` accumulates child failures. `tests/mgit.bats` covers an early failure and successful final checkout in both dispatch modes. The manual, running-commands guide, changelog, and workspace-dispatch specification describe the result.

### Verification

The focused Bats case and complete gate passed: repository audit, ShellCheck, Bash syntax, Bats, mandoc lint, and `git diff --check`.

### Outstanding concerns

None.

### Post-change review

The result matches the goal without changing selection or execution order. The aggregate status gives callers a reliable failure signal, and the added test catches regression to final-child status.

### Mini recap

Fan-out failure reporting is delivered and verified; no follow-on work was identified.

## Discussion

### Exit status contract

Decide whether any failure should return a single nonzero status or preserve a particular child command's status. Update the manual and test both Git and `-B` dispatch with an early failure and a successful final repository.
