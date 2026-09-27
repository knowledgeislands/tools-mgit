---
id: MGIT-CLI-009
area: CLI
title: Prune manifest scaffolding
theme: cli
horizon: triage
status: draft
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-09-27T18:59:44Z
updated_at: 2026-09-27T18:59:44Z
---

## Goal

Simplify `mgit` configuration by retiring schema numbering and named groups once their remaining roles have been resolved.

## Context

The proposed `locations` list records where registration searches. Existing `.mgit.toml` documents also carry `schema = 1` and group tables, including a structural `default` group used by repository selection and `repair`. Those fields and their commands need a deliberate migration path before removal.

## Boundary

Keep the distinction between workspace and repository documents. The current locations work retains schema numbering and groups; this item does not authorize their removal or select a replacement for every group use.

## Discussion

### Migration questions

Determine how existing manifests are read and rewritten, whether any group selection remains useful, and how `repair` identifies structural members without a named `default` group. Update help, completion, tests, guides, and the manual together when the decision is made.
