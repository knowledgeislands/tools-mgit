---
id: MGIT-CLI-001
title: Add named repository groups
theme: cli
horizon: next
status: open
blocks: []
blocked-by: []
baseline-ref: null
transferred-from: knowledgeislands/tools-ki:KI-TOOL-CLI-011
---

## Context

Replace generated `.mgit-config.toml` manifests in non-Git container directories with versioned `.mgit-workspace.toml` files that hold ordered repository groups. Retain `.mgit-config.toml` only at repository leaves for mGit-owned metadata such as cross-repository symlinks. Rename manifest-driven workspace reconciliation from `bootstrap` to `repair`. This follows the same container/leaf ownership model as KI workspaces while remaining an mGit-owned command and manifest design.

## Boundary

Do not introduce KI workspace parsing, weaken manifest validation, or make this work a prerequisite for KI workspace registration. A repository leaf retains its `.mgit-config.toml` only for mGit-owned leaf metadata; a non-Git container owns no `.mgit-config.toml` after registration. `register` refreshes generated default workspace membership but preserves named user groups. `bootstrap` is removed rather than retained as a compatibility alias.

## Current state

`mgit` currently writes `.mgit-config.toml` into every container and some repository leaves, then recursively resolves the structural member hierarchy. There is no durable, ordered, human-authored subset definition and no distinction in generated ownership between non-Git parents and repository leaves. Its manifest-driven reconciliation command is named `bootstrap`, although it repairs a partial workspace as safely as it creates missing checkouts. The user has chosen the container/leaf split and breaking rename, so a Soon stage would add no useful shaping interval.

## Steps

1. Define strict schema-1 `.mgit-workspace.toml` records with a default group, ordered direct-repository and nested-workspace membership, and named user groups. Resolve all paths relative to their workspace file; reject malformed syntax, cycles, duplicate repository resolution, unknown groups, and unsafe containment.
2. Change `register` to make one physical post-order traversal: stop at Git repository leaves, retain or refresh their `.mgit-config.toml` only for leaf metadata, create or refresh each non-Git container's default workspace group, preserve its named groups, and replace any old generated parent `.mgit-config.toml` only after preflighting the complete write set.
3. Resolve a direct-CWD workspace's default group in place of the old parent-manifest hierarchy. Add `-g` / `--group NAME` to select a named group, preserve declared order through recursive workspace expansion, then apply existing `--filter` options without reordering.
4. Rename the manifest-driven `bootstrap` command and all of its diagnostics, help, completion, tests, and documentation to `repair`; preserve its safe no-replacement behaviour and provide no compatibility alias.
5. Keep `repair` structural: it follows the resolved default workspace hierarchy to materialize missing repository leaves, but does not alter named user groups. Treat parent `.mgit-config.toml` files as obsolete generated state rather than attempting a compatibility read or migration.
6. Extend Bats coverage for parent-config replacement, leaf-config retention, generated-default refresh with named-group preservation, ordered recursive selection, malformed and cyclic workspace membership, group/filter composition, `repair`, and safe registration preflight.
7. Update command help, shell completion, README, user guide, and `mgit(1)` to document the container/leaf file ownership, workspace syntax, selection behavior, the `repair` rename, and breaking boundary.

## Files touched

- `bin/mgit`
- `tests/mgit.bats`
- `README.md`
- `docs/user-guide/running-commands.md`
- `docs/user-guide/repository-sets.md`
- `man/mgit.1`

## Verify

Run `shellcheck bin/mgit install.sh` and `bats tests/` successfully. Confirm focused Bats cases prove that registration replaces a parent `.mgit-config.toml` with a workspace file, preserves repository-leaf configuration, refreshes only a workspace default group, and selects ordered groups recursively.

## Dependencies / blocks

No implementation dependency. The KI roadmap audit is clean after placing `repo_code` in the `ki-repo` configuration table and declaring the `CLI` theme mapping under `ki-roadmap`.

## Delegation

### Locked decisions

The container/leaf split, schema-1 workspace file, generated `default` group, preservation of named groups, direct-CWD default selection, `-g` / `--group`, and the breaking `bootstrap` → `repair` rename are fixed. A workspace member is an ordered TOML array-table record: `kind = "repository"` records `path`, `type`, and optional `source`; `kind = "workspace"` records a child workspace `path`. The generated default group is the only group whose membership `register` rewrites. Non-default groups may name existing repository or workspace paths, but cannot carry structural `type` or `source` metadata. Do not reintroduce parent `.mgit-config.toml` compatibility, an alias for `bootstrap`, or KI-specific configuration semantics.

### Escalate

Stop for a decision if preserving named groups would require lossy or unsafe mutation of an existing workspace file, if a required Chezmoi update cannot preserve its managed-source contract, or if recursive workspace membership exposes a path containment or clone-source ambiguity outside this schema.

### Rounds

1. **Workspace core — judgment, `gpt-5.6-sol`.** Implement the workspace parser, post-order registration, recursive selection, and `repair` source traversal in `bin/mgit`; add only the targeted Bats cases needed to drive that contract. Done means parent configuration is replaced only after preflight, repository-leaf metadata remains valid, default membership resolves recursively in declaration order, and `repair` remains non-destructive. Scope: `bin/mgit`, `tests/mgit.bats`. The orchestrator reviews the executable diff adversarially and runs focused Bats cases plus ShellCheck before integration.
2. **Documentation and command surface — mechanical, `gpt-5.6-terra`.** After the core gate, update README, user guide, manual, usage, and completions for the exact implemented schema and `repair` command. Done means all public descriptions agree and contain no `bootstrap` compatibility claim. Scope: `README.md`, `docs/user-guide/`, `man/mgit.1`, and completion/help text in `bin/mgit`; serialize with the core worker where `bin/mgit` write contention remains. The orchestrator reviews the diff and runs the completion tests.
3. **Integration gate — orchestrator.** Re-read every changed public contract, run `shellcheck bin/mgit install.sh`, `bats tests/`, and the roadmap audit, then record the result in the item acceptance packet. Any failed check, new external dependency, destructive migration issue, or public contract question stops the item.

## Discussion

### Container and leaf ownership

`.mgit-workspace.toml` is the generated-and-curated container record: `register` owns its default group, while named non-default groups remain user-owned. Its default membership distinguishes a direct repository leaf from a nested workspace directory, allowing each container to retain concise local paths and the root to expand the hierarchy deterministically. `.mgit-config.toml` is leaf-only and never describes child repository membership after this change.

The schema is deliberately explicit:

```toml
schema = 1
default = "default"

[[groups.default.members]]
kind = "repository"
path = "tools-mgit"
type = "standard"
source = "git@github.com:knowledgeislands/tools-mgit.git"

[[groups.default.members]]
kind = "workspace"
path = "subgroup"
```

`register` may replace only `groups.default.members`; named groups retain their ordered membership. The direct repository records retain the structure and source information that `repair` needs to materialize an incomplete workspace.

### Selection and compatibility

With no explicit group, a direct-CWD workspace selects its generated default group. `--group NAME` selects exactly one named group and retains its declared order through nested workspace resolution. Existing `--filter` options apply afterward, preserving that order. Normal commands, listing, `structure`, and `worktree` use the resulting selection; `register` refreshes only default membership and `repair` follows the default hierarchy without changing user groups. The originating `tools-ki` work item is non-blocking evidence of the analogous need, not a shared implementation dependency.
