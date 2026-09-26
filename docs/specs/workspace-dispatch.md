# Workspace discovery and dispatch — MGIT-WS

This as-built area specifies how [mgit specifications](index.md) represent repository sets, select repositories, and run ordinary commands across resulting checkouts. It excludes repository-structure conversion and worktree mutation.

## Repository-set sources

### MGIT-WS-001 — Direct workspace selection

When current directory contains a workspace-kind `.mgit.toml` manifest and manifest use is enabled, mgit MUST select its configured default group or group named by `--group`.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `register preserves named groups and their selected order`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-002 — Recursive workspace expansion

When a selected workspace member is another workspace, mgit MUST recursively use child workspace's configured default group rather than propagating parent's `--group` selection.

_Conformance:_ conforming

_Verify:_ `bin/mgit` — `select_workspace`; `bats tests/mgit.bats` — `register writes schema-1 workspaces in physical postorder`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-003 — Manifest safety validation

mgit MUST reject malformed, duplicate, unsafe, missing, or cyclic workspace members rather than dispatching against a partial workspace selection.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `workspace selection rejects malformed, duplicate, and unsafe paths`; `workspace selection rejects invalid groups and unsafe workspace cycles`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-004 — Discovery fallback

When no current-directory workspace-kind manifest is present, or with `--ignore`, mgit MUST discover repositories below current directory, keep current repository when applicable, and omit repositories nested inside another discovered repository.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `bare mgit lists discovered repos`; `--ignore bypasses workspace selection for discovery`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-005 — Discovery traversal mode

mgit MUST use physical directory traversal by default and MAY follow symlinked container directories only when `--follow-symlinks` is selected.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--physical and --follow-symlinks control container traversal`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-006 — Agora repository set

With `--agora`, mgit MUST use only absolute, unique repository roots returned by `ki agora roots --null`, MUST NOT follow repository symlink metadata, and MUST stop before command dispatch when resolution fails.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--agora selects only NUL-delimited roots from ki`; `--agora preserves its exact roots instead of following symlink metadata`; `--agora stops before command when ki cannot resolve roots`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

## Named groups and narrowing

### MGIT-WS-007 — Alternative group membership

mgit MUST permit an alternative named group to contain only direct structural-default workspace members and MUST preserve existing alternative groups when `register` refreshes structural default group.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `group commands manage alternative workspace groups`; `register preserves named groups and their selected order`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-008 — Named-group management

mgit MUST create, delete, add, and remove named alternative groups atomically, MUST refuse to alter structural `default` group through those operations, and MUST leave manifest unchanged when an operation fails validation.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `group commands manage alternative workspace groups`; `group commands reject incomplete and surplus arguments`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-009 — Filter composition

`--filter` MUST narrow final selected repository set by one or more glob patterns after selection and metadata expansion without changing how unfiltered set is discovered or expanded.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--filter limits repo set by glob`; `--filter applies to bare commands and requires a pattern`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-010 — Whole-repository filters

`--filter` MUST select logical repositories before checkout expansion. A matching repository MUST retain its primary checkout and, when `--all-worktrees` is present, all active linked worktrees.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--filter selects whole repos before optional worktree expansion`.

_Evidence:_ The named Bats check implements this requirement and passes in the repository CI gate.

## Dispatch-set command execution

### MGIT-WS-011 — Metadata closure

Outside Agora selection, mgit MUST add repositories reached through repository-kind `.mgit.toml` cross-repository symlink metadata, transitively and without duplicate dispatch targets.

_Conformance:_ conforming

_Verify:_ `bin/mgit` — metadata queue and `parse_mgit`; `bats tests/mgit.bats` — `a cross-repo symlink is recorded as a TOML entry`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-012 — Checkout dispatch

For repository listing, ordinary commands, and `sync`, mgit MUST dispatch only to each selected repository's primary checkout by default: the repository root for a standard repository and the required `main/` checkout for a nested repository. With `-W` or `--all-worktrees`, mgit MUST instead include every active worktree while excluding a nested repository's bare store. Bare repositories MUST remain unchanged. The option MUST NOT alter `structure` or `worktree` management behavior.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `normal commands use primary checkouts unless all worktrees are requested`.

_Evidence:_ The named Bats check implements this requirement and passes in the repository CI gate.

### MGIT-WS-013 — Default Git dispatch

For a non-reserved command, mgit MUST run `git` with supplied command and arguments in each selected checkout while preserving ordinary Git command options.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `ordinary Git command options remain pass-through`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-014 — Bare command dispatch

With `--bare`, mgit MUST run supplied command directly in each selected checkout instead of prefixing it with `git`.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--filter applies to bare commands and requires a pattern`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

## Configuration contract

### MGIT-WS-015 — Discriminated configuration

Every canonical `.mgit.toml` document MUST declare `schema = 1` and exactly one supported top-level kind, `workspace` or `repository`, and mgit MUST reject fields or tables belonging to other kind.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `discriminated manifests reject mixed document kinds`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-016 — ~~Explicit configuration migration~~ (deprecated)

### MGIT-WS-017 — ~~Configuration conflict refusal~~ (deprecated)

## Repository synchronization

### MGIT-WS-018 — Repository-set synchronization

`mgit sync` MUST skip and show dirty worktrees, fast-forward pull clean tracking branches, push commits ahead of upstream, name repositories changed or exceptional, and collapse already-current repositories into one count.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `sync rolls up current repositories and shows dirty worktrees`; `sync pulls incoming commits and pushes outgoing commits`; `sync reports no-upstream bare and divergent repositories`; `sync honors repository filters`.

_Evidence:_ The named Bats checks cover clean, dirty, incoming, outgoing, no-upstream, bare, divergent, and filtered repository states.
