# mgit

Run commands across many Git repositories and worktrees at once. `mgit status`, `mgit pull`, or `mgit -B npm test` runs in every checkout in set, printing repository name before output.

Repository set is **determined at runtime** by walking directory tree for `.git`, or **predetermined** by optional checked-in `.mgit.toml` workspace document. Workspace configuration is never required — reach for it when set should be explicit, reproducible, deterministic, or divided into groups.

`mgit register` writes one schema-1 filename with an explicit role: `kind = "workspace"` in non-Git containers and `kind = "repository"` in leaves that own cross-repository symlink metadata. It also migrates unambiguous `.mgit-workspace.toml` and `.mgit-config.toml` files; mixed or conflicting state is rejected. Use `mgit group create <group-name>` and `mgit group add <group-name> <member-name>` to make alternative named repository set without editing configuration directly.

When `ki` is available, `mgit --agora <name> status` uses resolved named Agora as one exact repository set, while `mgit --estate status` selects every repository in registered KI estate. These optional selectors invoke `ki` only when requested; `mgit` never reads KI configuration itself. `--agora estate` remains equivalent spelling for `--estate`.

## Get started

Install with Homebrew:

```sh
brew install knowledgeislands/tap/mgit
```

Then run:

```sh
mgit
mgit status
```

[Guides](docs/guides/README.md) cover installation, command execution, repository-set configuration, worktrees, and local development. For exact command syntax, run `mgit help`, `mgit help <command>`, or installed `mgit(1)` manual.

## License

[MIT](LICENSE) © 2026 Kris Brown.
