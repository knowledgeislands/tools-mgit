---
id: KI-TOOL-MGIT-CLI-021
area: CLI
title: Estate overview
kind: deliver
purpose: capability
component: cli
horizon: now
status: awaiting-review
blocks: []
blocked_by: []
baseline_ref: 088c2f4eb94f4af693e517e41a36e9f1d336e242
created_at: 2026-10-18T04:10:00Z
updated_at: 2026-10-18T06:02:00Z
---

## Goal

Add `mgit overview`, a read-only estate view that shows, in one screen, each selected repository's branch state, its obsolete branches and its outstanding work, as a terminal table or `--json`.

## Context

Kris, 17 October 2026: "I'm thinking I want some kind of Git something a bit more than status, it tells me things like what branches are, whether they're obsolete, in a really nice format and output. So similar to I think what we did with Almanac was amazing, so something similar that tells me what's outstanding across all the repos".

The tools-burndown roadmap overview of 17 October asked three questions about it, each recommending a): ESTATE-HOME (mgit owns the overview and its `--json`, copying git-almanac's output conventions; git-almanac stays single-repository; [KI-TOOL-KI-CLI-140](/Users/krisbrown/workspaces/knowledge-islands/tools-ki/docs/roadmap/KI-TOOL-KI-CLI-140-git-hygiene-estate-audit.md) reads mgit's JSON), OVERVIEW-VERB (a new verb `overview`, so `mgit status` stays plain Git) and MGIT-RECORDS. The tools-burndown run of 18 October took all three under Kris's overnight instruction to take the recommended course ("provisional, for Kris to confirm") and captured this record.

## Boundary

- **In:** a new owned command `mgit overview [--json] [-v|--verbose] [--stale-days N]` that reads local Git state only, across the selected set and `--all-worktrees`; a terminal view naming only checkouts that need attention, a closing verdict with counts, and a JSON document; help, manual, completion, README, running-commands guide, workspace-dispatch specification, changelog and Bats cases.
- **Out:** any fetch or other network call, any deletion or pruning of branches, stashes or worktrees, pull-request facts (they need a provider), an HTML page, changes to git-almanac or `ki`, and the shared parallel runner, which [KI-TOOL-MGIT-CLI-018](KI-TOOL-MGIT-CLI-018-estate-scale-output.md) delivers and then moves this command onto. No release.

## Current state

No overview exists. `mgit worktree status` prints branch and cleanliness for every worktree, and `mgit status` passes through to Git, printing every checkout in full. Branch hygiene facts (merged, gone, stale, stashes) are gathered nowhere in mgit. The clean-down criteria in the `ki-git` standard (`Clean-down state`, from [KI-HARNESS-GOV-203](/Users/krisbrown/workspaces/knowledge-islands/ki-agentic-harness/docs/roadmap/KI-HARNESS-GOV-203-git-clean-down-criteria.md)) name the deciding read-only commands and a 30-day stale threshold.

## Steps

- [x] Add a per-checkout collector that writes one result file: branch or detached state, upstream with ahead and behind, gone or none; staged, modified and untracked counts; stash count; linked worktrees with prunable and detached flags; the default branch (`origin/HEAD`, else `main` or `master`); local branches merged into the default branch, patch-equivalent to it (`git cherry`), with a gone upstream, or stale; remote-tracking branches merged or stale; last commit age and last fetch age. Automation branches are judged by the same rules.
- [x] Classify each checkout as clean, attention or failed, and render a terminal view that names only attention and failed checkouts, one line each with its findings, then `mgit overview: N repositories: C clean, A need attention, F failed`; `--verbose` names clean checkouts too.
- [x] Render `--json` as one document with tool, command, version, stale threshold, one object per checkout and the summary counts, through a JSON string escaper.
- [x] Wire `overview` as an owned command: listing selectors and `--all-worktrees` apply, `-B` is rejected, usage and `help overview` exist, completion covers it; exit `0` unless a checkout failed.
- [x] Add Bats cases in disposable repositories with isolated configuration: clean, staged, modified and untracked, ahead and behind, gone upstream, merged, patch-equivalent, stale and automation branches, stash, linked and detached worktrees, JSON shape, `--stale-days` validation, and a proof that refs, index, stash and `FETCH_HEAD` are unchanged.
- [x] Update the manual, README, running-commands guide, workspace-dispatch specification and changelog.
- [x] Run the complete gate.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes: `ki repo audit --repo .`, `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1` and `git diff --check`. The overview Bats cases pass, the JSON case parses with `python3 -m json.tool` where Python is present, and the read-only case shows no ref, index, stash or `FETCH_HEAD` change.

## Dependencies / blocks

Not blocked. The record was captured to sit on the runner of [KI-TOOL-MGIT-CLI-018](KI-TOOL-MGIT-CLI-018-estate-scale-output.md), but the build order puts it first, so it lands on a serial collector shaped as one worker per checkout and -018 moves that worker onto the pool. The obsolete-branch criteria follow the `ki-git` standard's clean-down state, which waits on Kris's acceptance of KI-HARNESS-GOV-203; if those criteria change, this command follows them. `ki`'s estate clean-down audit, [KI-TOOL-KI-CLI-140](/Users/krisbrown/workspaces/knowledge-islands/tools-ki/docs/roadmap/KI-TOOL-KI-CLI-140-git-hygiene-estate-audit.md), is the intended JSON consumer and is not changed here.

## Documentation impact

### Decision Records

None; ESTATE-HOME a) and OVERVIEW-VERB a) are recorded below as provisional decisions local to this record.

### Specifications

Workspace dispatch gains a requirement for the read-only overview: facts, classification, output and exit status.

### Guides

Running commands gains an overview section.

### Roadmap

KI-TOOL-MGIT-CLI-018 moves the collector onto its runner.

## Review

### Delivered

From the Ready baseline `088c2f4`, `mgit overview [--json] [-v|--verbose] [--stale-days N]` is an owned command over the selected set. A serial collector prints one tab-separated fact per line for each checkout; a classifier and two renderers turn the facts into the terminal view and one JSON document. It reads local Git only, with `GIT_OPTIONAL_LOCKS=0` so `git status` cannot refresh the index, and never fetches. A checkout needs attention for changes, a detached HEAD, a missing or gone upstream, ahead or behind, stashes, prunable or detached linked worktrees, or obsolete branches: local branches merged into the default branch (`origin/HEAD`, else `main` or `master`), patch-equivalent by `git cherry`, with a gone upstream, or unmerged and stale; remote-tracking branches merged or stale. Automation branches follow the same rules and are marked. The command exits `1` only when a checkout cannot be read. No version bump, release or tag.

### Change Summary

The commit `feat(cli): add the KI-TOOL-MGIT-CLI-021 read-only overview` adds the collector, classifier, renderers, JSON string escaper, usage, help, Bash and Zsh completion and selector handling to `bin/mgit`; adds six Bats cases and extends the reserved-command help loop; and updates the manual, README, running-commands guide, changelog, MGIT-WS-022 and a new MGIT-WS-024 in the workspace-dispatch specification.

### Verification

`ki repo audit --repo .` passes with the existing HOOK-1 warning; `shellcheck`, `bash -n`, `mandoc -T lint` and `git diff --check` are clean; `bats tests/` passes 107 of 107. The JSON case parses with `python3 -m json.tool`. The read-only case gives a tracked file a new timestamp so plain `git status` would rewrite the index, then shows refs, stashes, index bytes and the absence of `FETCH_HEAD` unchanged after `overview` and `-W overview --json`; with the `GIT_OPTIONAL_LOCKS=0` guard removed, that case fails. All runs used disposable fixtures with isolated Git configuration.

### Outstanding concerns

Each is provisional, for Kris to confirm:

- **No upstream counts as attention.** A branch without an upstream is named, so a local-only repository is never clean. This follows "work is safe only once it is on a remote".
- **Several lines for one checkout.** Each checkout prints its findings on one line, then one indented line for each obsolete branch, rather than putting every branch on the first line.
- **In-use branches are kept.** A branch checked out in any worktree, and its remote-tracking branch, is never called obsolete. This keeps a freshly created branch from showing as merged.
- **`-W` reports once.** Under `-W`, stashes, worktrees and branches are reported once per repository, on its first selected checkout.
- **The criteria may move.** They follow the `ki-git` clean-down state, which is still waiting on acceptance of KI-HARNESS-GOV-203.

Human acceptance is outstanding.

### Post-change review

The collector does not render anything, so KI-TOOL-MGIT-CLI-018 can run it per checkout in its pool and capture its output unchanged. Empty values are written as `-` because `read` merges adjacent tab separators; the record lines keep that convention. JSON comes from fixed fields plus escaped strings, with no dependency beyond Bash and Git.

### Mini recap

The estate overview is built serially, read-only, with terminal and JSON views; it is ready for the -018 runner.

## Discussion

- **Facts per repository:** branch, upstream, ahead and behind, dirty and untracked counts, stashes, worktrees, local and remote branches merged or gone, age of the last commit, and `automation/*` branches.
- **Obsolete branches:** merged into the default branch or patch-equivalent to it; upstream gone; an `automation/*`, `dependabot/*` or `renovate/*` branch already merged; or idle beyond a threshold. The criteria should follow [KI-HARNESS-GOV-203](/Users/krisbrown/workspaces/knowledge-islands/ki-agentic-harness/docs/roadmap/KI-HARNESS-GOV-203-git-clean-down-criteria.md), so mgit and `ki` judge alike.
- **Output:** git-almanac's conventions, namely an end-of-run verdict, pass, warn and fail counts, and `--json`. Clean repositories appear only in a count unless `--verbose`.
- **Consumers:** [KI-TOOL-KI-CLI-140](/Users/krisbrown/workspaces/knowledge-islands/tools-ki/docs/roadmap/KI-TOOL-KI-CLI-140-git-hygiene-estate-audit.md) proposes clean-down from `mgit overview --json` rather than collecting the same facts a second time. An HTML estate page in git-almanac would need its single-repository non-goal lifted, which is ESTATE-HOME b) and not taken.

### Adoption (provisional, for Kris to confirm)

Adopted into Next and planned to Ready on 18 October 2026 by the ways-of-working mgit-build run, provisionally on Fable's opinion of 18 October (fable-opinion-2, option a), under Kris's KEEP-PUSHING and FABLE-OPINION answers. Building stops at Awaiting review, pure Bash with Bats fixtures only, with no release. Kris confirms or reverses the adoption and plan by editing this record. Built to Awaiting review the same day; the choices in Outstanding concerns are provisional, for Kris to confirm.
