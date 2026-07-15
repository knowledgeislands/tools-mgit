# mgit

Run commands across many Git repositories and worktrees at once. `mgit status`, `mgit pull`, `mgit -B npm test` — each runs in every checkout in the set, with the repo name printed before its output.

The set of repositories is **determined at runtime** by walking the directory tree for `.git`, or **predetermined** by an optional checked-in `.mgitconfig` manifest. The manifest is never required — reach for it when you want the set to be explicit and reproducible, or to span repos that live outside the current tree.

## Install

**Homebrew** (macOS / Linux):

```sh
brew install knowledgeislands/tap/mgit
```

**curl** (any system with bash + git):

```sh
curl -fsSL https://raw.githubusercontent.com/knowledgeislands/tools-mgit/main/install.sh | bash
```

The installer drops `mgit` into `~/.local/bin` by default; set `MGIT_INSTALL_DIR` to change that, or `MGIT_VERSION` to pin a tag.

Requirements: `bash` (3.2+, the macOS system bash is fine) and `git`.

## Usage

```text
mgit [options] [command]      run `git <command>` in every repo
mgit [options] -B [command]   run <command> bare (no leading `git`)
mgit [options]                list the repos that would be operated on
mgit register                 generate .mgitconfig manifests for a tree
mgit worktree <command>       inspect or manage worktrees for the tree
```

Examples:

```sh
mgit status                   # git status in each repo
mgit pull --ff-only           # fast-forward every repo
mgit -B 'bun install'         # run a non-git command in each repo
mgit                          # just list the discovered repos
```

### Options

| Option                    | Effect                                                          |
| ------------------------- | --------------------------------------------------------------- |
| `-P`, `--physical`        | Don't follow symlinked container dirs (default).                |
| `-L`, `--follow-symlinks` | Follow symlinked container dirs (never symlinked repos).        |
| `-B`, `--bare`            | Run the command bare, without prefixing it with `git`.          |
| `-I`, `--ignore`          | Ignore `.mgitconfig` files; discover repos by walking the tree. |
| `-h`, `--help`            | Show usage.                                                     |
| `-V`, `--version`         | Print the version.                                              |

## Worktrees

`mgit` distinguishes a working tree from its shared Git store. A normal checkout has a `.git` directory; a linked worktree has a `.git` file; both are working trees and are discovered by `mgit`. Bare `*.git` stores are also discovered, and can be included explicitly in a `.mgitconfig` manifest.

Existing commands keep their meaning: `mgit status` runs in every discovered working tree, while a bare store receives the Git command directly. `mgit worktree list` de-duplicates linked checkouts by their common Git directory, so each shared repository is listed once.

```bash
mgit worktree list            # paths, branches, and state grouped by common Git store
mgit worktree status          # clean/dirty status for every working tree
```

Create a named worktree from inside one of its repositories:

```bash
cd ~/workspaces/kis/knowledgeislands/tools-mgit
mgit worktree add codex       # ../tools-mgit-codex on branch worktree/codex
mgit worktree add fix main    # create worktree/fix from main
```

The default sibling location preserves the current layout. To adopt a grouped workspace layout without migrating any existing repository, set `MGIT_WORKTREE_ROOT`; the worktree is created at `<root>/<repository-name>/<name>`.

```bash
export MGIT_WORKTREE_ROOT="$HOME/workspaces/kis"
cd ~/workspaces/kis/knowledgeislands/tools-mgit
mgit worktree add review      # ~/workspaces/kis/tools-mgit/review
```

`mgit worktree add` only creates a new `worktree/<name>` branch. It refuses an existing destination or branch. `mgit worktree remove` operates only on a linked worktree of the current repository and needs explicit confirmation. Git still rejects a dirty worktree unless `--force` is also explicit.

```bash
mgit worktree remove ../tools-mgit-codex --yes
mgit worktree remove ../tools-mgit-codex --yes --force
```

Missing worktrees are shown as `prunable` by `list` and `missing (prunable)` by `status`; `mgit` never prunes their metadata automatically.

See [the worktree workflow and staged migration guide](docs/worktrees.md) for a recommended rollout from existing repositories under `~/workspaces/kis`.

## The `.mgitconfig` model

Without a manifest, `mgit` finds repos by walking the current tree for `.git` (dropping any repo nested inside another). A `.mgitconfig` makes the set explicit and lets it span repos that live outside the tree.

A **leaf dir** holds a `.git` (it is a repo); the **container dirs** are the directories between your cwd and the leaf dirs. A `.mgitconfig` holds two kinds of line:

```text
<path>                a member — a child container dir, or a child repo
                      (relative to the file's dir, or ~-prefixed / absolute)
<link>  ->  <target>  a symlink this repo owns, pointing into another repo
```

At runtime `mgit` walks that hierarchy: container members are recursed into, repo members are operated on, and the repo containing each symlink target is pulled in too (transitively, with cycle guards). Git already tracks the symlinks themselves, so they return on clone — `mgit` only records where they point.

### `mgit register`

`mgit register` writes a `.mgitconfig` into every container dir (listing its child containers and repos) and into every leaf dir that owns cross-repo symlinks (listing them). It stops at leaf dirs — it never descends into a repo — and always scans fresh, overwriting generated manifests. Run it once to snapshot a workspace, and again whenever the layout changes.

## Development

Two tools are needed to lint and test locally — the same ones CI runs:

```sh
brew install shellcheck bats-core
```

Then run the checks CI runs ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)):

```sh
shellcheck bin/mgit install.sh   # lint
bats tests/                      # test
```

## License

[MIT](LICENSE) © 2026 Kris Brown.
