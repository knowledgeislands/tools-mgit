---
id: MGIT-CLI-006
area: CLI
title: Adopt website tool routes
theme: cli
horizon: now
status: done
blocks: []
blocked_by: []
baseline_ref: 78094b180cb0dab9a32cd47271fbf880f6767ad4
created_at: 2026-09-17T21:05:58Z
updated_at: 2026-09-18T04:11:50Z
---

# MGIT-CLI-006: Adopt website tool routes

## Goal

Keep the website's advertised `mgit` version matching what this repository has released, and align this installer's version-pinning interface with the other Knowledge Islands tools.

## Context

`knowledgeislands/ki-website` delivered `KI-WEB-SITE-007`, which gives every released Knowledge Islands tool the same two public routes: `/tooling/<tool>/` for people and `/install/<tool>/` for machines. Both are generated from one website-owned registry.

`mgit` now has a product page at `https://knowledgeislands.info/tooling/mgit/` and a stable installer endpoint at `https://knowledgeislands.info/install/mgit`, which redirects to `https://raw.githubusercontent.com/knowledgeislands/tools-mgit/v0.12.0/install.sh`. The registry currently advertises `v0.12.0`.

The website does not discover releases. It advances only when this repository hands it the new version, which keeps the public recommendation deliberate — but it also means a release that is not handed over leaves the site advertising an older version.

This installer also accepts an explicit version only through `MGIT_VERSION`, while `ki` and `git-almanac` accept a positional `vX.Y.Z`. That inconsistency is the subject of `tools-ki` `KI-TOOL-CLI-076`.

## Boundary

This does not move release authority, installer behaviour, artifact hosting, or checksum verification to the website. The website is an indirection layer over what this repository publishes.

Do not remove the latest-release default from the installer. Pinning is an explicit opt-in; an unpinned `curl | sh` must keep working.

## Current state

The website already advertises released `mgit` version `v0.12.0`, but this repository still documents the branch-hosted installer and accepts an exact version only through `MGIT_VERSION`.

## Steps

- [x] Accept and validate one positional `vX.Y.Z`, giving it precedence over `MGIT_VERSION` while preserving latest-release discovery and `--link`.
- [x] Route public installation examples through the website endpoint and document the human-facing tool page and exact-version form.
- [x] Specify and test the installer contract, then update the manual and v1 baseline.

## Files touched

`install.sh`, `tests/mgit.bats`, `README.md`, `docs/guides/user/installation.md`, `docs/specs/index.md`, `docs/specs/distribution.md`, `man/mgit.1`, and `CHANGELOG.md`.

## Verify

Run `shellcheck bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1`, and `ki repo audit --repo .`.

## Dependencies / blocks

The website route and cross-tool positional-version decision already exist. No unresolved build-order dependency remains.

## Documentation impact

### Decision Records

No local decision record is needed; the accepted cross-tool decision is `tools-ki` `PDR-KI-TOOLS-001`.

### Specifications

Add a distribution specification for website routes and version selection.

### Guides

Update installation examples and explain latest versus exact-version installation.

### Roadmap

Close this item after the installer, tests, specifications, guide, manual, and changelog agree.

## Review

### Delivered

From immutable baseline `78094b180cb0dab9a32cd47271fbf880f6767ad4`, the installer gained exact positional version pinning and the public documentation adopted the website tool and installer routes. Release authority, artifact hosting, latest-release discovery, and local `--link` behavior remain within the approved boundary.

### Summary of changes

`install.sh` now validates positional and environment version inputs with positional precedence. `README.md`, the installation guide, `mgit(1)`, the v1 changelog baseline, Bats coverage, and a new distribution specification describe the same interface.

### Verification

`shellcheck bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1`, and `ki repo audit --repo .` pass.

### Outstanding concerns

None.

### Post-change review

The delivered behavior satisfies the goal and preserves the stated compatibility paths. The installer rejects ambiguous version inputs before any download and the published examples now use the stable website routes.

### Mini recap

MGit now follows the shared Knowledge Islands installer pinning and route contract. No additional durable learning route is needed beyond the specification and user installation guide.

## Done

Accepted 2026-09-18 by Kris Brown on review packet above.

## Discussion

### The release handoff

Add a named release follow-up: after publishing a release intended for general recommendation, hand `ki-website` an item naming the exact version and the immutable installer target `https://raw.githubusercontent.com/knowledgeislands/tools-mgit/v0.12.0/install.sh` with the new tag substituted. The website updates its registry entry and ships.

The website verifies declared routes before deployment and reports upstream drift as a warning rather than a failure, so an outstanding handoff is visible without breaking anyone's build.

### Version pinning

Accept a positional `vX.Y.Z` argument in addition to `MGIT_VERSION`, per the interface proposed in `tools-ki` `KI-TOOL-CLI-076`. Keep `MGIT_VERSION` working as an alias. Follow that item rather than deciding the interface here.

### Related

Originating repository and item: `knowledgeislands/ki-website` `KI-WEB-SITE-007`. That item is done and this one does not block it. The route contract is documented at `docs/guides/tool-routes.md` in that repository.
