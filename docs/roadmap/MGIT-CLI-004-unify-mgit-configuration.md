---
id: MGIT-CLI-004
title: Unify mGit configuration
area: CLI
theme: cli
horizon: next
status: awaiting-review
blocks: []
blocked_by: []
baseline_ref: f13154fe09eb350e21aac69c24eb7c7a89c1763c
---

## Goal

Replace the split `.mgit-workspace.toml` and `.mgit-config.toml` contracts with one explicit `.mgit.toml` format that represents either a workspace manifest or repository-local mGit metadata without conflating their fields.

## Context

mGit currently writes workspace membership to `.mgit-workspace.toml` and repository symlink metadata to `.mgit-config.toml`. The names expose implementation history rather than the tidy tool-level convention already used by `.git-almanac.toml`, and the two files leave downstream consumers to guess which mGit contract is authoritative.

The split has already produced semantic drift: the `ki` CLI still reads legacy workspace membership from a direct-CWD `.mgit-config.toml`, while current mGit documentation and implementation use `.mgit-workspace.toml`. The observed local estate contains thirteen workspace manifests and one repository-local manifest, so migration must cover both kinds without losing groups, members, or symlink metadata.

## Boundary

This item owns the mGit schema, parser and writer behaviour, workspace discovery, registration, group selection, repair behaviour, documentation, tests, and an explicit migration path to `.mgit.toml`. It does not rename the KI repository declaration, implement the corresponding `ki` CLI reader changes, or mutate generated manifests and Chezmoi-managed estate state as an implicit side effect.

## Current state

`bin/mgit` and the published guidance treat `.mgit-workspace.toml` as the workspace manifest, while repository symlink metadata uses `.mgit-config.toml`. Tests cover both surfaces separately, and no canonical `.mgit.toml` schema or migration path exists.

## Steps

- [x] Define the versioned, discriminated `.mgit.toml` schema and its invalid mixed states in the workspace specification.
- [x] Update discovery, parsing, writing, registration, repair, and group selection to use the canonical schema.
- [x] Add explicit migrations from both legacy filenames, including conflict and Chezmoi-managed-state diagnostics.
- [x] Update the README, user guides, manual page, and examples to distinguish workspace and repository kinds within the one format.
- [x] Add focused and end-to-end coverage for both kinds, migration paths, and ambiguous-input failure.

## Files touched

- `bin/mgit`
- `docs/specs/workspace-dispatch.md`
- `README.md`, `docs/guides/user/`, and `man/mgit.1`
- `CHANGELOG.md` and `AGENTS.md`
- `tests/mgit.bats`
- `docs/roadmap/MGIT-CLI-004-unify-mgit-configuration.md`

## Verify

- `shellcheck bin/mgit`
- `bats tests/mgit.bats`
- Confirm a fixture can migrate and dispatch from each legacy workspace and repository form, while a mixed or conflicting state fails with an actionable diagnostic.

## Dependencies / blocks

There is no local prerequisite. The accepted schema becomes an external prerequisite for `KI-TOOL-CLI-055` in `tools-ki`; that cross-repository relationship is narrative rather than a local `blocks` edge.

## Documentation impact

### Decision Records

No Decision Record is required unless implementation reveals a durable design choice not adequately owned by the behaviour specification.

### Specifications

Update `docs/specs/workspace-dispatch.md` to own the `.mgit.toml` schema, kind-specific invariants, discovery, and migration behaviour.

### Guides

Update the README, user guides, examples, and manual page for the canonical filename and migration workflow.

### Roadmap

Retain this record through review and report the accepted contract to the waiting `tools-ki` item; no additional local roadmap record is currently required.

## Review

### Delivered

Implemented the approved canonical configuration contract across `bin/mgit`, tests, specifications, user guidance, command help, completion, and manual. `.mgit.toml` now declares `schema = 1` and top-level `kind = "workspace"` or `kind = "repository"`; `mgit register` owns explicit legacy migration and conflict refusal.

### Summary of changes

- Replaced split runtime and writer paths with discriminated canonical manifest handling for workspace selection, named groups, repair, and repository symlink closure.
- Added migration preflight for `.mgit-workspace.toml` and `.mgit-config.toml`, including canonical-plus-legacy, multiple-legacy, wrong-kind, mixed-document, and Chezmoi synchronization boundaries.
- Added focused Bats coverage for both canonical kinds, both legacy migrations, conflict refusal, ordinary-command guidance, mixed documents, and Agora isolation.
- Updated behavior specification, user guides, examples, manual, standing repository guidance, and a navigable Standard Readme-inspired README.
- Applied user-approved scope clarification to model `CHANGELOG.md` on `tools-ki`: one curated v1 baseline rather than per-0.x release history.

### Verification

- `shellcheck bin/mgit install.sh` — passed.
- `bats tests/` — 54 tests passed.
- `mandoc -T lint man/mgit.1` — passed; plain UTF-8 rendering inspected.
- `bin/mgit --help`, `--version`, and Bash/Zsh completion smoke checks — passed.
- KI adapter, specification, guide, authoring, tool-repository, and Git audits — passed.
- Whole-repository audit — implementation-scoped skills passed; pre-existing `ki-repo` `FILES-6` failure remains on unchanged `.gitignore` unmanaged section.

### Outstanding concerns

- `KI-TOOL-CLI-055` in `tools-ki` remains downstream work; this delivery does not change another repository or its legacy reader.
- Existing estate manifests are intentionally not rewritten. Each configuration owner must run or authorize migration independently.
- Whole-repository audit remains non-clean because unchanged `.gitignore` has a pre-existing `ki-repo` `FILES-6` finding outside this item.
- Acceptance, push, release, and Homebrew formula updates remain outside this implementation boundary.

### Post-change review

The delivered behavior matches the approved goal and scope: one mGit-owned filename has explicit kind separation, legacy state has a bounded migration path, and ambiguity fails closed with actionable diagnostics. Regression risk is concentrated in shell parsing and registration traversal; schema, migration, group, repair, symlink-closure, Agora, completion, and command-dispatch coverage all pass. The item is ready for human acceptance review; the unrelated `.gitignore` audit finding is disclosed rather absorbed into this delivery.

### Mini recap

The repository now owns a versioned `.mgit.toml` contract, explicit legacy migration, synchronized user-facing documentation, and the pre-v1 changelog baseline requested during delivery. No additional durable learning route is needed: changelog policy is already captured in `AGENTS.md`, behavior is in Specifications, and migration procedure is in user guide. Downstream KI reader work remains linked to `KI-TOOL-CLI-055` without automatic cross-repository action.

## Discussion

### Intended contract

Define a versioned `.mgit.toml` document with an explicit discriminator such as `kind = "workspace"` or `kind = "repository"`. Preserve the current workspace groups and members and the repository-local symlink metadata, validate that fields match the declared kind, and reject ambiguous mixed documents.

The schema must remain an mGit-owned contract rather than becoming a shared configuration file for unrelated tools. Record the accepted shape in the repository's durable specification or decision surface before downstream implementation relies on it.

### Migration

Provide a bounded migration from both existing filenames, including clear diagnostics for conflicts and a deliberate policy for generated or Chezmoi-managed manifests. Avoid indefinite dual-write behaviour or silent precedence between two legacy files. Any estate-wide rewrite remains separately authorized and should retain one independently reviewable commit per repository or configuration owner.

### Downstream hand-off

This item has no local prerequisite and can proceed independently of the KI naming decision. Its accepted `.mgit.toml` contract is one external return condition for `KI-TOOL-CLI-055` in `tools-ki`.
