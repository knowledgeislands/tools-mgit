---
id: KI-TOOL-MGIT-CLI-025
area: CLI
title: Escape-hatch flag names
kind: deliver
purpose: debt
component: cli
horizon: next
status: ready
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-18T08:37:21Z
updated_at: 2026-10-18T08:52:00Z
---

## Goal

Settle the escape-hatch flags: the deprecated `-B/--bare` alias goes now, `-R/--raw` stays for running any command, and `-G/--git` stays as a temporary name for running Git past mgit's own commands until `-B` returns in its place as the bypass-to-Git flag.

## Context

Kris's answer of 18 October 2026 in the ways-of-working decisions log ("owner answers, batch 5"): "But I think minus K can just be dropped anyway. You've got an idea of everything that I run on my machine. So yeah, on the past to a scare patch, I think I'd rather go with that, which is a raw and a, and then I'd really, we could run that for a little while and we can say that minus G is a temporary gap and then it goes back to minus B for a bypass." The thread read it back as MGIT-FLAGS: drop the deprecated `-B` now; keep `-R` (raw) and `-G`; `-G` is temporary, and later `-B` returns as the bypass-to-Git flag. "Minus K" is read as `-B` and "past to a scare patch" as the pass-through escape hatch.

Kris confirmed the reading on 18 October 2026 in the ways-of-working decisions log ("owner answers (typed)", MGIT-FLAGS): first migrate every `mgit -B` use in the chezmoi source and across the repositories to `mgit -R`, then remove `-B`.

[KI-TOOL-MGIT-CLI-019](KI-TOOL-MGIT-CLI-019-pass-through-escape-hatch.md) delivered `-G/--git`, `-R/--raw` and `-B/--bare` as a deprecated alias of `-R` that warns once on standard error.

### Uses of `mgit -B` found

A read-only search on 18 October 2026 of `~/workspaces` (every territory) and the chezmoi source `~/.local/share/chezmoi`, excluding this repository, for `mgit` invocations carrying `-B` or `--bare` (including combined short options), shell aliases and functions wrapping `mgit`, and programs spawning `mgit` with a `-B` or `--bare` argument:

- **No script, alias, function or program uses `mgit -B` or `mgit --bare`.** The only hits are prose in ki-principal work reports about this very change.
- **One stale consumer:** the chezmoi-managed Zsh completion `dot_zsh/completions/_mgit` (last changed 11 October 2026) still offers `-B` and `--bare` as "run an ordinary command without git prefix" and predates `-R`, `-G`, `-j`, `-v`, `--json` and `overview`. `mgit completion zsh` generates the current completion; the chezmoi copy should be regenerated from it when this lands, a change owned by the dotfiles repository.

Kris's interactive shell history was not searched.

The confirmed migration repeated the search on 18 October 2026 with the same result outside this repository, and changed the chezmoi completion snapshot's two `-B`/`--bare` entries to `-R`/`--raw` in the dotfiles repository. Inside this repository, `tests/territory-protocol.bats` and `tests/territory-producer.bats` still drive their fixtures with `-B`.

## Boundary

- **In:** removing `-B/--bare` as an alias of `-R` (a usage error naming `-R/--raw` for a transition period, so `mgit -B npm test` never runs as `git npm test`); help, manual, completion, README, running-commands guide, MGIT-WS-014, MGIT-WS-019, MGIT-WS-022, changelog and Bats cases; noting `-G` as temporary in help and the guide.
- **In:** the territory Bats suites switch their fixture dispatch from `-B` to `-R`.
- **Out:** reintroducing `-B` as the bypass-to-Git flag, which is a later step after `-G` has run for a while and needs its own record; renaming `-R`; editing the chezmoi completion, owned by the dotfiles repository. No release.

## Current state

`-B/--bare` sets the same direct-command mode as `-R/--raw` in `bin/mgit` and prints `mgit: warning: -B/--bare is deprecated; use -R/--raw` once per run; two Bats cases prove the alias and its warning.

## Steps

- [x] Kris confirms the reading above.
- [ ] In `bin/mgit`, make `-B` and `--bare` a status-`2` usage error naming `-R/--raw`, raised in global option parsing before any discovery, so `mgit -B <command>` runs nothing; drop the deprecation warning and the `bare_option` bookkeeping that only distinguished the alias.
- [ ] Drop `-B` and `--bare` from usage text and from the Bash and Zsh completion scripts.
- [ ] Mark `-G/--git` as temporary, until `-B` returns as the bypass-to-Git flag, in usage text, the manual and the running-commands guide.
- [ ] In `tests/mgit.bats`, replace the alias and warning assertions with a removed-flag case proving both spellings exit `2`, name `-R/--raw` and run nothing; update the help and completion assertions.
- [ ] Switch `tests/territory-protocol.bats` and `tests/territory-producer.bats` fixture dispatch from `-B` to `-R`.
- [ ] Update the manual, README, running-commands guide, MGIT-WS-014, MGIT-WS-022 and the changelog baseline.
- [ ] Run the complete gate.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `tests/territory-protocol.bats`, `tests/territory-producer.bats`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes, in disposable fixtures. `mgit -B pwd` and `mgit --bare pwd` exit `2` with the `-R/--raw` hint and no command output; `mgit -R pwd` is unchanged; `mgit --help`, `mgit completion bash` and `mgit completion zsh` no longer offer `-B` or `--bare`.

## Dependencies / blocks

No blocker; Kris confirmed the reading. The chezmoi-managed Zsh completion in the dotfiles repository should be regenerated from `mgit completion zsh` once this is released.

## Documentation impact

### Decision Records

None; the names are local to this record and KI-TOOL-MGIT-CLI-019.

### Specifications

MGIT-WS-014 makes `-B/--bare` a usage error naming `-R/--raw`, and MGIT-WS-022 drops `--bare` from the pass-through options. MGIT-WS-019 names only `-R` and needs no change.

### Guides

Running commands drops the deprecation note and marks `-G` as temporary.

### Roadmap

A later record makes `-B` the bypass-to-Git flag.

## Discussion

### Two steps

1. **Now (this record):** `-B/--bare` stops being an alias. A usage error is safer than silently changing meaning, because `-B` later becomes the Git bypass and an old `mgit -B npm test` must never become `git npm test`.
2. **Later (separate record):** after `-G` has been in use for a while, `-B/--bypass` (or `-B` alone) becomes the bypass-to-Git flag and `-G` either stays as an alias or is retired. The long name is open: `--bare` also names bare repositories in mgit, which is why -019 avoided it.

### Adoption

Captured and adopted into Next on 18 October 2026 by the ways-of-working accept-mgit run, under Kris's MGIT-FLAGS answer, marked as waiting on his confirmation of the read-back. Planned to Ready on 18 October 2026 by the ways-of-working mgit-flags run after his confirmation.
