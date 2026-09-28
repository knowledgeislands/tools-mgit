---
id: MGIT-CLI-012
area: CLI
title: Consistent mutation controls
theme: cli
horizon: triage
status: draft
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-09-28T09:24:23Z
updated_at: 2026-09-28T09:24:23Z
---

## Goal

Let users inspect and confirm changes made by `mgit` management commands through clear, consistent controls while retaining automatic execution by default.

## Context

`sync` offers `-i` / `--interactive` confirmation for each pull and push, `structure` offers `--dry-run`, and `worktree add` preflights the set. `register` and `repair` have no comparable preview or confirmation. The running-commands guide also omits the recently added `sync -i` behavior.

## Boundary

Keep ordinary Git and `-B` command pass-through under the invoked command's own interaction rules. Do not change default automatic execution or the meaning of `worktree remove --force` as part of this intake item.

## Discussion

### Command scope

Decide which `mgit`-owned mutations benefit from a preview, per-repository confirmation, or both. A shared option should be offered only where its meaning is consistent; command-specific controls may be clearer.

### Guidance alignment

Bring the running-commands guide and accepted behavior documentation up to date with `sync -i`, and keep help, completion, tests, and the manual aligned with any later control changes.
