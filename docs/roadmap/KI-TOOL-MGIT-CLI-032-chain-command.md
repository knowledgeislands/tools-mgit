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
status: awaiting-review
blocks: []
blocked_by: []
baseline_ref: d4bb1b86928b7da74bfa5999957fdd33b36157ad
created_at: 2026-10-28T22:44:14Z
updated_at: 2026-10-28T22:54:27Z
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

- [x] Add `chain` to the owned commands: split its raw words at each literal `--then` into steps, reject an empty step, `-R`, `--learn`, and `-v` with `--json` as usage errors, and give `mgit chain -h`, `mgit help chain` and `mgit --help chain` the chain usage.
- [x] Read recipes from `mgit.chain.<name>` when the only word after `chain` is a valid Git configuration key name with a value, splitting the value into words with single quotes, double quotes and backslash escapes; reject an unterminated quote or empty step naming the recipe.
- [x] Run a recipe at top level when `mgit <name>` has no other words, `<name>` is not an mgit-owned command, and none of `-B`, `-R` or `--learn` is given; share one owned-command list with the learn check.
- [x] Add a chain worker on the shared pool that runs each step in turn inside the checkout, stops at the first non-zero status, and keeps each step's output and status; render one block per checkout in selection order with each step `ok`, `failed (exit N)` or `not run` and its output, then `mgit chain: N repositories: N completed, N stopped, N failed to start` naming each checkout that did not complete with its step and exit status; exit `1` unless every checkout completed.
- [x] Add a streaming form under `-v` with the same per-step stop and the same tally, and a `--json` document with each checkout's outcome and steps and a `summary` object.
- [x] Add Bash and Zsh completion for `chain` (recipe names and `--then`), the usage text and command listing, MGIT-WS-028, the manual, README, running-commands guide and changelog, documenting a path named `--then` as `./--then`.
- [x] Add Bats cases for splitting with Git flags surviving, stop-at-first-failure with other checkouts continuing, the tally, parallel and verbose runs, JSON, recipes with quoting, top-level precedence, `-B` bypass, the no-shadow rule, and the usage errors.

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

New MGIT-WS-028 in the dispatch specification states the chain contract, recipes and their precedence; MGIT-WS-022 names the selectors `chain` accepts, and MGIT-WS-026's owned-name rule covers `chain` as an mgit command.

### Guides

The running-commands guide gains a section on chains and recipes; the README usage lists `chain`.

### Roadmap

None expected; any follow-on found in delivery is reported to the coordinator rather than captured, under CAPTURE-GATE.

## Review

### Delivered

`mgit chain STEP [--then STEP]...` runs Git steps in order in every selected checkout on the shared pool, stopping each checkout at its first failing step while the others carry on, with one block per checkout and a tally of completed, stopped and failed to start; `-v` streams it and `--json` prints one document. Recipes in `mgit.chain.NAME` run as `mgit chain NAME`, or as `mgit NAME` when the name is the sole word, not mgit-owned, and no `-B`, `-R` or `--learn` is given. Help, usage, Bash and Zsh completion, the manual, README, running-commands guide, MGIT-WS-028 and the changelog cover it, including the `./--then` path form.

### Change Summary

- `bin/mgit`: chain parsing, recipe lookup and shell-like splitting, the chain worker, captured, streaming and JSON renderers, the top-level recipe rule, one shared `is_mgit_command` list used by the learn check and the recipe rule, `chain_usage`, `mgit help chain`, the command listing and both completions.
- `tests/mgit.bats`: nine chain cases, and `chain` in the standalone-help loop.
- `docs/specs/workspace-dispatch.md`: new MGIT-WS-028 under Chained commands; MGIT-WS-022 names the selectors `chain` accepts.
- `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `CHANGELOG.md` (Unreleased, Added); no version bump.

### Verification

- `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `mandoc -T lint man/mgit.1`, `git diff --check` and `rumdl check` on the changed Markdown: pass.
- `MGIT_KI_PRODUCER=<installed ki> TMPDIR=<run directory> bats tests/`: 151 of 151 pass, none skipped, the nine chain cases among them.
- `ki repo audit --repo .`: the only FAIL is the existing SHELL-HOOK finding on `.githooks/pre-commit`, untouched by this work; a MAN-STYLE finding the new FILES subsection raised was fixed before commit.

### Outstanding concerns

- Every checkout is shown in captured output, including completed ones, because the brief asks for one block per repository; over a large set a quiet-collapse like ordinary dispatch may read better, left for review.
- A recipe is read from the Git configuration visible in the invoking directory, as Git aliases are; a repository-local recipe in one member is not seen from the workspace root.

### Post-change review

Reviewed the diff against the agreed design: `--then` splitting is literal and global, Git flags pass unchanged, the stop rule is per checkout, owned names are never shadowed, `-B` reaches Git, and `mgit NAME ARGS` stays pass-through. The interpretation of "failed to start" as no step completed is recorded under Discussion.

### Mini recap

Chain and recipes are delivered and documented, with the full suite green; acceptance and any release stay with Kris.

## Discussion

### Authority

Captured, planned and delivered in one run under Kris's instruction of 28 October 2026 quoted in Context, relayed by the ki.sop.main coordinator's mgit-chain brief, which approves the plan above. Acceptance and any release stay with Kris.

### Outcome categories

"Failed to start" is read as a checkout where no step completed: its first step failed, or the checkout could not be entered. "Stopped" is a checkout whose chain failed at a later step after at least one completed. The three counts therefore partition the selection.

### Top-level recipes

`mgit <name>` runs a recipe only when the name is the sole word after the global options. `mgit <name> <args>` stays Git pass-through, because appending arguments to a multi-step recipe has no single meaning. This keeps the rule deterministic: mgit-owned commands first, then a recipe for a lone word, then Git.
