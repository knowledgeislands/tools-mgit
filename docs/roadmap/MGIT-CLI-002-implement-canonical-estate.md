---
id: MGIT-CLI-002
title: Support Agora sets
area: CLI
theme: cli
horizon: next
status: awaiting-review
blocks: []
blocked_by: []
baseline_ref: 5fc140df96fcd2b62abc0e9bd14f06573faa320f
---

## Goal

Let a user run an ordinary MGit command over the locally resolved members of a named Agora or the KI estate, without making MGit understand KI configuration.

## Context

The Harness has published the repository-kind and store-role contract that originally blocked this record. `ki` now resolves registered local repositories for a reciprocal named Agora or the reserved `estate` selector. `tools-ki` now provides the V1 `ki agora roots <name>` resolver: it writes newline-delimited absolute roots by default and supports NUL-delimited roots through `--null` / `-0`. MGit consumes only the NUL form. Invalid, empty, missing, or non-reciprocal selections fail without roots on standard output; the resolver never clones repositories, infers membership from paths, or includes local source or legacy stores.

MGit already selects a local repository set through discovery or a `.mgit-workspace.toml` manifest. Those path-based workspace groups remain separate from Agoras, which are portable declarations without local paths. Parsing `.ki-config.toml`, the local registry, or peer declarations in Bash would duplicate `ki` authority and couple MGit to an evolving configuration model.

## Boundary

Do not parse KI declarations or the local KI registry in MGit. Do not create or alter an Agora, make source or legacy stores Git repositories, replace workspace-manifest selection authority, or write another repository. Existing MGit commands must continue to require only Bash and Git; any `ki` dependency applies only to an explicit Agora selection.

Do not revive the retired `.mgit-config.toml` member-set model or use presentation output from `ki agora show` as a machine interface.

## Current state

MGit currently chooses its base set from a workspace manifest or filesystem discovery, then expands active worktrees and follows repository-owned symlink metadata. It has no external set selector, invokes no KI command, and does not recognise `--agora`.

## Steps

- [x] Add a repeat-safe `-a` / `--agora <name>` global selector and reject its combination with workspace or discovery selectors and reserved management commands.
- [x] Invoke `ki agora roots --null <name>` exactly once, fail before selection on a missing or failing resolver, and validate the non-empty NUL-delimited physical repository roots it returns.
- [x] Use those exact roots as the base set, skipping discovery, workspace parsing, and symlink-metadata expansion; retain filtering and active-worktree expansion.
- [x] Document the selector in help, Bash and Zsh completion, the user guide, and `mgit(1)`.
- [x] Add hermetic Bats coverage for successful selection, NUL-safe paths, resolver failure, missing `ki`, selector conflicts, and no expansion beyond the returned set.

## Files touched

- `bin/mgit`
- `tests/mgit.bats`
- `README.md`
- `docs/guides/user/running-commands.md`
- `man/mgit.1`

## Verify

```sh
shellcheck bin/mgit install.sh
bats tests/
ki repo audit --skill ki-authoring --repo .
ki repo audit --skill ki-change-management-roadmap --repo .
```

## Dependencies / blocks

The V1 resolver is available. There are no unresolved local work-item dependencies.

## Review

### Delivered

`mgit --agora <name>` resolves one named Agora or `estate` through `ki agora roots --null <name>`, then runs ordinary Git or bare commands over that exact root set. It is unavailable to MGit management commands and never reads KI configuration.

### Summary of changes

The selector validates a non-empty stream of absolute physical Git repository roots before MGit selects any command target. It retains filters and active-worktree expansion, but skips workspace parsing, filesystem discovery, and repository-owned symlink metadata. Help, both completion systems, the README, user guide, and manual document the optional `ki` dependency and selector boundaries.

### Verification

- `bash -n bin/mgit` — pass.
- `shellcheck bin/mgit install.sh` — pass.
- `bats tests/` — pass (50 tests), including five hermetic Agora-selector cases.
- `mandoc -Tlint man/mgit.1` — pass.
- `./bin/mgit --agora ki-fnd` — listed the eight locally resolved `ki-fnd` roots.

### Outstanding concerns

The feature depends on the delivered V1 `ki agora roots --null` contract only when `--agora` is explicit. No current unresolved concern blocks review.

### Post-change review

The NUL stream is captured before parsing, so a failing resolver cannot leave partial roots for MGit to execute. The selector refuses discovery and workspace flags and skips symlink-metadata expansion, preventing a resolved Agora from silently growing beyond `ki`'s authoritative roots.

### Mini recap

Baseline: `5fc140df96fcd2b62abc0e9bd14f06573faa320f`.

Implementation: `6948640487a12d4561ecb7d7577fdb254d0038bb`.

## Discussion

### MGit adapter

`--agora <name>` invokes `ki` once, safely consumes the returned roots, and applies normal command fan-out and worktree handling to that fixed set. It does not read any KI file. Without `--agora`, MGit neither invokes nor requires `ki`.

The selector is a read-only set source: `register`, `repair`, workspace-group mutation, `structure`, and `worktree` remain local-manifest or discovery operations. It rejects `--group`, `--ignore`, `--physical`, and `--follow-symlinks`; `--filter` narrows the resolved roots and `--bare` remains available. Skipping symlink-metadata expansion preserves the resolved Agora as the exact authoritative set rather than silently adding linked repositories.

### Promotion condition

The resolver is released, documented, and locally verified. This item is ready for implementation under the stated boundary and verification gates.
