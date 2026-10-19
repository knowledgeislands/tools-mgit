---
id: KI-TOOL-MGIT-CLI-023
area: CLI
title: Hands-on behaviour check
kind: audit
purpose: corrective
component: cli
status: done
blocks: []
blocked_by: []
baseline_ref: 713bc3618c48136fc88f7277c8df6512cceb4e02
created_at: 2026-10-18T08:37:21Z
updated_at: 2026-10-19T20:40:12Z
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

The five records are done and their code is on `main`. One finding, the `--filter` short letter, is fixed. Kris ran the hands-on check on 19 October 2026 and it passed with no further findings.

## Steps

- [x] Kris uses the behaviour on his estate and reports findings.
- [x] Record each finding under Remedial findings with its disposition: fix here, capture separately, or keep as is.
- [x] Plan the fixes to Ready with `ki-plan`, then build them with Bats cases in disposable fixtures. The one fix, the `--filter` short letter, was built in `781973e`; the passed check raised nothing more to plan.

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

## Review

### Delivered

Within the boundary, Kris used the runner, sync, overview and escape-hatch behaviour on his own estate and the check passed: Kris, 19 October 2026, in the [ways-of-working decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.ways-of-working/decisions.md) ("owner answers, push, mgit check, DESK-CAM"): "pushed, mgit checked", read back as MGIT-RELEASE a) now due because the hands-on check passed. The check raised no finding beyond the two already recorded under Remedial findings. Excluded as planned: the release, which follows [Release mgit](../guides/developer/releasing.md) under its own authority, and any agent-run sync against the real estate. Baseline `713bc3618c48136fc88f7277c8df6512cceb4e02`.

### Change Summary

- This record only: the check recorded as passed, its steps completed, and this review. No code changed; the one remedial fix, the `--filter` short letter, landed earlier in `781973e`.
- Approved deviation: the record goes from `draft` to `awaiting-review` without a separate Ready step, because the passed check left nothing to plan or build; the tools-burndown mgitrel run brief, under MGIT-RELEASE a), authorises recording the check and bringing the record to Awaiting review.

### Verification

- Kris's hands-on check on his estate: passed, 19 October 2026.
- `MGIT_KI_PRODUCER=<ki> TMPDIR=<run temp> bats tests/` under macOS Bash 3.2: 135 of 135 pass, none skipped.
- `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `mandoc -T lint man/mgit.1`, `git diff --check`: pass.
- `ki repo audit --repo .`: FAIL=0, the same 7 warnings as at baseline.

### Outstanding concerns

- **Command-line convention departures.** The CLI-DEPARTURES finding under Remedial findings is a fix for mgit's next change and is not built: `-j/--jobs` refuses `--jobs=2` and `-j2`, short options do not group, `--dry-run` lacks `-n`, and `worktree remove --force` lacks `-f`. It is captured as triage in [KI-TOOL-MGIT-CLI-029](KI-TOOL-MGIT-CLI-029-cli-convention-departures.md), its home once this record is pruned.
- **External members in the consumer manifest (from KI-TOOL-MGIT-CLI-017).** The chezmoi-managed `workspaces/personal/dot_mgit.toml` gains the dotfiles checkout as an external member only after a release carrying unified members reaches every machine that applies it. That release is prepared but not cut; the manifest change follows it as CONSUMER-MIGRATE, the chezmoi work's, for Kris's `chezmoi diff` review.

### Post-change review

The goal holds: Kris has used the behaviour on his estate and confirmed it works the way he wants, and the one finding he raised for a fix here is built. Scope held: nothing was built beyond the earlier `--filter` fix. No regression risk from this change, which touches only the record. Ready for acceptance review once the convention-departure finding has a home.

### Mini recap

Recorded Kris's passed hands-on check of mgit's runner, sync, overview and escape-hatch behaviour and brought the record to Awaiting review. Two concerns carry forward: the convention departures need their own record before pruning, and the consumer-manifest migration follows the release.

## Done

Accepted 2026-10-19 by Kris Brown on the review packet above.

### Acceptance

Accepted on 19 October 2026 by the tools-burndown `mgitgo` run, under Kris Brown's answer of 19 October 2026 at 21:34 BST in the ki-principal [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md) ("Summary of 21:28 answered"): "All recommended", taken as BURNDOWN-ACCEPT a) and MGIT-GO a), "accept KI-TOOL-MGIT-CLI-028 and KI-TOOL-MGIT-CLI-023 and publish mgit `v0.18.0` on `9a3564d`". Re-check against `main` at `bfa9a82` before closure: `MGIT_KI_PRODUCER=<ki> bats tests/` passes 135 of 135 with none skipped in disposable fixtures; `shellcheck`, `bash -n`, `mandoc -T lint` and `git diff --check` pass; `ki repo audit --repo .` has no failure. The two outstanding concerns have homes: the command-line convention departures are captured in [KI-TOOL-MGIT-CLI-029](KI-TOOL-MGIT-CLI-029-cli-convention-departures.md), and the consumer-manifest migration follows the v0.18.0 release as CONSUMER-MIGRATE in the chezmoi work.

## Discussion

### What to check

The provisional choices accepted as built, each worth a deliberate look:

- **Runner (-018):** captured output loses colour; interactive commands such as `mgit commit` without `-m` fail unless `-v`; the closing line goes to standard output; a checkout without an upstream is never quiet; the oldest worker gates the pool.
- **Escape hatch (-019):** `-G help` reaches Git while `-G -h` shows mgit help; `-B` warns at dispatch.
- **Sync (-020):** interactive mode asks only for real actions; bare repositories are counted, not named; one fetch per repository and remote under `-W`; pushes stay serial; a gone upstream counts as no upstream.
- **Overview (-021):** no upstream counts as attention; obsolete branches print on indented lines; in-use branches are never obsolete; `-W` reports once per repository.
- **Member findings (-022):** a missing inward path reports as missing; the `register add --repo` hint is relative to the manifest.

### Remedial findings

Record each finding Kris reports here, with its disposition, before planning.

- **No short letter for `--filter` (fixed here).** Kris, 18 October 2026, CLI-F-FILTER c) in the [ways-of-working decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.ways-of-working/decisions.md) ("owner answer, CLI-F-FILTER; mark"): "I'm thinking we just go with `--filter` and no short version". `--filter` is unchanged; `-f` is a status-`2` usage error that names `--filter` and runs nothing, as `-G` was handled, leaving `-f` free for force or file. Help, Bash and Zsh completions, manual, README, guides, the MGIT-WS-009 specification and the changelog are updated, with the Bats case `-f is not a short filter and runs nothing`; the house form is recorded in the `ki-repo-tools` command-line conventions. The flag-name record this would have joined, [KI-TOOL-MGIT-CLI-025](https://github.com/knowledgeislands/tools-mgit/blob/5d23dce/docs/roadmap/KI-TOOL-MGIT-CLI-025-escape-hatch-flag-names.md), is already pruned.
- **Command-line convention departures (fix at mgit's next change).** Kris, 18 October 2026, CLI-DEPARTURES a) in the [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md) ("CLI-DEPARTURES"): each departure from the `ki-repo-tools` [command-line conventions](/Users/krisbrown/.local/share/ki/harnesses/knowledgeislands/ki-agentic-harness/skills/repo-structure/ki-repo-tools/references/standards-cli-conventions.md) found by [KI-HARNESS-GOV-218](/Users/krisbrown/workspaces/knowledge-islands/ki-agentic-harness/docs/roadmap/KI-HARNESS-GOV-218-cli-conventions.md) is recorded on the record owning the command, as a fix for the tool's next change, not built now. mgit departs three ways: `-j/--jobs` takes its value only as a separate word, so `--jobs=2` and `-j2` are refused, and short options without arguments do not group, so `-vW` is refused where it should mean `-v -W`; `--dry-run` has no `-n` short letter; and `worktree remove --force` has no `-f` short letter, which the CLI-F-FILTER fix above left free for force. `-f, --filter` is not a departure under CLI-F-FILTER. Each fix carries its Bats case and the help, completion, manual and changelog updates.

### Adoption

Captured and adopted into Next on 18 October 2026 by the ways-of-working accept-mgit run, under Kris's MGIT-BEHAVIOUR-CHECK answer in the same batch. Not planned; planning waits for Kris's findings.
