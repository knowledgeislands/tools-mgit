---
id: KI-TOOL-MGIT-CLI-020
area: CLI
title: Safe parallel sync
kind: deliver
purpose: capability
component: cli
horizon: next
status: ready
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-18T04:10:00Z
updated_at: 2026-10-18T05:46:00Z
---

## Goal

Make `mgit sync` fast and quiet across the estate: fetch every selected repository in parallel, classify each one, act only where the action is safe, and warn without touching anything else.

## Context

Kris, 17 October 2026: "I like a sync that's a better syncing than it is at the minute, because essentially it steps through every single one of them." Earlier the same day, captured in [KI-TOOL-MGIT-CLI-018](KI-TOOL-MGIT-CLI-018-estate-scale-output.md): "if pulls and gets rebase or merge warning, it should effectively automatically abort and give me warning instead".

Today `sync` visits repositories one at a time. Each clean tracking branch runs `git pull --ff-only`, then `git push` when commits remain ahead; a checkout with local changes prints `git status --short` and is skipped. See [Run commands across repositories](../guides/user/running-commands.md).

The tools-burndown roadmap overview of 17 October proposed this record as part of an mgit plan; the tools-burndown run of 18 October captured it under that plan's MGIT-RECORDS a), provisional for Kris to confirm.

## Boundary

- **In:** `mgit sync` on the runner of [KI-TOOL-MGIT-CLI-018](KI-TOOL-MGIT-CLI-018-estate-scale-output.md): parallel `git fetch`, then classification of each checkout and only the safe action, fast-forward merge for a behind branch and push for an ahead one; diverged, dirty, detached and no-upstream checkouts are warned and left untouched; a summary naming only checkouts that pulled, pushed, warned or failed; `--verbose` restoring per-checkout lines; `--interactive` kept. Bats cases in disposable fixtures with local bare origins only.
- **Out:** merges, rebases or any abort-and-recover path; parallel pushes; any change to repository selection, the `.mgit.toml` model or the exit-status contract; running sync against a real estate. No release.

## Current state

`sync_command` visits checkouts one at a time, printing `[n/N] label: checking`, then `git pull --ff-only` and `git push` for a clean tracking branch; dirty, detached, no-upstream and bare checkouts are reported and make the run exit `1`; a diverged branch shows as `pull failed`. `--interactive` confirms each pull and push.

## Steps

- [ ] Fetch every eligible checkout (non-bare, on a branch with an upstream) in the runner's pool with `git fetch --quiet`, no prompts, recording fetch failures.
- [ ] Classify each checkout after the fetch: bare, dirty, detached, no upstream, fetch failed, current, behind, ahead or diverged, using `git status --porcelain` and `git rev-list --left-right --count HEAD...@{u}`.
- [ ] Act serially in selection order: a behind branch runs `git merge --ff-only --quiet @{u}`; an ahead branch runs `git push --quiet`; diverged, dirty, detached, no-upstream and fetch-failed checkouts get a one-line warning and nothing else; `--interactive` confirms each pull and push as today.
- [ ] Print by default only the checkouts that pulled, pushed, warned or failed, then the counts (in sync, skipped by the user, bare); `--verbose` adds today's per-checkout progress lines. Keep exit `1` whenever a checkout was warned or failed, as today.
- [ ] Update the existing sync Bats cases and add cases for parallel fetch, diverged left untouched with `pull.rebase` set, behind fast-forwarded, ahead pushed, dirty with its short status, fetch failure, default quiet output and `--verbose`, all against local bare origins.
- [ ] Update help, manual, README, running-commands guide, workspace-dispatch specification and changelog.
- [ ] Run the complete gate.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes: `ki repo audit --repo .`, `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1` and `git diff --check`. Every sync case runs in disposable repositories with local bare origins; no case or check runs sync against a real estate.

## Dependencies / blocks

Blocked by [KI-TOOL-MGIT-CLI-018](KI-TOOL-MGIT-CLI-018-estate-scale-output.md), whose runner it uses. Fable's condition holds: build only if every test runs wholly in disposable fixtures, which this plan meets.

## Documentation impact

### Decision Records

None; the classification and the serial push are recorded below as decisions local to this record.

### Specifications

MGIT-WS-018 changes to fetch, classify and act, with warned checkouts left untouched.

### Guides

Running commands describes the new sync output and `--verbose`.

### Roadmap

None.

## Discussion

```text
sync   fetch (parallel) ──► classify ──► act
                              │ current                    → count only
                              │ behind                     → merge --ff-only @{u}
                              │ ahead                      → push
                              │ diverged                   → WARN, touch nothing
                              │ dirty / detached / no upstream → WARN, skip
```

- Fetch runs in the runner's worker pool; pushes may stay serial if credential prompts or rate limits make parallel pushes unsafe.
- No path merges or rebases, whatever `pull.rebase` says: a behind branch uses `merge --ff-only @{u}`, so a diverged branch is a warning in the summary, never an abort to recover.
- Bare repositories stay skipped, now as one count rather than a line each.
- The end-of-run summary names only repositories that pulled, pushed, warned or failed; `--verbose` restores every line.

### Adoption (provisional, for Kris to confirm)

Adopted into Next and planned to Ready on 18 October 2026 by the ways-of-working mgit-build run, provisionally on Fable's opinion of 18 October (fable-opinion-2, option a), under Kris's KEEP-PUSHING and FABLE-OPINION answers. Building stops at Awaiting review, pure Bash with Bats fixtures only, with no release. Kris confirms or reverses the adoption and plan by editing this record. Fable's condition, build only if every test runs wholly in disposable fixtures, is met by the plan's local bare origins.
