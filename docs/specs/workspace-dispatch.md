# Workspace discovery and dispatch — MGIT-WS

This as-built area specifies how [mgit specifications](index.md) represent repository sets, select repositories, and run ordinary commands across resulting checkouts. It excludes repository-structure conversion and worktree mutation.

## Repository-set sources

### MGIT-WS-001 — Direct workspace selection

When current directory contains a workspace-kind `.mgit.toml` manifest and manifest use is enabled, mgit MUST select its declared direct members, local members before external repository members. It MUST continue to read existing schema-1 manifests using their configured default group, and MUST read legacy `[registered.members."PATH"]` tables as external members with one deprecation warning per manifest, keyed by physical path, until `register` rewrites them.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `register migrates a legacy structural group to direct members`; `legacy registered members stay readable with a warning until register rewrites them`; `repair warns once about a legacy manifest whichever spelling reached it`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-002 — Recursive workspace expansion

When a selected workspace member is another workspace, mgit MUST recursively use that child's direct members. Existing schema-1 child workspaces use their configured default group.

_Conformance:_ conforming

_Verify:_ `bin/mgit` — `select_workspace`; `bats tests/mgit.bats` — `register writes unversioned group-free workspaces in physical postorder`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-003 — Manifest safety validation

mgit MUST reject malformed, duplicate, unsafe, missing, or cyclic workspace members rather than dispatching against a partial workspace selection. A direct repository member MAY be external — one or more leading `../` segments followed by a safe relative path — and MUST otherwise lie below the manifest directory; an external member whose physical path lies inside the manifest directory MUST be rejected, in selection and in `repair`, naming the local member path to declare instead. A missing external member MUST fail selection like a missing local member. Repositories MUST be identified by physical path: two local members reaching the same repository fail, while an external member reached again through another workspace, or after a local member, MUST be dispatched once.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `workspace selection rejects malformed, duplicate, and unsafe paths`; `workspace selection rejects mixed formats and unsafe workspace cycles`; `external member paths must climb out and then name a safe repository path`; `external members dispatch exactly once with or without a navigation symlink`; `an external member that resolves back inside its workspace is rejected`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-004 — Discovery fallback

When no current-directory workspace-kind manifest is present, or with `--ignore`, mgit MUST discover repositories below current directory, keep current repository when applicable, and omit repositories nested inside another discovered repository.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `bare mgit lists the discovered repos`; `--ignore bypasses workspace selection for discovery`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-005 — Discovery traversal mode

mgit MUST use physical directory traversal by default and MAY follow symlinked container directories only when `--follow-symlinks` is selected.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--physical and --follow-symlinks control container traversal`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-006 — Territory repository set

With `-t/--territory HANDLE`, `--estate` or `--principals`, mgit MUST call `ki territory roots --null --territory HANDLE`, `ki territory roots --null --estate` or `ki territory roots --null --principals`, passing every repeated `--filter PREFIX` to KI. It MUST buffer the entire stream, require successful producer completion and complete NUL framing, validate absolute existing unique Git roots, and stop before dispatch on any error. It MUST NOT follow repository symlink metadata. Missing registration metadata, ambiguous identities or handles, selected missing roots and zero matches MUST fail; excluded unavailable registered roots MUST NOT block an otherwise valid selection. mgit MUST preserve the producer's root order and MUST NOT select or reorder territory Capitals itself.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--territory selects only NUL-delimited roots from ki`; `--territory preserves its exact roots instead of following symlink metadata`; `--territory stops before a command when ki cannot resolve roots`; `--principals selects the territory Capitals in the producer's order`; `--principals stops before a command when ki cannot resolve roots`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

## Repository narrowing

### MGIT-WS-007 — ~~Alternative group membership~~ (deprecated)

### MGIT-WS-008 — ~~Named-group management~~ (deprecated)

### MGIT-WS-009 — Filter composition

`--filter` MUST accept nonempty literal case-sensitive directory-basename prefixes, repeatable with OR semantics; it has no short letter, and `-f` MUST be a status-`2` usage error that names `--filter` and runs nothing. Default discovery and offline snapshots MUST use the same basename predicate locally, before worktree expansion. Explicit KI scopes MUST pass filters to the producer before physical-root validation. Empty prefixes and zero matches MUST fail before dispatch; no glob option or alias exists.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--filter limits the repo set by literal basename prefixes`; `--filter applies to bare commands and requires a pattern`; `-f is not a short filter and runs nothing`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-010 — Whole-repository filters

`--filter` MUST select logical repositories before checkout expansion. A matching repository MUST retain its primary checkout and, when `--all-worktrees` is present, all active linked worktrees.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--filter selects whole repos before optional worktree expansion`.

_Evidence:_ The named Bats check implements this requirement and passes in the repository CI gate.

## Dispatch-set command execution

### MGIT-WS-011 — Metadata closure

Outside explicit KI selection, mgit MUST add repositories reached through repository-kind `.mgit.toml` cross-repository symlink metadata, transitively and without duplicate dispatch targets.

_Conformance:_ conforming

_Verify:_ `bin/mgit` — metadata queue and `parse_mgit`; `bats tests/mgit.bats` — `a cross-repo symlink is recorded as a TOML entry`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-012 — Checkout dispatch

For repository listing, ordinary commands, and `sync`, mgit MUST dispatch only to each selected repository's primary checkout by default: the repository root for a standard repository and the required `main/` checkout for a nested repository. With `-W` or `--all-worktrees`, mgit MUST instead include every active worktree while excluding a nested repository's bare store. Bare repositories MUST remain unchanged. The option MUST NOT alter `structure` or `worktree` management behavior.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `normal commands use primary checkouts unless all worktrees are requested`.

_Evidence:_ The named Bats check implements this requirement and passes in the repository CI gate.

### MGIT-WS-013 — Default Git dispatch

For a non-reserved command, mgit MUST run `git` with supplied command and arguments in each selected checkout while preserving ordinary Git command options.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `ordinary Git command options remain pass-through`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-014 — Bare command dispatch

With `-R/--raw`, mgit MUST run the supplied argument vector directly in each selected checkout instead of prefixing it with `git`. `--bare` MUST be a status-`2` usage error that names `-R/--raw` and runs nothing. With `-B/--bypass`, mgit MUST pass every argument to `git`, including command names mgit owns; `-G` and `--git` MUST be status-`2` usage errors that name `-B/--bypass` and run nothing. `--bypass` with `--raw`, and either without a command, MUST be usage errors.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `--filter applies to bare commands and requires a pattern`; `--bypass runs Git subcommands that mgit owns`; `--raw runs the argument vector directly`; `--bare, -G and --git are removed and run nothing`; `--bypass and --raw reject invalid combinations`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

## Configuration contract

### MGIT-WS-015 — Discriminated configuration

New `.mgit.toml` documents MUST omit a schema field and declare exactly one supported top-level kind, `workspace` or `repository`. Workspace members MUST use one direct `members` map. mgit MUST also read existing `schema = 1` grouped workspace and repository documents and MUST reject mixed document shapes and fields or tables belonging to the other kind. `repair` MUST revalidate and write only a known repository shape or a workspace with only the structural default group, then clone missing declared repositories. `repair --dry-run`, or `-n`, MUST preview the exact config change and missing clones without writing. `--apply` MUST fail as an unknown option with status `2`. Alternative groups MUST be refused.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `discriminated manifests reject mixed document kinds`; `register migrates a legacy structural group to direct members`; `register refuses to discard legacy alternative groups`; `repair dry-run previews and default repairs a structural default workspace`; `repair keeps repository metadata and refuses unknown or alternative shapes`; `repair rejects the removed apply option without writing`.

_Evidence:_ The named source and Bats checks implement this requirement and pass in the repository CI gate.

### MGIT-WS-016 — ~~Explicit configuration migration~~ (deprecated)

### MGIT-WS-017 — ~~Configuration conflict refusal~~ (deprecated)

## Repository synchronization

### MGIT-WS-018 — Repository-set synchronization

`mgit sync` MUST fetch the upstream remote of every branch that tracks a remote branch, whether or not its worktree is clean, through the shared runner, at most once per repository and remote, before it changes any checkout. It MUST then act serially in selection order: fast-forward a branch only behind its upstream, push a branch only ahead, and leave every other branch untouched. It MUST NOT merge or rebase, whatever the user's pull configuration. It MUST skip and show dirty worktrees; name diverged branches with their counts and an in-memory merge prediction, clean or conflicting in N files, that changes no branch, index or worktree, listing conflicting files only with `-v/--verbose` and falling back to the plain warning where Git cannot predict; detached heads, branches without upstreams and failed fetches as warnings; and name repositories changed. It MUST give every selected checkout exactly one outcome - in sync, pulled, pushed, skipped or failed, where local changes, detached heads, missing upstreams, divergence, bare repositories and declined `-i` actions are skipped, and a failed status, fetch, comparison, pull or push is failed, a dirty checkout whose fetch failed keeping both reasons - and MUST end with `mgit sync: N repositories: N in sync, N pulled, N pushed, N skipped, N failed`, zero counts included, followed by one indented line per skipped or failed checkout naming its reason and, where its branch has an upstream, its ahead and behind counts, marked `(stale)` after a failed fetch. When `-i` input ends, the tally MUST add `N not reached`. Pull and push results, the tally and its detail MUST go to standard output; skips, warnings, failures, progress and prompts to standard error. The tally MUST NOT depend on `-v/--verbose`, and without it sync MUST NOT print per-checkout progress.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `sync rolls up current repositories and shows dirty worktrees`; `sync pulls incoming commits and pushes outgoing commits`; `sync interactive mode confirms each pull and push`; `sync reports no-upstream bare and divergent repositories`; `sync predicts a conflicting merge without touching the checkout`; `sync keeps the plain divergence warning when merge-tree is unavailable`; `sync names held commits after the tally and keeps streams apart`; `sync interactive prompts go to standard error`; `sync honors repository filters`; `sync fetches every repository before fast-forwarding them in order`; `sync warns about failed fetches and detached checkouts and leaves them untouched`; `sync fetches a repository once for all its tracked worktrees`.

_Evidence:_ The named Bats checks cover clean, dirty, incoming, outgoing, no-upstream, bare, divergent (clean, conflicting and unpredicted), dirty with held commits, failed-fetch with stale counts, interrupted interactive, and filtered repository states, with the tally summing to the selection and each stream checked.

## Fan-out result

### MGIT-WS-019 — Aggregate command failure

Ordinary Git and `-R` dispatch MUST attempt every selected checkout and return status `1` when any child command fails, even when the final child succeeds. It MUST return `0` only when every child succeeds, and its closing line MUST name each failed checkout with its exit status.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `fan-out reports an early failure after a successful final checkout`.

_Evidence:_ The named Bats case exercises both dispatch families with an early failure and successful final checkout.

### MGIT-WS-020 — Checkout output identity

Ordinary command headers and `sync` progress and outcomes MUST use the selected checkout label, including external worktrees, while Git executes at the checkout path. Ordinary command results MUST appear in selection order whatever order the checkouts finish in. Captured standard output MUST contain no ANSI styling; a non-empty `NO_COLOR` MUST disable styling on a terminal.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `captured command output has no color and sync uses checkout labels`.

_Evidence:_ The named Bats case covers standard, nested, and external worktree output in a captured stream.

### MGIT-WS-021 — Management previews

`register --dry-run`, or `-n`, MUST report proposed manifest writes and removals without changing local manifests or Chezmoi source state, including with location additions and removals. `repair --dry-run`, or `-n`, MUST report recognised config repairs and missing clone targets using the same "would" wording style as registration, without changing files. `register`, and `register --dry-run` before it, MUST name each hand-written external member that no saved location reproduces and that registration therefore drops. Both commands MUST retain preflight validation; `repair` MUST perform recognised repairs and missing clones by default, MUST NOT replace existing paths or clone a missing external member, and MUST validate config repairs before writing.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `register dry-run previews add and rm without changing manifests or Chezmoi`; `register dry-run previews repository manifest removal without deleting it`; `repair dry-run previews missing clone targets without creating them`; `repair materializes structural defaults and recreates nested layout`; `repair refuses a missing member without a clone URL`; `repair validates external members but never clones a missing one`; `register names each hand-written external member it drops`.

_Evidence:_ The named Bats cases cover preview output, unchanged state, and default execution.

### MGIT-WS-022 — Global selector applicability

mgit MUST reject a global selector that the selected command would ignore with a namespaced status-`2` usage error before repository discovery or mutation. Listing accepts discovery, territory, estate or principals, filtering, and all-worktrees selectors. Ordinary pass-through additionally accepts `--bypass`, `--raw`, `--learn` and the runner options `--jobs`, `--verbose` and `--json`, but not `--verbose` with `--json`. `sync` and `overview` accept listing selectors; `overview` also accepts the runner options, and `sync` accepts `--jobs` and `--verbose` but not `--json`. `structure` and `worktree` accept discovery and filtering selectors. `register` accepts only territory as a saved-location shorthand; `repair` and `completion` accept no global selector. Help and version MUST remain available with selectors.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `inapplicable global selectors fail before management commands change state`; `command-specific selectors reject ignored combinations`; `help and version remain available with selectors`; `runner options are validated and rejected where they do not apply`.

_Evidence:_ The selector matrix covers status, namespace, and no-side-effect behavior for the command families.

### MGIT-WS-023 — Saved territory snapshots and hard cut-over

Saved `territory:HANDLE` locations MUST resolve current membership only during explicit `register` add, rm or refresh. Ordinary generated snapshots MUST remain offline without automatic refresh. Failed producer resolution or validation MUST leave the manifest byte-identical. Old Agora flags, `agora:` locations, `agora` fields and Agora member tables MUST fail with actionable, explicit migration guidance, including old schema-1 Agora snapshots; no aliases or historical-name reinterpretation are permitted. Migration guidance MUST preview the replacement membership and preserve user state. Territory, estate, principals and explicit repository scopes MUST be exclusive outside register's saved-location editing grammar.

_Conformance:_ conforming

_Verify:_ `MGIT_KI_PRODUCER=/absolute/path/to/committed/ki bats tests/territory-producer.bats tests/territory-protocol.bats`.

_Evidence:_ Real executable fixtures separate registry keys, the Capital key, handle and directory basenames, and prove literal filters, failure atomicity, spaces/newlines, worktree expansion, saved refresh and offline operations.

## Estate overview

### MGIT-WS-024 — Read-only estate overview

`mgit overview` MUST read local Git state only, never fetching or changing refs, the index, stashes or `FETCH_HEAD`. For each selected checkout it MUST report working-tree changes, HEAD and upstream state with ahead and behind counts, stashes, prunable or detached linked worktrees, and obsolete branches by the `ki-git` clean-down criteria: local branches merged into or patch-equivalent to the default branch, with a gone upstream, or unmerged and idle beyond the stale threshold; remote-tracking branches merged or stale. Branches checked out in a worktree MUST NOT be obsolete. The terminal view MUST name only checkouts needing attention unless `--verbose`, and close with clean, attention and failed counts; `--json` MUST print one JSON document. The command MUST exit `1` only when a checkout cannot be read.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `overview names only checkouts that need attention and counts the rest`; `overview reports obsolete branches by the clean-down criteria`; `overview reports stashes, detached checkouts and worktrees once per repository`; `overview prints one JSON document`; `overview reads Git state without changing it`; `overview fails only for unreadable checkouts and validates its options`.

_Evidence:_ The named Bats cases cover each attention state and obsolete-branch kind, JSON shape, a byte-for-byte read-only proof against a stale index, failure and option validation.

## Shared runner

### MGIT-WS-025 — Bounded parallel runner and concise output

Ordinary Git and `-R` dispatch, and `overview` collection, MUST run selected checkouts in a pool of at most `--jobs` workers (default 8), each with standard input from `/dev/null`, `GIT_TERMINAL_PROMPT=0` and `GIT_EDITOR` and `GIT_SEQUENCE_EDITOR` set to `false`, capturing output in a private temporary directory removed on exit or interrupt. Progress MUST go to standard error only when it is a terminal. Ordinary dispatch MUST then print, in selection order, the header and captured output of each checkout with output or a non-zero status, counting the rest, and any checkout quiet under MGIT-WS-026, as quiet, with no built-in rule for any command; one closing line MUST give the quiet, output and failed counts. `--verbose` MUST restore serial streaming dispatch with no closing line, and `--json` MUST print one JSON document.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `the runner prints results in selection order and counts quiet checkouts`; `the runner runs checkouts concurrently up to the job limit`; `with no templates every checkout with output is shown`; `verbose streams every checkout in turn as before`; `json prints ordinary-command results as one document`; `workers cannot prompt, open an editor or read the terminal`; `the runner draws no progress off a terminal and removes its files`; `overview runs on the pool and takes the global output options`.

_Evidence:_ The named Bats cases prove ordering against reversed finishing times, concurrency by shared markers, the quiet rules, failure naming, the streaming and JSON alternatives, the input and editor guards, and temporary-file removal on success and on a termination signal.

### MGIT-WS-026 — Learned output templates

`mgit learn COMMAND`, and `--learn` before a Git command, MUST run the command through the runner as an ordinary Git command, then replace each checkout's path, remote URL, upstream, remote, branch and repository name in its standard output and standard error with `{path}`, `{remote-url}`, `{upstream}`, `{remote}`, `{branch}` and `{repository}`, longest value first and ignoring values shorter than two characters. Learning MUST accept one checkout or more. When all exit `0` and every checkout, or strictly more than half, share the same non-empty normalised output, mgit MUST state how many agreed out of how many, name any differing checkouts, and write that output as a plain-text template, one file per command after Git alias expansion, in `${XDG_CONFIG_HOME:-~/.config}/mgit/templates/`, only after a yes answer read from standard input that is a terminal; when standard input is not a terminal it MUST NOT read it, and on that, any other answer or end of input it MUST write nothing and exit `1`. Otherwise it MUST write nothing and, unless every output was empty, exit `1` naming the failed checkouts or those differing from the most common output. A later captured run of the same command after alias expansion MUST count a checkout as quiet when it exits `0` and its normalised output equals the template; `--verbose`, `--json` output and `-R` commands MUST remain unfiltered. `learn --list` MUST print each template's command and file, and `learn --forget COMMAND` MUST remove one. mgit-owned command names, and `--learn` with `--raw`, `--verbose` or `--json`, MUST be usage errors.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `learn writes a template that later runs count as quiet`; `learn normalises remotes, paths and repository names`; `learn names the repositories that differ and writes nothing`; `learn asks before writing a majority output`; `learn never asks without a terminal`; `learn learns from a single repository`; `a learned standard-error message is quiet only while it matches`; `a template never quiets a failed checkout`; `learn lists and forgets templates`; `learn file names encode every argument readably`; `learn options are validated before anything runs`.

_Evidence:_ The named Bats cases learn templates in disposable repositories with local bare origins and an isolated configuration directory, and prove alias sharing, normalisation, refusal on difference, confirmation of unanimous and majority output on a terminal and refusal without one, failure, learning from a single repository, standard-error matching, the raw views and the template file names.

### MGIT-WS-027 — Option syntax

mgit MUST accept its global options, and each mgit-owned command's options, in the forms the command-line conventions allow: short options without a value group, so `-vW` means `-v -W`; a short option's value MAY be attached, so `-j4` means `-j 4`, and a value letter inside a group takes the rest of the word, so `-vj4` means `-v -j 4`; and a long option's value MAY follow an equals sign, so `--jobs=4` means `--jobs 4`. Each form MUST behave exactly as its separate form, including its usage errors, and an equals sign after a long option that takes no value MUST be a usage error. Global option parsing MUST stop at the command word or `--`, and words after it MUST reach Git, or the command `-R` runs, unchanged. `-n` MUST be the short form of `--dry-run` on `register` and `structure`, and `-f` of `--force` on `worktree remove`; neither is a global option.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `short options group and take attached values as their separate forms`; `words after the command reach Git without option expansion`; `sync interactive mode confirms each pull and push`; `register dry-run previews add and rm without changing manifests or Chezmoi`; `structure nested previews then restructures every standard repo in the set`; `structure standard restores a nested repository with only main`; `worktree remove supports a standard sibling and protects the primary checkout`; `overview reports obsolete branches by the clean-down criteria`.

_Evidence:_ The named Bats cases run grouped, attached and equals forms against disposable repositories and show each matches its separate form or usage error, that `mgit -v log -n1 --format=%s` reaches Git unchanged, and that `-n` previews and `-f` removes a dirty linked worktree.
