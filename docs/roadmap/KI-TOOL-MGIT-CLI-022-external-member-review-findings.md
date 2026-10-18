---
id: KI-TOOL-MGIT-CLI-022
area: CLI
title: External member review findings
status: triage
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-18T04:10:00Z
updated_at: 2026-10-18T04:10:00Z
---

## Goal

Settle the four low findings from the independent review of [KI-TOOL-MGIT-CLI-017](KI-TOOL-MGIT-CLI-017-unified-external-members.md): fix, document or drop each one.

## Context

The tools-burndown mgit-review run of 17 October found nothing blocking in KI-TOOL-MGIT-CLI-017 and four low findings. Its MGIT-REVIEW-LOWS query recommended a): accept KI-TOOL-MGIT-CLI-017 as it stands and capture the findings as one triage record. The tools-burndown run of 18 October captured this record under Kris's overnight instruction to take the recommended course ("provisional, for Kris to confirm"); acceptance of KI-TOOL-MGIT-CLI-017 stays with Kris.

- **L1, missing external member.** If the external checkout is missing, selection fails for the whole set, including from `~/workspaces`, and repair only reports it. A missing local member behaves the same way, so this matters only if the member is declared on a machine without the checkout.
- **L2, external path back inside the workspace.** A hand-written path such as `../personal/acquire` is quietly deduplicated, not rejected. Registration never writes one.
- **L3, register drops hand-written external members.** `mgit register` drops a hand-written external member that has no matching location, and `--dry-run` does not name it. The guide documents this.
- **L4, cosmetic.** `mgit repair` prints the deprecation warning twice for one manifest, once for each spelling of its path.

## Boundary

This capture does not adopt, schedule, implement or release anything, and does not reopen KI-TOOL-MGIT-CLI-017.

## Discussion

L4 is a likely quick fix; L2 and L3 could become a rejection and a `--dry-run` line; L1 may be accepted as documented behaviour.
