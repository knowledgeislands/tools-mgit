# Run commands across repositories

From a workspace directory, `mgit` runs the requested command in every active checkout. With no command, it lists the repositories that would be used. If the current directory contains `.mgit-workspace.toml`, it uses that workspace's selected group; otherwise it discovers Git repositories beneath the current directory.

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

Workspace members are selected before filters are applied. The filter then narrows normal commands, repository listing, `structure`, and `worktree` commands. It does not change what `register` or `repair` reads.

Use `-g` or `--group` to choose a named group from the workspace in the current directory instead of its configured default. Child workspaces always use their own configured defaults.

```sh
mgit --group ci status
mgit -g ci -B bun run test
```

## Select an Agora

When `ki` is installed, use `--agora` to run an ordinary Git or bare command across the local roots resolved for a named Agora or `estate`:

```sh
mgit --agora ki-fnd status
mgit --agora estate -B git fetch --all --prune
```

MGit invokes `ki agora roots --null <name>` once, and uses only the returned repository roots. It does not read KI declarations, the local registry, or peer repositories. `--filter` can narrow the resolved set, but `--agora` cannot be combined with discovery or workspace selectors (`--physical`, `--follow-symlinks`, `--ignore`, or `--group`) or with MGit management commands.

## Discovery options

- `-P` or `--physical` does not follow symlinked container directories. This is the default.
- `-L` or `--follow-symlinks` follows symlinked container directories but never symlinked repositories.
- `-I` or `--ignore` ignores `.mgit-workspace.toml` manifests and discovers repositories by walking the tree.

See [define a repository set](repository-sets.md) when discovery is not sufficient, or [manage worktrees](worktrees.md) for the structure and worktree commands.
