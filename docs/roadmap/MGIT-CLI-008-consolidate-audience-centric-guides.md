---
id: MGIT-CLI-008
title: Consolidate audience-centric guides
area: CLI
theme: cli
horizon: now
status: awaiting-review
blocks: []
blocked_by: []
transferred_from: ki-website
baseline_ref: f40156f4a974968ee573264b17758c1813e16734
created_at: 2026-09-21T15:44:00Z
updated_at: 2026-09-22T06:58:54Z
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

- [x] Delete `docs/worktrees.md`, whose content already lives at `docs/guides/user/worktrees.md` and which no document links.
- [x] Name the worktree guide's path in the `SEE ALSO` section of `man/mgit.1`, so the route the stub served survives in a document readers actually open.
- [x] State the documentation boundary in `docs/guides/README.md`: the collection answers how, `docs/specs/` answers what, and `docs/roadmap/` answers when.
- [x] Document the `--estate` selector in `docs/guides/user/running-commands.md` alongside `--agora`, matching `bin/mgit` and `man/mgit.1`.
- [x] Tell a reader how to upgrade in `docs/guides/user/installation.md`, for both Homebrew and the installer, before the completion section that already assumes it.
- [x] Confirm the collection index routes by audience first, and that each audience index routes its own readers.
- [x] Run the guides and authoring audits and repair what they report.

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

## Review

### Delivered

The approved boundary was the guide collection and the documents that route into it. Baseline `f40156f4a974968ee573264b17758c1813e16734`, the commit that shaped this record to `ready`.

Delivered: `docs/worktrees.md` removed; the worktree and wider user-guide routes named explicitly in `man/mgit.1`; the documentation boundary stated in `docs/guides/README.md`; the `--estate` selector documented in `docs/guides/user/running-commands.md`; an upgrade route added to `docs/guides/user/installation.md`.

Excluded, as planned: no change to `bin/mgit`, to command behaviour, to `docs/specs/`, or to the `README.md` install and usage sections, which remain the proportional entry point their own standard asks for.

### Summary of changes

- `docs/worktrees.md` deleted. The whole guide had already moved to `docs/guides/user/worktrees.md` in `e9f16a4`, leaving a one-line redirect that no document linked. Deleting it was chosen over keeping a pointer because the stub carried no knowledge, served no reader, and was itself the second document outside the collection this item exists to remove.
- `man/mgit.1` `SEE ALSO` now names `docs/guides/user/` and what each of its four guides covers, rather than gesturing at "the worktree structures guide" with no path. The `.TH` date advanced to the change date, following the page's existing practice.
- `docs/guides/README.md` gained a `What lives elsewhere` section stating the boundary: guides answer how, specifications answer what and are authoritative where the two disagree, roadmap items answer when, and the manual with `mgit help` is the complete command reference. The boundary is now stated rather than assumed, which was the open question about `docs/specs/`.
- `docs/guides/user/running-commands.md` documents `--estate` as shorthand for `--agora estate`, and its restriction paragraph now covers both selectors rather than only `--agora`. This closes the gap where `README.md` and `man/mgit.1` showed a selector the user guide never mentioned.
- `docs/guides/user/installation.md` gained an `Upgrade` section covering `brew update && brew upgrade mgit` and re-running the installer, including the environment variables a non-default install must repeat. The completion section already told a reader to refresh completion after upgrading without saying how to upgrade.

One judgment call is recorded rather than deferred: `docs/specs/distribution.md` and `docs/specs/workspace-dispatch.md` are behaviour specifications and stay where they are. Every section is a numbered requirement with normative language, a conformance state, a named verification hook, and its evidence; none of it is procedure for a reader to follow.

### Verification

| Gate                                                     | Outcome                                            |
| -------------------------------------------------------- | -------------------------------------------------- |
| `ki repo audit --skill ki-guides --concise`                | PASS · 1 skill, exit 0                              |
| `ki repo audit --skill ki-authoring --concise`             | PASS · 1 skill, exit 0                              |
| `ki repo audit --concise`                                  | PASS · 15 skills, exit 0                            |
| `bats tests/`                                              | 58 of 58 pass, no failures                          |
| `shellcheck bin/mgit install.sh`; `bash -n` on both        | Clean, exit 0                                       |
| `mandoc -T lint man/mgit.1`                                | Clean, exit 0                                       |
| `git diff --check`                                         | Clean, exit 0                                       |
| `grep -rn 'worktrees.md'`                                  | No reference to the deleted path remains            |

The rendered manual was inspected with `mandoc -T utf8 man/mgit.1 | col -b` after the layout change, as the definition of done requires.

### Outstanding concerns

None blocking. One thing a reviewer may wish to weigh: deleting `docs/worktrees.md` means a link to that path on `main` now returns a 404 rather than a redirect. The path was a guide for one commit's worth of history and nothing in the repository, the manual, or the README cited it, so the exposure is limited to an external link made in that window. Restoring a stub is a one-line change if a reviewer disagrees.

### Post-change review

The goal - every practical document in the collection, under the audience that needs it, with no second copy outside it - now holds. `docs/` contains only `guides/`, `specs/`, and `roadmap/`; no loose practical document sits beside them.

Scope held to the planned files. Regression risk is confined to the manual, whose only functional surface is the rendered page, and that was linted and inspected. No executable, test, or configuration path was touched, and the full suite passes unchanged.

Acceptance readiness: ready for human review. Nothing here needs a Decision Record; the arrangement it consolidates was already adopted.

### Mini recap

Delivered a completeness sweep of the guide collection rather than a restructure: one stray document removed, one boundary stated, two user-guide gaps closed, and the manual pointed at the collection. Verified through the guides, authoring, and full repository audits plus the repository's own gate, all clean.

Learning worth routing, without promoting it here: the `--estate` gap arose because a selector was added to `bin/mgit`, the README, and the manual but not to the guide written for the reader who would meet it. The developer definition of done already lists the user guides among the surfaces that must stay aligned, so the check exists and was missed rather than absent. A reviewer may judge whether that is worth reinforcing anywhere.

## Discussion

Shaping settles how far consolidation goes, not whether it happens. The prompting question is whether every practical document in this repository is in the guide collection, under the audience that needs it, and reachable from the collection index.
