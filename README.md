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

### Shell completion

`mgit` can print completion setup for Bash and Zsh. Add one of these to your shell configuration:

```bash
source <(mgit completion bash)
```

```zsh
autoload -Uz compinit && compinit
eval "$(mgit completion zsh)"
```

## Usage

```text
mgit [options] [command]      run `git <command>` in every repo
mgit [options] -B [command]   run <command> bare (no leading `git`)
mgit [options]                list the repos that would be operated on
mgit register                 generate .mgitconfig manifests for a tree
mgit structure <type>         change repositories to standard or nested structure
mgit worktree <command>       inspect or manage worktrees for the tree
mgit completion <shell>       print Bash or Zsh completion setup
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

`mgit` recognises two repository structures. A standard repository is an ordinary checkout with a `.git/` directory, optionally with sibling linked worktrees:

```text
repoB/
├── .git/
└── <files>

repoB-featureA/   # optional sibling linked worktree
```

A nested repository is an `mgit`-managed container with a colocated bare store and child checkouts:

```text
repoA/
├── .bare/      # shared Git store
├── .git        # controller file pointing to ./.bare
├── main/       # required default checkout
└── featureA/   # optional branch checkout
```

`mgit register` records each logical repository only once. At runtime, ordinary commands resolve both structures to their active checkouts: `repoA/main` and `repoA/featureA` for nested repositories; `repoB` and `repoB-featureA` for standard repositories. They never run in `.bare/` or the nested controller directory.

Change every eligible standard repository in the current set to nested structure with a mandatory preview and confirmation:

```bash
mgit structure nested --dry-run
mgit structure nested --yes
```

This requires a clean, attached checkout without existing linked worktrees. It preserves the original files as a rollback backup. Change back only when a nested repository's sole checkout is `main/`:

```bash
mgit structure standard --dry-run
mgit structure standard --yes
```

Add an existing remote branch to every standard and nested repository in the current set:

```bash
mgit worktree add featureA
```

This creates `repoA/featureA` for a nested repository and `repoB-featureA` for a standard repository. Each checkout is on local branch `featureA`, tracking `origin/featureA`. The command preflights every participating repository before changing any of them. Use `mgit worktree list` or `mgit worktree status` to inspect the full checkout set; `mgit worktree remove PATH --yes` safely removes a linked checkout and never the primary or required `main/` checkout.

See [the worktree structures guide](docs/worktrees.md) for the complete layouts and safety rules.

## The `.mgitconfig` model

Without a manifest, `mgit` finds repos by walking the current tree for `.git` (dropping any repo nested inside another). A `.mgitconfig` makes the set explicit and lets it span repos that live outside the tree.

A **leaf dir** holds a `.git` (it is a repo); the **container dirs** are the directories between your cwd and the leaf dirs. A generated `.mgitconfig` labels its members:

```text
standard <path>       conventional repository structure
nested <path>         mgit-managed nested repository structure
bare <path>           bare Git repository
dir <path>            child directory containing more members
<link>  ->  <target>  symlink this repo owns, pointing into another repository
```

The structure labels make the generated file self-describing. Git remains the runtime source of truth, so rerun `mgit register` after a structure change to refresh them. At runtime `mgit` walks that hierarchy: container members are recursed into, repo members are operated on, and the repo containing each symlink target is pulled in too (transitively, with cycle guards). Git already tracks the symlinks themselves, so they return on clone — `mgit` only records where they point. Existing untyped member lines remain valid.

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
