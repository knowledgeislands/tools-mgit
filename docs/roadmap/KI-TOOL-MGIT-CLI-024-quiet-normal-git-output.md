---
id: KI-TOOL-MGIT-CLI-024
area: CLI
title: Quiet normal Git output
kind: deliver
purpose: capability
component: cli
horizon: next
status: draft
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-18T08:37:21Z
updated_at: 2026-10-18T10:10:00Z
---

## Goal

Commands that always print a normal "nothing happened" message, such as `git pull` saying "Already up to date." and `git push` saying "Everything up-to-date", count as quiet across the estate, so only checkouts where something actually happened are shown. The rule is conservative and configurable, and the raw output is always one option away.

## Context

Kris's MGIT-QUIET-NORMAL answer of 18 October 2026 in the ways-of-working decisions log ("owner answers, batch 5") asks for standard no-change output to be treated as quiet.

Under the shared runner of [KI-TOOL-MGIT-CLI-018](KI-TOOL-MGIT-CLI-018-estate-scale-output.md), `dispatch_captured` in `bin/mgit` counts a checkout as quiet only when it exits `0` with empty standard output and standard error, or, for `status`, when `git status --porcelain=v2 --branch` shows no change entries and `# branch.ab +0 -0`. So `mgit pull` or `mgit push` over a level estate prints a header and Git's no-change line for every checkout, which is the scrolling Kris asked -018 to end. Git writes some of these messages to standard error (`git push` writes "Everything up-to-date" there).

## Boundary

- **In:** a quiet rule for captured pass-through output that matches the whole of a checkout's output (both streams, after trimming) against a small built-in set of exact no-change messages, applied only on exit `0`; a configuration point to extend or disable the set; a way to see the raw output (the existing `-v/--verbose`, and the `--json` `stdout` and `stderr` fields kept unfiltered); help, manual, running-commands guide, MGIT-WS-025 and Bats cases.
- **Out:** partial-output filtering (a checkout with any unmatched line is shown in full); matching on non-zero exits; localised Git messages beyond forcing a known locale if that is chosen; `sync`, which already has its own result model; any change to the exit-status contract. No release.

## Current state

`dispatch_worker` marks a checkout quiet only for `status` or a Git alias whose expansion begins with `status` (such as `st = status -sb`); `dispatch_captured` otherwise treats any captured byte on either stream as output. No message is matched, and nothing is configurable.

The status-alias rule landed on 18 October 2026 under Kris's MGIT-ST-QUIET answer in the ways-of-working decisions log, ahead of this record's planning, because `mgit st` counted every clean, level checkout as output; it is folded here rather than opened as a separate record. The no-change message rule above remains to do.

## Steps

- [ ] Settle the questions below and the exact starting pattern set with fixtures for each message.
- [ ] Add the matcher to the captured pass-through path, applied on exit `0` only, with the configuration point.
- [ ] Document the rule, the configuration and the raw views; add Bats cases for each pattern, an unmatched extra line, a non-zero exit and the raw views.
- [ ] Run the complete gate.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes, in disposable fixtures with local bare origins.

## Dependencies / blocks

None; it builds on the runner already on `main`.

## Documentation impact

### Decision Records

None expected.

### Specifications

MGIT-WS-025 gains the no-change message rule.

### Guides

Running commands describes the rule, its configuration and how to see raw output.

### Roadmap

None.

## Discussion

### Starting pattern set

Conservative and exact, each tied to its subcommand:

- `pull`: `Already up to date.` (and the older `Already up-to-date.`).
- `push`: `Everything up-to-date`.
- `fetch`: empty output is already quiet.
- `merge`: `Already up to date.`

Each candidate needs a fixture proving the exact text for the Git versions in use.

### Questions for planning

- **Locale.** Git translates these messages. Either run captured workers with `LC_ALL=C` (changes every captured command's language) or match only the C locale text and let other locales show as output; the second is the conservative choice.
- **Configuration home.** A user-level setting (environment variable or `git config mgit.quiet.*`) rather than `.mgit.toml`, since the set describes Git's wording, not the repository set; confirm.
- **Raw view.** `-v` already shows everything, streaming; decide whether a separate `--no-quiet` (captured, parallel, nothing collapsed) is worth adding, and keep `--json` unfiltered with only its `quiet` flag changing.

### Adoption

Captured and adopted into Next on 18 October 2026 by the ways-of-working accept-mgit run, under Kris's MGIT-QUIET-NORMAL answer. Not planned.
