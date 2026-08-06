---
id: TRD-43b5c5e6
title: Trade response expectations
created_at: 2026-08-06T02:10:20Z
sender: knowledgeislands/tools-mgit
receiver: knowledgeislands/ki-agentic-harness
kind: knowledge
source_ref: TRD-0f0b10a2
---

# TRD-43b5c5e6: Trade response expectations

## Context

An exporter may depend on whether a receiver will take up submitted work or retain submitted knowledge. It can observe the receiver's eventual disposition through the receiver-owned inbound copy and, after adoption, follow the linked local work item. The dependency belongs to the exporter's own planning, but should be intelligible to both parties.

## Submission

Retain this distinction in the trade skill and any companion trade-operation surface:

- A submitted trade carries an expected receiver disposition. The receiver may create an inbound copy for consideration and later communicate `adopted`, `retained`, `declined`, `clarify`, or another receiver-owned decision. An exporter may wait on that signal before proceeding with dependent local work.
- An expected response is not a deadline, delivery guarantee, implementation commitment, or priority transfer. The receiver remains free to decide whether and when to receive, consider, or resolve the trade.
- The receiver may use the exporter's stated dependency as context when choosing local priority, but no trade state may impose that choice.
- A draft pre-advisement remains observable discussion only. It carries no delivery, consideration, disposition, or response expectation unless and until it is promoted into a separately immutable submitted trade.

After a terminal disposition, the exporter can continue to observe the linked local work or retained knowledge in the receiver repository. That observation needs no additional mandatory outcome-reporting state: the receiver's ordinary local records remain the source of truth.

## Constraints

Do not add peer-write authority, network transport, response deadlines, automatic receipt, inferred disposition, automatic prioritisation, or mandatory downstream reporting. Preserve the receiver-only decision fields and the separation between delivery, disposition, local roadmap authority, and implementation acceptance.
