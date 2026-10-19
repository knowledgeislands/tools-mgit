---
id: KI-TOOL-MGIT-CLI-026
area: CLI
title: Sync conflict precheck
kind: deliver
purpose: capability
component: cli
size: m
horizon: next
status: ready
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-18T08:37:21Z
updated_at: 2026-10-19T23:36:00Z
---

## Goal

When `mgit sync` finds a branch that has diverged from its upstream, it says whether merging its upstream would conflict, and in which files, without touching the branch, index or working tree, so Kris knows which divergences are easy before deciding what to do.

## Context

Kris asked on 18 October 2026, in the ways-of-working decisions log ("owner answers, batch 5"): "I'm guessing on MD Sync, if it did a fetch, can it work out if it's going to conflict, if it did a merge or not, or does it actually have to try and do a rebase or merge first? Either way, I'm interested to see what's happening." ("MD Sync" is speech-to-text for `mgit sync`.) The thread answered yes, with `git merge-tree --write-tree`, and captured this as MGIT-SYNC-PRECHECK.

Since [KI-TOOL-MGIT-CLI-020](https://github.com/knowledgeislands/tools-mgit/blob/2ca3a8e/docs/roadmap/KI-TOOL-MGIT-CLI-020-safe-parallel-sync.md), `sync` fetches in parallel, classifies each checkout against its freshly fetched upstream, and gives a diverged branch a one-line warning and nothing else; it never merges or rebases.

`git merge-tree --write-tree [--name-only] [--no-messages] HEAD @{upstream}` computes the merge in memory, writes only unreachable objects, and exits `0` for a clean merge and `1` for conflicts, listing the conflicted paths. A disposable check on 18 October 2026 confirmed both exit statuses and an unchanged working tree with Git 2.56.0.

## Boundary

- **In:** for each diverged checkout after the fetch, run the in-memory merge in the fetch worker or the classification pass, and extend the warning to say "would merge cleanly" or "would conflict in N files" (naming them under `--verbose`); a Git version probe and fallback; MGIT-WS-018, help, manual, running-commands guide, changelog and Bats cases against local bare origins.
- **Out:** performing the merge or rebase, or any change to the branch, index, working tree or remote; changing which checkouts `sync` acts on; parallel pushes; running sync against the real estate. No release.

## Current state

`sync_command` in `bin/mgit` classifies a checkout with commits on both sides of `HEAD...@{upstream}` as diverged and warns without any prediction.

## Steps

- [ ] In the serial classification pass, run `git merge-tree --write-tree --name-only --no-messages HEAD @{upstream}` for each diverged checkout. Exit `0` extends the warning to `diverged from U, A ahead and B behind, merge would be clean (skipped)`; exit `1` to `..., merge would conflict in N files (skipped)`, N counting the path lines after the tree line, with the paths printed as indented detail under `-v` only; any other exit, including an older Git that rejects `--write-tree`, keeps today's warning unchanged. No separate version probe.
- [ ] Add Bats cases against local bare origins for a clean divergence, a conflicting one with its paths under `-v` only, and the fallback through a `git` wrapper that refuses `merge-tree`; each asserts an unchanged HEAD, index and worktree and no merge or rebase state. Update the existing divergent case.
- [ ] Update MGIT-WS-018, `sync_usage`, `man/mgit.1`, `README.md`, the running-commands guide and `CHANGELOG.md`.
- [ ] Run the complete gate.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes; every case runs in disposable repositories with local bare origins.

## Dependencies / blocks

None; it builds on the sync already on `main`.

## Documentation impact

### Decision Records

None expected, unless planning chooses to declare a minimum Git version.

### Specifications

MGIT-WS-018 gains the merge prediction for diverged branches.

### Guides

Running commands shows the new warning.

### Roadmap

A rebase prediction would be a later record.

## Discussion

### Minimum Git version and fallback

`git merge-tree --write-tree` needs **Git 2.38** or later; `--name-only` and `--no-messages` arrived with it. mgit declares no minimum Git version today. Machines here have Git 2.56.0 (Homebrew) and 2.54.0 (Apple Git-157), both well above it.

**Fallback:** below 2.38, or if the probe fails, `sync` keeps today's plain "diverged" warning with no prediction. The deprecated trivial-merge form of `git merge-tree` is not a reliable conflict test and is not used.

### Merge versus rebase

`merge-tree` predicts a merge of the two tips. A rebase replays each local commit in turn, so it can conflict on an intermediate commit even when the final merge is clean, and the reverse. The first version should say "merge would be clean / conflict" and not claim to predict a rebase. `git replay` (Git 2.44+) can replay commits in memory, but is marked experimental; consider it later for a rebase prediction.

### Cost

One extra in-memory merge per diverged checkout only, which is rare across the estate; objects it writes are unreachable and left to `git gc`.

### Adoption

Captured and adopted into Next on 18 October 2026 by the ways-of-working accept-mgit run, under Kris's MGIT-SYNC-PRECHECK question and the thread's answer. Not planned.

### Planning

Planned to Ready on 20 October 2026 by the tools-burndown burnmgit run, `size: m` under MGIT-026-SIZE a). Decided under HIGH-APPLY, 20 October:

- **Merge only.** The Goal predicts a merge, not a rebase, as the Discussion above argues; a rebase prediction through `git replay` is offered to the coordinator as an idea, not captured, under CAPTURE-GATE.
- **No version probe.** The `merge-tree` exit status itself is the probe: `0` clean, `1` conflicts, anything else falls back to today's warning. This costs nothing when no branch has diverged and needs no Git version parsing.
- **Wording.** The prediction is appended to the existing diverged line, so the line stays one warning; conflicted paths appear under `-v` only, as indented detail like `git status --short` for a dirty checkout.
- **Interaction with [KI-TOOL-MGIT-CLI-030](KI-TOOL-MGIT-CLI-030-sync-closing-summary.md).** 030 is still a draft; whichever lands second carries the prediction into its closing detail line.
