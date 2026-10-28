---
id: KI-TOOL-MGIT-CLI-032
area: CLI
title: Chain Git commands
kind: deliver
purpose: capability
component: cli
priority: high
size: m
horizon: now
status: ready
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-28T22:44:14Z
updated_at: 2026-10-28T22:44:14Z
---

# Chain Git commands

## Goal

Run several Git commands in order across the selected repositories in one go, so each repository works through its own sequence, stops at its first failure without holding the others back, and the run ends with one account of where every repository got to. Sequences used often can be saved as named recipes.

## Context

Kris, 28 October 2026, in the KI State of play (ki.sop.main): "I like the chain thing, so we should add that pretty quickly. I wonder if we can just get ahead and do that right now." The brief that relays it authorises capture, planning and delivery of one record to Awaiting review, and gives the design Kris agreed:

- `mgit chain <git command> [args...] --then <git command> [args...] [--then ...]`, unquoted. `chain` takes the rest of the line raw, so mgit's option parser consumes neither Git flags nor `--then`, and splits it at each literal `--then`; each piece is one Git subcommand, run as ordinary pass-through commands are.
- Inside each repository the steps run in order and that repository stops at its first failing step; other repositories carry on. Repositories run in parallel under `-j`, `-v` streams them one at a time, and the usual selection options apply. Mixing mgit-owned commands into a chain is out of scope for v1.
- One block per repository naming each step's outcome, then one tally: completed, stopped at a step, and failed to start. `--json` if the existing JSON result path makes it cheap.
- Recipes: `git config mgit.chain.<name> "<steps joined by --then>"`, run with `mgit chain <name>`; also `mgit <name>` if it can be done cleanly, never shadowing an mgit-owned command, ahead of Git pass-through, and bypassed by `-B`.
- Document a path literally named `--then`; update help, usage, completion, the manual and the guides; add Bats cases.

Today a sequence such as fetch, fast-forward pull and push needs three separate `mgit` runs, each across the whole set, and a repository whose pull failed is still pushed by the third run unless the user notices.

## Boundary

- **In:** the `chain` command and its recipes in `bin/mgit`; help, usage, Bash and Zsh completion, `man/mgit.1`, `README.md`, the running-commands guide, a new MGIT-WS-028 in the dispatch specification and `CHANGELOG.md`; Bats cases in disposable repositories.
- **Out:** mgit-owned commands as chain steps; `-R` raw steps and learned output templates inside a chain; `mgit sync` behaviour, which MGIT-PUSH-GUARD, MGIT-TOLERANT and a sync redesign own separately; a release or version bump.

## Current state

[`bin/mgit`](../../bin/mgit) parses global options with `split_options top`, which already stops at the first operand, so every word after `chain` would reach the command untouched. An unowned command goes to `dispatch_captured`, which runs one `dispatch_worker` per checkout on the shared pool (`runner_run`), or to `dispatch_streaming` under `-v`; `--json` prints one document with a `summary` object. Each worker runs exactly one Git command; there is no notion of steps, and no `mgit.*` Git configuration is read today. `resolve_git_aliases` is the precedent for reading Git configuration from the invoking directory's context. The learn path keeps its own list of mgit-owned command names.

## Steps

- [ ] Add `chain` to the owned commands: split its raw words at each literal `--then` into steps, reject an empty step, `-R`, `--learn`, and `-v` with `--json` as usage errors, and give `mgit chain -h`, `mgit help chain` and `mgit --help chain` the chain usage.
- [ ] Read recipes from `mgit.chain.<name>` when the only word after `chain` is a valid Git configuration key name with a value, splitting the value into words with single quotes, double quotes and backslash escapes; reject an unterminated quote or empty step naming the recipe.
- [ ] Run a recipe at top level when `mgit <name>` has no other words, `<name>` is not an mgit-owned command, and none of `-B`, `-R` or `--learn` is given; share one owned-command list with the learn check.
- [ ] Add a chain worker on the shared pool that runs each step in turn inside the checkout, stops at the first non-zero status, and keeps each step's output and status; render one block per checkout in selection order with each step `ok`, `failed (exit N)` or `not run` and its output, then `mgit chain: N repositories: N completed, N stopped, N failed to start` naming each checkout that did not complete with its step and exit status; exit `1` unless every checkout completed.
- [ ] Add a streaming form under `-v` with the same per-step stop and the same tally, and a `--json` document with each checkout's outcome and steps and a `summary` object.
- [ ] Add Bash and Zsh completion for `chain` (recipe names and `--then`), the usage text and command listing, MGIT-WS-028, the manual, README, running-commands guide and changelog, documenting a path named `--then` as `./--then`.
- [ ] Add Bats cases for splitting with Git flags surviving, stop-at-first-failure with other checkouts continuing, the tally, parallel and verbose runs, JSON, recipes with quoting, top-level precedence, `-B` bypass, the no-shadow rule, and the usage errors.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `docs/specs/workspace-dispatch.md`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `CHANGELOG.md`.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes: `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1` and `git diff --check`; the new chain cases are among those passing.

## Dependencies / blocks

None. Blocks nothing. Independent of the queued sync work, which this record does not touch.

## Documentation impact

### Decision Records

None: `chain` adds a command in the existing dispatch and runner patterns, and Kris's agreed design in Context is its rationale.

### Specifications

New MGIT-WS-028 in the dispatch specification states the chain contract, recipes and their precedence; MGIT-WS-022's selector applicability and MGIT-WS-026's owned-name rule cover `chain` through it.

### Guides

The running-commands guide gains a section on chains and recipes; the README usage lists `chain`.

### Roadmap

None expected; any follow-on found in delivery is reported to the coordinator rather than captured, under CAPTURE-GATE.

## Discussion

### Authority

Captured, planned and delivered in one run under Kris's instruction of 28 October 2026 quoted in Context, relayed by the ki.sop.main coordinator's mgit-chain brief, which approves the plan above. Acceptance and any release stay with Kris.

### Outcome categories

"Failed to start" is read as a checkout where no step completed: its first step failed, or the checkout could not be entered. "Stopped" is a checkout whose chain failed at a later step after at least one completed. The three counts therefore partition the selection.

### Top-level recipes

`mgit <name>` runs a recipe only when the name is the sole word after the global options. `mgit <name> <args>` stays Git pass-through, because appending arguments to a multi-step recipe has no single meaning. This keeps the rule deterministic: mgit-owned commands first, then a recipe for a lone word, then Git.
