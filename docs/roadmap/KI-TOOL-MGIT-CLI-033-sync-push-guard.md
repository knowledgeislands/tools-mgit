---
id: KI-TOOL-MGIT-CLI-033
area: CLI
title: Guard sync pushes
kind: deliver
purpose: corrective
component: cli
priority: high
size: m
horizon: now
status: awaiting-review
blocks: []
blocked_by: []
baseline_ref: 0a995a84eccd2b6d8731a73689574c75927746ce
created_at: 2026-10-31T14:20:53Z
updated_at: 2026-10-31T14:21:51Z
---

# Guard sync pushes

## Goal

Make `mgit sync` safe to run routinely: by default it fetches and fast-forwards only, names each branch only ahead of its upstream instead of pushing it, publishes only when asked with `--push`, and never pushes a repository that has opted out in its Git configuration.

## Context

Kris adopted MGIT-PUSH-GUARD at 01:04 GMT on 25 October 2026, after a blind review: "sync pushes only with --push". The decision, routed to ki.prj.tools-burndown by KI State of play, reads: by default `mgit sync` fetches and fast-forwards, and reports ahead-only branches as "ahead N, not pushed (pass --push)" instead of pushing them; `mgit sync --push` publishes; `git config mgit.syncPush false` is a hard per-repository veto that `--push` and `-i` never override; update `sync_usage`, the zsh completion, the man page and the tests, and announce the changed default; test the default no-push, explicit push, veto precedence, interactive mode and linked worktrees in disposable repositories. The line asks for the work to be captured in this roadmap.

Why: at 01:27 BST on 25 October a routine `mgit sync` published background runs' unreviewed local commits to `main` in nine HNR site repositories and ki-principal, and four sites redeployed.

Kris released ki.prj.tools-burndown on 31 October 2026, "Release it, one fix at a time", and ki.prj.ways-of-working's window plan runs this as unit U5: push to `main`, no tag and no release ("stop to ask me before any ki or mgit release", 16 October).

## Boundary

- **In:** the `sync` command's push rule, `--push` option and `mgit.syncPush` veto in `bin/mgit`; `sync_usage`, Bash and Zsh completion, `man/mgit.1`, `README.md`, the running-commands guide, MGIT-WS-018 and `CHANGELOG.md`; Bats cases in disposable repositories.
- **Out:** the sync redesign over `mgit chain` steps (SYNC-RECIPE) and MGIT-TOLERANT; any other sync outcome; a version bump, tag or release.

## Current state

`sync_command` in [`bin/mgit`](../../bin/mgit) fetches every tracking branch, then serially fast-forwards a branch only behind and runs `git push` on a branch only ahead, asking first under `-i`. Nothing reads `mgit.*` configuration in sync, and there is no way to stop it pushing. A declined `-i` action is counted as skipped without failing the run.

## Steps

- [x] Add `--push` to `sync`; without it, name a branch only ahead as `ahead N, not pushed (pass --push)` on standard error and in the tally detail, counted as skipped without failing the run, and never prompt for its push under `-i`.
- [x] Read `mgit.syncPush` with `git config --bool` in each checkout; false vetoes the push whatever `--push` or `-i` says, naming `mgit.syncPush is false`, and a value Git cannot read as a boolean vetoes it too, naming `mgit.syncPush is not a boolean`.
- [x] Update `sync_usage`, Bash and Zsh completion, the manual, README, running-commands guide, MGIT-WS-018 and the changelog's Changed section announcing the new default.
- [x] Add and adjust Bats cases for the default no-push, explicit push, veto precedence under `--push` and `-i --push`, interactive mode with and without `--push`, and linked worktrees sharing the repository's veto.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `docs/specs/workspace-dispatch.md`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `CHANGELOG.md`.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes: `ki repo audit --repo .`, `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1` and `git diff --check`, with the new and adjusted sync cases among the passing.

## Dependencies / blocks

None. Blocks nothing. SYNC-RECIPE, queued in ki.prj.tools-burndown, will rebuild sync on `mgit chain` and must keep this push rule.

## Documentation impact

### Decision Records

None: the rationale is Kris's adopted MGIT-PUSH-GUARD decision quoted in Context.

### Specifications

MGIT-WS-018 states the push rule, the veto and the unpushed outcome.

### Guides

The running-commands guide and README describe `--push` and `mgit.syncPush`.

### Roadmap

None expected; any follow-on found in delivery is reported to the coordinator rather than captured.

## Review

### Delivered

`mgit sync` now fetches and fast-forwards only. A branch only ahead of its upstream is named `ahead N, not pushed (pass --push)` on standard error and in the tally detail, counted as skipped without failing the run; `mgit sync --push` publishes it, and `-i` offers a push only with `--push`. `git config mgit.syncPush false` vetoes the push whatever `--push` or `-i` says, naming `mgit.syncPush is false`, and a value Git cannot read as a boolean vetoes it too. Usage, both completions, the manual, README, running-commands guide, MGIT-WS-018 and the changelog announce the new default.

### Change Summary

- `bin/mgit`: `--push` in `sync_command`, the per-checkout `mgit.syncPush` veto read with `git config --bool`, the unpushed outcome, `sync_usage`, and Bash and Zsh completion.
- `tests/mgit.bats`: two new cases, for the veto under `--push` and `-i --push` with false, true, unset and non-boolean values, and for linked worktrees sharing the repository's veto; the push case now proves the default no-push before `--push`, and the interactive, input-ended, held-commit and prompt-stream cases use `--push` where they push, with `-i` alone shown offering no push.
- `docs/specs/workspace-dispatch.md` (MGIT-WS-018), `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `CHANGELOG.md` (Unreleased, Changed); no version bump.

### Verification

- `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `mandoc -T lint man/mgit.1` and `git diff --check`: pass.
- `TMPDIR=<run directory> bats tests/`: 153 of 153 pass, the 15 sync cases among them.
- `ki repo audit --repo .`: the only FAIL is the existing SHELL-HOOK finding on `.githooks/pre-commit`, untouched by this work.

### Outstanding concerns

- An unpushed branch counts as skipped but, like a declined `-i` action, does not make sync exit unsuccessfully, so a script relying on sync's exit status to notice unpublished commits must read the tally. Left for review.
- `mgit.syncPush` is read as Git resolves it in each checkout, so a global `mgit.syncPush false` vetoes every repository; the decision names it per repository, and the global form is a side effect rather than a feature.

### Post-change review

Reviewed the diff against MGIT-PUSH-GUARD: no path pushes without `--push`; the veto is checked before the `-i` prompt, so neither `--push` nor `-i` overrides it; pulls, divergence, dirty and fetch-failure handling are unchanged.

### Mini recap

The push guard is delivered and documented with the full suite green; acceptance and any release stay with Kris.

## Discussion

### Authority

Captured, planned and delivered in one run under Kris's MGIT-PUSH-GUARD decision quoted in Context, carried by ki.prj.ways-of-working's window unit U5. Acceptance and any release stay with Kris.
