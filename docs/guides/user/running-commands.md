# Run commands across repositories

From a workspace directory, `mgit` runs requested command in every active checkout. With no command, it lists repositories that would be used. If current directory contains workspace-kind `.mgit.toml`, it uses selected group; otherwise it discovers Git repositories beneath current directory.

```sh
mgit
mgit status
mgit sync
```

Prefix a command with `-B` to run it directly rather than as a Git subcommand:

```sh
mgit -B bun install
mgit -B bun run build
```

## Synchronise clean repositories

Run `mgit sync` to inspect and update every worktree in the selected set. A worktree with local changes prints `git status --short` output and is skipped. A clean tracking branch runs `git pull --ff-only`, then `git push` when local commits remain ahead of its upstream.

Repositories that pulled or pushed commits are named. Repositories that were already current are reported as one final count. Bare repositories, detached heads, branches without upstreams, divergence, and Git command failures are named and make the command exit with status `1` without forcing a change.

The existing selectors and filters narrow the same way as ordinary commands:

```sh
mgit --group engineering sync
mgit --filter 'tools-*' sync
mgit --agora ki-fnd sync
```

## Limit the set

Use `-f` or `--filter` to select repository paths with a shell glob. A bare pattern also matches the final path component, and repeated filters are combined as a union.

```sh
mgit -f 'mcp-*' status
mgit -f 'mcp-*' -B bun run build
```

Workspace members are selected before filters are applied. The filter then narrows normal commands, repository listing, `sync`, `structure`, and `worktree` commands. It does not change what `register` or `repair` reads.

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

`--estate` is shorthand for `--agora estate`, which resolves every repository in the registered KI estate:

```sh
mgit --estate status
```

The two selectors carry the same restrictions and cannot be combined with each other.

MGit invokes `ki agora roots --null <name>` once, and uses only the returned repository roots. It does not read KI declarations, the local registry, or peer repositories. `--filter` can narrow the resolved set, but neither selector can be combined with discovery or workspace selectors (`--physical`, `--follow-symlinks`, `--ignore`, or `--group`) or with MGit management commands.

## Discovery options

- `-P` or `--physical` does not follow symlinked container directories. This is the default.
- `-L` or `--follow-symlinks` follows symlinked container directories but never symlinked repositories.
- `-I` or `--ignore` ignores workspace selection from `.mgit.toml` and discovers repositories by walking tree; repository-kind symlink metadata still expands discovered set.

See [define a repository set](repository-sets.md) when discovery is not sufficient, or [manage worktrees](worktrees.md) for the structure and worktree commands.
