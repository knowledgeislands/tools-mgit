---
id: KI-TOOL-MGIT-CLI-020
area: CLI
title: Safe parallel sync
status: triage
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-18T04:10:00Z
updated_at: 2026-10-18T04:10:00Z
---

## Goal

Make `mgit sync` fast and quiet across the estate: fetch every selected repository in parallel, classify each one, act only where the action is safe, and warn without touching anything else.

## Context

Kris, 17 October 2026: "I like a sync that's a better syncing than it is at the minute, because essentially it steps through every single one of them." Earlier the same day, captured in [KI-TOOL-MGIT-CLI-018](KI-TOOL-MGIT-CLI-018-estate-scale-output.md): "if pulls and gets rebase or merge warning, it should effectively automatically abort and give me warning instead".

Today `sync` visits repositories one at a time. Each clean tracking branch runs `git pull --ff-only`, then `git push` when commits remain ahead; a checkout with local changes prints `git status --short` and is skipped. See [Run commands across repositories](../guides/user/running-commands.md).

The tools-burndown roadmap overview of 17 October proposed this record as part of an mgit plan; the tools-burndown run of 18 October captured it under that plan's MGIT-RECORDS a), provisional for Kris to confirm.

## Boundary

This capture does not adopt, schedule, implement or release anything. It does not change the repository-selection boundary or `.mgit.toml` model. It depends on the shared runner in [KI-TOOL-MGIT-CLI-018](KI-TOOL-MGIT-CLI-018-estate-scale-output.md).

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
