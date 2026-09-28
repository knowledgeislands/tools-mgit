---
id: MGIT-CLI-010
area: CLI
title: Report fan-out failures
theme: cli
horizon: triage
status: draft
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-09-28T09:21:04Z
updated_at: 2026-09-28T09:21:04Z
---

## Goal

Make a command run across repositories report failure when any selected repository fails, while still reporting the outcome for every repository.

## Context

Ordinary Git and `-B` command dispatch currently returns the last repository command's exit status. An earlier failure followed by a successful last repository therefore appears successful to a caller. The manual documents this behavior, so changing it also changes a published CLI contract.

## Boundary

Keep the current repository selection, execution order, and continue-through-the-set behavior. This item does not change the exit rules for `mgit` management commands.

## Discussion

### Exit status contract

Decide whether any failure should return a single nonzero status or preserve a particular child command's status. Update the manual and test both Git and `-B` dispatch with an early failure and a successful final repository.
