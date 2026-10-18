---
id: KI-TOOL-MGIT-CLI-022
area: CLI
title: External member review findings
kind: deliver
purpose: corrective
component: cli
horizon: next
status: ready
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-18T04:10:00Z
updated_at: 2026-10-18T05:46:00Z
---

## Goal

Settle the four low findings from the independent review of [KI-TOOL-MGIT-CLI-017](KI-TOOL-MGIT-CLI-017-unified-external-members.md): fix, document or drop each one.

## Context

The tools-burndown mgit-review run of 17 October found nothing blocking in KI-TOOL-MGIT-CLI-017 and four low findings. Its MGIT-REVIEW-LOWS query recommended a): accept KI-TOOL-MGIT-CLI-017 as it stands and capture the findings as one triage record. The tools-burndown run of 18 October captured this record under Kris's overnight instruction to take the recommended course ("provisional, for Kris to confirm"); acceptance of KI-TOOL-MGIT-CLI-017 stays with Kris.

- **L1, missing external member.** If the external checkout is missing, selection fails for the whole set, including from `~/workspaces`, and repair only reports it. A missing local member behaves the same way, so this matters only if the member is declared on a machine without the checkout.
- **L2, external path back inside the workspace.** A hand-written path such as `../personal/acquire` is quietly deduplicated, not rejected. Registration never writes one.
- **L3, register drops hand-written external members.** `mgit register` drops a hand-written external member that has no matching location, and `--dry-run` does not name it. The guide documents this.
- **L4, cosmetic.** `mgit repair` prints the deprecation warning twice for one manifest, once for each spelling of its path.

## Boundary

- **In:** a disposition for each of the four findings in `bin/mgit`, Bats cases, the repository-sets guide, the workspace-dispatch specification and the changelog.
- **Out:** reopening KI-TOOL-MGIT-CLI-017, cloning external members, changing the `locations` grammar, the chezmoi-managed consumer manifest, any version bump, release or tag.

## Current state

`workspace_warn_legacy` (`bin/mgit`) remembers warned manifests by the path string it was given, so `repair` warns once for `./.mgit.toml` and once for the canonical path (L4). `select_workspace` resolves an external member and deduplicates it against local members by physical path, so a hand-written `../personal/acquire` from `~/workspaces/personal` is quietly selected once rather than rejected (L2). `register_tree` rebuilds members from discovery and saved locations, so a hand-written external member with no matching location disappears without a word, in a real run or under `--dry-run` (L3). A missing external member fails selection for the whole set with `unsafe or missing external repository path`, exactly as a missing local member does (L1).

## Steps

- [ ] L4: key the legacy deprecation warning by the manifest's physical path, so one manifest warns once per run whichever spelling reached it.
- [ ] L2: reject an external member whose physical path lies inside the manifest's own directory, in selection and in repair preflight, with an error that names the local path to write instead.
- [ ] L3: make `register` and `register --dry-run` name each hand-written external member it drops because no saved location produces it, with the `register add --repo` route to keep it.
- [ ] L1: keep the behaviour and document it: a missing external member fails selection like a missing local member, so declare one only on machines that have the checkout.
- [ ] Add Bats cases for L2, L3 and L4, and update the repository-sets guide, the workspace-dispatch specification and the changelog.
- [ ] Run the complete gate.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `docs/guides/user/repository-sets.md`, `docs/specs/workspace-dispatch.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes: `ki repo audit --repo .`, `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1` and `git diff --check`. The new Bats cases show one warning per manifest under `repair`, a rejected inward external path, and a named drop line from `register` and `register --dry-run`.

## Dependencies / blocks

None. It settles the review findings on KI-TOOL-MGIT-CLI-017, whose code is on `main`.

## Documentation impact

### Decision Records

None; each disposition is local to this record and recorded below.

### Specifications

MGIT-WS-003 gains the inward external-path rejection and states that a missing external member fails selection; MGIT-WS-021 gains the named drop line under `register --dry-run`.

### Guides

The repository-sets guide states the missing-member behaviour and the drop line.

### Roadmap

None; the four findings close here.

## Discussion

L4 is a likely quick fix; L2 and L3 could become a rejection and a `--dry-run` line; L1 may be accepted as documented behaviour.

### Adoption (provisional, for Kris to confirm)

Adopted into Next and planned to Ready on 18 October 2026 by the ways-of-working mgit-build run, provisionally on Fable's opinion of 18 October (fable-opinion-2, option a), under Kris's KEEP-PUSHING and FABLE-OPINION answers. Building stops at Awaiting review, pure Bash with Bats fixtures only, with no release. Kris confirms or reverses the adoption and plan by editing this record.
