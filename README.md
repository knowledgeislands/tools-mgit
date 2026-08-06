# mgit

Run commands across many Git repositories and worktrees at once. `mgit status`, `mgit pull`, `mgit -B npm test` — each runs in every checkout in the set, with the repo name printed before its output.

The set of repositories is **determined at runtime** by walking the directory tree for `.git`, or **predetermined** by an optional checked-in `.mgit-workspace.toml` manifest. Workspace manifests are never required — reach for them when you want the set to be explicit, reproducible, deterministic, or divided into groups.

`mgit register` generates workspace manifests for non-Git containers. Repository leaf directories use `.mgit-config.toml` only for cross-repository symlink metadata. Use `mgit group create <group-name>` and `mgit group add <group-name> <member-name>` to make an alternative named repository set without editing the manifest directly.

## Get started

Install `mgit`, change to a workspace directory, then list its repositories or run a Git command:

```sh
mgit
mgit status
```

The [guides](docs/guides/README.md) cover installation, command execution, repository-set manifests, worktrees, and local development. For exact command syntax, run `mgit help`, `mgit help <command>`, or read the installed `mgit(1)` manual.

## License

[MIT](LICENSE) © 2026 Kris Brown.
