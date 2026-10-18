---
id: KI-TOOL-MGIT-CLI-025
area: CLI
title: Escape-hatch flag names
kind: deliver
purpose: debt
component: cli
horizon: next
status: draft
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-18T08:37:21Z
updated_at: 2026-10-18T08:37:21Z
---

## Goal

Settle the escape-hatch flags: the deprecated `-B/--bare` alias goes now, `-R/--raw` stays for running any command, and `-G/--git` stays as a temporary name for running Git past mgit's own commands until `-B` returns in its place as the bypass-to-Git flag.

## Context

Kris's answer of 18 October 2026 in the ways-of-working decisions log ("owner answers, batch 5"): "But I think minus K can just be dropped anyway. You've got an idea of everything that I run on my machine. So yeah, on the past to a scare patch, I think I'd rather go with that, which is a raw and a, and then I'd really, we could run that for a little while and we can say that minus G is a temporary gap and then it goes back to minus B for a bypass." The thread read it back as MGIT-FLAGS: drop the deprecated `-B` now; keep `-R` (raw) and `-G`; `-G` is temporary, and later `-B` returns as the bypass-to-Git flag. "Minus K" is read as `-B` and "past to a scare patch" as the pass-through escape hatch.

**Waiting on Kris's confirmation of this reading.** Do not plan or build until he confirms it.

[KI-TOOL-MGIT-CLI-019](KI-TOOL-MGIT-CLI-019-pass-through-escape-hatch.md) delivered `-G/--git`, `-R/--raw` and `-B/--bare` as a deprecated alias of `-R` that warns once on standard error.

### Uses of `mgit -B` found

A read-only search on 18 October 2026 of `~/workspaces` (every territory) and the chezmoi source `~/.local/share/chezmoi`, excluding this repository, for `mgit` invocations carrying `-B` or `--bare` (including combined short options), shell aliases and functions wrapping `mgit`, and programs spawning `mgit` with a `-B` or `--bare` argument:

- **No script, alias, function or program uses `mgit -B` or `mgit --bare`.** The only hits are prose in ki-principal work reports about this very change.
- **One stale consumer:** the chezmoi-managed Zsh completion `dot_zsh/completions/_mgit` (last changed 11 October 2026) still offers `-B` and `--bare` as "run an ordinary command without git prefix" and predates `-R`, `-G`, `-j`, `-v`, `--json` and `overview`. `mgit completion zsh` generates the current completion; the chezmoi copy should be regenerated from it when this lands, a change owned by the dotfiles repository.

Kris's interactive shell history was not searched.

## Boundary

- **In:** removing `-B/--bare` as an alias of `-R` (a usage error naming `-R/--raw` for a transition period, so `mgit -B npm test` never runs as `git npm test`); help, manual, completion, README, running-commands guide, MGIT-WS-014, MGIT-WS-019, MGIT-WS-022, changelog and Bats cases; noting `-G` as temporary in help and the guide.
- **Out:** reintroducing `-B` as the bypass-to-Git flag, which is a later step after `-G` has run for a while and needs its own record; renaming `-R`; editing the chezmoi completion, owned by the dotfiles repository. No release.

## Current state

`-B/--bare` sets the same direct-command mode as `-R/--raw` in `bin/mgit` and prints `mgit: warning: -B/--bare is deprecated; use -R/--raw` once per run; two Bats cases prove the alias and its warning.

## Steps

- [ ] Kris confirms the reading above.
- [ ] Make `-B` and `--bare` a usage error that names `-R/--raw`, and drop them from usage text and completion.
- [ ] Mark `-G/--git` as temporary in help, manual and guide.
- [ ] Replace the alias Bats cases with usage-error cases, and update the documents listed in Boundary.
- [ ] Run the complete gate.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes, in disposable fixtures.

## Dependencies / blocks

Waits on Kris's confirmation of the reading. The chezmoi-managed Zsh completion in the dotfiles repository should be regenerated from `mgit completion zsh` once this is released.

## Documentation impact

### Decision Records

None; the names are local to this record and KI-TOOL-MGIT-CLI-019.

### Specifications

MGIT-WS-014, MGIT-WS-019 and MGIT-WS-022 drop the alias.

### Guides

Running commands drops the deprecation note and marks `-G` as temporary.

### Roadmap

A later record makes `-B` the bypass-to-Git flag.

## Discussion

### Two steps

1. **Now (this record):** `-B/--bare` stops being an alias. A usage error is safer than silently changing meaning, because `-B` later becomes the Git bypass and an old `mgit -B npm test` must never become `git npm test`.
2. **Later (separate record):** after `-G` has been in use for a while, `-B/--bypass` (or `-B` alone) becomes the bypass-to-Git flag and `-G` either stays as an alias or is retired. The long name is open: `--bare` also names bare repositories in mgit, which is why -019 avoided it.

### Adoption

Captured and adopted into Next on 18 October 2026 by the ways-of-working accept-mgit run, under Kris's MGIT-FLAGS answer, marked as waiting on his confirmation of the read-back. Not planned.
