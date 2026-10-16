---
id: KI-TOOL-MGIT-CLI-017
area: CLI
title: Unified external members
kind: deliver
purpose: capability
component: cli
horizon: now
status: ready
blocks: []
blocked_by: []
baseline_ref: 438722c6a899aaa9b1624a7e122cd844fc250e88
created_at: 2026-10-16T21:10:00Z
updated_at: 2026-10-16T21:10:00Z
---

# Unified external members

## Goal

A workspace manifest records every repository in its set, local or external, as one `[members."PATH"]` entry carrying `kind`, `type` and optional `source`. External repositories keep `locations` as their discovery instruction; `[registered.members."PATH"]` is retired to a read-only legacy form.

## Context

Owner request of 16 October 2026: the dotfiles checkout `~/.local/share/chezmoi` joins the personal workspace (`~/workspaces/personal`) as `../../.local/share/chezmoi`, with a navigation symlink `~/workspaces/personal/dotfiles`. Discovery skips symlinked repositories, so explicit registration stays. The generated `[registered.members."PATH"]` tables carry no type or source and are a second representation of the same set; the owner asks for one members representation. The request authorises capture, planning and delivery of this record; it grants no acceptance, release or tag.

## Boundary

- **In:** member path validation, parsing, register output, recursive selection and deduplication, repair, legacy `registered.members` migration, doctor, help, manual, README, specification, user guide, changelog and tests.
- **Out:** a repair option that clones external members, changes to `locations` grammar, territory producer behaviour, version bump, release, tag and Homebrew publication.

## Current state

`parse_workspace` accepts `[members."PATH"]` only below the manifest directory and keeps location-derived roots in a separate `workspace_location_paths` list from empty `[registered.members."PATH"]` tables. `select_workspace` selects direct members (duplicate real paths fail) and then registered roots (duplicates skipped). `register_tree` writes registered tables from saved locations; `repair` ignores them.

## Steps

- [ ] Add external member path validation and accept it for direct repository members; parse legacy registered tables into members with a deprecation warning.
- [ ] Make `register` write location roots as typed, sourced members and drop locally discovered duplicates.
- [ ] Rework `select_workspace` deduplication by physical path and order local before external members.
- [ ] Make `repair` validate present external members and report, not clone, missing ones; keep legacy entries out of repair.
- [ ] Update usage, manual, README, workspace-dispatch specification, repository-sets guide and changelog.
- [ ] Add Bats cases for path validation, registration, parsing, recursive dispatch, deduplication with and without a navigation symlink, repair and legacy migration.
- [ ] Run the complete gate and a live read-only listing with the working-tree build.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `README.md`, `CHANGELOG.md`, `docs/specs/workspace-dispatch.md`, `docs/guides/user/repository-sets.md` and this record.

## Verify

`ki repo audit --repo .`, `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1`, `git diff --check`. Live: `bin/mgit` listing from `~/workspaces/personal` and `~/workspaces` against a reviewed manifest copy, read-only.

## Dependencies / blocks

None. The consumer manifest in the chezmoi source migrates only once the installed `mgit` reads the new form.

## Documentation impact

### Decision Records

None; the decisions above are local to this record.

### Specifications

Workspace dispatch: direct selection admits external repository members, deduplication by physical path, repair excludes external clones, legacy registered tables are deprecated.

### Guides

Repository sets shows the unified members form and the migration.

### Roadmap

This single record.

## Discussion

Planning decisions, 16 October 2026:

- **Path rule.** A direct repository member path is either local (a safe relative path below the manifest directory) or external (one or more leading `../` segments followed by a safe relative tail). Workspace members and legacy grouped members stay local.
- **Registration.** `register` writes each location root as a repository member with its detected type and `origin` source. A root inside the workspace that local discovery already records is not written again.
- **Selection and deduplication.** Selection takes local members, then external members, each in path order. Repositories are identified by their resolved physical path: an external member already selected anywhere in the recursive set, or a local member already selected as an external one, is skipped; two local members resolving to the same repository still fail.
- **Repair.** Repair validates present external members like local ones but never clones a missing external member; it reports it and continues.
- **Migration.** Legacy `[registered.members."PATH"]` tables stay readable for selection with a once-per-manifest deprecation warning. Plain `mgit register` (or `--dry-run` to preview) rewrites them as members from the saved locations. No separate migrate command.
