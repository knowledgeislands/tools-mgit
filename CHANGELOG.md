# Changelog

All notable changes to `mgit` are documented here. This changelog records the v1 release baseline; it does not retroactively track individual 0.x releases. Tags and commit history remain the record of pre-v1 run-up.

## [1.0.0] — in progress

Pre-v1 work is summarized as one baseline. Separate 0.x release entries are not maintained.

### Shipped commands

#### General

- `mgit`
- `mgit --help`
- `mgit --version`
- `mgit help [command]`

#### Repository-set selection

- `mgit --group <name>`
- `mgit --filter <glob>`
- `mgit --physical`
- `mgit --follow-symlinks`
- `mgit --ignore`
- `mgit --agora <name>`
- `mgit --estate`
- `mgit --bare <command>`

#### Workspace management

- `mgit register`
- `mgit repair`
- `mgit group create <name>`
- `mgit group delete <name>`
- `mgit group add <name> <member>`
- `mgit group remove <name> <member>`

#### Repository management

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
- Schema-1 `.mgit.toml` documents use explicit `workspace` or `repository` kind for repository-set membership and cross-repository symlink metadata.
- `mgit register` refreshes canonical configuration, preserves named groups, and synchronizes Chezmoi-managed state.
- Workspace selection recursively expands child workspaces, while repository metadata adds linked repositories transitively without duplicate dispatch.
- Named groups provide alternative direct-member views without changing structural default group.
- Agora and estate selectors use exact repository roots resolved by `ki` without reading KI configuration directly.
- Selected standard and nested repositories expand to active worktrees before commands run.
- `mgit repair` recreates missing standard, nested, and bare repositories from structural workspace metadata without replacing existing paths.
- Repository structure and worktree commands operate consistently across standard and nested layouts.
- Owned syntax reports namespaced usage errors, while ordinary Git options and command arguments pass through unchanged.

### Distribution baseline

- `install.sh`
- `mgit(1)`
- `brew install knowledgeislands/tap/mgit`
- Bash and Zsh completion definitions
