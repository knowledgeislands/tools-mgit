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

Pass an exact release with `bash -s -- vX.Y.Z`; omitting it installs the latest release. The installer writes to `~/.local/bin` by default. See the [mgit tool page](https://knowledgeislands.info/projects/mgit/) and [installation guide](docs/guides/user/installation.md) for alternate directories, shell completion, local development links, and installation checks.

## Usage

Run `mgit` without a command to list the selected repositories. Pass a Git subcommand to run it across the set, or use `-R` to run another command directly. `-G` passes a command to Git even when mgit owns its name, as in `mgit -G worktree list`; `-G` is a temporary name until `-B` returns as the bypass-to-Git flag:

```sh
mgit
mgit status
mgit sync
mgit sync -i
mgit overview
mgit -R npm test
mgit -v pull
mgit doctor
mgit diag
mgit help repair
```

`mgit sync` fetches every clean tracking branch in parallel, then fast-forwards branches that are only behind and pushes branches that are only ahead, one checkout at a time. Diverged, dirty, detached and untracked branches are named with a warning and left untouched; nothing is merged or rebased. Repositories already current are rolled into one count; pass `-v` for progress on every checkout. Use `mgit sync -i` to confirm each pull and push separately; an empty answer skips that action.

Ordinary commands run in up to eight checkouts at once (`-j/--jobs N` sets the limit). Only checkouts with output or a failure are shown, in selection order, followed by one line counting the quiet ones and naming each failure. A `git status`, or a Git alias for one such as `st = status -sb`, that is clean and level with its upstream counts as quiet. Pass `-v/--verbose` for one checkout at a time with all output streamed, as for an interactive command, or `--json` for one document.

`mgit overview` shows, read-only, what is outstanding across the set: dirty files, ahead and behind counts, stashes, worktrees needing attention, and obsolete branches by the Git clean-down criteria. It names only checkouts that need attention, and `--json` prints one document for tools.

Use `mgit register` to write an unversioned `.mgit.toml` document. It writes `kind = "workspace"` in a non-Git container or `kind = "repository"` in a repository that owns cross-repository symlink metadata.

Use `mgit register --dry-run` to preview manifest changes. `mgit repair` previews recognised configuration repair and missing repository clones by default; `mgit repair --apply` performs them after validation. Inapplicable global selectors fail with a usage error before a management command runs.

Existing `schema = 1` manifests remain readable. `mgit repair` can remove the recognised obsolete marker as part of its explicit apply path; alternative groups need a manual decision and are refused. `mgit doctor` evaluates Git and the current manifest without writes, with a verdict and pass/warn/fail/skipped counts; an absent optional manifest is healthy. Both `doctor` and `diag` identify the tool, version, installation mode, host platform and architecture, executing Bash runtime, and configuration state. `mgit diag` omits local paths and configuration error details unless `--full` is explicit. Health does not assess package updates or repository synchronization.

When `ki` is installed, optional selectors can use a territory handle, every repository in the registered KI estate, or the territory Capitals (`--principals`, in KI's order: Knowledge Islands Principal first, then the rest alphabetically). A workspace manifest stores `locations`, defaulting to `local`; `mgit register add` and `mgit register rm` change that list and refresh its generated members. A repository outside the workspace, such as `../../.local/share/chezmoi`, becomes an ordinary `[members."PATH"]` entry with `kind`, `type` and `source`, and is dispatched once however many workspaces reach it. A plain `mgit register` refreshes the saved locations later. Ordinary commands read the generated entries without invoking `ki`.

```sh
mgit --territory knowledge-islands status
mgit --estate status
mgit --principals status
mgit register add --territory short --repo ../shared-tools
mgit -t knowledge-islands -f tools- -f kit- status
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

Territory, estate and principals selectors are exclusive and use `ki territory roots --null --territory HANDLE`, `--estate` or `--principals`, passing repeated filters to KI before physical-root checks. Filters match nonempty, literal, case-sensitive directory-basename prefixes with OR semantics, before linked-worktree expansion. Default workspace snapshots use the same prefixes offline. Selected missing roots, missing registration metadata, ambiguous identities, zero matches and incomplete producer output stop dispatch.

Old `-a/--agora`, `agora:` locations and Agora snapshot schema are rejected without aliases or automatic migration. Back up the manifest, explicitly replace old locations with verified `territory:HANDLE` locations and review the snapshot changes before running `mgit register --dry-run`; see [saved-location migration](docs/guides/user/repository-sets.md#migrate-agora-locations). No user state is deleted by the cut-over.
