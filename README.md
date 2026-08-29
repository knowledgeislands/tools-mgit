# mgit

Run commands across many Git repositories at once.

`mgit` applies a Git subcommand or another command to every repository in a selected set, printing each repository name before its output.

## Table of Contents

- [Background](#background)
- [Install](#install)
- [Usage](#usage)
- [Documentation](#documentation)
- [Maintainer](#maintainer)
- [Contributing](#contributing)
- [License](#license)

## Background

Working with a directory full of related repositories often means repeating the same Git command or maintaining an ad hoc shell loop. `mgit` provides one predictable interface for that work while remaining a standalone Bash script with only Bash 3.2 or later and Git as runtime dependencies.

Repository sets can be discovered at runtime by walking the current directory for Git repositories or predetermined by an optional checked-in `.mgit.toml` workspace document. Configuration is useful when the set should be explicit, reproducible, or divided into named groups; it is not required for ordinary discovery.

## Install

On macOS or Linux, install the published release with Homebrew:

```sh
brew install knowledgeislands/tap/mgit
```

On any system with Bash and Git, use the release installer:

```sh
curl -fsSL https://raw.githubusercontent.com/knowledgeislands/tools-mgit/main/install.sh | bash
```

The installer writes to `~/.local/bin` by default. See the [installation guide](docs/guides/user/installation.md) for alternate directories, shell completion, local development links, and installation checks.

## Usage

Run `mgit` without a command to list the selected repositories. Pass a Git subcommand to run it across the set, or use `-B` to run another command directly:

```sh
mgit
mgit status
mgit pull --ff-only
mgit -B npm test
```

Use `mgit register` to write a schema-1 `.mgit.toml` document. It writes `kind = "workspace"` in a non-Git container or `kind = "repository"` in a repository that owns cross-repository symlink metadata.

Create and select alternative named groups without editing the document directly:

```sh
mgit group create ci
mgit group add ci tools-mgit
mgit --group ci status
```

When `ki` is installed, optional selectors can use a resolved Agora or every repository in the registered KI estate. `mgit` invokes `ki` only for these selectors and does not read KI configuration itself.

```sh
mgit --agora ki-fnd status
mgit --estate status
```

Run `mgit help`, `mgit help <command>`, or `man mgit` for the complete command reference.

## Documentation

- [User guide](docs/guides/user/README.md) — installation, command execution, repository sets, and worktrees.
- [Developer guide](docs/guides/developer/README.md) — local development and verification.
- [Changelog](CHANGELOG.md) — the curated feature baseline planned for v1.

## Maintainer

Kris Brown maintains `mgit`. Use [GitHub issues](https://github.com/knowledgeislands/tools-mgit/issues) for questions and maintenance requests.

## Contributing

Issues and pull requests are welcome. Follow the [developer guide](docs/guides/developer/README.md), use Conventional Commit messages, and run its complete verification gate before submitting a change.

## License

[MIT](LICENSE) © 2026 Kris Brown.
