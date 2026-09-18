---
id: MGIT-CLI-007
area: CLI
title: Synchronise repository set
theme: cli
horizon: now
status: done
blocks: []
blocked_by: []
baseline_ref: 78094b180cb0dab9a32cd47271fbf880f6767ad4
created_at: 2026-09-18T03:53:07Z
updated_at: 2026-09-18T04:11:50Z
---

# MGIT-CLI-007: Synchronise repository set

## Goal

Give people one concise command that brings every safe repository in the selected set up to date and makes exceptions immediately visible.

## Context

Running separate status, pull, and push sweeps produces repetitive output and makes it hard to spot the few repositories that need attention. A reserved `mgit sync` command can use standard Git commands, skip worktrees with local changes, report repositories that moved, and collapse already-current repositories into one count.

## Boundary

The command does not discard changes, create upstreams, resolve divergence, choose branches, force pushes, synchronise bare repositories, or hide Git failures. It keeps the existing repository-set selectors and filters.

## Current state

MGit can fan out arbitrary `git status`, `git pull`, and `git push` commands, but each sweep prints every repository independently and does not apply a safe status-before-network workflow.

## Steps

- [x] Add reserved `mgit sync` dispatch, help, and shell completion using `git status --short`, `git pull --ff-only`, and `git push`.
- [x] Report dirty, pulled, pushed, unsupported, and failed repositories individually while rolling already-current repositories into one summary count.
- [x] Cover clean, dirty, incoming, outgoing, no-upstream, divergent, and selection behavior in Bats.
- [x] Specify and document the command in the user guide, manual, README, and v1 baseline.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `README.md`, `docs/guides/user/README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, `man/mgit.1`, and `CHANGELOG.md`.

## Verify

Run `shellcheck bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1`, and `ki repo audit --repo .`.

## Dependencies / blocks

No build-order dependencies. The command composes the existing selected repository and active-worktree sets.

## Documentation impact

### Decision Records

No decision record is needed; this is a bounded CLI workflow over existing Git operations.

### Specifications

Add the observable synchronisation behavior to the workspace-dispatch specification.

### Guides

Explain the safety rule, action summaries, exceptional states, and use with existing selectors.

### Roadmap

Close this item after the implementation, tests, specification, guide, manual, and changelog agree.

## Review

### Delivered

From immutable baseline `78094b180cb0dab9a32cd47271fbf880f6767ad4`, MGit gained a reserved `sync` command over the existing selected worktree set. It uses standard Git commands, skips local changes, never forces integration or publication, and leaves unsupported or failed repositories unchanged.

### Summary of changes

`bin/mgit` now implements status, fast-forward pull, ahead-count, and push handling with compact per-action output and one already-current count. Help, Bash and Zsh completion, Bats fixtures, README, user guide, manual, v1 changelog baseline, and workspace-dispatch specification expose the command consistently.

### Verification

`shellcheck bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1`, and `ki repo audit --repo .` pass. Tests cover clean, dirty, incoming, outgoing, no-upstream, bare, divergent, filtered, help, and completion behavior.

### Outstanding concerns

None.

### Post-change review

The command provides the requested compact set overview while retaining visible exceptions and safe Git semantics. Any repository that did not reach a synchronized state makes the aggregate command fail.

### Mini recap

`mgit sync` is now the concise status, pull, and push workflow for a selected repository set. Its safety and output contract are durable in the specification and user guide.

## Done

Accepted 2026-09-18 by Kris Brown on review packet above.

## Discussion

### Command name

Use `sync`. The shorter name describes the intended result without implying that repositories are reset or rebuilt.

### Safety and Git semantics

Inspect each worktree before network operations. Dirty worktrees print their short status and are skipped. Clean tracking branches use a fast-forward-only pull before testing whether local commits need a normal push. Repositories that cannot follow that path remain unchanged, are reported, and make the overall command fail.

### Output shape

Name every repository that was pulled, pushed, skipped, unsupported, or failed. Count repositories that required no change and print one final already-in-sync line so a large healthy set stays compact.
