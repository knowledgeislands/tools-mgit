---
id: MGIT-CLI-013
area: CLI
title: Clarify selector applicability
theme: cli
horizon: triage
status: draft
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-09-28T09:26:16Z
updated_at: 2026-09-28T09:26:16Z
---

## Goal

Make it clear which repository-selection options affect each command, so a command cannot silently operate on a broader set than the user expected.

## Context

`--filter` narrows ordinary dispatch, `sync`, `structure`, and `worktree`, but does not change what `register` or `repair` reads. `--all-worktrees` affects listing, ordinary dispatch, and `sync`, but not `structure` or worktree management. These exceptions are documented, yet the global parser still accepts option combinations whose effect may be absent or surprising.

## Boundary

Do not silently apply filtering to registration or repair as part of this intake item. The separate MGIT-CLI-009 record owns any schema or named-group simplification.

## Discussion

### Option contract

Review each global selector against the command groups. Decide whether an inapplicable combination should be rejected, warned about, or given a defined effect; account for compatibility with existing scripts. Keep help, completion, guides, and tests aligned with the chosen contract.
