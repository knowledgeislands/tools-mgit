# mgit user guide

`mgit` runs Git commands, or an arbitrary command with `-B`, across a set of repositories and their active worktrees.

## Guides

- [Install and configure your shell](installation.md) covers Homebrew, the installer, requirements, and completion.
- [Run commands across repositories](running-commands.md) covers discovery, commands, filters, and options.
- [Define a repository set](repository-sets.md) covers `.mgit.toml`, groups, `register`, and `repair`.
- [Manage worktrees](worktrees.md) covers standard and nested repository structures, migration, and linked worktrees.

## Quick start

Install `mgit`, change to a directory containing Git repositories, then inspect the set before running a command:

```sh
mgit
mgit status
```

By default, `mgit` discovers repository roots beneath the current directory. Use `mgit register` when the set should be explicit, reproducible, deterministic, or divided into groups.
