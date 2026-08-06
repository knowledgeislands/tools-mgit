---
id: TRD-0f0b10a2
title: Draft trade advisories
created_at: 2026-08-06T01:51:29Z
sender: knowledgeislands/tools-mgit
receiver: knowledgeislands/ki-agentic-harness
kind: knowledge
source_ref: TRD-67a0c878
---

# TRD-0f0b10a2: Draft trade advisories

## Context

The current trade contract makes an outbound sender envelope and payload immutable, and an inbound copy means the receiver has accepted delivery for consideration. That is appropriate for submitted work or knowledge, but it leaves no governed way to advise a peer early, while scope is still being shaped.

## Submission

Consider a draft pre-advisement phase for both work and knowledge trades. A sender could make a draft visible to a declared peer, and that peer could create a local draft copy before either side treats it as a submitted delivery or a receiver decision.

The phase must remain distinct from the existing `sent` / `received` lifecycle. A draft received locally should mean only that the receiver can inspect the proposal; it must not imply accepted delivery, `unconsidered`, adoption, retention, priority, or a roadmap item.

The design needs an explicit draft state and placement, revision or withdrawal semantics, a relationship between draft and eventual immutable submitted record, and a promotion boundary at which sender provenance and payload become byte-stable. Once promoted, the existing route validation, receiver-owned decision fields, release observation, and no-peer-write rules should continue unchanged.

## Constraints

Do not retrofit draft mutation into existing submitted `TRD-*` records or weaken their immutable-copy rule. Do not introduce network transport, automatic copying, peer-checkout writes, inferred receiver interest, automatic disposition, or priority authority. The receiver must remain free to ignore a draft advisory or remove its local draft copy under the eventual contract.
