# Changelog

All notable changes to `mgit` are documented here as a consolidated Pre-1.0 baseline. It is updated as the tool evolves; tags, GitHub releases and commit history retain the exact 0.x snapshots.

## Pre-1.0 baseline

This baseline describes the `v0.17.0` release. Separate 0.x release entries are not maintained here.

### Command surface

#### General

- `mgit`
- `mgit --help`
- `mgit --version`
- `mgit help [command]`
- `mgit diag [--full]`
- `mgit doctor`

#### Repository-set selection

- `mgit --filter <prefix>`
- `mgit --all-worktrees`
- `mgit --physical`
- `mgit --follow-symlinks`
- `mgit --ignore`
- `mgit --territory <handle>`
- `mgit --estate`
- `mgit --principals`
- `mgit --git <git-command>`
- `mgit --raw <command>`
- `mgit --bare <command>` (deprecated alias for `--raw`)
- `mgit --jobs <n> <command>`
- `mgit --verbose <command>`
- `mgit --json <command>`

#### Workspace management

- `mgit register [add|rm] [--territory <handle>] [--repo <path>] [--dry-run]`
- `mgit repair [--apply]`

#### Repository management

- `mgit sync`
- `mgit overview [--json] [-v|--verbose] [--stale-days <days>]`
- `mgit structure standard [--dry-run]`
- `mgit structure nested [--dry-run]`
- `mgit worktree list`
- `mgit worktree status`
- `mgit worktree add <branch>`
- `mgit worktree remove <path> [--force]`

#### Shell integration

- `mgit completion bash`
- `mgit completion zsh`

### Behaviours

- Runtime discovery walks Git repositories below current directory, with physical or symlink-following traversal and optional literal case-sensitive directory-basename prefix filters.
- Unversioned `.mgit.toml` documents use explicit `workspace` or `repository` kind for repository-set membership and cross-repository symlink metadata.
- `mgit repair` previews a validated legacy-schema diff and missing clones; `--apply` performs the repairs after preflight. Alternative group selections are never discarded automatically.
- `mgit register` refreshes repository entries from saved local, territory-handle, and explicit repository locations; add/rm change locations, while registration synchronizes Chezmoi-managed state.
- Repositories outside a workspace are ordinary typed `[members."../PATH"]` entries generated from saved locations, deduplicated by physical path across the recursive set and never cloned by `repair`; one that resolves back inside its own workspace is rejected, and `register` (and `--dry-run`) names each hand-written external member it drops. Legacy `[registered.members]` tables remain readable with one deprecation warning per manifest until `mgit register` rewrites them.
- Ordinary commands run in a bounded parallel pool (`--jobs`, default 8) with a terminal-only progress line, then print in selection order only checkouts with output or a failure and one closing count naming each failure; a clean, level `git status` is quiet. Workers cannot prompt, read the terminal or open an editor. `--verbose` restores serial streaming and `--json` prints one document.
- `mgit overview` reads local Git state only and names checkouts needing attention: changes, a detached HEAD, a missing or gone upstream, ahead or behind, stashes, prunable or detached worktrees, and obsolete branches by the Git clean-down criteria (merged, patch-equivalent, gone upstream, stale), with `--verbose` and a single-document `--json`.
- Workspace selection recursively expands child workspaces, while repository metadata adds linked repositories transitively without duplicate dispatch.
- Territory, estate and principals selectors buffer exact NUL-delimited roots from `ki territory roots --null`, keeping KI's order, passing repeated nonempty literal prefixes to KI before physical-root validation; failures never dispatch a partial set.
- Selected standard and nested repositories target only their primary checkout by default; `--all-worktrees` expands them to every active checkout.
- `mgit repair --apply` recreates missing standard, nested, and bare repositories from workspace member metadata without replacing existing paths.
- `register --dry-run` previews manifest writes and removals without changing local or Chezmoi state; `repair` previews config changes and missing clones by default.
- `mgit doctor` evaluates Git and manifest readiness without mutation, reports its check scope, verdict and pass/warn/fail/skipped counts, and does not assess package updates or repository synchronization. An absent optional manifest is healthy.
- `doctor` and `diag` share tool/version, proven local/release/unknown installation mode, host platform/architecture, executing Bash runtime and configuration-state context. `diag` keeps paths and configuration errors behind explicit `--full` output.
- Repository structure and worktree commands operate consistently across standard and nested layouts.
- `mgit sync` skips dirty worktrees, fast-forward pulls and pushes clean tracking branches, reports changed or exceptional repositories, and rolls already-current repositories into one count.
- Owned syntax reports namespaced usage errors, while ordinary Git options and command arguments pass through unchanged.
- Global selectors that a selected command would ignore fail with a namespaced usage error before management work begins; help and version remain available.
- `-G/--git` sends a command to Git even when mgit owns its name; `-R/--raw` runs a command directly, and `-B/--bare` remains as a deprecated alias that warns on standard error.
- Ordinary Git and `-R` fan-out attempt every selected checkout and return status `1` if any child command fails.
- Command headers and `sync` use checkout labels consistently; ANSI styling appears only on a terminal unless `NO_COLOR` is set.
- Old Agora flags, saved `agora:` locations and Agora schema are rejected with explicit migration guidance; no aliases, glob filters or automatic state migration remain.

### Distribution baseline

- `install.sh`
- `mgit(1)`
- `brew install knowledgeislands/tap/mgit`
- Stable website routes at `/projects/mgit/` and `/install/mgit`, with exact positional `vX.Y.Z` installer pinning and `MGIT_VERSION` retained as an alias.
- Bash and Zsh completion definitions
