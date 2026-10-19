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
horizon: soon
status: draft
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-19T21:10:01Z
updated_at: 2026-10-19T22:23:07Z
---

# Sync Closing Summary

## Goal

`mgit sync` ends with one closing tally that accounts for every selected repository by outcome, in sync, pulled, pushed, skipped and failed, and names each skipped repository with its reason and any commits it still holds unpushed or unpulled, so a run never leaves work stranded without saying so. The tally reads like the closing line `mgit st` and `mgit overview` already print, and follows the `ki-repo-tools` [command-line conventions](/Users/krisbrown/.local/share/ki/harnesses/knowledgeislands/ki-agentic-harness/skills/repo-structure/ki-repo-tools/references/standards-cli-conventions.md).

## Context

Kris, 19 October 2026, SYNC-SUMMARY in the [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md): "mgit sync could do with a better summary". The run printed, in order, a skip line for ki-agentic-harness (`local changes (skipped)`) with four `M` paths, `ki-principal: pushed 1 commit`, and `55 repositories already in sync`. `mgit st` then showed ki-agentic-harness `[ahead 5]`: five commits stayed unpushed, the sync output never said so, and nothing added up the 57 repositories.

How `sync_command` in [`bin/mgit`](../../bin/mgit) reports today:

- Each changed or troubled checkout gets one `mgit sync: <label>: <outcome>` line on standard output as it is reached: `pulled N commits`, `pushed N commits`, `local changes (skipped)` followed by `git status --short`, `detached HEAD (skipped)`, `branch B has no upstream (skipped)`, `fetch from R failed (skipped)`, `diverged from U, A ahead and B behind (skipped)`, and `status failed`, `cannot compare with upstream`, `pull failed` or `push failed`.
- The closing lines count only three things: `N repositories already in sync`, `N actions skipped by user` under `-i`, and `N bare repositories skipped` without `-v`. Pulled, pushed, warned and failed checkouts are never counted, so the reader adds them up from the lines above.
- The local-changes check runs before the ahead and behind count, so a dirty checkout's unpushed or unpulled commits are never computed or shown. Its branch is still fetched: the fetch pass selects by branch and upstream, not cleanliness, so a fresh behind count is available. The manual and the running-commands guide say sync fetches every *clean* tracking branch, which the code does not match; planning should settle which is meant.
- Every skip except a user's `-i` refusal sets the exit status to `1`, as does a bare repository.

The other fan-out commands already close with one tally line. Ordinary dispatch, which `mgit st` uses, prints `mgit: 57 repositories: N quiet, N with output, N failed: label (exit n), …`, naming each failure; `mgit overview` prints `mgit overview: N repositories: N clean, N need attention, N failed`. Both also give `--json` a `summary` object; `sync` has no `--json`.

[MGIT-WS-018](../specs/workspace-dispatch.md#mgit-ws-018--repository-set-synchronization) specifies today's output: name changed repositories and warnings, and collapse current and bare repositories into counts. The `sync` Bats cases in [`tests/mgit.bats`](../../tests/mgit.bats) assert those closing lines.

## Boundary

- **In:** the closing tally and skipped-repository detail in `sync_command`; ahead and behind counts for checkouts skipped after their upstream is known; MGIT-WS-018, `sync` help, manual, README, running-commands guide and changelog; Bats cases against local bare origins in disposable repositories, updating the existing `sync` cases.
- **Out:** changing which checkouts `sync` pulls, pushes or skips, or acting on a dirty checkout; merge prediction for diverged branches, which [KI-TOOL-MGIT-CLI-026](KI-TOOL-MGIT-CLI-026-sync-conflict-precheck.md) owns; option-parsing departures, which [KI-TOOL-MGIT-CLI-029](KI-TOOL-MGIT-CLI-029-cli-convention-departures.md) owns; summaries of other commands; running `sync` against the real estate.

## Shaping

**Approach:** count each checkout's outcome in `sync_command` as it is reached, compute ahead and behind for a skipped checkout whose upstream is known, and print one closing tally after the per-repository lines, in the shape `mgit st` and `mgit overview` already use; update MGIT-WS-018, every `sync` Bats case and the four documents in Boundary together.

**Dependencies:** none blocking. Wording interacts with [KI-TOOL-MGIT-CLI-026](KI-TOOL-MGIT-CLI-026-sync-conflict-precheck.md), whichever lands second; a stream or option-parsing departure found here goes to [KI-TOOL-MGIT-CLI-029](KI-TOOL-MGIT-CLI-029-cli-convention-departures.md).

**Decisions still needed:** the nine open design choices in Discussion, above all the outcome categories, tally shape, where skipped detail goes, and whether `--json` is in scope.

**Promotion to Next:** when Kris or planning settles choices 1 to 3 and 7, which fix the output contract; the rest can be settled during planning.

## Dependencies / blocks

None. Blocks nothing. KI-TOOL-MGIT-CLI-026 rewords the diverged warning line, so whichever lands second should rebase its wording on the other.

## Discussion

Origin: SYNC-SUMMARY, captured at triage for adoption, horizon and plan by this repository. `size: m` is provisional: the counting is small, but the output change touches the specification, every `sync` Bats case and four documents.

Open design choices, for planning rather than decided here:

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
