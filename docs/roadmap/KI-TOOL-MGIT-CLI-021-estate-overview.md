---
id: KI-TOOL-MGIT-CLI-021
area: CLI
title: Estate overview
status: triage
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-18T04:10:00Z
updated_at: 2026-10-18T04:10:00Z
---

## Goal

Add `mgit overview`, a read-only estate view that shows, in one screen, each selected repository's branch state, its obsolete branches and its outstanding work, as a terminal table or `--json`.

## Context

Kris, 17 October 2026: "I'm thinking I want some kind of Git something a bit more than status, it tells me things like what branches are, whether they're obsolete, in a really nice format and output. So similar to I think what we did with Almanac was amazing, so something similar that tells me what's outstanding across all the repos".

The tools-burndown roadmap overview of 17 October asked three questions about it, each recommending a): ESTATE-HOME (mgit owns the overview and its `--json`, copying git-almanac's output conventions; git-almanac stays single-repository; [KI-TOOL-KI-CLI-140](/Users/krisbrown/workspaces/knowledge-islands/tools-ki/docs/roadmap/KI-TOOL-KI-CLI-140-git-hygiene-estate-audit.md) reads mgit's JSON), OVERVIEW-VERB (a new verb `overview`, so `mgit status` stays plain Git) and MGIT-RECORDS. The tools-burndown run of 18 October took all three under Kris's overnight instruction to take the recommended course ("provisional, for Kris to confirm") and captured this record.

## Boundary

This capture does not adopt, schedule, implement or release anything. `overview` reads local Git only, with no network, and never deletes a branch. It depends on the shared runner in [KI-TOOL-MGIT-CLI-018](KI-TOOL-MGIT-CLI-018-estate-scale-output.md).

## Discussion

- **Facts per repository:** branch, upstream, ahead and behind, dirty and untracked counts, stashes, worktrees, local and remote branches merged or gone, age of the last commit, and `automation/*` branches.
- **Obsolete branches:** merged into the default branch or patch-equivalent to it; upstream gone; an `automation/*`, `dependabot/*` or `renovate/*` branch already merged; or idle beyond a threshold. The criteria should follow [KI-HARNESS-GOV-203](/Users/krisbrown/workspaces/knowledge-islands/ki-agentic-harness/docs/roadmap/KI-HARNESS-GOV-203-git-clean-down-criteria.md), so mgit and `ki` judge alike.
- **Output:** git-almanac's conventions, namely an end-of-run verdict, pass, warn and fail counts, and `--json`. Clean repositories appear only in a count unless `--verbose`.
- **Consumers:** [KI-TOOL-KI-CLI-140](/Users/krisbrown/workspaces/knowledge-islands/tools-ki/docs/roadmap/KI-TOOL-KI-CLI-140-git-hygiene-estate-audit.md) proposes clean-down from `mgit overview --json` rather than collecting the same facts a second time. An HTML estate page in git-almanac would need its single-repository non-goal lifted, which is ESTATE-HOME b) and not taken.
