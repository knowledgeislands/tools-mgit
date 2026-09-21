---
id: MGIT-CLI-008
area: CLI
title: Consolidate audience-centric guides
theme: documentation-structure
blocks: []
blocked_by: []
transferred_from: ki-website
created_at: 2026-09-21T15:44:00Z
updated_at: 2026-09-21T16:12:00Z
horizon: now
status: draft
---

## Goal

Every practical `mgit` document lives in the guide collection under the audience that needs it, with no second copy outside it.

## Context

`tools-mgit` already splits `docs/guides/` into `user/` and `developer/`, and its collection index routes both. The gap is material sitting outside the collection: `docs/worktrees.md` exists alongside the real guide at `docs/guides/user/worktrees.md`. Two documents with one name is the state a collection standard exists to prevent, whichever way it is resolved.

`docs/specs/` also holds `distribution.md` and `workspace-dispatch.md`. Those may be correctly placed — a specification is not a guide — but the boundary is worth stating rather than assuming.

KI Website now declares, for every page it publishes under `apps/site/src/guidance/`, the exact upstream document and pinned ref that page was written from, and a `verify:guidance --network` sweep reports the pages whose source has moved. The site intends to derive public guidance for this project from this repository's own guides and cite them at a pinned ref, so the quality and stability of `docs/guides/` here directly determines the quality of what the site can publish.

That is a pull, not an obligation: KI Website derives, it does not own. This repository decides what its guides say and when they change.

Separately, `ki-guides` is being asked to require audience directories under `docs/guides/` rather than permitting a flat collection (`ki-agentic-harness` `KI-HARNESS-GOV-083`). If that lands, this repository's collection has to satisfy it.

## Boundary

Adopted into `Now` by explicit approval, so this is prioritised work rather than intake. It remains `status: draft`: `ki-plan` shapes it to `Ready` before any implementation, and this repository still owns its plan and sequencing.

KI Website derives and cites; it does not own this collection. A guide that would not serve this repository's own readers should not be written for the site's benefit.

## Shaping

- Resolve `docs/worktrees.md`: fold it into the user guide, or reduce it to a pointer and say so in the file.
- Confirm the `docs/specs/` documents are behaviour specifications rather than displaced guides.
- Check the user collection covers installation, repository sets, running commands, and worktrees to the depth a first-time reader needs.
- Run `ki repo audit --skill ki-guides --repo .` once the collection settles.

## Discussion

Shaping settles how far consolidation goes, not whether it happens. The prompting question is whether every practical document in this repository is in the guide collection, under the audience that needs it, and reachable from the collection index.
