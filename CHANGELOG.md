# Changelog

All notable changes to `mgit` are documented here as a consolidated Pre-1.0 baseline. It is updated as the tool evolves; tags, GitHub releases and commit history retain the exact 0.x snapshots.

## Unreleased

### Added

- `mgit chain` runs several Git commands in order in each checkout, split at each `--then`; a checkout stops at its first failing step while the others carry on, and one tally counts those that completed, stopped and failed to start. It takes `-j`, `-v` and `--json`. Recipes saved as `git config mgit.chain.NAME` run as `mgit chain NAME`, or as `mgit NAME` when mgit does not own the name; `-B` bypasses them.

### Changed

- `mgit sync` no longer pushes by default. It fetches and fast-forwards, and names each branch only ahead of its upstream as `ahead N, not pushed (pass --push)`, counted as skipped without failing the run; pass `mgit sync --push` to publish them. `git config mgit.syncPush false` in a repository is a hard veto that neither `--push` nor `-i` overrides, and `-i` asks about pushes only with `--push`.
- `mgit repair` now writes recognised config repairs and clones missing repositories by default. Use `--dry-run` or `-n` to preview without changing files; `--apply` is no longer accepted. Existing-path, external-member and preflight validation guards remain in place.

## Pre-1.0 baseline

This baseline describes the `v0.18.0` release. Separate 0.x release entries are not maintained here.

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
- `mgit --bypass <git-command>`
- `mgit --raw <command>`
- `mgit --learn <git-command>`
- `mgit --jobs <n> <command>`
- `mgit --verbose <command>`
- `mgit --json <command>`

#### Workspace management

- `mgit register [add|rm] [--territory <handle>] [--repo <path>] [-n|--dry-run]`
- `mgit repair [--dry-run]`

#### Repository management

- `mgit sync [-i|--interactive] [-v|--verbose]`
- `mgit overview [--json] [-v|--verbose] [--stale-days <days>]`
- `mgit structure standard [-n|--dry-run]`
- `mgit structure nested [-n|--dry-run]`
- `mgit worktree list`
- `mgit worktree status`
- `mgit worktree add <branch>`
- `mgit worktree remove <path> [-f|--force]`

#### Output learning

- `mgit learn <git-command>`
- `mgit learn --list`
- `mgit learn --forget <git-command>`

#### Shell integration

- `mgit completion bash`
- `mgit completion zsh`

### Behaviours

- Runtime discovery walks Git repositories below current directory, with physical or symlink-following traversal and optional literal case-sensitive directory-basename prefix filters.
- Unversioned `.mgit.toml` documents use explicit `workspace` or `repository` kind for repository-set membership and cross-repository symlink metadata.
- `mgit repair` performs validated legacy-schema repair and missing clones after preflight; `--dry-run` or `-n` previews them without writing. Alternative group selections are never discarded automatically.
- `mgit register` refreshes repository entries from saved local, territory-handle, and explicit repository locations; add/rm change locations, while registration synchronizes Chezmoi-managed state.
- Repositories outside a workspace are ordinary typed `[members."../PATH"]` entries generated from saved locations, deduplicated by physical path across the recursive set and never cloned by `repair`; one that resolves back inside its own workspace is rejected, and `register` (and `--dry-run`) names each hand-written external member it drops. Legacy `[registered.members]` tables remain readable with one deprecation warning per manifest until `mgit register` rewrites them.
- Ordinary commands run in a bounded parallel pool (`--jobs`, default 8) with a terminal-only progress line, then print in selection order only checkouts with output or a failure and one closing count naming each failure. Nothing is quiet by built-in rule beyond empty output: `mgit learn` learns a Git command's normal output, with each checkout's path, remote, upstream, branch and name set aside, from one checkout or more into a template under `~/.config/mgit/templates/` when every checkout, or more than half, agree and the user confirms on a terminal, and later runs count a matching checkout as quiet. Workers cannot prompt, read the terminal or open an editor. `--verbose` restores serial streaming and `--json` prints one document.
- `mgit overview` reads local Git state only and names checkouts needing attention: changes, a detached HEAD, a missing or gone upstream, ahead or behind, stashes, prunable or detached worktrees, and obsolete branches by the Git clean-down criteria (merged, patch-equivalent, gone upstream, stale), with `--verbose` and a single-document `--json`.
- Workspace selection recursively expands child workspaces, while repository metadata adds linked repositories transitively without duplicate dispatch.
- Territory, estate and principals selectors buffer exact NUL-delimited roots from `ki territory roots --null`, keeping KI's order, passing repeated nonempty literal prefixes to KI before physical-root validation; failures never dispatch a partial set.
- Selected standard and nested repositories target only their primary checkout by default; `--all-worktrees` expands them to every active checkout.
- `mgit repair` recreates missing standard, nested, and bare repositories from workspace member metadata without replacing existing paths.
- `register --dry-run` previews manifest writes and removals without changing local or Chezmoi state; `repair --dry-run` (or `-n`) previews config changes and missing clones without writing.
- `mgit doctor` evaluates Git and manifest readiness without mutation, reports its check scope, verdict and pass/warn/fail/skipped counts, and does not assess package updates or repository synchronization. An absent optional manifest is healthy.
- `doctor` and `diag` share tool/version, proven local/release/unknown installation mode, host platform/architecture, executing Bash runtime and configuration-state context. `diag` keeps paths and configuration errors behind explicit `--full` output.
- Repository structure and worktree commands operate consistently across standard and nested layouts.
- `mgit sync` fetches every remote-tracking branch, clean or dirty, in parallel through the shared runner, once per repository and remote, then fast-forwards branches only behind and pushes branches only ahead, one checkout at a time. Diverged, dirty, detached and untracked branches and failed fetches are warned about and left untouched; it never merges or rebases. A diverged branch's warning predicts, in memory with `git merge-tree`, whether merging its upstream would be clean or conflict in N files, listing the files under `-v`. It ends with one tally on standard output, `N repositories: N in sync, N pulled, N pushed, N skipped, N failed`, then one indented line per skipped or failed checkout with its reason and ahead and behind counts, marked stale after a failed fetch; skips, warnings, progress and prompts go to standard error, and `-v` adds per-checkout progress without changing the tally.
- Owned syntax reports namespaced usage errors, while ordinary Git options and command arguments pass through unchanged.
- mgit's own options follow the command-line conventions: short options group (`-vW`), a short option's value may be attached (`-j4`, `-vj4`) and a long option's value may follow `=` (`--jobs=4`), for the global options and every mgit command's own; `-n` is the short form of `--dry-run` on `register` and `structure`, and `-f` of `worktree remove --force`. Words after the command are never rewritten.
- Global selectors that a selected command would ignore fail with a namespaced usage error before management work begins; help and version remain available.
- `-B/--bypass` sends a command to Git even when mgit owns its name; `-R/--raw` runs a command directly. The temporary `-G/--git` names are usage errors that name `-B/--bypass`, and `--bare`, formerly a deprecated alias of `-R`, is a usage error that names `-R/--raw`; both run nothing.
- `--filter` has no short letter: `-f` is a usage error that names `--filter` and runs nothing, leaving `-f` free for force or file.
- Ordinary Git and `-R` fan-out attempt every selected checkout and return status `1` if any child command fails.
- Command headers and `sync` use checkout labels consistently; ANSI styling appears only on a terminal unless `NO_COLOR` is set.
- Old Agora flags, saved `agora:` locations and Agora schema are rejected with explicit migration guidance; no aliases, glob filters or automatic state migration remain.

### Distribution baseline

- `install.sh`
- `mgit(1)`
- `brew install knowledgeislands/tap/mgit`
- Stable website routes at `/projects/mgit/` and `/install/mgit`, with exact positional `vX.Y.Z` installer pinning and `MGIT_VERSION` retained as an alias.
- Bash and Zsh completion definitions
