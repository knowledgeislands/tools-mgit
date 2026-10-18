---
id: KI-TOOL-MGIT-CLI-027
area: CLI
title: Fatal Bats assertions
purpose: debt
status: triage
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-18T17:10:05Z
updated_at: 2026-10-18T18:18:51Z
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

## Dependencies / blocks

None. Blocks nothing.

## Discussion

Origin: the ways-of-working bats-rule run of 18 October 2026. The line counts are that run's read-only sample and should be re-counted against the audit at planning. Planning question: whether any exposed fault in the territory suites is a test fault or a real producer or protocol defect, which would need its own record. Capture only; adoption, priority and plan belong to this repository.
