---
id: KI-TOOL-MGIT-CLI-020
area: CLI
title: Safe parallel sync
kind: deliver
purpose: capability
component: cli
horizon: now
status: awaiting-review
blocks: []
blocked_by: []
baseline_ref: 00ef0def90e66d0a8bde0c2e4efb79590c4334d9
created_at: 2026-10-18T04:10:00Z
updated_at: 2026-10-18T06:39:50Z
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

- [x] Fetch every eligible checkout (non-bare, on a branch with an upstream) in the runner's pool with `git fetch --quiet`, no prompts, recording fetch failures.
- [x] Classify each checkout after the fetch: bare, dirty, detached, no upstream, fetch failed, current, behind, ahead or diverged, using `git status --porcelain` and `git rev-list --left-right --count HEAD...@{u}`.
- [x] Act serially in selection order: a behind branch runs `git merge --ff-only --quiet @{u}`; an ahead branch runs `git push --quiet`; diverged, dirty, detached, no-upstream and fetch-failed checkouts get a one-line warning and nothing else; `--interactive` confirms each pull and push as today.
- [x] Print by default only the checkouts that pulled, pushed, warned or failed, then the counts (in sync, skipped by the user, bare); `--verbose` adds today's per-checkout progress lines. Keep exit `1` whenever a checkout was warned or failed, as today.
- [x] Update the existing sync Bats cases and add cases for parallel fetch, diverged left untouched with `pull.rebase` set, behind fast-forwarded, ahead pushed, dirty with its short status, fetch failure, default quiet output and `--verbose`, all against local bare origins.
- [x] Update help, manual, README, running-commands guide, workspace-dispatch specification and changelog.
- [x] Run the complete gate.

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

## Review

### Delivered

From the Ready baseline `00ef0de`, `mgit sync` first fetches, through the shared runner pool, the upstream remote of every clean tracking branch, once per repository and remote, with no prompts. It then acts one checkout at a time in selection order: a branch only behind runs `git merge --ff-only --quiet @{upstream}`, a branch only ahead runs `git push --quiet`, and a diverged, dirty, detached, untracked or fetch-failed checkout gets a one-line warning and nothing else. It never merges or rebases, whatever `pull.rebase` says. By default only checkouts that pulled, pushed, warned or failed are named, followed by the counts of repositories in sync, actions skipped by the user and bare repositories; `sync -v/--verbose`, or the global `-v`, adds the numbered per-checkout progress and the pull and push announcements. The global `-j` sets the fetch limit and `--json` is a usage error with `sync`. Exit status stays `1` whenever a checkout warned or failed. No version bump, release or tag.

### Change Summary

The commit `feat(cli): add the KI-TOOL-MGIT-CLI-020 safe parallel sync` rewrites `sync_command` in `bin/mgit` with a serial fetch-ownership prepass, a fetch worker on the runner and a serial action pass, and adds `--verbose` to sync's usage and Bash and Zsh completion; updates the existing sync Bats cases and adds three, for parallel fetch with ordered fast-forwards, failed fetches and detached heads, and one fetch per repository across tracked worktrees; and updates the manual, README, running-commands guide, MGIT-WS-018, MGIT-WS-022 and the changelog.

The preceding commit `test: make Bats assertions fatal under Bash 3.2` (`00ef0de`) was found while building: under Bash 3.2 a failing `[[ ]]` or `!` assertion in the middle of a Bats test did not fail it. It appends `|| false` to every such assertion and fixes the five latent assertions this exposed, none of which hid a product fault.

### Verification

`ki repo audit --repo .` passes with the existing HOOK-1 warning; `shellcheck`, `bash -n`, `mandoc -T lint` and `git diff --check` are clean; `bats tests/` passes 122 of 122. Run against the baseline `bin/mgit`, the ten updated or new sync cases fail. The diverged case sets `pull.rebase true` and checks that HEAD is unchanged and no rebase or merge state exists. All runs used disposable fixtures with local bare origins and isolated Git configuration.

### Outstanding concerns

Each is provisional, for Kris to confirm:

- **Interactive mode asks only for real actions.** `-i` now asks once per checkout that is behind or ahead, rather than asking to pull every clean tracking branch, because a branch can no longer be both.
- **Bare repositories are counted.** By default a bare repository is counted in the closing lines rather than named; it still makes the exit status `1`, and `--verbose` names it.
- **One fetch per repository and remote.** Under `-W`, linked worktrees of one repository share a single fetch, so concurrent fetches never race for its ref locks; a failed fetch is reported against every checkout that depended on it.
- **Pushes stay serial.** Pushes run in the main shell one at a time, where a credential prompt can still appear; only fetches are parallel and promptless.
- **A gone upstream is no upstream.** A branch whose upstream ref no longer exists is warned as having no upstream.
- **Global runner options.** The global `-v` and `-j` apply to sync; `--json` is rejected.

Human acceptance is outstanding.

### Post-change review

Fetching is the only parallel step and changes nothing but remote-tracking refs; every change to a branch or a remote happens afterwards in the main shell, one checkout at a time, after classification against freshly fetched refs, so no checkout is touched unless it is strictly behind or strictly ahead.

### Mini recap

Sync now fetches in parallel, fast-forwards or pushes only when that is safe, warns about the rest and stays quiet unless asked.

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

Adopted into Next and planned to Ready on 18 October 2026 by the ways-of-working mgit-build run, provisionally on Fable's opinion of 18 October (fable-opinion-2, option a), under Kris's KEEP-PUSHING and FABLE-OPINION answers. Building stops at Awaiting review, pure Bash with Bats fixtures only, with no release. Kris confirms or reverses the adoption and plan by editing this record. Fable's condition, build only if every test runs wholly in disposable fixtures, is met by the plan's local bare origins. Built to Awaiting review the same day; the choices in Outstanding concerns are provisional, for Kris to confirm.
