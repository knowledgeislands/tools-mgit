# Changelog

All notable changes to `mgit` are documented here.

This changelog records the 0.8.0 release baseline. It does not retroactively track individual earlier releases; their tags and commit history remain the record of that run-up.

## [0.8.0] — 2026-07-30

Earlier releases are summarized as this baseline; separate historical entries are not maintained here.

### Shipped commands

#### General

- `mgit`
- `mgit [options] [command ...]`
- `mgit [options] -B command [argument ...]`

#### Workspace management

- `mgit register`
- `mgit repair`

#### Repository management

- `mgit structure standard --dry-run|--yes`
- `mgit structure nested --dry-run|--yes`
- `mgit worktree list`
- `mgit worktree status`
- `mgit worktree add <branch>`
- `mgit worktree remove <path> --yes [--force]`

#### Shell integration

- `mgit completion <shell>`

### Distribution baseline

- `install.sh`
- `mgit(1)`
- Homebrew: `knowledgeislands/tap/mgit`

[0.8.0]: https://github.com/knowledgeislands/tools-mgit/releases/tag/v0.8.0
