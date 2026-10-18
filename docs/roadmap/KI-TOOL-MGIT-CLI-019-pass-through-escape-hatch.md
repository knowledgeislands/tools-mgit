---
id: KI-TOOL-MGIT-CLI-019
area: CLI
title: Pass-through escape hatch
kind: deliver
purpose: capability
component: cli
status: done
blocks: []
blocked_by: []
baseline_ref: 022ce41317e90845af2a45864d6e20f82893ee08
created_at: 2026-10-17T21:31:16Z
updated_at: 2026-10-18T08:38:21Z
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

- [x] Add `-G/--git`: dispatch bypasses every owned command, including `help`, and runs `git ARGS` in each selected checkout through the same dispatch path as pass-through.
- [x] Add `-R/--raw` with today's `-B` behaviour, executing the argument vector directly; pipes and redirections need an explicit `sh -c`.
- [x] Keep `-B/--bare` as a deprecated alias of `--raw` that warns once on stderr, `mgit: warning: -B/--bare is deprecated; use -R/--raw`, and otherwise behaves exactly as before.
- [x] Reject `--git` with `--raw` (or `-B`), and either without a command, as usage errors; apply selector rejection to the new options as for `-B` today.
- [x] Reword `-P/--physical` and `-L/--follow-symlinks` help to say they control discovery only (no workspace manifest, or `--ignore`) and what is followed.
- [x] Add Bats cases for `--git` with an owned name, `--raw`, the `-B` warning and unchanged behaviour, the usage errors, and selectors with each.
- [x] Update help, manual, completion, README, running-commands guide, workspace-dispatch specification and changelog.
- [x] Run the complete gate.

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

## Review

### Delivered

From the Ready baseline `022ce41`, `-G/--git` passes every argument to Git in each selected checkout, including names mgit owns such as `worktree`, `sync` and `help`, through the shared runner and with the same selectors as ordinary pass-through. `-R/--raw` is today's direct execution of the argument vector. `-B/--bare` behaves exactly as `-R` and prints `mgit: warning: -B/--bare is deprecated; use -R/--raw` on standard error once per run, just before dispatch, so usage errors stay clean. `--git` with `--raw` or `--bare`, `--git` without a command and `--raw` without a command are usage errors, and selector rejections name the spelling used. `-P/--physical` and `-L/--follow-symlinks` help now says they apply only while discovering repositories, without a manifest or with `--ignore`. No version bump, release or tag.

### Change Summary

The commit `feat(cli): add the KI-TOOL-MGIT-CLI-019 pass-through escape hatch` adds the options, the owned-command bypass, the deprecation warning, usage text and Bash and Zsh completion to `bin/mgit`; adds three Bats cases, extends the selector matrices with `-R`, and moves existing direct-command cases from `-B` to `-R`; and updates the manual, README, user guides index, running-commands guide, changelog, MGIT-WS-014, MGIT-WS-019, MGIT-WS-022 and MGIT-WS-025.

### Verification

`ki repo audit --repo .` passes with the existing HOOK-1 warning; `shellcheck`, `bash -n`, `mandoc -T lint` and `git diff --check` are clean; `bats tests/` passes 119 of 119. Run against the baseline `bin/mgit`, the three new cases fail. The `-B` case compares its standard output byte for byte with `-R` and checks the warning is the only addition. All runs used disposable fixtures with isolated Git configuration.

### Outstanding concerns

Each is provisional, for Kris to confirm:

- **The warning comes at dispatch.** `-B` warns only when a command actually runs, not on a usage error or with `--version`, so error output keeps its `mgit: error:` first line.
- **`-G -h` shows mgit help.** Help flags before the command still belong to mgit; `mgit -G help` is the way to run `git help` everywhere.
- **Existing tests moved to `-R`.** Direct-command cases now use the new spelling, and one case keeps proving `-B` is unchanged apart from the warning.
- **No removal date.** The deprecation names no release for removing `-B`; that is for Kris to set.

Human acceptance is outstanding.

### Post-change review

The bypass computes one `owned_command` word after option parsing, `git` under `--git`, and every top-level owned-command branch tests that word, so no owned command can run under `--git` and new owned commands inherit the rule.

### Mini recap

Owned names can now reach Git with `-G`, direct commands use `-R`, and `-B` keeps working with a warning.

## Done

Accepted 2026-10-18 by Kris on the review packet above, in the owner answers, batch 5, of the [ways-of-working decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.ways-of-working/decisions.md) (ACCEPT-018 to -022): "as it is, we accept what's there basically, and then anything else I come back with, we can do remedial work ... so we can accept everything." The provisional adoption, plan and choices under Outstanding concerns are confirmed as built. Retiring `-B/--bare` now, and `-B` later returning as the bypass-to-Git flag in place of `-G`, is [KI-TOOL-MGIT-CLI-025](KI-TOOL-MGIT-CLI-025-escape-hatch-flag-names.md), waiting on Kris's confirmation. Kris's hands-on check, and any remedial work it finds, is [KI-TOOL-MGIT-CLI-023](KI-TOOL-MGIT-CLI-023-hands-on-behaviour-check.md).

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

Adopted into Next and planned to Ready on 18 October 2026 by the ways-of-working mgit-build run, provisionally on Fable's opinion of 18 October (fable-opinion-2, option a), under Kris's KEEP-PUSHING and FABLE-OPINION answers. Building stops at Awaiting review, pure Bash with Bats fixtures only, with no release. Kris confirms or reverses the adoption and plan by editing this record. The run's brief keeps `-B/--bare` as a deprecated alias of `--raw` with a warning, superseding the retirement error in Dispatch model; `--raw` executes argv directly and `-P/-L` get clearer help with no rename, each provisional, for Kris to confirm. Built to Awaiting review the same day; the choices in Outstanding concerns are provisional, for Kris to confirm.
