---
id: KI-TOOL-MGIT-CLI-027
area: CLI
title: Fatal Bats assertions
kind: deliver
purpose: debt
project: tools-burndown
priority: medium
size: s
status: done
blocks: []
blocked_by: []
baseline_ref: 73a665af3e4ab8c111044332bc2ac619dca30e53
created_at: 2026-10-18T17:10:05Z
updated_at: 2026-10-20T00:48:16Z
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

- [x] Add `|| false` to each of the seven assertions the audit names.
- [x] Run both suites, the producer suite with `MGIT_KI_PRODUCER` naming the local `ki`; for any test that now fails, decide whether the fault is in the test or in the producer or protocol, fix a test fault here, and raise a real defect to the coordinator, since CAPTURE-GATE lets this run create no record.
- [x] Run the complete gate and confirm `SHELL-FATAL` no longer warns.

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

## Review

### Delivered

Within the approved boundary, from baseline `73a665a`: the seven bare assertions the audit named now end `|| false`, six in `tests/territory-producer.bats` and one in `tests/territory-protocol.bats`. `tests/mgit.bats`, the `SHELL-FATAL` criterion and other repositories were left alone.

### Change Summary

`tests/territory-producer.bats` (lines 76, 77, 84, 158, 159 and 218) and `tests/territory-protocol.bats` (line 26) gain `|| false`; this record. No fault was exposed, so no defect needed routing.

### Verification

`ki repo audit --repo .` FAIL=0, its three warnings unrelated to this change (`.rumdl.toml` template drift, Claude Desktop binding, no committed `.githooks/pre-commit`); `ki repo audit --skill ki-repo-tools` reports no `SHELL-FATAL`; `shellcheck bin/mgit install.sh`, `bash -n`, `mandoc -T lint man/mgit.1` and `git diff --check` pass; `bats tests/` with `MGIT_KI_PRODUCER` naming the local `ki` and `TMPDIR` in the run's temporary directory: 135 passed, none failed or skipped.

Independent acceptance by acceptmgit on 20 October 2026, against committed revision `ba04f398143974183c5b8160e7f7f5129c690c44`: the full definition-of-done gate passes, including 141 Bats tests with the committed KI producer and isolated fixtures; repository, roadmap, authoring and tools audits have no FAIL, and the tools audit has no `SHELL-FATAL` warning. Shellcheck, Bash syntax, manual lint, rumdl and whitespace checks pass. The rendered manual and emitted Bash and Zsh completion syntax were checked. The two existing audit warnings concern authoring-template drift and the Claude binding.

### Outstanding concerns

None.

### Post-change review

The goal is met: a failing negative check mid-test now fails its test under Bash 3.2, and every assertion still holds. Tests only, so no regression risk to `mgit`. Ready for acceptance.

### Mini recap

Seven assertions made fatal; the territory suites pass with the real producer; `SHELL-FATAL` clears. No learning to route.

## Done

Accepted 20 October 2026 by acceptmgit under Kris’s TO-DONE authority on the review packet above.

## Discussion

Origin: the ways-of-working bats-rule run of 18 October 2026. The line counts are that run's read-only sample and should be re-counted against the audit at planning. Planning question: whether any exposed fault in the territory suites is a test fault or a real producer or protocol defect, which would need its own record. Capture only; adoption, priority and plan belong to this repository.

### Adoption

Adopted into Next on 19 October 2026 by the tools-burndown trimga run, under Kris's instruction of 19 October 2026, 23:21 BST, in the [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md): "There are 23 tickets across triage for the tool projects, can we get those triaged immediately?" Not planned. `priority: medium` and `size: s`: seven assertions in two suites, one commit unless an exposed fault needs its own record.

### Planning

Planned to Ready on 20 October 2026 by the tools-burndown burnmgit run. The audit re-count on 20 October matches Current state. No design choice was open; the one judgement, how an exposed real defect is routed, was decided under HIGH-APPLY, 20 October: report it to the coordinator rather than capture a record, under CAPTURE-GATE.

### Independent acceptance

Kris’s TO-DONE instruction of 20 October 2026 in the [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md) authorises an independent acceptance pass; this run’s brief explicitly grants “full authority to accept and prune” these four named records. The requirements, completed Steps, delivery packet and current implementation were reviewed independently, and the full gate was re-run rather than relying on delivery reports.
