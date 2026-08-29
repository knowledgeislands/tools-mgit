# Workspace discovery and dispatch — MGIT-WS

This as-built area specifies how [mgit specifications](index.md) represent repository sets, select repositories, and run ordinary commands across resulting checkouts. It excludes repository-structure conversion and worktree mutation.

## Repository-set sources

### MGIT-WS-001 — Direct workspace selection

When current directory contains a workspace-kind `.mgit.toml` manifest and manifest use is enabled, mgit MUST select its configured default group or group named by `--group`.

_Verify:_ `bats tests/mgit.bats` — `register preserves named groups and their selected order`.

### MGIT-WS-002 — Recursive workspace expansion

When a selected workspace member is another workspace, mgit MUST recursively use child workspace's configured default group rather than propagating parent's `--group` selection.

_Verify:_ `bin/mgit` — `select_workspace`; `bats tests/mgit.bats` — `register writes schema-1 workspaces in physical postorder`.

### MGIT-WS-003 — Manifest safety validation

mgit MUST reject malformed, duplicate, unsafe, missing, or cyclic workspace members rather than dispatching against a partial workspace selection.

_Verify:_ `bats tests/mgit.bats` — `workspace selection rejects malformed, duplicate, and unsafe paths`; `workspace selection rejects invalid groups and unsafe workspace cycles`.

### MGIT-WS-004 — Discovery fallback

When no current-directory workspace-kind manifest is present, or with `--ignore`, mgit MUST discover repositories below current directory, keep current repository when applicable, and omit repositories nested inside another discovered repository.

_Verify:_ `bats tests/mgit.bats` — `bare mgit lists discovered repos`; `--ignore bypasses workspace selection for discovery`.

### MGIT-WS-005 — Discovery traversal mode

mgit MUST use physical directory traversal by default and MAY follow symlinked container directories only when `--follow-symlinks` is selected.

_Verify:_ `bats tests/mgit.bats` — `--physical and --follow-symlinks control container traversal`.

### MGIT-WS-006 — Agora repository set

With `--agora`, mgit MUST use only absolute, unique repository roots returned by `ki agora roots --null`, MUST NOT follow repository symlink metadata, and MUST stop before command dispatch when resolution fails.

_Verify:_ `bats tests/mgit.bats` — `--agora selects only NUL-delimited roots from ki`; `--agora preserves its exact roots instead of following symlink metadata`; `--agora stops before command when ki cannot resolve roots`.

## Named groups and narrowing

### MGIT-WS-007 — Alternative group membership

mgit MUST permit an alternative named group to contain only direct structural-default workspace members and MUST preserve existing alternative groups when `register` refreshes structural default group.

_Verify:_ `bats tests/mgit.bats` — `group commands manage alternative workspace groups`; `register preserves named groups and their selected order`.

### MGIT-WS-008 — Named-group management

mgit MUST create, delete, add, and remove named alternative groups atomically, MUST refuse to alter structural `default` group through those operations, and MUST leave manifest unchanged when an operation fails validation.

_Verify:_ `bats tests/mgit.bats` — `group commands manage alternative workspace groups`; `group commands reject incomplete and surplus arguments`.

### MGIT-WS-009 — Filter composition

`--filter` MUST narrow final selected repository set by one or more glob patterns after selection and metadata expansion without changing how unfiltered set is discovered or expanded.

_Verify:_ `bats tests/mgit.bats` — `--filter limits repo set by glob`; `--filter applies to bare commands and requires a pattern`.

### MGIT-WS-010 — Whole-repository filters

When a filter selects a repository with linked worktrees, mgit MUST retain that repository's active worktrees in dispatch set.

_Verify:_ `bats tests/mgit.bats` — `--filter selects whole repos, keeping linked worktrees`.

## Dispatch-set command execution

### MGIT-WS-011 — Metadata closure

Outside Agora selection, mgit MUST add repositories reached through repository-kind `.mgit.toml` cross-repository symlink metadata, transitively and without duplicate dispatch targets.

_Verify:_ `bin/mgit` — metadata queue and `parse_mgit`; `bats tests/mgit.bats` — `a cross-repo symlink is recorded as a TOML entry`.

### MGIT-WS-012 — Active-worktree dispatch

mgit MUST expand each selected standard or nested repository into its active worktrees, excluding nested repository's bare store, before listing or dispatching ordinary commands.

_Verify:_ `bats tests/mgit.bats` — `normal commands expand a managed workspace to all child worktrees`.

### MGIT-WS-013 — Default Git dispatch

For a non-reserved command, mgit MUST run `git` with supplied command and arguments in each selected checkout while preserving ordinary Git command options.

_Verify:_ `bats tests/mgit.bats` — `ordinary Git command options remain pass-through`.

### MGIT-WS-014 — Bare command dispatch

With `--bare`, mgit MUST run supplied command directly in each selected checkout instead of prefixing it with `git`.

_Verify:_ `bats tests/mgit.bats` — `--filter applies to bare commands and requires a pattern`.

## Configuration contract

### MGIT-WS-015 — Discriminated configuration

Every canonical `.mgit.toml` document MUST declare `schema = 1` and exactly one supported top-level kind, `workspace` or `repository`, and mgit MUST reject fields or tables belonging to other kind.

_Verify:_ `bats tests/mgit.bats` — `discriminated manifests reject mixed document kinds`.

### MGIT-WS-016 — ~~Explicit configuration migration~~ (deprecated)

### MGIT-WS-017 — ~~Configuration conflict refusal~~ (deprecated)
