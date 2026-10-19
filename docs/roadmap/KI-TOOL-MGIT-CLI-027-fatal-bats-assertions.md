---
id: KI-TOOL-MGIT-CLI-027
area: CLI
title: Fatal Bats assertions
kind: deliver
purpose: debt
project: tools-burndown
priority: medium
size: s
horizon: next
status: draft
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-18T17:10:05Z
updated_at: 2026-10-19T22:23:07Z
---

# Fatal Bats Assertions

## Goal

Every bare `[[ ]]` or `!` assertion in tools-mgit's two remaining warning suites ends `|| false`, so a failing check in the middle of a test fails it under macOS Bash 3.2, and the `ki-repo-tools` `SHELL-FATAL` warning clears for this repository.

## Context

Under macOS Bash 3.2, Bats does not stop a test at a failing bare `[[ ]]` or `!` command that is not the test's last, so the failure is logged and the test still passes. tools-mgit `00ef0de` fixed this in `tests/mgit.bats` and exposed latent faults. [KI-HARNESS-GOV-211](https://github.com/knowledgeislands/ki-agentic-harness/blob/87da1b26/docs/roadmap/KI-HARNESS-GOV-211-bats-fatal-assertions.md) made the rule part of `ki-repo-tools` and added the `SHELL-FATAL` warning. Its run of 18 October found two more tools-mgit suites with such assertions:

- `tests/territory-producer.bats`: 6 lines.
- `tests/territory-protocol.bats`: 1 line.

Kris agreed on 18 October 2026 (BATS-CLEANUP a), ways-of-working decisions log, 17:59 BST owner answers) to capture one triage record each in tools-mgit and tools-rig.

## Boundary

- In: adding `|| false` to each bare assertion in the two suites; fixing any test or code fault that making them fatal exposes; confirming `SHELL-FATAL` passes for the repository.
- Out: `tests/mgit.bats`, already fixed in `00ef0de`; changing the `SHELL-FATAL` criterion; other repositories' suites, including tools-rig's.

## Current state

The `ki-repo-tools` audit on 19 October 2026 confirmed the capture's counts: `SHELL-FATAL` warns on six assertions in `tests/territory-producer.bats` (lines 76, 77, 84, 158, 159 and 218) and one in `tests/territory-protocol.bats` (line 26). `tests/mgit.bats` is clean.

## Steps

- [ ] Add `|| false` to each of the seven assertions the audit names.
- [ ] Run both suites; for any test that now fails, decide whether the fault is in the test or in the producer or protocol, fix a test fault here and capture a real defect as its own record.
- [ ] Run the complete gate and confirm `SHELL-FATAL` no longer warns.

## Files touched

`tests/territory-producer.bats`, `tests/territory-protocol.bats` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes and `ki repo audit --skill ki-repo-tools --repo .` reports no `SHELL-FATAL` warning.

## Dependencies / blocks

None. Blocks nothing.

## Documentation impact

### Decision Records

None: the rule is already `ki-repo-tools`'s.

### Specifications

None: tests only, no behaviour changes.

### Guides

None.

### Roadmap

A real defect the fatal assertions expose becomes its own record.

## Discussion

Origin: the ways-of-working bats-rule run of 18 October 2026. The line counts are that run's read-only sample and should be re-counted against the audit at planning. Planning question: whether any exposed fault in the territory suites is a test fault or a real producer or protocol defect, which would need its own record. Capture only; adoption, priority and plan belong to this repository.

### Adoption

Adopted into Next on 19 October 2026 by the tools-burndown trimga run, under Kris's instruction of 19 October 2026, 23:21 BST, in the [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md): "There are 23 tickets across triage for the tool projects, can we get those triaged immediately?" Not planned. `priority: medium` and `size: s`: seven assertions in two suites, one commit unless an exposed fault needs its own record.
