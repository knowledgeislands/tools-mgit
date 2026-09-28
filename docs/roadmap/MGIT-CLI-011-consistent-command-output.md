---
id: MGIT-CLI-011
area: CLI
title: Consistent command output
theme: cli
horizon: triage
status: draft
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-09-28T09:22:45Z
updated_at: 2026-09-28T09:22:45Z
---

## Goal

Make repository identity and action progress easy to read consistently across ordinary commands and `sync`, both in a terminal and in captured output.

## Context

Ordinary command headers use checkout labels that hide worktree storage paths, while `sync` prints physical paths. Ordinary headers also emit ANSI color codes even when output is redirected. `sync` now announces each repository and its pull or push, but the command families do not share an output convention.

## Boundary

Keep repository selection and Git actions unchanged. This item does not create an interactive interface or a machine-readable output format.

## Discussion

### Presentation contract

Decide which messages need a checkout label versus a physical path, and when color should appear. Keep failure details visible and verify representative standard, nested, and external worktree output with and without a terminal.
