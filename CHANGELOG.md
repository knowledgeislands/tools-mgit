# Changelog

All notable changes to this project are documented here.

This changelog records the V1 release baseline. It does not retroactively track individual 0.x releases; their tags and commit history remain the record of that run-up.

## [1.0.0] — in progress

Pre-V1 work is summarized as this baseline; separate 0.x release entries are not maintained.

### Shipped commands

#### General

- `mgit`
- `mgit --help`
- `mgit --version`
- `mgit [options] <git-command> [argument...]`
- `mgit --bare <command> [argument...]`

#### Workspace management

- `mgit register`
- `mgit repair`
- `mgit group create <name>`
- `mgit group delete <name>`
- `mgit group add <name> <member>`
- `mgit group remove <name> <member>`

#### Repository management

- `mgit structure nested [--dry-run]`
- `mgit structure standard [--dry-run]`
- `mgit worktree list`
- `mgit worktree status`
- `mgit worktree add <branch>`
- `mgit worktree remove <path> [--force]`

#### Shell integration

- `mgit completion <shell>`

### Behaviours

- `mgit` discovers repository roots at runtime or reads a checked-in `.mgit-workspace.toml` manifest.
- Workspace manifests define the structural `default` group, optional alternative groups, repositories, and child workspaces.
- `mgit group` creates empty alternative groups and manages only direct `default`-group members.
- `mgit register` generates structural workspace records, preserves alternative groups, and records cross-repository symlinks in leaf `.mgit-config.toml` files.
- `mgit repair` recreates missing default-group repositories from recorded clone URLs without replacing existing paths.
- `mgit structure` applies changes by default and supports `--dry-run` previews.
- `mgit worktree` manages standard and nested worktrees while protecting primary and required `main/` checkouts.
- `mgit completion <shell>` emits Bash and Zsh definitions for the command hierarchy, options, group names, and workspace members.

### Distribution baseline

- `install.sh`
- `mgit(1)`
