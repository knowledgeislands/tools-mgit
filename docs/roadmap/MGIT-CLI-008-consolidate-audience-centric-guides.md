---
id: MGIT-CLI-008
title: Consolidate audience-centric guides
area: CLI
theme: cli
horizon: now
status: draft
blocks: []
blocked_by: []
transferred_from: ki-website
baseline_ref: null
created_at: 2026-09-21T15:44:00Z
updated_at: 2026-09-21T16:40:00Z
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

## Current state

`docs/guides/` splits `user/` and `developer/`, each with its own index, and `.ki.toml` declares `[skills.ki-guides]`. The user collection covers installation, repository sets, running commands, and worktrees; the developer collection covers local development, releasing, and the definition of done. The structure is right, so this is a completeness sweep rather than a restructure.

## Steps

- [ ] Sweep `README.md`, `docs/specs/`, and any `man/` page for practical instruction that belongs in the collection.
- [ ] Confirm every audience directory has an index that routes its own readers.
- [ ] Place anything found under the audience that needs it, rather than under the audience that wrote it.
- [ ] Confirm the collection index routes by audience before anything else.
- [ ] Run the guides audit and repair what it reports.

## Files touched

`docs/guides/` and its audience directories; `README.md` and other documents where instruction moves out of them.

## Verify

`ki repo audit --skill ki-guides --repo .` passes, and `ki repo audit --skill ki-authoring --repo .` passes over the collection.

## Dependencies / blocks

Nothing blocks this. `KI-HARNESS-GOV-083` in `ki-agentic-harness` proposes making audience directories a `ki-guides` requirement; this collection already groups by audience, so that change should confirm the arrangement rather than force one.

## Documentation impact

### Decision Records

No decision record is needed. This is consolidation within an arrangement the repository has already adopted.

### Specifications

No behaviour-level contract changes. Where a guide and a specification disagree, the specification is authoritative and the guide is corrected.

### Guides

This item is entirely guide impact: gaps are filled, stray practical material is brought in, and the indexes are made to route.

### Roadmap

No further roadmap change is expected unless the sweep finds behaviour documented nowhere, which would be raised as its own item.

## Discussion

Shaping settles how far consolidation goes, not whether it happens. The prompting question is whether every practical document in this repository is in the guide collection, under the audience that needs it, and reachable from the collection index.
