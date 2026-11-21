---
id: KI-TOOL-MGIT-CLI-034
area: CLI
title: Push honours sync veto
priority: high
size: s
assignee: owner
status: triage
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-11-21T10:58:22Z
updated_at: 2026-11-21T10:58:22Z
---

# Push honours sync veto

## Goal

Let a repository that sets `git config mgit.syncPush false` opt out of every push mgit makes across the selected set, so that `mgit push` and a push step in `mgit chain` cannot publish its held commits either.

## Context

Kitteth reported on 21 November 2026 that held commits went out on 19 and 20 November through Kris's own `mgit sync --push` and `mgit push`. [KI-TOOL-MGIT-CLI-033](KI-TOOL-MGIT-CLI-033-sync-push-guard.md), awaiting review, delivered Kris's MGIT-PUSH-GUARD decision: `mgit sync` pushes only with `--push`, and `mgit.syncPush` false is a hard per-repository veto that neither `--push` nor `-i` overrides.

The code confirms the gap. `push` is not an mgit-owned command (`is_mgit_command` in [`bin/mgit`](../../bin/mgit) names only `register`, `repair`, `doctor`, `diag`, `sync`, `overview`, `structure`, `worktree`, `chain`, `learn`, `completion`, `help` and `config`), so `mgit push` is ordinary Git pass-through and runs `git push` in every selected checkout. `mgit.syncPush` is read only inside `sync_command`. A `push` step in `mgit chain` runs the same pass-through, so it ignores the veto too.

No document states that `mgit push` is the deliberate way round the veto. The veto's scope follows from MGIT-PUSH-GUARD, which was about sync alone: KI-TOOL-MGIT-CLI-033's Boundary takes in only the `sync` command, and README, the running-commands guide, `man/mgit.1`, MGIT-WS-018 and the changelog all describe the veto as stopping sync. Pass-through was simply not considered, so the behaviour reads as an unintended gap rather than a designed override; but pass-through by design hands Git its command unchanged, so whether mgit should ever refuse a Git command is Kris's call.

## Boundary

- **In:** honouring a repository's `mgit.syncPush` false, or non-boolean value, when mgit runs `git push` through pass-through or a `chain` step across the selected set, naming the refusal in the same terms sync uses; the configuration key's name and documentation if the veto widens beyond sync; Bats cases in disposable repositories.
- **Out:** `mgit sync`'s push rule, which KI-TOOL-MGIT-CLI-033 owns; `git push` run directly, outside mgit; `-R` raw commands; any release or version bump.

## Discussion

The question for Kris: should the `mgit.syncPush` veto also bind `mgit push` and push steps in `mgit chain`, or should a repository keep `mgit push` as the explicit way to publish it? If it should bind them, the choices still open are whether any explicit flag may override it, whether the key keeps its sync-specific name or gains a general one such as `mgit.push`, and whether a Git alias that pushes, which mgit cannot see through, is left out. Captured as triage for Kris to adopt or cancel; the coordinating brief proposed a draft at Soon, which needs his approval.
