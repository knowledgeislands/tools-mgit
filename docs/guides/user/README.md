# mgit user guide

Use `mgit` to run Git commands, or an arbitrary command with `-B`, across repositories and their active worktrees. Choose an installation route, define or discover your repository set, and inspect it before running commands.

## Guides

- [Install and configure your shell](installation.md) covers Homebrew, the installer, requirements, and completion.
- [Run commands across repositories](running-commands.md) covers discovery, commands, filters, and options.
- [Define a repository set](repository-sets.md) covers `.mgit.toml`, `register`, and `repair`.
- [Manage worktrees](worktrees.md) covers standard and nested repository structures, structure conversion, and linked worktrees.

## Quick start

Install `mgit`, change to a directory containing Git repositories, then inspect the set before running a command:

```sh
mgit
mgit status
mgit sync
```

By default, `mgit` discovers repository roots beneath the current directory. Use `mgit register` when the set should be explicit, reproducible, deterministic, or stable across runs.
