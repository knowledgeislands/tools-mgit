# Run commands across repositories

From a workspace directory, `mgit` discovers Git repositories beneath the current directory and runs the requested command in every active checkout. With no command, it lists the repositories that would be used.

```sh
mgit
mgit status
mgit pull --ff-only
```

Prefix a command with `-B` to run it directly rather than as a Git subcommand:

```sh
mgit -B bun install
mgit -B bun run build
```

## Limit the set

Use `-f` or `--filter` to select repository paths with a shell glob. A bare pattern also matches the final path component, and repeated filters are combined as a union.

```sh
mgit -f 'mcp-*' status
mgit -f 'mcp-*' -B bun run build
```

The filter narrows normal commands, repository listing, `structure`, and `worktree` commands. It does not change what `register` or `bootstrap` reads.

## Discovery options

- `-P` or `--physical` does not follow symlinked container directories. This is the default.
- `-L` or `--follow-symlinks` follows symlinked container directories but never symlinked repositories.
- `-I` or `--ignore` ignores `.mgit-config.toml` manifests and discovers repositories by walking the tree.

See [define a repository set](repository-sets.md) when discovery is not sufficient, or [manage worktrees](worktrees.md) for the structure and worktree commands.
