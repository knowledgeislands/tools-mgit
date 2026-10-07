# Workspace discovery and dispatch — MGIT-WS

This as-built area specifies how [mgit specifications](index.md) represent repository sets, select repositories, and run ordinary commands across resulting checkouts. It excludes repository-structure conversion and worktree mutation.

## Repository-set sources

### MGIT-WS-001 — Direct workspace selection

When current directory contains a workspace-kind `.mgit.toml` manifest and manifest use is enabled, mgit MUST select its declared direct members. It MUST continue to read existing schema-1 manifests using their configured default group.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `register migrates a legacy structural group to direct members`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-002 — Recursive workspace expansion

When a selected workspace member is another workspace, mgit MUST recursively use that child's direct members. Existing schema-1 child workspaces use their configured default group.

_Conformance:_ conforming

_Verify:_ `bin/mgit` — `select_workspace`; `bats tests/mgit.bats` — `register writes unversioned group-free workspaces in physical postorder`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-003 — Manifest safety validation

mgit MUST reject malformed, duplicate, unsafe, missing, or cyclic workspace members rather than dispatching against a partial workspace selection.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `workspace selection rejects malformed, duplicate, and unsafe paths`; `workspace selection rejects mixed formats and unsafe workspace cycles`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-004 — Discovery fallback

When no current-directory workspace-kind manifest is present, or with `--ignore`, mgit MUST discover repositories below current directory, keep current repository when applicable, and omit repositories nested inside another discovered repository.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `bare mgit lists the discovered repos`; `--ignore bypasses workspace selection for discovery`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-005 — Discovery traversal mode

mgit MUST use physical directory traversal by default and MAY follow symlinked container directories only when `--follow-symlinks` is selected.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--physical and --follow-symlinks control container traversal`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-006 — Territory repository set

With `-t/--territory HANDLE` or `--estate`, mgit MUST call `ki territory roots --null --territory HANDLE` or `ki territory roots --null --estate`, passing every repeated `--filter PREFIX` to KI. It MUST buffer the entire stream, require successful producer completion and complete NUL framing, validate absolute existing unique Git roots, and stop before dispatch on any error. It MUST NOT follow repository symlink metadata. Missing registration metadata, ambiguous identities or handles, selected missing roots and zero matches MUST fail; excluded unavailable registered roots MUST NOT block an otherwise valid selection.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--territory selects only NUL-delimited roots from ki`; `--territory preserves its exact roots instead of following symlink metadata`; `--territory stops before a command when ki cannot resolve roots`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

## Repository narrowing

### MGIT-WS-007 — ~~Alternative group membership~~ (deprecated)

### MGIT-WS-008 — ~~Named-group management~~ (deprecated)

### MGIT-WS-009 — Filter composition

`-f/--filter` MUST accept nonempty literal case-sensitive directory-basename prefixes, repeatable with OR semantics. Default discovery and offline snapshots MUST use the same basename predicate locally, before worktree expansion. Explicit KI scopes MUST pass filters to the producer before physical-root validation. Empty prefixes and zero matches MUST fail before dispatch; no glob option or alias exists.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--filter limits the repo set by literal basename prefixes`; `--filter applies to bare commands and requires a pattern`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-010 — Whole-repository filters

`--filter` MUST select logical repositories before checkout expansion. A matching repository MUST retain its primary checkout and, when `--all-worktrees` is present, all active linked worktrees.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--filter selects whole repos before optional worktree expansion`.

_Evidence:_ The named Bats check implements this requirement and passes in the repository CI gate.

## Dispatch-set command execution

### MGIT-WS-011 — Metadata closure

Outside explicit KI selection, mgit MUST add repositories reached through repository-kind `.mgit.toml` cross-repository symlink metadata, transitively and without duplicate dispatch targets.

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

New `.mgit.toml` documents MUST omit a schema field and declare exactly one supported top-level kind, `workspace` or `repository`. Workspace members MUST use one direct `members` map. mgit MUST also read existing `schema = 1` grouped workspace and repository documents and MUST reject mixed document shapes and fields or tables belonging to the other kind. `repair` MUST preview the exact config change and missing clones without writing; `--apply` MUST revalidate and write only a known repository shape or a workspace with only the structural default group, then clone missing declared repositories. Alternative groups MUST be refused.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `discriminated manifests reject mixed document kinds`; `register migrates a legacy structural group to direct members`; `register refuses to discard legacy alternative groups`; both config-repair tests under `repair`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-016 — ~~Explicit configuration migration~~ (deprecated)

### MGIT-WS-017 — ~~Configuration conflict refusal~~ (deprecated)

## Repository synchronization

### MGIT-WS-018 — Repository-set synchronization

`mgit sync` MUST skip and show dirty worktrees, fast-forward pull clean tracking branches, push commits ahead of upstream, name repositories changed or exceptional, and collapse already-current repositories into one count.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `sync rolls up current repositories and shows dirty worktrees`; `sync pulls incoming commits and pushes outgoing commits`; `sync reports no-upstream bare and divergent repositories`; `sync honors repository filters`.

_Evidence:_ The named Bats checks cover clean, dirty, incoming, outgoing, no-upstream, bare, divergent, and filtered repository states.

## Fan-out result

### MGIT-WS-019 — Aggregate command failure

Ordinary Git and `-B` dispatch MUST attempt every selected checkout in order and return status `1` when any child command fails, even when the final child succeeds. It MUST return `0` only when every child succeeds.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `fan-out reports an early failure after a successful final checkout`.

_Evidence:_ The named Bats case exercises both dispatch families with an early failure and successful final checkout.

### MGIT-WS-020 — Checkout output identity

Ordinary command headers and `sync` progress and outcomes MUST use the selected checkout label, including external worktrees, while Git executes at the checkout path. Captured standard output MUST contain no ANSI styling; a non-empty `NO_COLOR` MUST disable styling on a terminal.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `captured command output has no color and sync uses checkout labels`.

_Evidence:_ The named Bats case covers standard, nested, and external worktree output in a captured stream.

### MGIT-WS-021 — Management previews

`register --dry-run` MUST report proposed manifest writes and removals without changing local manifests or Chezmoi source state, including with location additions and removals. `repair` MUST preview recognised config repairs and missing clone targets without changing them. Both commands MUST retain preflight validation; `repair` may mutate the selected workspace only with `--apply`.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `register dry-run previews add and rm without changing manifests or Chezmoi`; `register dry-run previews repository manifest removal without deleting it`; `repair previews missing clone targets without creating them`.

_Evidence:_ The named Bats cases cover preview output, unchanged state, and default execution.

### MGIT-WS-022 — Global selector applicability

mgit MUST reject a global selector that the selected command would ignore with a namespaced status-`2` usage error before repository discovery or mutation. Listing accepts discovery, territory or estate, filtering, and all-worktrees selectors. Ordinary pass-through additionally accepts bare execution. `sync` accepts listing selectors. `structure` and `worktree` accept discovery and filtering selectors. `register` accepts only territory as a saved-location shorthand; `repair` and `completion` accept no global selector. Help and version MUST remain available with selectors.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `inapplicable global selectors fail before management commands change state`; `command-specific selectors reject ignored combinations`; `help and version remain available with selectors`.

_Evidence:_ The selector matrix covers status, namespace, and no-side-effect behavior for the command families.

### MGIT-WS-023 — Saved territory snapshots and hard cut-over

Saved `territory:HANDLE` locations MUST resolve current membership only during explicit `register` add, rm or refresh. Ordinary generated snapshots MUST remain offline without automatic refresh. Failed producer resolution or validation MUST leave the manifest byte-identical. Old Agora flags, `agora:` locations, `agora` fields and Agora member tables MUST fail with actionable, explicit migration guidance, including old schema-1 Agora snapshots; no aliases or historical-name reinterpretation are permitted. Migration guidance MUST preview the replacement membership and preserve user state. Territory, estate and explicit repository scopes MUST be exclusive outside register's saved-location editing grammar.

_Conformance:_ conforming

_Verify:_ `MGIT_KI_PRODUCER=/absolute/path/to/committed/ki bats tests/territory-producer.bats tests/territory-protocol.bats`.

_Evidence:_ Real executable fixtures separate registry keys, the Capital key, handle and directory basenames, and prove literal filters, failure atomicity, spaces/newlines, worktree expansion, saved refresh and offline operations.
