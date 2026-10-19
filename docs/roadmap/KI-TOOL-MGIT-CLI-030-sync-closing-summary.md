---
id: KI-TOOL-MGIT-CLI-030
area: CLI
title: Sync closing summary
kind: deliver
purpose: capability
project: tools-burndown
component: cli
priority: high
size: m
horizon: now
status: awaiting-review
blocks: []
blocked_by: []
baseline_ref: 72d38213fb1611f0d4b6b6dfaa68118d0282e9d2
created_at: 2026-10-19T21:10:01Z
updated_at: 2026-10-20T00:45:00Z
---

# Sync Closing Summary

## Goal

`mgit sync` ends with one closing tally that accounts for every selected repository by outcome, in sync, pulled, pushed, skipped and failed, and names each skipped repository with its reason and any commits it still holds unpushed or unpulled, so a run never leaves work stranded without saying so. The tally reads like the closing line `mgit st` and `mgit overview` already print, and follows the `ki-repo-tools` [command-line conventions](/Users/krisbrown/.local/share/ki/harnesses/knowledgeislands/ki-agentic-harness/skills/repo-structure/ki-repo-tools/references/standards-cli-conventions.md).

## Context

Kris, 19 October 2026, SYNC-SUMMARY in the [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md): "mgit sync could do with a better summary". The run printed, in order, a skip line for ki-agentic-harness (`local changes (skipped)`) with four `M` paths, `ki-principal: pushed 1 commit`, and `55 repositories already in sync`. `mgit st` then showed ki-agentic-harness `[ahead 5]`: five commits stayed unpushed, the sync output never said so, and nothing added up the 57 repositories.

How `sync_command` in [`bin/mgit`](../../bin/mgit) reports today:

- Each changed or troubled checkout gets one `mgit sync: <label>: <outcome>` line on standard output as it is reached: `pulled N commits`, `pushed N commits`, `local changes (skipped)` followed by `git status --short`, `detached HEAD (skipped)`, `branch B has no upstream (skipped)`, `fetch from R failed (skipped)`, `diverged from U, A ahead and B behind (skipped)`, and `status failed`, `cannot compare with upstream`, `pull failed` or `push failed`.
- The closing lines count only three things: `N repositories already in sync`, `N actions skipped by user` under `-i`, and `N bare repositories skipped` without `-v`. Pulled, pushed, warned and failed checkouts are never counted, so the reader adds them up from the lines above.
- The local-changes check runs before the ahead and behind count, so a dirty checkout's unpushed or unpulled commits are never computed or shown. Its branch is still fetched: the fetch pass selects by branch and upstream, not cleanliness, so a fresh behind count is available. The manual and the running-commands guide say sync fetches every _clean_ tracking branch, which the code does not match; planning should settle which is meant.
- Every skip except a user's `-i` refusal sets the exit status to `1`, as does a bare repository.

The other fan-out commands already close with one tally line. Ordinary dispatch, which `mgit st` uses, prints `mgit: 57 repositories: N quiet, N with output, N failed: label (exit n), …`, naming each failure; `mgit overview` prints `mgit overview: N repositories: N clean, N need attention, N failed`. Both also give `--json` a `summary` object; `sync` has no `--json`.

[MGIT-WS-018](../specs/workspace-dispatch.md#mgit-ws-018--repository-set-synchronization) specifies today's output: name changed repositories and warnings, and collapse current and bare repositories into counts. The `sync` Bats cases in [`tests/mgit.bats`](../../tests/mgit.bats) assert those closing lines.

## Boundary

- **In:** the closing tally and skipped-repository detail in `sync_command`; ahead and behind counts for checkouts skipped after their upstream is known; MGIT-WS-018, `sync` help, manual, README, running-commands guide and changelog; Bats cases against local bare origins in disposable repositories, updating the existing `sync` cases.
- **Out:** changing which checkouts `sync` pulls, pushes or skips, or acting on a dirty checkout; merge prediction for diverged branches, which [KI-TOOL-MGIT-CLI-026](KI-TOOL-MGIT-CLI-026-sync-conflict-precheck.md) owns; option-parsing departures, which [KI-TOOL-MGIT-CLI-029](KI-TOOL-MGIT-CLI-029-cli-convention-departures.md) owns; summaries of other commands; running `sync` against the real estate.

## Shaping

**Approach:** count each checkout's outcome in `sync_command` as it is reached, compute ahead and behind for a skipped checkout whose upstream is known, and print one closing tally after the per-repository lines, in the shape `mgit st` and `mgit overview` already use; update MGIT-WS-018, every `sync` Bats case and the four documents in Boundary together.

**Dependencies:** none blocking. Wording interacts with [KI-TOOL-MGIT-CLI-026](KI-TOOL-MGIT-CLI-026-sync-conflict-precheck.md), whichever lands second; a stream or option-parsing departure found here goes to [KI-TOOL-MGIT-CLI-029](KI-TOOL-MGIT-CLI-029-cli-convention-departures.md).

**Decisions still needed:** none; all nine are decided in Discussion.

**Readiness:** Ready once SYNC-CATEGORIES and SYNC-STREAMS landed on 20 October.

## Current state

`sync_command` in [`bin/mgit`](../../bin/mgit) keeps three counters, `synced`, `skipped` for a user's `-i` refusal and `bare_count`, and one `failed` flag; pulled, pushed, warned and failed checkouts are not counted, so no total can be printed today. The local-changes skip `continue`s before the upstream lookup and the `rev-list --left-right --count`, so a dirty checkout's ahead and behind are never computed, although its branch is still fetched. A `q` answer or end of input under `-i` returns `1` straight after `runner_cleanup`, printing no closing lines. All output goes to standard output and `sync` has no `--json`.

[MGIT-WS-018](../specs/workspace-dispatch.md#mgit-ws-018--repository-set-synchronization), the manual, the README and the [running-commands guide](../guides/user/running-commands.md) describe today's closing counts, and the specification, manual and guide say only _clean_ tracking branches are fetched, which the code does not match. Six `sync` Bats cases in [`tests/mgit.bats`](../../tests/mgit.bats) assert `already in sync` closing lines.

Under `-i`, any answer other than yes or no, `q` included, reprompts; only the end of input stops the run early. No gaps remain.

## Steps

- [x] Give every selected checkout exactly one outcome in `sync_command` - in sync, pulled, pushed, skipped or failed - recording each skipped or failed checkout's label and reason. Local changes, detached HEAD, no upstream, divergence, bare repositories and `-i` refusals are skipped; a failed status, fetch, comparison, pull or push is failed; a dirty checkout whose fetch also failed is failed with both reasons, `local changes, fetch from R failed`.
- [x] For a skipped checkout on a branch whose upstream resolves, compute ahead and behind of the checked-out branch against `@{upstream}`; mark the counts `stale` where that checkout's fetch failed, and give a detached HEAD or a branch without an upstream no counts, saying so rather than printing zeros. Which checkouts are pulled, pushed or skipped does not change.
- [x] Replace the closing count lines with `mgit sync: N repositories: N in sync, N pulled, N pushed, N skipped, N failed`, zero counts included, counting selected checkouts (linked worktrees under `-W` too), then one indented line per skipped or failed checkout, such as `ki-agentic-harness: local changes, 5 ahead, 0 behind` indented two spaces. Print it identically with and without `-v`, bare repositories always counted as skipped; `-v` adds only progress lines.
- [x] When interactive input ends, print the tally and detail for the checkouts reached, with `N not reached` added to the tally so it still sums to the selection, and exit `1`. Keep every other exit status as it is.
- [x] Send skip, warning and failure lines with their indented detail, `-v` progress and `-i` prompts to standard error; keep `pulled` and `pushed` lines, the tally and its detail on standard output.
- [x] Update every `sync` Bats case and add cases for a dirty checkout ahead of and behind its upstream, a failed fetch with stale counts, a detached HEAD, an `-i` refusal, interactive input ending, and a mixed run whose tally sums to the selected set, against local bare origins in disposable repositories.
- [x] Update MGIT-WS-018, `sync_usage`, `man/mgit.1`, `README.md`, the running-commands guide and `CHANGELOG.md`; correct the clean-branch wording to say every branch with a remote upstream is fetched, and that a branch tracking a local branch (remote `.`) needs no fetch.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `docs/specs/workspace-dispatch.md`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md` and `CHANGELOG.md`.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes: `shellcheck bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1` and `git diff --check`. The new Bats cases assert the exact tally line, that its counts sum to the selected checkout count, that a dirty checkout ahead of its upstream is named after the tally with its unpushed count, that a failed fetch's counts are marked `stale`, and that ending interactive input prints the tally with `not reached`.

## Dependencies / blocks

None. Blocks nothing. KI-TOOL-MGIT-CLI-026 rewords the diverged warning line, so whichever lands second should rebase its wording on the other.

## Documentation impact

### Decision Records

None: the tally follows the existing dispatch and `overview` closing-line pattern, and SYNC-STREAMS b) brings `sync` into line with the `ki-repo-tools` stream convention, so no departure is left to record.

### Specifications

MGIT-WS-018 changes: its closing-count clause is replaced by the settled tally, it gains the held-commit detail for skipped checkouts, and its clean-branch fetch wording is corrected or the behaviour narrowed under choice 9; its Verify list names the new Bats cases.

### Guides

The running-commands guide's `sync` section describes the new tally and skipped detail and the settled clean-branch wording; the README and manual change to match.

### Roadmap

None beyond the KI-TOOL-MGIT-CLI-026 wording interaction and any departure routed to KI-TOOL-MGIT-CLI-029. `sync --json`, deferred under choice 7, is offered to the coordinator as an idea, not captured, under CAPTURE-GATE.

## Review

### Delivered

Within the approved boundary, from baseline `72d3821`: `mgit sync` gives every selected checkout one of five outcomes and closes with `mgit sync: N repositories: N in sync, N pulled, N pushed, N skipped, N failed`, adding `N not reached` when interactive input ends, then one line indented two spaces per skipped or failed checkout with its reason and its ahead and behind counts, marked `stale` after a failed fetch and omitted for a detached HEAD or a branch without an upstream. Skip, warning, progress and prompt lines now go to standard error; `pulled` and `pushed` lines and the tally stay on standard output. Which checkouts are pulled, pushed or skipped is unchanged, as is the exit status.

### Change Summary

`bin/mgit`: `sync_warn` and `sync_outcome` helpers, the outcome counters and detail list, ahead and behind computed before the fetch-failure, local-changes and divergence skips, the closing tally, prompts on standard error and the reflowed `sync_usage`. `tests/mgit.bats`: every `sync` case updated to the tally, and two new cases, held commits with separated streams and prompts on standard error. MGIT-WS-018 in `docs/specs/workspace-dispatch.md`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md` and `CHANGELOG.md` describe the tally, streams and the corrected fetch wording: every branch with a remote upstream is fetched.

### Verification

`ki repo audit --repo .` FAIL=0, its two warnings unrelated to this change (`.rumdl.toml` template drift, Claude Desktop binding); `shellcheck bin/mgit install.sh`, `bash -n`, `mandoc -T lint man/mgit.1`, `rumdl check` and `git diff --check` pass; `bats tests/` with `MGIT_KI_PRODUCER` naming the local `ki` and `TMPDIR` in the run's temporary directory: 139 passed, none failed or skipped. The cases assert the exact tally lines, sums to the selection, a dirty checkout's held commits, `stale` counts after a failed fetch, a detached HEAD without counts, and `not reached` when input ends.

### Outstanding concerns

Moving skip and warning lines to standard error changes what a caller capturing only standard output sees; the changelog says so. `sync --json`, deferred under SYNC-JSON, is offered to the coordinator as an idea.

### Post-change review

The goal is met: the SYNC-SUMMARY case, a dirty checkout five commits ahead, is now named after the tally with `5 ahead`, and the tally sums to the selection. The interaction with [KI-TOOL-MGIT-CLI-026](KI-TOOL-MGIT-CLI-026-sync-conflict-precheck.md) is resolved: its merge prediction is carried in the divergence detail. Ready for acceptance.

### Mini recap

One closing tally for `sync`, held commits named, streams split per SYNC-STREAMS b). No learning to route.

## Discussion

Origin: SYNC-SUMMARY, captured at triage for adoption, horizon and plan by this repository. `size: m` is provisional: the counting is small, but the output change touches the specification, every `sync` Bats case and four documents.

Design choices, as framed at promotion; the decisions follow in Decided.

1. **Outcome categories.** Whether the tally is exactly in sync, pulled, pushed, skipped and failed, or splits warnings out as `need attention` like `overview`. Where diverged, detached, no-upstream, failed fetch, bare and a user's `-i` refusal each fall, and whether `status failed`, `cannot compare`, `pull failed` and `push failed` are the only failures.
2. **Tally shape.** A sketch is `mgit sync: 57 repositories: 55 in sync, 0 pulled, 1 pushed, 1 skipped, 0 failed: ki-agentic-harness (local changes, 5 ahead)`. Whether zero counts are printed, as dispatch does, or omitted; whether the prefix is `mgit sync:` or dispatch's bare `mgit:`; and whether a repository that both pulled and pushed is possible or counted once.
3. **Where skipped detail goes.** Inline after the tally, as dispatch names failures, on one indented line per skipped repository after the tally, or only on the existing per-repository lines with counts added. With 50 or more repositories, the early skip lines scroll away above the status output, which argues for repeating them at the end.
4. **Which held commits to count.** Ahead and behind for a dirty checkout against its freshly fetched upstream; whether to report a failed fetch's counts against the stale upstream, with a stale marker, or not at all; detached heads and branches without upstreams have nothing to compare with. Whether only the checked-out branch counts, as `mgit st` does, or other local branches ahead of their upstreams too.
5. **Standard streams.** Today every line goes to standard output. The conventions put warnings and progress on standard error and the result on standard output. Whether this record moves skip and warning lines to standard error, keeping only the tally on standard output, or leaves streams alone and records the departure on KI-TOOL-MGIT-CLI-029.
6. **Exit status.** Whether a dirty or otherwise skipped checkout keeps exiting `1`, as now, and whether the tally should say which outcomes caused a non-zero exit.
7. **Machine output.** Whether `sync` gains `--json` with a `summary` object matching dispatch and `overview`, here or on a later record.
8. **Verbose mode.** Bare repositories are counted only without `-v` today. Whether the tally is identical with and without `-v`, so verbose adds progress and nothing else.
9. **Clean-branch wording.** Whether the manual and guide are corrected to say every tracking branch is fetched, or the fetch pass is narrowed to clean branches, which would cost the dirty checkouts' behind counts in choice 4.

### Adoption

Adopted into Soon on 19 October 2026 by the tools-burndown trimga run, under Kris's instruction of 19 October 2026, 23:21 BST, in the [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md): "There are 23 tickets across triage for the tool projects, can we get those triaged immediately?" Not planned. `priority: high`, raised from `medium`: a sync that leaves commits unpushed without saying so risks stranded work, which deferring keeps costing. `size: m` kept from capture.

### Promotion

Promoted from Soon to Next as a draft on 19 October 2026 by the tools-burndown mgitplan run, under Kris's decision MGIT-030-NEXT a) of 19 October 2026, 23:42 BST, in the [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md): "Go ahead with the recommendations." This replaces the earlier promotion condition, which waited for choices 1 to 3 and 7; all nine choices are now settled with Kris at planning. Not Ready.

### Decided

Choices 2, 3, 4, 6, 7, 8 and 9 were decided under HIGH-APPLY, 20 October: the coordinator applied the mgitplan run's recommendation a) for each, at high confidence after blind review, with the reviewer's additions folded in, in the [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md) under Speed (20 October).

- **SYNC-TALLY (2):** `mgit sync: N repositories: N in sync, N pulled, N pushed, N skipped, N failed`, keeping the `mgit sync:` prefix, printing zero counts and counting each checkout once; a branch both ahead and behind has diverged and is skipped, so pulled and pushed never overlap. The count is of selected checkouts, so linked worktrees under `-W` count as `overview` counts them.
- **SYNC-SKIPDETAIL (3):** the per-repository lines stay; after the tally, one indented line per skipped or failed checkout repeats its reason with its counts.
- **SYNC-HELD (4):** the checked-out branch only, as `mgit st` does. A dirty checkout gets its fresh ahead and behind; a checkout whose fetch failed gets counts against the last-fetched upstream marked `stale`, the freshness checked for a dirty checkout too; a detached HEAD or a branch without an upstream gets no counts, and the detail says so rather than printing zeros.
- **SYNC-EXIT (6):** the exit status stays as it is, with no extra explanation on the tally line. When interactive input ends, the tally and detail cover the checkouts reached and add `N not reached`. `q` is not a quit answer today: it reprompts, and stays so.
- **SYNC-JSON (7):** deferred; `sync` gains no `--json` here.
- **SYNC-VERBOSE (8):** the tally is identical with and without `-v`, bare repositories always counted as skipped; `-v` adds only progress lines.
- **SYNC-CLEANFETCH (9):** the specification, manual and guide are corrected to the code: every branch with a remote upstream is fetched, and a branch tracking a local branch, remote `.`, needs no fetch.

Choices 1 and 5 were applied under TO-DONE at 00:20 BST on 20 October, in the same log, and reached this run through the coordinator's inbox:

- **SYNC-CATEGORIES (1), c):** five exclusive outcomes, a failed fetch counting as failed; a dirty checkout whose fetch also failed keeps both reasons.
- **SYNC-STREAMS (5), b):** skip, warning, progress and prompt lines to standard error; the tally and per-repository results on standard output. [KI-TOOL-MGIT-CLI-029](KI-TOOL-MGIT-CLI-029-cli-convention-departures.md) no longer needs a `sync` stream departure.
