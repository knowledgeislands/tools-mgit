---
id: MGIT-CLI-001
title: Add named repository groups
theme: cli
horizon: future
status: open
candidate: true
blocks: []
blocked-by: []
baseline-ref: null
transferred-from: knowledgeislands/tools-ki:KI-TOOL-CLI-011
---

## Context

Explore named, ordered repository groups in `.mgit-config.toml` so an operator can run a command over an intentional subset without duplicating a manifest or changing working directories. This follows the same ergonomic need that led KI workspaces to record nested containers, but remains an mGit-owned command and manifest design.

## Boundary

Do not change mGit's existing recursive `register` ownership model, introduce KI workspace parsing, weaken manifest validation, or make this candidate a prerequisite for KI workspace registration.

## Discussion

### Selection model

A future design should define how a named group references existing typed manifest members, how order and duplicates behave, and how CLI selection interacts with the current all-members default. It must preserve unambiguous behaviour for standard, nested, bare, and directory members.

### Promotion condition

Promote when a concrete repeated subset workflow establishes the desired CLI grammar, manifest shape, backward migration, and verification boundary. The originating `tools-ki` work item is non-blocking evidence of the analogous need, not a shared implementation dependency.
