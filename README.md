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

Repository sets can be discovered at runtime by walking the current directory for Git repositories or predetermined by an optional checked-in `.mgit.toml` workspace document. Configuration is useful when the set should be explicit and reproducible; it is not required for ordinary discovery.

## Install

On macOS or Linux, install the published release with Homebrew:

```sh
brew install knowledgeislands/tap/mgit
```

On any system with Bash and Git, use the release installer:

```sh
curl -fsSL https://knowledgeislands.info/install/mgit | bash
```

Pass an exact release with `bash -s -- vX.Y.Z`; omitting it installs the latest release. The installer writes to `~/.local/bin` by default. See the [mgit tool page](https://knowledgeislands.info/tooling/mgit/) and [installation guide](docs/guides/user/installation.md) for alternate directories, shell completion, local development links, and installation checks.

## Usage

Run `mgit` without a command to list the selected repositories. Pass a Git subcommand to run it across the set, or use `-B` to run another command directly:

```sh
mgit
mgit status
mgit sync
mgit sync -i
mgit -B npm test
```

`mgit sync` updates clean tracking branches with fast-forward-only pulls and normal pushes. It shows progress before each pull and push, names repositories that changed or need attention, and rolls repositories already current into one count. Use `mgit sync -i` to confirm each pull and push separately; an empty answer skips that action.

Use `mgit register` to write an unversioned `.mgit.toml` document. It writes `kind = "workspace"` in a non-Git container or `kind = "repository"` in a repository that owns cross-repository symlink metadata.

Use `mgit register --dry-run` to preview manifest changes or `mgit repair --dry-run` to preview clones of missing workspace repositories. Inapplicable global selectors fail with a usage error before a management command runs.

Existing `schema = 1` manifests remain readable. Run `mgit config repair` in the manifest directory to preview removal of the obsolete marker, then `mgit config repair --apply` to make the validated change. This does not run the clone-oriented `mgit repair` command or refresh registered locations. Alternative groups need a manual decision and are refused.

When `ki` is installed, optional selectors can use a resolved Agora or every repository in the registered KI estate. A workspace manifest stores `locations`, defaulting to `local`; `mgit register add` and `mgit register rm` change that list and refresh its generated repository entries. A plain `mgit register` refreshes the saved locations later. Ordinary commands read the generated entries without invoking `ki`.

```sh
mgit --agora kis status
mgit --estate status
mgit register add --agora personal --repo ../shared-tools
mgit register rm --repo ../shared-tools
```

Run `mgit help`, `mgit help <command>`, or `man mgit` for the complete command reference.

## Documentation

- [User guide](docs/guides/user/README.md) — installation, command execution, repository sets, and worktrees.
- [Developer guide](docs/guides/developer/README.md) — local development and verification.
- [Changelog](CHANGELOG.md) — the consolidated pre-1.0 command and feature baseline.

## Maintainer

Kris Brown maintains `mgit`. The repository roadmap is the canonical maintenance queue.

## Contributing

Pull requests are welcome. Follow the [developer guide](docs/guides/developer/README.md), use Conventional Commit messages, and run its complete verification gate before submitting a change.

## License

[MIT](LICENSE) © 2026 Kris Brown.
