---
id: KI-TOOL-MGIT-CLI-017
area: CLI
title: Unified external members
kind: deliver
purpose: capability
component: cli
status: done
blocks: []
blocked_by: []
baseline_ref: 4070e62095da49f79f55e090973a07ac3c163146
created_at: 2026-10-16T21:10:00Z
updated_at: 2026-10-18T17:09:15Z
---

# Unified external members

## Goal

A workspace manifest records every repository in its set, local or external, as one `[members."PATH"]` entry carrying `kind`, `type` and optional `source`. External repositories keep `locations` as their discovery instruction; `[registered.members."PATH"]` is retired to a read-only legacy form.

## Context

Owner request of 16 October 2026: the dotfiles checkout `~/.local/share/chezmoi` joins the personal workspace (`~/workspaces/personal`) as `../../.local/share/chezmoi`, with a navigation symlink `~/workspaces/personal/dotfiles`. Discovery skips symlinked repositories, so explicit registration stays. The generated `[registered.members."PATH"]` tables carry no type or source and are a second representation of the same set; the owner asks for one members representation. The request authorises capture, planning and delivery of this record; it grants no acceptance, release or tag.

A parallel capture of 17 October 2026, _Unify repository members_, recorded the same request under this number and is merged here. It adds that the dotfiles checkout's Git remote is `git@github.com:krisb/dotfiles.git`, that the earlier registration wrote `repo:../../.local/share/chezmoi` in `locations` beside an empty `registered.members` table, and that the owner wants the external path under ordinary `members` with `kind = "repository"`, `type = "standard"` and the origin as `source`. The [repository-set guide](../guides/user/repository-sets.md) describes the resulting model.

Reconciliation, 17 October 2026: the delivery commits were rebased onto that capture. The original Ready baseline `438722c` and the parallel reservation `b206b8d` made the same ledger advance, so the rebase dropped `438722c`; `4070e62`, which holds both the reservation and the parallel capture, is the baseline now.

## Boundary

- **In:** member path validation, parsing, register output, recursive selection and deduplication, repair, legacy `registered.members` migration, doctor, help, manual, README, specification, user guide, changelog and tests.
- **Out:** a repair option that clones external members, changes to `locations` grammar, territory producer behaviour, version bump, release, tag and Homebrew publication. Renaming the dotfiles checkout or changing its remote, general symlink discovery, a change to repository-selection scope and any new runtime dependency are out too. The working chezmoi registration and navigation symlink stay until a reviewed migration is available; consumer changes belong to their owning repository, and this record grants no authority to apply dotfiles or modify live workspaces.

## Current state

`parse_workspace` accepts `[members."PATH"]` only below the manifest directory and keeps location-derived roots in a separate `workspace_location_paths` list from empty `[registered.members."PATH"]` tables. `select_workspace` selects direct members (duplicate real paths fail) and then registered roots (duplicates skipped). `register_tree` writes registered tables from saved locations; `repair` ignores them.

## Steps

- [x] Add external member path validation and accept it for direct repository members; parse legacy registered tables into members with a deprecation warning.
- [x] Make `register` write location roots as typed, sourced members and drop locally discovered duplicates.
- [x] Rework `select_workspace` deduplication by physical path and order local before external members.
- [x] Make `repair` validate present external members and report, not clone, missing ones; keep legacy entries out of repair.
- [x] Update usage, manual, README, workspace-dispatch specification, repository-sets guide and changelog.
- [x] Add Bats cases for path validation, registration, parsing, recursive dispatch, deduplication with and without a navigation symlink, repair and legacy migration.
- [x] Run the complete gate and a live read-only listing with the working-tree build.

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

## Review

### Delivered

From the Ready baseline (`438722c` before rebase, now `4070e62`), external repositories are ordinary `[members."../PATH"]` entries with `kind`, `type` and `source`, generated from saved `repo:` and `territory:` locations. Selection deduplicates by physical path across the recursive set; repair validates present external members and never clones a missing one; legacy `[registered.members]` tables stay readable with a once-per-manifest warning and a doctor warning until `mgit register` rewrites them. No version bump, release, tag, acceptance or pruning.

### Change Summary

`e7511d1` (`bcac3d1` before rebase) changes `bin/mgit` (path rule, parser scopes, register, selection, repair, doctor, help), adds five Bats cases and updates two, and updates the manual, README, changelog, workspace-dispatch specification and repository-sets guide.

### Verification

`ki repo audit --repo .` passes with the existing HOOK-1 warning; `shellcheck`, `bash -n`, `mandoc -T lint` and `git diff --check` are clean; `bats tests/` passes 98 of 98; the producer proof with `MGIT_KI_PRODUCER` set to the installed `ki` passes 10 of 10. Live, the working-tree build lists the unchanged consumer manifests from `~/workspaces/personal` (7) and `~/workspaces` (54) with healthy doctor verdicts, previews `register add --repo ~/.local/share/chezmoi --dry-run` as 7 local and 1 external member without writes, and a disposable overlay of real repositories dispatches the real dotfiles checkout exactly once from both levels, with and without a navigation symlink and under `--follow-symlinks` discovery.

### Outstanding concerns

A manifest containing external members is rejected as unsafe by v0.17.0 and earlier, so the chezmoi-managed consumer manifest `workspaces/personal/dot_mgit.toml` should gain the dotfiles member only after a release reaches every machine that applies it; it is unchanged. Human acceptance is outstanding.

### Post-change review

One representation now carries the whole repository set; `locations` remains the discovery instruction. Two local members resolving to one repository still fail, as before. Legacy tables are read, never written.

### Mini recap

External membership unified with tests and documentation. A possible follow-up, not captured: let `register add --repo` accept a navigation symlink and store its resolved target.

## Done

Accepted 2026-10-18 by the ways-of-working mgit-build run on Fable's opinion, provisionally for Kris to confirm, on the review packet above.

## Discussion

### Acceptance (provisional, for Kris to confirm)

Accepted on 18 October 2026 by the ways-of-working mgit-build run, provisionally on Fable's opinion of 18 October (fable-opinion-2), under Kris's KEEP-PUSHING and FABLE-OPINION answers and taken under ACCEPT-NIGHT's condition: the independent mgit-review run of 17 October passed with no blocking or medium findings. Its four low findings are [KI-TOOL-MGIT-CLI-022](KI-TOOL-MGIT-CLI-022-external-member-review-findings.md). The outstanding consumer-manifest concern is a release and chezmoi matter owned by the dotfiles repository, not triggered by acceptance. Kris confirms or reopens this by editing the record; it is not pruned.

Confirmed 2026-10-18 by Kris in the 17:59 BST owner answers of the [ways-of-working decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.ways-of-working/decisions.md) (MGIT-017-CONFIRM a)): "The CLI-017 is agreed on the recommendations." The provisional acceptance above stands as human acceptance.

Planning decisions, 16 October 2026:

- **Path rule.** A direct repository member path is either local (a safe relative path below the manifest directory) or external (one or more leading `../` segments followed by a safe relative tail). Workspace members and legacy grouped members stay local.
- **Registration.** `register` writes each location root as a repository member with its detected type and `origin` source. A root inside the workspace that local discovery already records is not written again.
- **Selection and deduplication.** Selection takes local members, then external members, each in path order. Repositories are identified by their resolved physical path: an external member already selected anywhere in the recursive set, or a local member already selected as an external one, is skipped; two local members resolving to the same repository still fail.
- **Repair.** Repair validates present external members like local ones but never clones a missing external member; it reports it and continues.
- **Migration.** Legacy `[registered.members."PATH"]` tables stay readable for selection with a once-per-manifest deprecation warning. Plain `mgit register` (or `--dry-run` to preview) rewrites them as members from the saved locations. No separate migrate command.

Requirements folded in from the parallel capture, 17 October 2026, each met by the delivery above:

- **One member namespace.** Local discovery and explicit external registration share one path-keyed repository member; `locations` keeps refresh intent; repository and workspace documents, and repository and child-workspace members, stay distinct.
- **Path safety.** External paths may leave the workspace directory under an explicit rule rather than a weakened general check; registration, parsing, recursive dispatch, identity resolution and deduplication are reviewed together.
- **Migration.** Existing `registered.members` manifests remain readable, and rewriting never silently discards saved locations or unrelated members.
- **Verification.** The checkout dispatches exactly once from `~/workspaces/personal` and `~/workspaces`, with the navigation symlink present; disposable public-CLI tests cover external relative paths, duplicate inclusion, nested traversal, invalid paths and migration failures.
- **Repair and offline dispatch.** Recording an external `source` never makes repair clone; ordinary dispatch keeps using the saved member set offline.
- **Consumer coordination.** The consumer source `workspaces/personal/dot_mgit.toml` in [krisb/dotfiles](https://github.com/krisb/dotfiles) migrates alongside a released mGit, preserving source/live agreement and chezmoi's review-and-apply boundary.
