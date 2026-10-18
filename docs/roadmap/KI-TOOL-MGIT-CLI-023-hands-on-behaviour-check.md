---
id: KI-TOOL-MGIT-CLI-023
area: CLI
title: Hands-on behaviour check
kind: audit
purpose: corrective
component: cli
horizon: next
status: draft
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-18T08:37:21Z
updated_at: 2026-10-18T18:18:51Z
---

## Goal

Kris uses the new runner, sync, overview and escape-hatch behaviour on his own estate and confirms it works the way he wants, and anything he finds wrong or unwelcome is put right here.

## Context

Kris accepted [KI-TOOL-MGIT-CLI-018](https://github.com/knowledgeislands/tools-mgit/blob/2ca3a8e/docs/roadmap/KI-TOOL-MGIT-CLI-018-estate-scale-output.md), [KI-TOOL-MGIT-CLI-019](https://github.com/knowledgeislands/tools-mgit/blob/2ca3a8e/docs/roadmap/KI-TOOL-MGIT-CLI-019-pass-through-escape-hatch.md), [KI-TOOL-MGIT-CLI-020](https://github.com/knowledgeislands/tools-mgit/blob/2ca3a8e/docs/roadmap/KI-TOOL-MGIT-CLI-020-safe-parallel-sync.md), [KI-TOOL-MGIT-CLI-021](https://github.com/knowledgeislands/tools-mgit/blob/2ca3a8e/docs/roadmap/KI-TOOL-MGIT-CLI-021-estate-overview.md) and [KI-TOOL-MGIT-CLI-022](https://github.com/knowledgeislands/tools-mgit/blob/2ca3a8e/docs/roadmap/KI-TOOL-MGIT-CLI-022-external-member-review-findings.md) as built on 18 October 2026, in the ways-of-working decisions log ("owner answers, batch 5"): "I think there's a bunch of probably checks for me to do on Mgate by the looks of things. But as it is, we accept what's there basically, and then anything else I come back with, we can do remedial work with maybe we can have a single roadmap item that's left for MGear, which is to check the behaviors or something like that, so we can accept everything." ("Mgate" and "MGear" are speech-to-text for mgit.)

Every build was verified only in disposable Bats fixtures; none has run against the real estate. On this Mac, `~/.local/bin/mgit` is a symlink to this checkout's `bin/mgit`, so the new behaviour is already live there while it still reports version 0.17.0; other machines see it only after a release.

This record also carries the open concern of [KI-TOOL-MGIT-CLI-017](https://github.com/knowledgeislands/tools-mgit/blob/ff7f44e/docs/roadmap/KI-TOOL-MGIT-CLI-017-unified-external-members.md), folded here on 18 October 2026 under Kris's PRUNE-HELD a) answer: mgit v0.17.0 and earlier reject a manifest with external members as unsafe, so the chezmoi-managed consumer manifest `workspaces/personal/dot_mgit.toml` gains the dotfiles checkout as an external member only after a release carrying unified members reaches every machine that applies it. When that release has landed, the hands-on check confirms it and hands the manifest change to the chezmoi work for Kris's `chezmoi diff` review.

## Boundary

- **In:** Kris's hands-on use of ordinary pass-through output and the quiet count, `-j/--jobs`, `-v/--verbose`, `--json`, the progress line, `mgit sync` (parallel fetch, fast-forward, push and warnings), `mgit overview`, `-G/--git` and `-R/--raw`, and the provisional choices each record listed under Outstanding concerns; remedial fixes for what he reports, with Bats cases.
- **Out:** the separately captured follow-ons, [KI-TOOL-MGIT-CLI-024](https://github.com/knowledgeislands/tools-mgit/blob/c4da60c/docs/roadmap/KI-TOOL-MGIT-CLI-024-quiet-normal-git-output.md) (normal no-change output as quiet), [KI-TOOL-MGIT-CLI-025](https://github.com/knowledgeislands/tools-mgit/blob/5d23dce/docs/roadmap/KI-TOOL-MGIT-CLI-025-escape-hatch-flag-names.md) (flag names) and [KI-TOOL-MGIT-CLI-026](KI-TOOL-MGIT-CLI-026-sync-conflict-precheck.md) (conflict precheck); a release, which follows [Release mgit](../guides/developer/releasing.md) under its own authority; any agent-run sync against the real estate.

## Current state

The five records are done and their code is on `main`. No finding has been reported yet.

## Steps

- [ ] Kris uses the behaviour on his estate and reports findings.
- [ ] Record each finding under Remedial findings with its disposition: fix here, capture separately, or keep as is.
- [ ] Plan the fixes to Ready with `ki-plan`, then build them with Bats cases in disposable fixtures.

## Files touched

Depends on the findings; likely `bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes, and Kris confirms each fixed finding by hand.

## Dependencies / blocks

Waits on Kris's hands-on use; nothing in this repository blocks it.

## Documentation impact

### Decision Records

None expected.

### Specifications

Any behaviour a fix changes in the workspace-dispatch specification.

### Guides

Running commands, where a fix changes what users see.

### Roadmap

Findings outside this boundary become their own records.

## Discussion

### What to check

The provisional choices accepted as built, each worth a deliberate look:

- **Runner (-018):** captured output loses colour; interactive commands such as `mgit commit` without `-m` fail unless `-v`; the closing line goes to standard output; a checkout without an upstream is never quiet; the oldest worker gates the pool.
- **Escape hatch (-019):** `-G help` reaches Git while `-G -h` shows mgit help; `-B` warns at dispatch.
- **Sync (-020):** interactive mode asks only for real actions; bare repositories are counted, not named; one fetch per repository and remote under `-W`; pushes stay serial; a gone upstream counts as no upstream.
- **Overview (-021):** no upstream counts as attention; obsolete branches print on indented lines; in-use branches are never obsolete; `-W` reports once per repository.
- **Member findings (-022):** a missing inward path reports as missing; the `register add --repo` hint is relative to the manifest.

### Remedial findings

None yet. Record each finding Kris reports here, with its disposition, before planning.

### Adoption

Captured and adopted into Next on 18 October 2026 by the ways-of-working accept-mgit run, under Kris's MGIT-BEHAVIOUR-CHECK answer in the same batch. Not planned; planning waits for Kris's findings.
