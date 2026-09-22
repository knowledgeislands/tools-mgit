---
id: MGIT-CLI-008
title: Consolidate audience-centric guides
area: CLI
theme: cli
horizon: now
status: ready
blocks: []
blocked_by: []
transferred_from: ki-website
baseline_ref: null
created_at: 2026-09-21T15:44:00Z
updated_at: 2026-09-22T06:52:37Z
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

Adopted into `Now` by explicit approval, so this is prioritised work rather than intake. `ki-plan` shaped it to `Ready` before any implementation, and this repository still owns its plan and sequencing.

KI Website derives and cites; it does not own this collection. A guide that would not serve this repository's own readers should not be written for the site's benefit.

## Shaping

- Resolve `docs/worktrees.md`: fold it into the user guide, or reduce it to a pointer and say so in the file.
- Confirm the `docs/specs/` documents are behaviour specifications rather than displaced guides.
- Check the user collection covers installation, repository sets, running commands, and worktrees to the depth a first-time reader needs.
- Run `ki repo audit --skill ki-guides --repo .` once the collection settles.

## Current state

`docs/guides/` splits `user/` and `developer/`, each with its own index, and `.ki.toml` declares `[skills.ki-guides]`. The user collection covers installation, repository sets, running commands, and worktrees; the developer collection covers local development, releasing, and the definition of done. The structure is right, so this is a completeness sweep rather than a restructure.

The sweep found four concrete things, and the plan below resolves each.

`docs/worktrees.md` no longer holds the guide. Commit `e9f16a4` moved the whole document into `docs/guides/user/worktrees.md` and left a one-line redirect behind, so the content is already folded in and only the shell remains. Nothing in the repository links it: `README.md`, both collection indexes, and `man/mgit.1` route elsewhere or name no path at all. A stub that no reader reaches is the second document outside the collection this item exists to remove, and `docs/` has no home for a loose Markdown file beside `decisions/`, `specs/`, `guides/`, and `roadmap/`. It is deleted rather than kept as a pointer, and `man/mgit.1` gains the explicit guide path its `SEE ALSO` currently only gestures at.

`docs/specs/distribution.md` and `docs/specs/workspace-dispatch.md` are behaviour specifications, not displaced guides. Every section is a numbered `MGIT-DIST-NNN` or `MGIT-WS-NNN` requirement stating one current behaviour in normative language with a conformance state, a named Bats or source verification hook, and its evidence. They record what `mgit` does and how that is proven, never how a reader should operate it. They stay where they are, and the collection index states the boundary rather than leaving it to be inferred.

The user collection covers all four topics, but two accuracy gaps sit inside that coverage. `--estate` is a real selector - `bin/mgit` accepts it and `man/mgit.1` documents it as exactly equivalent to `--agora estate` - and `README.md` shows it, yet `docs/guides/user/running-commands.md` documents only `--agora`. A reader who meets `mgit --estate status` in the README finds nothing about it in the guide written for them. Separately, `installation.md` tells a reader to refresh completion "after upgrading `mgit`" without ever saying how to upgrade, which is the first thing a first-time reader needs after installing.

Nothing in `README.md` or `man/mgit.1` is practical instruction displaced from the collection. The README's install and usage material is the proportional entry point its own standard asks for and routes onward to the guides; the manual is the command reference the guides defer to.

## Steps

- [ ] Delete `docs/worktrees.md`, whose content already lives at `docs/guides/user/worktrees.md` and which no document links.
- [ ] Name the worktree guide's path in the `SEE ALSO` section of `man/mgit.1`, so the route the stub served survives in a document readers actually open.
- [ ] State the documentation boundary in `docs/guides/README.md`: the collection answers how, `docs/specs/` answers what, and `docs/roadmap/` answers when.
- [ ] Document the `--estate` selector in `docs/guides/user/running-commands.md` alongside `--agora`, matching `bin/mgit` and `man/mgit.1`.
- [ ] Tell a reader how to upgrade in `docs/guides/user/installation.md`, for both Homebrew and the installer, before the completion section that already assumes it.
- [ ] Confirm the collection index routes by audience first, and that each audience index routes its own readers.
- [ ] Run the guides and authoring audits and repair what they report.

## Files touched

`docs/worktrees.md` (deleted); `docs/guides/README.md`; `docs/guides/user/running-commands.md`; `docs/guides/user/installation.md`; `man/mgit.1`.

## Verify

`ki repo audit --skill ki-guides --repo .` passes, `ki repo audit --skill ki-authoring --repo .` passes over the collection, and the full `ki repo audit --repo .` still passes across every declared skill. Alongside the mechanical gates: `grep -rn 'worktrees.md'` reports no reference to the deleted path, and `--estate` and the upgrade route appear in the user collection as well as in `README.md` and `man/mgit.1`.

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
