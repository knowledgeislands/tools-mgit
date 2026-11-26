---
id: KI-TOOL-MGIT-CLI-034
area: CLI
title: Push honours sync veto
kind: deliver
purpose: corrective
component: cli
priority: high
size: s
assignee: work/ki.summit
horizon: next
status: draft
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-11-21T10:58:22Z
updated_at: 2026-11-22T20:28:53Z
---

# Push honours sync veto

## Goal

Let a repository that sets `git config mgit.syncPush false` opt out of every push mgit makes across the selected set, so that `mgit push` and a push step in `mgit chain` cannot publish its held commits either.

## Context

Kitteth reported on 21 November 2026 that held commits went out on 19 and 20 November through Kris's own `mgit sync --push` and `mgit push`. [KI-TOOL-MGIT-CLI-033](https://github.com/knowledgeislands/tools-mgit/blob/70fffecb60e252880844892e21a9abd4625cb48b/docs/roadmap/KI-TOOL-MGIT-CLI-033-sync-push-guard.md), awaiting review, delivered Kris's MGIT-PUSH-GUARD decision: `mgit sync` pushes only with `--push`, and `mgit.syncPush` false is a hard per-repository veto that neither `--push` nor `-i` overrides.

The code confirms the gap. `push` is not an mgit-owned command (`is_mgit_command` in [`bin/mgit`](../../bin/mgit) names only `register`, `repair`, `doctor`, `diag`, `sync`, `overview`, `structure`, `worktree`, `chain`, `learn`, `completion`, `help` and `config`), so `mgit push` is ordinary Git pass-through and runs `git push` in every selected checkout. `mgit.syncPush` is read only inside `sync_command`. A `push` step in `mgit chain` runs the same pass-through, so it ignores the veto too.

No document states that `mgit push` is the deliberate way round the veto. The veto's scope follows from MGIT-PUSH-GUARD, which was about sync alone: KI-TOOL-MGIT-CLI-033's Boundary takes in only the `sync` command, and README, the running-commands guide, `man/mgit.1`, MGIT-WS-018 and the changelog all describe the veto as stopping sync. Pass-through was simply not considered, so the behaviour reads as an unintended gap rather than a designed override; but pass-through by design hands Git its command unchanged, so whether mgit should ever refuse a Git command is Kris's call.

## Boundary

- **In:** honouring a repository's `mgit.syncPush` false, or non-boolean value, when mgit runs `git push` through pass-through or a `chain` step across the selected set, naming the refusal in the same terms sync uses; the configuration key's name and documentation if the veto widens beyond sync; Bats cases in disposable repositories.
- **Out:** `mgit sync`'s push rule, which KI-TOOL-MGIT-CLI-033 owns; `git push` run directly, outside mgit; `-R` raw commands; any release or version bump.

## Current state

`mgit.syncPush` is read only inside `sync_command` in [`bin/mgit`](../../bin/mgit). `push` is not an mgit-owned command, so `mgit push` passes straight to `git push` in every selected checkout, and a `push` step in `mgit chain` runs the same pass-through; neither reads the veto. The documentation describes the veto as stopping sync alone. Three choices are still open, listed under Discussion; planning settles them before the record is Ready.

## Steps

- [ ] Settle the three open choices in Discussion with Kris: whether an explicit flag may override the veto, whether the key keeps its name or gains a general one, and whether pushing Git aliases are left out.
- [ ] Before pass-through or a `chain` step runs `git push`, read each selected checkout's `mgit.syncPush` with `git config --bool`; false, or a value Git cannot read as a boolean, skips that checkout's push, naming the reason as sync does.
- [ ] Update the usage text, the manual, README, the running-commands guide, MGIT-WS-018 and the changelog for the wider veto.
- [ ] Add Bats cases in disposable repositories for `mgit push` and a `chain` push step, with the veto false, true, unset and not a boolean.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `docs/specs/workspace-dispatch.md`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `CHANGELOG.md`.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes: `ki repo audit --repo .`, `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1` and `git diff --check`, with the new push and chain cases among the passing.

## Dependencies / blocks

None. It builds on KI-TOOL-MGIT-CLI-033's veto, and blocks nothing.

## Documentation impact

### Decision Records

None: the rationale is Kris's MGIT-PUSH-GUARD decision and his adoption of this record, quoted in Context and Discussion.

### Specifications

MGIT-WS-018 widens the veto from sync to every push mgit makes.

### Guides

The running-commands guide and README describe the veto as binding `mgit push` and `chain` push steps.

### Roadmap

None expected; any follow-on found in delivery is reported to ki.summit rather than captured.

## Discussion

The question for Kris: should the `mgit.syncPush` veto also bind `mgit push` and push steps in `mgit chain`, or should a repository keep `mgit push` as the explicit way to publish it? If it should bind them, the choices still open are whether any explicit flag may override it, whether the key keeps its sync-specific name or gains a general one such as `mgit.push`, and whether a Git alias that pushes, which mgit cannot see through, is left out. Captured as triage for Kris to adopt or cancel.

### Adoption

Kris adopted the record on 22 November 2026 on the question cards in Loreward's Home Chat: ADOPT-MGIT-034 a at about 19:58 GMT, "Adopt, draft at Soon", and, since the card offered Soon against ROADMAP-UPCOMING-NEW a, which admits new work only at Now or Next, ADOPT-MGIT-034-HORIZON a at about 20:10 GMT, "Next". Both answers are recorded in ki.summit's change 20, 4.2, in the Cairn store, `work/ki/ki.summit/20-ki-sop-main-legacy.change.md`. It is held by ki.summit for ki.tools while that seat is vacant. The adoption gate passes: Kris's approval, its home in tools-mgit's CLI, size `s`, and a known next step, settling the three choices above while planning it to Ready.
