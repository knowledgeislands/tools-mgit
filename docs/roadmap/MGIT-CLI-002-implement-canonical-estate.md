---
id: MGIT-CLI-002
title: Implement canonical estate
theme: cli
horizon: waiting-for
status: draft
blocks: []
blocked-by: [MGIT-CLI-001]
baseline-ref: null
---

## Goal

Let mGit consume the agreed canonical KI repository estate and store references while retaining each workspace manifest's authority over local grouping and selection.

## Context

`MGIT-CLI-001` establishes the mGit-side parser, selection, registration, repair, and fixture evidence. The work trade adopted from `tools-ki` also requires the Harness `ki-repo` kind and store-role contract proposed by `TRD-d2cd35f7`. This item is the implementation successor once both conditions are met.

## Boundary

Do not begin implementation until `MGIT-CLI-001` is done and Harness publishes the reviewable shared contract. Do not make source or legacy stores Git repositories, replace workspace-manifest selection authority, or write another repository.

## Dependencies / blocks

Waiting for completion of `MGIT-CLI-001` and publication of the Harness `ki-repo` kind and store-role contract from `TRD-d2cd35f7`.

## Discussion

### Promotion condition

When both named conditions are met, move this item to `next` or `now`, compare the shared contract with the discovery fixture matrix, then shape the smallest compatible implementation and verification plan.
