---
id: KI-TOOL-MGIT-CLI-019
area: CLI
title: Pass-through escape hatch
status: triage
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-17T21:31:16Z
updated_at: 2026-10-18T04:10:00Z
---

## Goal

Give `mgit` an explicit escape hatch so a Git subcommand that `mgit` overrides, or any shell command, can still run unchanged in every selected repository, with clearly named options for symlink handling.

## Context

Owner request, 17 October 2026, in Kris's words: "A lot commands in mgit effectively pass-throughs ... anything I create mgit level overrides pass-through ... There should some kind escape hatch". The requested options are:

- `--bare`: run the Git subcommand in each child, bypassing `mgit`'s own command of the same name (named `--git` below).
- `--raw`: run any shell command in each repository, replacing today's `-B`.
- Clear physical and follow-symlinks options.

Today any unknown command passes through to Git, while `register`, `repair`, `doctor`, `diag`, `sync`, `structure`, `worktree`, `completion` and `help` are owned by `mgit`; `git worktree` therefore cannot be run across the set. `-B, --bare` currently means "run COMMAND directly instead of as a Git subcommand", and `-P, --physical` (default) and `-L, --follow-symlinks` control traversal of symlinked container directories.

## Boundary

This capture does not adopt, schedule, implement or release anything. It does not change the repository-selection boundary or `.mgit.toml` model.

## Discussion

### Names (provisional)

The tools-burndown roadmap overview of 17 October found that "bare" already has two meanings in mgit: today's `-B/--bare` shell-command option, and the bare repositories that `sync` skips. Reusing `--bare` for Git bypass would add a third. Its ESCAPE-NAMES query recommended a): `--git` (`-G`) for plain Git pass-through and `--raw` (`-R`) for shell commands, retiring `-B/--bare` with an error that names `--raw`. The tools-burndown run of 18 October took a) under Kris's overnight instruction to take the recommended course on a judgement call ("provisional, for Kris to confirm"), so this record now uses those names.

### Dispatch model

```text
 mgit [selectors] ARGS...
   │
   ├── --raw / -R CMD...   ──> run CMD in each checkout (shell command)     [was -B / --bare]
   ├── --git / -G GITCMD.. ──> git GITCMD in each checkout, even if mgit owns GITCMD
   ├── -B / --bare         ──> usage error naming --raw
   ├── owned command       ──> mgit implementation (worktree, sync, overview, ...)
   └── anything else       ──> git ARGS in each checkout (pass-through)
```

- **Retirement.** `-B/--bare` fails with a usage error that names `--raw`, so an existing `mgit -B npm test` never runs as `git npm test`. The changelog and release notes mark the break.
- **Raw execution.** Decide whether `--raw` executes argv directly, as `-B` does today, or through a shell string so pipes and redirections work, and how quoting is documented.
- **Symlink options.** "Clear" options is read as reviewing the names and help for `-P/--physical` and `-L/--follow-symlinks` (for example aligning with `cd -P`/`-L` and stating what is followed); confirm whether a rename is wanted or only clearer documentation.
- **Selectors and output.** Every selector and `--all-worktrees` should apply to `--git` and `--raw` as they do to pass-through today. Output interacts with [KI-TOOL-MGIT-CLI-018](KI-TOOL-MGIT-CLI-018-estate-scale-output.md).
- **Coverage.** Help, manual, completion, README, running-commands guide, workspace-dispatch specification, changelog and Bats cases for each dispatch path and the `-B` retirement error.
