---
id: MGIT-CLI-012
area: CLI
title: Consistent mutation controls
theme: cli
horizon: now
status: ready
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-09-28T09:24:23Z
updated_at: 2026-10-02T11:09:21Z
---

## Goal

Let users inspect and confirm changes made by `mgit` management commands through clear, consistent controls while retaining automatic execution by default.

## Context

`sync` offers `-i` / `--interactive` confirmation for each pull and push, `structure` offers `--dry-run`, and `worktree add` preflights the set. `register` and `repair` have no comparable preview or confirmation. The running-commands guide also omits the recently added `sync -i` behavior.

## Boundary

Keep ordinary Git and `-B` command pass-through under the invoked command's own interaction rules. Do not change default automatic execution or the meaning of `worktree remove --force` as part of this intake item.

## Current state

`sync -i` confirms pull and push, `structure --dry-run` previews conversion, and worktree addition preflights. `register` and `repair` execute automatically without a preview.

## Steps

- [ ] Add `register --dry-run` and `repair --dry-run` so each reports proposed file or clone actions without writing or cloning; keep automatic execution as the default.
- [ ] Preserve preflight failure behavior and avoid Chezmoi writes during a register preview.
- [ ] Align help, completion, manual, running-commands and repository-set guides, specifications, and changelog.
- [ ] Test previews leave manifests and repositories untouched, including registration add/rm and missing clone targets.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, completion output, `docs/guides/user/running-commands.md`, `docs/guides/user/repository-sets.md`, `docs/specs/workspace-dispatch.md`, and `CHANGELOG.md`.

## Verify

Run focused Bats preview and execution cases, then the complete `tools-mgit` gate.

## Dependencies / blocks

Registration's manifest format from the delivered manifest item is the baseline. Ordinary Git and `-B` pass-through keep their own interaction rules.

## Documentation impact

### Decision Records

No separate decision record is needed; the scoped preview policy is captured here.

### Specifications

Specify preview behavior, no-write guarantees, and automatic defaults.

### Guides

Document `sync -i` and both new preview options where users choose a mutation.

### Roadmap

No follow-on roadmap item is expected.

## Discussion

### Command scope

Decide which `mgit`-owned mutations benefit from a preview, per-repository confirmation, or both. A shared option should be offered only where its meaning is consistent; command-specific controls may be clearer.

### Guidance alignment

Bring the running-commands guide and accepted behavior documentation up to date with `sync -i`, and keep help, completion, tests, and the manual aligned with any later control changes.
