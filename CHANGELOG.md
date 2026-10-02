# Changelog

All notable changes to `mgit` are documented here as a consolidated Pre-1.0 baseline. It is updated as the tool evolves; tags, GitHub releases and commit history retain the exact 0.x snapshots.

## Pre-1.0 baseline

Separate 0.x release entries are not maintained here.

### Command surface

#### General

- `mgit`
- `mgit --help`
- `mgit --version`
- `mgit help [command]`

#### Repository-set selection

- `mgit --filter <glob>`
- `mgit --all-worktrees`
- `mgit --physical`
- `mgit --follow-symlinks`
- `mgit --ignore`
- `mgit --agora <name>`
- `mgit --estate`
- `mgit --bare <command>`

#### Workspace management

- `mgit register [add|rm] [--agora <name>] [--repo <path>] [--dry-run]`
- `mgit repair [--dry-run]`

#### Repository management

- `mgit sync`
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

- Runtime discovery walks Git repositories below current directory, with physical or symlink-following traversal and optional whole-repository glob filters.
- Unversioned `.mgit.toml` documents use explicit `workspace` or `repository` kind for repository-set membership and cross-repository symlink metadata.
- `mgit register` refreshes repository entries from saved local, Agora, and explicit repository locations; add/rm change locations, while registration synchronizes Chezmoi-managed state.
- Workspace selection recursively expands child workspaces, while repository metadata adds linked repositories transitively without duplicate dispatch.
- Agora and estate selectors use exact repository roots resolved by `ki` without reading KI configuration directly.
- Selected standard and nested repositories target only their primary checkout by default; `--all-worktrees` expands them to every active checkout.
- `mgit repair` recreates missing standard, nested, and bare repositories from workspace member metadata without replacing existing paths.
- `register --dry-run` previews manifest writes and removals without changing local or Chezmoi state; `repair --dry-run` previews missing clones. Both retain automatic execution by default.
- Repository structure and worktree commands operate consistently across standard and nested layouts.
- `mgit sync` skips dirty worktrees, fast-forward pulls and pushes clean tracking branches, reports changed or exceptional repositories, and rolls already-current repositories into one count.
- Owned syntax reports namespaced usage errors, while ordinary Git options and command arguments pass through unchanged.
- Ordinary Git and `-B` fan-out attempt every selected checkout and return status `1` if any child command fails.
- Command headers and `sync` use checkout labels consistently; ANSI styling appears only on a terminal unless `NO_COLOR` is set.

### Distribution baseline

- `install.sh`
- `mgit(1)`
- `brew install knowledgeislands/tap/mgit`
- Stable website routes at `/tooling/mgit/` and `/install/mgit`, with exact positional `vX.Y.Z` installer pinning and `MGIT_VERSION` retained as an alias.
- Bash and Zsh completion definitions
