---
id: KI-TOOL-MGIT-CLI-036
area: CLI
title: Sync as chain recipe
priority: medium
size: l
assignee: work/ki.tools
status: triage
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-11-26T02:55:00Z
updated_at: 2026-11-26T02:55:00Z
---

# KI-TOOL-MGIT-CLI-036: Sync as chain recipe

## Goal

`mgit sync` becomes a built-in recipe on the `mgit chain` engine, keeping its push guard and the `mgit.syncPush` veto, with `--exclude <prefix>`, `--merge` and `--json` giving a reason per skipped checkout, and a check-only run that does not fetch. It never forces, stashes or touches uncommitted files.

## Context

Kris's asks from ki.sop.tools' legacy and the Observatory's sync review, carried on one record:

- **SYNC-RECIPE**, ki.prj.tools-burndown's queue: safe fast-forward and publish steps over `mgit chain`, taken once KI-TOOL-MGIT-CLI-032 was accepted (it is, and pruned at tools-mgit 41c1766).
- **MGIT-AUTO** (Kris, MGIT-AUTO a, 27 October 2026, [legacy line](https://github.com/krisb/ki-cairn-store/blob/b759e7b4506da8df0c4ca680f577bae82f7cfe57/work-legacy/batch-01-initial/ki/ki.sop.tools/folded/ki.prj.tools-burndown/messages.md?plain=1#L49)): `mgit sync --merge`, `--exclude <prefix>` and `--json` with a reason per skipped checkout; never force, stash or touch uncommitted files.
- **The Observatory's two:** its [sync brief](https://github.com/krisb/ki-cairn-store/blob/b759e7b4506da8df0c4ca680f577bae82f7cfe57/work-legacy/batch-01-initial/ki/ki.reg.agora/folded/ki.prj.observatory/sync/observatory-sync-brief.md) found the local implementation narrower than the proposed pass, naming SYNC-RECIPE and MGIT-AUTO as the two tools-mgit pieces it needs.

At 0.18.0 `mgit sync` fetches every tracked branch, fast-forwards a branch only behind, pushes one only ahead only with `--push`, honours `mgit.syncPush = false`, and names every skipped checkout with its reason in one tally; the push guard (KI-TOOL-MGIT-CLI-033) is done and KI-TOOL-MGIT-CLI-034 (draft, `next`) stands beside this.

The scheduled-sync faults are cases of this record, each rechecked against the current `mgit sync` when it is planned and captured on its own only if seen failing: SYNC-UNPUSHED-EXIT ([legacy line](https://github.com/krisb/ki-cairn-store/blob/b759e7b4506da8df0c4ca680f577bae82f7cfe57/work-legacy/batch-01-initial/ki/ki.sop.tools/folded/ki.prj.tools-burndown/messages.md?plain=1#L76); parked recommendation: an unpushed branch leaves the exit successful, and the record says a successful sync does not mean pushed), LOOP-PUSH-BUSY ([L69](https://github.com/krisb/ki-cairn-store/blob/b759e7b4506da8df0c4ca680f577bae82f7cfe57/work-legacy/batch-01-initial/ki/ki.sop.tools/folded/ki.prj.tools-burndown/messages.md?plain=1#L69)), MGIT-CACHE-SCOPE and MGIT-CACHE-FAILED ([L74 and L75](https://github.com/krisb/ki-cairn-store/blob/b759e7b4506da8df0c4ca680f577bae82f7cfe57/work-legacy/batch-01-initial/ki/ki.sop.tools/folded/ki.prj.tools-burndown/messages.md?plain=1#L74); Kris asked for the cache concept in plain language first) and SNAPSHOT-SYNC ([L62](https://github.com/krisb/ki-cairn-store/blob/b759e7b4506da8df0c4ca680f577bae82f7cfe57/work-legacy/batch-01-initial/ki/ki.sop.tools/folded/ki.prj.tools-burndown/messages.md?plain=1#L62)).

Captured as triage from the ki.tools reset map ([4.1](https://github.com/krisb/ki-cairn-store/blob/d28c5faeca6ddcf069354dea49e8a645a37d7efb/work/ki/ki.tools/13-reset-map.change.md#41-kisoptools-legacy-10), N9).

## Boundary

- **In:** `mgit sync` as a chain recipe with the flags above and a check-only mode; the scheduled-sync faults as cases to recheck.
- **Out:** a scheduled sync job and where it runs, which personal.rig.summit's jobs register settles (MGIT-SYNC-JOB); any force, stash or change to uncommitted files.

## Discussion

**Rollout:** once it lands, sol and terra adopt `mgit sync` in place of their own sync loops, which personal.rig.summit and the rigs are told of along the tree. The mgit cache (MGIT-CACHE-SCOPE) goes to Kris in plain language before it is designed. Captured as triage for Kris to adopt or cancel.
