# mgit

Run commands across many Git repositories and worktrees at once. `mgit status`, `mgit pull`, `mgit -B npm test` — each runs in every checkout in the set, with the repo name printed before its output.

The set of repositories is **determined at runtime** by walking the directory tree for `.git`, or **predetermined** by an optional checked-in `.mgit-config.toml` manifest. The manifest is never required — reach for it when you want the set to be explicit and reproducible, or to span repos that live outside the current tree.

## Get started

Install `mgit`, change to a workspace directory, then list its repositories or run a Git command:

```sh
mgit
mgit status
```

The [user guide](docs/user-guide/README.md) covers installation, command execution, repository-set manifests, and worktrees. The [developer guide](docs/developer/README.md) covers working from a local checkout. For exact command syntax, run `mgit --help` or read the installed `mgit(1)` manual.

## License

[MIT](LICENSE) © 2026 Kris Brown.
