# Run commands across repositories

From a workspace directory, `mgit` runs the requested command in the primary checkout of every selected repository. With no command, it lists the checkouts that would be used. If the current directory contains a workspace-kind `.mgit.toml`, it uses the declared members; otherwise it discovers Git repositories beneath the current directory.

```sh
mgit
mgit status
mgit sync
```

Ordinary Git and `-R` commands run in every selected checkout, up to eight at a time. While they run, one progress line on a terminal shows how many have finished. When all have finished, each checkout that printed something or failed is shown in selection order with its header and output, and one line closes the run:

```text
tools-ki: git status --short
 M README.md
mgit: 54 repositories: 53 quiet, 1 with output, 0 failed
```

A checkout that exits `0` without output is quiet, and so is one whose output matches a learned template for the command (see [Learn normal output](#learn-normal-output)). With no templates, every checkout with output is shown. Pass `-v/--verbose` to see every checkout's output. The invocation exits with status `1` if any checkout command fails, and the closing line names each failed checkout with its exit status, as in `1 failed: tools-ki (exit 128)`.

Commands cannot read the terminal: standard input is empty, Git does not prompt for credentials and `GIT_EDITOR` is `false`, so a command that needs an editor or a prompt fails rather than waiting unseen. Captured output also loses Git's colour. For these commands pass `-v` or `--verbose`, which runs one checkout at a time with the terminal attached and streams every header and all output as before.

| Option | Effect |
| --- | --- |
| `-j N`, `--jobs N` | Run up to `N` checkouts at once (default 8; `-j 1` for one at a time). |
| `-v`, `--verbose` | One checkout at a time, every header and all output streamed, no closing line. |
| `--json` | One JSON document with each checkout's label, path, exit status, quiet flag, standard output and standard error, unfiltered, and the counts. |

The options go before the command, as in `mgit -j 4 fetch`. They apply to ordinary commands and to `overview`, and are a usage error elsewhere. An interrupt removes the run's temporary files.

mgit's options, and each mgit command's own options, follow the usual command-line forms: short options group, so `-vW` means `-v -W`; a short option's value may be attached, as in `-j4`; and a long option's value may follow an equals sign, as in `--jobs=4` or `--filter=mcp-`. A value letter takes the rest of its group, so `-vj4` means `-v -j 4`. Words after the command reach Git, or the command `-R` runs, unchanged, so `mgit log -n1` keeps Git's `-n`.

Command headers and `sync` progress use the same checkout labels. A linked worktree outside its repository is shown as `repository [branch]`, while Git still runs at the real checkout path. Color appears only on a terminal; captured output contains plain text. Set `NO_COLOR` to a non-empty value to disable color on a terminal.

Prefix a command with `-R` (`--raw`) to run it directly rather than as a Git subcommand. The arguments run as given, not through a shell, so use `sh -c` for pipes and redirections:

```sh
mgit -R bun install
mgit -R sh -c 'git log --oneline | head -1'
```

`--bare` has been removed: it is a usage error that names `-R/--raw`, and runs nothing.

Some names belong to mgit itself: `register`, `repair`, `doctor`, `diag`, `sync`, `overview`, `structure`, `worktree`, `chain`, `learn`, `completion` and `help`. Prefix a command with `-B` (`--bypass`) to send it to Git anyway:

```sh
mgit -B worktree list
mgit -B help -a
```

`-B` cannot be combined with `-R`. The temporary `-G` and `--git` names have been removed: they are usage errors that name `-B/--bypass`, and run nothing.

## Chain commands

`mgit chain` runs several Git commands in order in each checkout. Write the commands unquoted, separated by `--then`:

```sh
mgit chain fetch --prune --then pull --ff-only --then push
```

Every word after `chain` reaches Git unchanged except `--then`, which always separates steps, even after `--`; write a path named `--then` as `./--then`. Each checkout works through its own steps and stops at its first failing step, so a checkout whose pull failed is not pushed, while the other checkouts carry on. Checkouts run in parallel up to the `-j` limit, and the usual selection options apply. Each checkout then gets one block naming every step `ok`, `failed (exit N)` or `not run`, with that step's output, and one line closes the run:

```text
tools-ki
  1 ok: git fetch --prune
  2 failed (exit 1): git pull --ff-only
fatal: Not possible to fast-forward, aborting.
  3 not run: git push
mgit chain: 12 repositories: 11 completed, 1 stopped, 0 failed to start: tools-ki (step 2, exit 1)
```

A checkout is stopped when a later step failed after at least one completed, and failed to start when no step completed. The run exits `1` unless every checkout completed. `-v` streams each checkout's steps one checkout at a time with the terminal attached, and `--json` prints one document with each checkout's outcome and steps. Steps are Git commands only: `-R`, `--learn` and mgit's own commands cannot be chained, and learned templates do not apply.

Save a sequence you run often as a recipe in Git configuration, with the steps joined by `--then`; the value splits into words as a shell would, so quote a word that holds spaces:

```sh
git config --global mgit.chain.tidy 'fetch --prune --then pull --ff-only'
mgit chain tidy
mgit tidy
```

`mgit tidy` runs the recipe only when `tidy` is the only word and mgit does not own the name; a recipe takes precedence over a Git alias of the same name, `-B` sends the word to Git instead, and `mgit tidy --verbose` or any other added word goes to Git as before. Recipes are read from the Git configuration visible where you run mgit.

## Learn normal output

mgit has no built-in rules about which output is normal. Teach it by running a Git command with `learn` in front, or `--learn` among the options, over a set where every checkout is in its normal state:

```sh
mgit learn st
mgit --filter tools --learn status -sb
```

The command runs as usual. mgit then takes each checkout's output and replaces that checkout's own details with placeholders: `{path}` for its directory, `{remote-url}` for its remote's address, `{upstream}` for its upstream branch such as `origin/main`, `{remote}`, `{branch}` and `{repository}` for the repository's directory name, longest value first; values shorter than two characters are left alone. If every checkout then prints the same output, on both standard output and standard error, or more than half do, mgit always asks before writing it, saying how many agreed and naming any that differed, as in `mgit learn: 2 of 3 repositories agreed and 1 differed: tools-ki. Learn this output? [y/N]`; `y` writes the template and names the file, and any other answer writes nothing and exits `1`. It asks only when standard input is a terminal: a script or pipe gets the same counts and names, nothing written, a hint to run it from a terminal and exit `1`, without waiting. If any checkout failed, or no output is shared by more than half, it names the checkouts that differed from the most common output, writes nothing and exits `1`. One repository is enough to learn from, and output that is empty everywhere is already quiet, so nothing is written.

Templates live in `${XDG_CONFIG_HOME:-~/.config}/mgit/templates/`, one plain-text file per command after Git alias expansion, so `mgit st` and `mgit status -sb` share `status_-sb.template`. The file name joins the command's words with `_` and writes any other character outside letters, digits and `.,=@+-` as `%XX`. A template reads like this:

```text
# mgit output template, learned with: mgit learn st
# ...
command: status -sb
stdout: ## {branch}...{upstream}
```

Lines starting `stdout:` and `stderr:` hold the expected output, one line each after one space; `#` lines are comments, and trailing blank lines are ignored. Later runs of the same command count a checkout as quiet when it exits `0` and its normalised output matches the template exactly, so with the template above a clean `st` level with its upstream is hidden, while a checkout that is ahead, behind, dirty, detached or without an upstream is shown. A failed checkout is always shown. `-v/--verbose` and `--json` keep the raw output, and `-R/--raw` commands never use templates.

Learning runs the command for real, so learn a command that changes state, such as `pull` or `push`, only as part of a run you meant to make anyway; `mgit learn push` over a level set records Git's `Everything up-to-date`.

```sh
mgit learn --list                # each template's command and file
mgit learn --forget status -sb   # remove one template
```

`mgit learn sync` and the other mgit command names are usage errors; use `mgit -B --learn <command>` to learn the Git command of the same name. `--learn` cannot be combined with `-R`, `-v` or `--json`.

## Diagnose the current environment

Run `mgit diag` for share-safe tool/version, installation mode, host platform and architecture, executing Bash runtime, and configuration state. Both `diag` and `doctor` show this context. `local` identifies a direct or linked development checkout; `release` requires installed-package receipt evidence. An arbitrary copied executable remains `unknown` rather than guessing from its version. Host names include `macos`, `linux`, and `windows`; AMD64/x64 is reported as `x86_64` and AArch64 as `arm64`.

`mgit diag --full` adds the resolved executable, current directory, manifest path and configuration error details for private troubleshooting. Review fuller output before sharing it. Ordinary diagnostics omit paths and rejected configuration values.

Run `mgit doctor` to evaluate two read-only check units: Git availability and current manifest validity. It reports the check scope, pass/warn/fail/skipped counts and a healthy or unhealthy verdict; failures include a next action and exit with status 1. An absent optional manifest passes because filesystem discovery remains available. These checks do not synchronize repositories, assess package upgrades, or change configuration. Use `mgit diag --full` when an invalid manifest needs error detail, and `mgit repair --dry-run` to preview a recognised repair before running `mgit repair`.

## Include linked worktrees

Standard repositories use their root checkout by default; nested repositories use their required `main/` checkout. Pass `-W` or `--all-worktrees` to include every active linked worktree as well:

```sh
mgit --all-worktrees
mgit --all-worktrees status
mgit --all-worktrees sync
```

The option changes repository listing, ordinary Git or bare-command dispatch, and `sync`. It does not change `structure` or `worktree` management commands, which already operate on logical repositories or inspect worktrees explicitly.

## Synchronise clean repositories

Run `mgit sync` to inspect and update the primary checkout of every repository in the selected set. It first fetches the upstream remote of every branch that tracks a remote branch, clean or not, up to eight at once (`-j/--jobs N` sets the limit) and once per repository and remote. Then, one checkout at a time, a branch only behind its upstream is fast-forwarded and a branch only ahead is pushed. A diverged branch is named with its ahead and behind counts and left alone: sync never merges or rebases, whatever `pull.rebase` says. Its warning says whether merging its upstream `would be clean` or `would conflict in N files`, worked out in memory with `git merge-tree` without touching the checkout; `-v` lists the conflicting files. A Git older than 2.38 gives the plain warning. A checkout with local changes prints `git status --short` output and is skipped. Pass `--all-worktrees` to include linked worktrees.

Repositories that pulled or pushed commits are named on standard output as it happens; skips, warnings, failures, progress and `-i` prompts go to standard error. The run ends with one tally on standard output that accounts for every selected checkout, then one indented line for each checkout left behind, so a skip early in a long run is repeated where you will see it:

```text
mgit sync: 57 repositories: 55 in sync, 0 pulled, 1 pushed, 1 skipped, 0 failed
  ki-agentic-harness: local changes, 5 ahead, 0 behind
```

Local changes, detached heads, branches without upstreams, divergence, bare repositories and declined `-i` actions count as skipped; a failed status, fetch, comparison, pull or push counts as failed, and a dirty checkout whose fetch failed keeps both reasons. A branch with an upstream shows its ahead and behind counts, even when dirty, so unpushed commits are never left unmentioned; after a failed fetch they compare with the last fetched upstream and are marked `(stale)`. Every skip except a declined action, and every failure, makes the command exit with status `1` without forcing a change. If `-i` input ends, the tally counts the checkouts not reached. Pass `-v` or `--verbose`, globally or after `sync`, to also see numbered progress for every checkout and each pull and push as it starts; the tally is the same.

The existing selectors and filters narrow the same way as ordinary commands:

```sh
mgit --filter 'tools-' sync
mgit --filter 'tools-' sync --verbose
mgit --territory knowledge-islands sync
```

## See what is outstanding

Run `mgit overview` for a read-only view of the selected set. It reads local Git state only: nothing is fetched, and no ref, index or stash changes. Each checkout that needs attention gets one line naming its findings, followed by an indented line for each obsolete branch, and a closing line counts the rest:

```text
tools-ki: 2 modified, ahead 1, 1 stash, 2 obsolete branches
  feature/done (local): merged
  origin/automation/old (remote): stale, 95 days old, automation
mgit overview: 54 repositories: 51 clean, 3 need attention, 0 failed
```

A checkout needs attention for staged, modified, untracked or conflicted files; a detached HEAD, no upstream or a gone upstream; commits ahead or behind its last-fetched upstream; stashes; prunable or detached linked worktrees; or obsolete branches. A local branch is obsolete when it is merged into the default branch (`origin/HEAD`, else `main` or `master`), patch-equivalent to it, tracks a gone upstream, or is unmerged and idle for more than `--stale-days` days (default 30). A remote-tracking branch is obsolete when merged or stale. `automation/*`, `dependabot/*` and `renovate/*` branches follow the same rules and are marked. Branches checked out in a worktree are never obsolete.

Pass `--verbose` to name clean checkouts too, and `--json` for one JSON document with every checkout and the counts, for tools such as `ki`; the global `-v` and `--json` do the same. Checkouts are read in parallel, bounded by `--jobs`. Selectors and `--all-worktrees` apply as for listing; with `--all-worktrees`, repository-wide facts (stashes, worktrees and branches) appear once per repository. The command exits with status `1` only when a checkout cannot be read. Ahead and behind counts are as fresh as the last fetch.

## Limit the set

Use `--filter` with a nonempty literal directory-basename prefix. It has no short letter; `-f` is a usage error that names `--filter`. Matching is case-sensitive; repeated prefixes are combined with OR. Characters such as `*` and `[` are literal, not glob syntax. A prefix never matches a parent directory or a linked-worktree name. Zero matches fail before dispatch.

```sh
mgit --filter 'mcp-' status
mgit --filter 'mcp-' -R bun run build
```

Workspace members are selected before filters are applied. The filter then narrows normal commands, repository listing, `sync`, `structure`, and `worktree` commands. `register` and `repair` reject `--filter` instead of silently ignoring it.

Global discovery selectors (`--physical`, `--follow-symlinks`, and `--ignore`) apply to listing, ordinary commands, `sync`, `structure`, and `worktree`. `--all-worktrees` applies to listing, ordinary commands, and `sync`; `--bypass`, `--raw` and `--learn` apply only to ordinary command pass-through. `register` accepts global `--territory` as a saved-location shorthand; `repair`, `doctor`, and `diag` accept no global selector. Inapplicable selectors fail with a usage error before a management command runs. Help and version remain available with selectors.

`mgit sync -i` (or `--interactive`) confirms each pull and push. `mgit structure standard --dry-run` and `mgit structure nested --dry-run` preview conversions. `mgit register --dry-run` previews manifest writes and removals, including `register add` and `register rm`; `mgit repair` performs recognised config repairs and clones missing repositories; `mgit repair --dry-run`, or `-n`, previews them without changing files.

## Select a territory

When `ki` is installed, use a territory handle, the registered estate or the territory Capitals:

```sh
mgit -t knowledge-islands --filter tools- --filter kit- status
mgit --territory knowledge-islands sync
mgit --estate status
mgit --principals -R pwd
```

MGit calls `ki territory roots --null --territory HANDLE [--filter PREFIX...]`, `ki territory roots --null --estate [--filter PREFIX...]` or `ki territory roots --null --principals [--filter PREFIX...]`. MGit keeps the producer's order, so `--principals` lists Knowledge Islands Principal first and the other Capitals alphabetically by territory name; mgit does not select or order Capitals itself. Filters go to KI so an excluded unavailable root does not block the selected set. Missing membership registrations, ambiguous identities or handles, selected unavailable roots and zero matches fail; mgit buffers and validates the entire output before executing any selected command. Spaces and newlines travel through NUL transport. Directory prefixes apply before optional linked-worktree expansion.

Territory, estate, principals and explicit repository scopes are mutually exclusive. MGit's native default is its workspace/snapshot selection or discovery. The territory, estate and principals scopes reject discovery traversal options and `--ignore`. `structure` and `worktree` accept local filters but reject these scopes; `register` accepts territory locations, while estate, principals, filters and other ignored global selectors are rejected.

`mgit register add --territory HANDLE` binds a saved search location and explicitly refreshes membership. Plain `mgit register` refreshes all saved locations later; ordinary snapshot commands never invoke KI or silently refresh. A failed refresh leaves the manifest unchanged. See [saved locations and migration](repository-sets.md#migrate-agora-locations) for the hard cut-over from old Agora syntax.

## Discovery options

Discovery options matter only when mgit discovers repositories by walking the tree: when the current directory has no workspace manifest, or with `--ignore`. They do not change a manifest's declared members.

- `-P` or `--physical` does not enter symlinked directories while discovering. This is the default.
- `-L` or `--follow-symlinks` also enters symlinked directories that contain repositories, but never follows a symlink to a repository itself.
- `-I` or `--ignore` ignores workspace selection from `.mgit.toml` and discovers repositories by walking tree; repository-kind symlink metadata still expands discovered set.

See [define a repository set](repository-sets.md) when discovery is not sufficient, or [manage worktrees](worktrees.md) for the structure and worktree commands.
