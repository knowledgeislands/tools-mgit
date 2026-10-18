---
id: KI-TOOL-MGIT-CLI-024
area: CLI
title: Quiet normal Git output
kind: deliver
purpose: capability
component: cli
status: done
blocks: []
blocked_by: []
baseline_ref: eb276dd0c57730fd2c6aee004b32151f4c88eea7
created_at: 2026-10-18T08:37:21Z
updated_at: 2026-10-18T18:18:51Z
---

## Goal

Commands that always print the same "nothing happened" output, such as `git status` on a clean, level branch, `git pull` saying "Already up to date." or `git push` saying "Everything up-to-date", count as quiet across the estate, so only checkouts where something actually happened are shown. mgit has no built-in rules: it learns what normal output looks like from the user's own estate, with `mgit learn <command>`, and keeps what it learned as readable, documented template files. The raw output is always one option away.

## Context

Kris's MGIT-QUIET-NORMAL answer of 18 October 2026 in the ways-of-working decisions log ("owner answers, batch 5") asks for standard no-change output to be treated as quiet. Kris's MGIT-QUIET-RULES and MGIT-QUIET-ROLLOUT answers in the same log ("owner answers, recap batch") replace the planned built-in pattern set with learning: no built-in rules, one template per command after alias resolution under `${XDG_CONFIG_HOME:-~/.config}/mgit/`, the built-in `st` rule moved out of code into a learned seed template, and seed templates learned only from read-only commands.

Under the shared runner of [KI-TOOL-MGIT-CLI-018](https://github.com/knowledgeislands/tools-mgit/blob/2ca3a8e/docs/roadmap/KI-TOOL-MGIT-CLI-018-estate-scale-output.md), `dispatch_captured` in `bin/mgit` counted a checkout as quiet only when it exited `0` with empty standard output and standard error, or, for `status` and its aliases, when porcelain status showed a clean, level branch. Git writes some no-change messages to standard error (`git push` writes "Everything up-to-date" there).

## Boundary

- **In:** `mgit learn <command...>` and `mgit --learn <command...>`, which run the Git command across the selected repositories as usual, replace each checkout's path, remote URL, upstream, remote, branch and repository name with placeholders, and write a template only when every repository's normalised output and exit status agree, otherwise naming the repositories that differed and writing nothing; `mgit learn --list` and `mgit learn --forget <command...>`; Git alias expansion so `st` and `status -sb` share one template; a template counts a checkout as quiet only on exit `0` with both streams matching exactly; removal of the built-in status rule; `-v/--verbose` and `-R/--raw` ignore templates and `--json` keeps `stdout` and `stderr` unfiltered with only its `quiet` flag changing; help, completion, manual, README, running-commands guide, MGIT-WS-025, MGIT-WS-026, changelog and Bats cases.
- **Out:** partial-output filtering (a checkout with any unmatched line is shown in full); matching on non-zero exits; any built-in template or pattern; a short flag for `--learn`, which waits on query MGIT-LEARN-FLAG; learning by running state-changing commands on the user's behalf; bringing `~/.config/mgit/` into the chezmoi source, which is ki.chezmoi's work; `sync`, which has its own result model; any change to the exit-status contract. No release.

## Current state

Delivered on 18 October 2026 by the ways-of-working mgit-learn run; awaiting Kris's review. The status-alias rule that landed earlier the same day under MGIT-ST-QUIET is gone from code; `mgit learn st` on a clean, level estate writes the template that now does its job.

## Steps

- [x] Replace the built-in status rule with template matching in `dispatch_worker`, applied on exit `0` only, after normalising the checkout's own details.
- [x] Add `learn`, `--learn`, `learn --list` and `learn --forget`, with alias resolution, readable percent-encoded file names, an atomic write and a documented template header.
- [x] Refuse learning with fewer than two repositories, on any failure, or when outputs differ; write nothing when every output is empty.
- [x] Document learning, the template format and the raw views; add Bats cases.
- [x] Run the complete gate.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `tests/territory-producer.bats`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes, in disposable fixtures with local bare origins and an isolated `XDG_CONFIG_HOME`: with no templates every checkout with output is shown; `mgit learn st` over two level checkouts with different branch names writes one template that later `mgit st` and `mgit status -sb` runs count as quiet; remote URLs, paths and repository names normalise; differing outputs are named and nothing is written; a learned standard-error message is quiet only while it matches; a failed checkout is never quiet; `--list` and `--forget` work; file names encode every argument; invalid learn options run nothing.

## Dependencies / blocks

None; it builds on the runner already on `main`. [KI-TOOL-MGIT-CLI-025](https://github.com/knowledgeislands/tools-mgit/blob/5d23dce/docs/roadmap/KI-TOOL-MGIT-CLI-025-escape-hatch-flag-names.md) landed in the same commit.

## Documentation impact

### Decision Records

None.

### Specifications

MGIT-WS-025 loses the built-in status rule; new MGIT-WS-026 specifies learned output templates.

### Guides

Running commands gains "Learn normal output" and describes the raw views.

### Roadmap

None.

## Review

### Delivered

Within the approved boundary, mgit has no built-in quiet rules: `mgit learn <command...>` and `mgit --learn <command...>` run a Git command across the selected repositories and write a template under `${XDG_CONFIG_HOME:-~/.config}/mgit/templates/` when every repository's normalised output agrees; later runs hide checkouts whose output matches. `mgit learn --list` and `mgit learn --forget` manage templates. The built-in status rule is removed. Excluded as planned: built-in templates, a short flag for `--learn`, learning by running state-changing commands, the chezmoi source and any release. Baseline `eb276dd0c57730fd2c6aee004b32151f4c88eea7`; the delivery commit follows it. [KI-TOOL-MGIT-CLI-025](https://github.com/knowledgeislands/tools-mgit/blob/5d23dce/docs/roadmap/KI-TOOL-MGIT-CLI-025-escape-hatch-flag-names.md)'s `-B/--bypass` amendment landed in the same commit.

### Change Summary

- `bin/mgit`: template functions (`template_dir`, `resolve_git_aliases`, `template_file`, `template_read`, `checkout_details`, `normalise_text`) replace the status-alias rule; `dispatch_worker` normalises each checkout's output and marks it quiet on an exact template match after exit `0`; `learn_verdict`, `learn_list` and `learn_forget`; `learn` and `--learn` parsing and validation; `repo_roots` recorded per checkout; usage, `mgit help learn`, Bash and Zsh completion.
- `tests/mgit.bats`: an isolated `XDG_CONFIG_HOME`; the two built-in status cases replaced by nine learning cases; a pass-through case given real output.
- `tests/territory-producer.bats`: the real NUL transport case runs with `-j 1`, fixing a parallel output-order race.
- `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md` ("Learn normal output"), `docs/specs/workspace-dispatch.md` (MGIT-WS-025 amended, MGIT-WS-026 new), `CHANGELOG.md`.

### Verification

- `MGIT_KI_PRODUCER=/opt/homebrew/bin/ki TMPDIR=<run temp> bats tests/`: 131 of 131 pass, none skipped, all in disposable fixtures with isolated HOME and XDG.
- `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `mandoc -T lint man/mgit.1`, `git diff --check`: pass.
- `ki repo audit --repo .`: pass (FAIL=0; warnings only for the missing committed pre-commit hook and non-fatal `[[ ]]` assertions in the territory suites, present at baseline).

### Outstanding concerns

- Seed templates live outside Git in `~/.config/mgit/templates/` on Kris's Mac until ki.chezmoi brings them into the chezmoi source (Messages line MGIT-CONFIG); Terra and Sol have none until then.
- Templates for `pull` and `push` are not seeded, because learning them means running them; Kris learns them on a normal run with `mgit learn pull` or `mgit --learn push`.
- A short flag for `--learn` waits on query MGIT-LEARN-FLAG.
- A template matches the whole output exactly, so a Git upgrade that rewords a message makes those checkouts loud again until relearned; that fails safe.

### Post-change review

The goal holds: a clean, level estate under `mgit st` prints nothing once `st` is learned, and any checkout whose output differs in any line, or that fails, is shown in full. Scope stayed inside the boundary plus the territory race fix found by the gate. Regression risk is moderate: until a template exists, commands that the old built-in rule hid (`status` on clean, level checkouts) now print, which is the intended no-built-in-rules behaviour. Ready for acceptance review.

### Mini recap

Replaced the built-in status rule with learned output templates, added `learn`, `--learn`, `--list` and `--forget`, and documented the template format; the full gate passes. Learning route proposed, not promoted: if templates prove brittle across Git versions, a later record could add line-level placeholders for counts and hashes.

## Done

Accepted 2026-10-18 by Kris Brown on the review packet above.

## Discussion

### Superseded plan

The record was first captured with a conservative built-in pattern set (`pull`, `push` and `merge` no-change messages) and questions about locale, configuration home and a raw view. MGIT-QUIET-RULES replaced it with learning: no built-in rules, so locale is whatever the user's Git prints when they learn, the configuration home is `${XDG_CONFIG_HOME:-~/.config}/mgit/templates/`, and `-v` plus unfiltered `--json` are the raw views.

### Adoption

Captured and adopted into Next on 18 October 2026 by the ways-of-working accept-mgit run, under Kris's MGIT-QUIET-NORMAL answer. Not planned.

### Acceptance

Accepted on 18 October 2026 by the `accept-prune` run of the ways-of-working Project work, under Kris Brown's standing grant recorded in the ki-principal ways-of-working decisions log, entry "2026-10-18 17:59 BST - owner answers, recap batch" (ACCEPT-AND-PRUNE): "I think anything which is awaiting acceptance can be accepted, and then we can prune anything which is in a state of done". Re-check against `main` at `5d23dce` before closure: `bats tests/` passes 131 of 131 in disposable fixtures; `shellcheck`, `bash -n` and `mandoc -T lint` pass; `ki repo audit --repo .` has no failure. The short-flag concern is settled: Kris answered MGIT-LEARN-FLAG a) at 18:04 BST, learning stays the subcommand `mgit learn <command>` with no short flag, and `-L` and `-P` keep their symbolic-link meanings.
