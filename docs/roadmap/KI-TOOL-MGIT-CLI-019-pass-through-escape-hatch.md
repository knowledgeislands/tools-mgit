---
id: KI-TOOL-MGIT-CLI-019
area: CLI
title: Pass-through escape hatch
kind: deliver
purpose: capability
component: cli
horizon: next
status: ready
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-17T21:31:16Z
updated_at: 2026-10-18T05:46:00Z
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

- **In:** `-G/--git`, which runs the Git subcommand in every selected checkout even when mgit owns a command of that name; `-R/--raw`, which runs any command directly, as `-B` does today; `-B/--bare` kept as a deprecated alias of `--raw` that prints one warning to stderr; clearer help for `-P/--physical` and `-L/--follow-symlinks`; help, manual, completion, README, running-commands guide, workspace-dispatch specification, changelog and Bats cases.
- **Out:** removing `-B/--bare`, renaming `-P` or `-L`, shell-string execution for `--raw`, any change to repository selection or the `.mgit.toml` model. No release.

## Current state

Any command mgit does not own passes through to Git; `register`, `repair`, `doctor`, `diag`, `sync`, `structure`, `worktree`, `overview`, `completion` and `help` are owned, so `git worktree` or `git help` cannot run across the set. `-B, --bare` runs a command directly, and is rejected with listing and with owned commands. `-P/-L` help says only "symlinked container directories" and does not say they apply to discovery alone.

## Steps

- [ ] Add `-G/--git`: dispatch bypasses every owned command, including `help`, and runs `git ARGS` in each selected checkout through the same dispatch path as pass-through.
- [ ] Add `-R/--raw` with today's `-B` behaviour, executing the argument vector directly; pipes and redirections need an explicit `sh -c`.
- [ ] Keep `-B/--bare` as a deprecated alias of `--raw` that warns once on stderr, `mgit: warning: -B/--bare is deprecated; use -R/--raw`, and otherwise behaves exactly as before.
- [ ] Reject `--git` with `--raw` (or `-B`), and either without a command, as usage errors; apply selector rejection to the new options as for `-B` today.
- [ ] Reword `-P/--physical` and `-L/--follow-symlinks` help to say they control discovery only (no workspace manifest, or `--ignore`) and what is followed.
- [ ] Add Bats cases for `--git` with an owned name, `--raw`, the `-B` warning and unchanged behaviour, the usage errors, and selectors with each.
- [ ] Update help, manual, completion, README, running-commands guide, workspace-dispatch specification and changelog.
- [ ] Run the complete gate.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes: `ki repo audit --repo .`, `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1` and `git diff --check`.

## Dependencies / blocks

Not blocked. It builds after [KI-TOOL-MGIT-CLI-018](KI-TOOL-MGIT-CLI-018-estate-scale-output.md) in the agreed order, so `--git` and `--raw` use that record's runner and `--verbose` like pass-through.

## Documentation impact

### Decision Records

None; the names and the alias are recorded below as provisional decisions local to this record.

### Specifications

MGIT-WS-014 renames to direct-command dispatch under `--raw` with the deprecated alias; a new requirement covers `--git`; MGIT-WS-022 lists the new options.

### Guides

Running commands documents both escape hatches and the deprecation.

### Roadmap

A later record may retire `-B/--bare` once Kris confirms; not captured here.

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

### Adoption (provisional, for Kris to confirm)

Adopted into Next and planned to Ready on 18 October 2026 by the ways-of-working mgit-build run, provisionally on Fable's opinion of 18 October (fable-opinion-2, option a), under Kris's KEEP-PUSHING and FABLE-OPINION answers. Building stops at Awaiting review, pure Bash with Bats fixtures only, with no release. Kris confirms or reverses the adoption and plan by editing this record. The run's brief keeps `-B/--bare` as a deprecated alias of `--raw` with a warning, superseding the retirement error in Dispatch model; `--raw` executes argv directly and `-P/-L` get clearer help with no rename, each provisional, for Kris to confirm.
