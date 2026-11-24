---
id: KI-TOOL-MGIT-CLI-035
area: CLI
title: Territory tests match ki
priority: medium
size: s
assignee: owner
status: triage
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-11-24T11:59:06Z
updated_at: 2026-11-24T11:59:06Z
---

# Territory tests match ki

## Goal

Bring tools-mgit's territory producer tests in line with how `ki` 0.14 and later produces territories, so that the full Bats suite passes again when `MGIT_KI_PRODUCER` names the installed `ki`.

## Context

`tests/territory-producer.bats` test 3, "real producer blocks selected missing roots and missing member registrations before dispatch", fails against `ki` 0.17.0 and later when run with `MGIT_KI_PRODUCER`; the other seven pass. Rechecked on 24 November 2026 on sol with `ki` 0.17.0: the test still fails at its first assertion, `assert_no_dispatch -t short` (line 112), so `mgit -t short` no longer refuses to dispatch when a selected root is missing, or dispatches regardless.

The [definition of done](../guides/developer/definition-of-done.md) requires the producer proof for selector changes, so while this fails no selector change can pass its gate honestly.

Source: ki.tools's change 10, 4.2 (TERRITORY-TEST), in the Cairn store, `work/ki/ki.tools/10-ki-sop-tools-legacy.change.md`. Kris asked on 24 November 2026 for it to be captured as its own tools-mgit record.

## Boundary

- **In:** `tests/territory-producer.bats` and, if the test shows mgit's selection is wrong rather than the test's expectation, the selection code in `bin/mgit` that blocks missing roots and missing member registrations before dispatch; the definition of done's producer note if the supported `ki` range changes.
- **Out:** changes to `ki` itself, which tools-ki owns; `mgit sync` and the scheduled-sync faults; any release or version bump.

## Discussion

Planning must first settle which side moved: whether `ki` 0.14 and later now reports missing roots in a way mgit should still block on, so that mgit's selection needs fixing, or whether the test's expectation is out of date and only the test changes. The other seven producer tests pass, so the gap looks confined to missing roots and missing member registrations. Captured as triage for Kris to adopt or cancel.
