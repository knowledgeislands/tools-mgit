---
id: KI-TOOL-MGIT-CLI-029
area: CLI
title: CLI convention departures
kind: deliver
purpose: debt
project: tools-burndown
component: cli
priority: medium
size: m
horizon: now
status: awaiting-review
blocks: []
blocked_by: []
baseline_ref: 4dff1a4a90e26a2e648c9386d1f65c381d8a615e
created_at: 2026-10-19T18:26:00Z
updated_at: 2026-10-20T00:00:00Z
---

# CLI Convention Departures

## Goal

mgit's option parsing follows the `ki-repo-tools` [command-line conventions](/Users/krisbrown/.local/share/ki/harnesses/knowledgeislands/ki-agentic-harness/skills/repo-structure/ki-repo-tools/references/standards-cli-conventions.md) in the four places it departs from them today, so `--jobs=2`, `-j2`, `-vW`, `-n` and `worktree remove -f` work as a user of other conventional tools expects.

## Context

[KI-HARNESS-GOV-218](/Users/krisbrown/workspaces/knowledge-islands/ki-agentic-harness/docs/roadmap/KI-HARNESS-GOV-218-cli-conventions.md) audited the house tools against the command-line conventions. Kris decided on 18 October 2026, CLI-DEPARTURES a) in the [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md) ("CLI-DEPARTURES"), that each departure is recorded on the record owning the command, as a fix for the tool's next change, not built at once. For mgit that record was [KI-TOOL-MGIT-CLI-023](KI-TOOL-MGIT-CLI-023-hands-on-behaviour-check.md), whose Remedial findings hold the finding. That record is Awaiting review and will be pruned after acceptance, so the finding moves here under the coordinator's MGIT-DEPARTURES-HOME a) answer of 19 October 2026.

mgit departs in four ways:

- `-j/--jobs` takes its value only as a separate word, so `--jobs=2` and `-j2` are refused.
- Short options without arguments do not group, so `-vW` is refused where it should mean `-v -W`.
- `--dry-run` has no `-n` short letter.
- `worktree remove --force` has no `-f` short letter, which the CLI-F-FILTER fix on KI-TOOL-MGIT-CLI-023 left free for force.

`-f, --filter` is not a departure: under CLI-F-FILTER `-f` is a usage error at the top level, and `--filter` keeps no short letter.

## Boundary

- **In:** the four fixes above in `bin/mgit`, each with its Bats case in disposable fixtures, and the matching help, Bash and Zsh completion, manual, user guide, specification and changelog updates.
- **Out:** a top-level `-f` for `--filter`; other departures the conventions might later name; other tools' departures, which live on their own records.

## Shaping

**Approach:** one shared argument pre-pass, `split_options`, run before each of mgit's own option loops, expands short groups, attached short values and `--name=value` into separate words, so each option keeps the one parsing path it has today; then `-n` for `--dry-run` and `-f` for `worktree remove --force`, each with its Bats case, help, completion, manual, guide, specification and changelog change.

**Dependencies:** none. [KI-TOOL-MGIT-CLI-030](KI-TOOL-MGIT-CLI-030-sync-closing-summary.md) is delivered without `sync --json`, so it adds no option to the loops this record touches.

**Decisions still needed:** none; the three planning questions are decided in Planning.

**Readiness:** Ready.

## Current state

The top-level loop in [`bin/mgit`](../../bin/mgit) stops at the first word that is not an option, which is the command, and everything after it goes to Git or the named mgit command. Its value options are `-t/--territory`, `--filter` and `-j/--jobs`, each taking only the next word; its flags are `-P`, `-L`, `-B`, `-R`, `-W`, `-I`, `-v`, `-h` and `-V` and the long-only `--learn`, `--json`, `--estate` and `--principals`, and it gives removed letters (`-G`, `-a`, `-f`) their own messages. mgit's own commands parse their options in their own loops, any order with operands:

- `register`: flags `--dry-run`, `-h`; values `-t/--territory`, `--repo`; removed `-a`.
- `structure standard` and `structure nested`: flags `--dry-run`, `-h`.
- `worktree add`: flag `-h`. `worktree remove`: flags `--force`, `-h`.
- `sync`: flags `-i`, `-v`, `-h`. `overview`: flags `--json`, `-v`, `-h`; value `--stale-days`.
- `doctor`: `-h`. `diag`: `--full`, `-h`. `repair`: `--apply`, `-h`.

`learn` and `completion` take a command or shell word, not options to group. Only `register` and `structure` have `--dry-run`, and neither passes arguments to Git.

## Steps

- [x] Add `split_options` to `bin/mgit`: given a mode, the short flag letters, the short value letters and the long value options, it rewrites the words into `split_args`. A short group expands letter by letter; a value letter takes the rest of the word as its value, or the next word whole when it ends the group; a letter that is neither is passed on as its own `-x`, so the existing loop names it. `--name=value` splits for a long value option and is passed on unchanged otherwise, so the loop refuses it. `--` and every word after it pass through untouched; in top-level mode so does the first word that is not an option, with everything after it, so pass-through arguments are never rewritten.
- [x] Run it before the top-level loop and before the loops of `register`, `structure standard`, `structure nested`, `worktree add`, `worktree remove`, `sync`, `overview`, `doctor`, `diag` and `repair`.
- [x] Add `-n` as the short form of `--dry-run` on `register` and both `structure` forms, and `-f` as the short form of `--force` on `worktree remove`.
- [x] Bats cases in disposable fixtures: `--jobs=2`, `-j2` and `-vj2` run as `-j 2`; `-vW` as `-v -W`; `-jv` refused as a non-numeric job count; `--verbose=x` refused; `mgit -v log -n1 --format=%s` passes `-n1` and `--format=%s` to Git unchanged; `--filter=PREFIX` and `-tHANDLE` select as their separate forms; `sync -iv`; `overview --stale-days=N`; `register -n`; `structure standard -n` and `structure nested -n`; `worktree remove -f` on a dirty worktree.
- [x] Update the usage text of the four touched commands, the Bash and Zsh completions, `man/mgit.1`, the running-commands, repository-sets and worktrees guides, a new option-syntax requirement in `docs/specs/workspace-dispatch.md`, MGIT-WS-021's `-n` wording, and `CHANGELOG.md`.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `docs/specs/workspace-dispatch.md`, `docs/guides/user/running-commands.md`, `docs/guides/user/repository-sets.md`, `docs/guides/user/worktrees.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes: `shellcheck bin/mgit install.sh`, `bash -n`, `bats tests/`, `mandoc -T lint man/mgit.1`, `rumdl check` and `git diff --check`. The new Bats cases show each attached, grouped and short form behaves as its separate long form, and that arguments after the command reach Git unchanged.

## Dependencies / blocks

None. Blocks nothing. It does not block the v0.18.0 release.

## Documentation impact

### Decision Records

None: the change brings mgit into line with the `ki-repo-tools` conventions, so no departure remains to record.

### Specifications

A new requirement in `docs/specs/workspace-dispatch.md` states the option syntax mgit accepts and that pass-through arguments are never rewritten; MGIT-WS-021 names `-n`.

### Guides

The running-commands guide gains the option syntax; the repository-sets and worktrees guides mention `-n` and `-f` where they show `--dry-run` and `--force`.

### Roadmap

None.

## Review

### Delivered

Within the approved boundary, from baseline `4dff1a4`: one shared pre-pass, `split_options`, runs before the global option loop and before the loops of `register`, `structure standard`, `structure nested`, `worktree add`, `worktree remove`, `sync`, `overview`, `doctor`, `diag` and `repair`. Short options group, short values attach, a value letter takes the rest of its group, and `--name=value` splits for value options. Global parsing stops at the command word, so pass-through words are never rewritten. `-n` is the short form of `--dry-run` on `register` and both `structure` forms, and `-f` of `--force` on `worktree remove`. No top-level `-f` and no other departure was added.

### Change Summary

`bin/mgit`: `split_options` and its eleven call sites, the `-n` and `-f` cases, the `structure` mode fixed to `--dry-run` whichever form is given, a usage note on option syntax, the four usage lines, and the Bash and Zsh completions (`-n`, `-f`, and `_arguments -s` for the commands with short flags). `tests/mgit.bats`: two new cases, grouped and attached forms and untouched pass-through words, and short or attached forms added to the existing `sync -i`, `overview --stale-days`, `register` dry-run, both `structure` and `worktree remove` cases; the completion and `-f`-filter assertions follow the new letters. MGIT-WS-027 is new and MGIT-WS-021 names `-n` in `docs/specs/workspace-dispatch.md`; `man/mgit.1`, `README.md`, the running-commands, repository-sets and worktrees guides and `CHANGELOG.md` describe the forms. A small audit fix rode along: the manual said `register` accepts the retired `-a` as its saved-location shorthand, now `-t`.

### Verification

`ki repo audit --repo .` FAIL=0, its two warnings unrelated (`.rumdl.toml` template drift, Claude Desktop binding); `shellcheck bin/mgit install.sh`, `bash -n`, `mandoc -T lint man/mgit.1`, `rumdl check .` and `git diff --check` pass; `bats tests/` with `MGIT_KI_PRODUCER` naming the local `ki` and `TMPDIR` in the run's temporary directory: 141 passed, none failed or skipped, the one completion assertion updated after the first run.

### Outstanding concerns

A word after a subcommand that starts with a hyphen is now split as options, so `worktree remove -odd-path` is refused letter by letter rather than whole; `--` before such a path still works. The spec area's preamble excludes structure and worktree mutation, yet MGIT-WS-027 names their `-n` and `-f`, as the only option-syntax home.

### Post-change review

The goal is met: `--jobs=2`, `-j2`, `-vW`, `-n` and `worktree remove -f` work as conventional tools do, every form shares its separate form's parsing path and messages, and Git's own `-n` after the command is untouched. Ready for acceptance.

### Mini recap

One option pre-pass for all of mgit's own options, two short letters added, no departures left on the conventions. No learning to route.

## Discussion

Origin: KI-TOOL-MGIT-CLI-023's CLI-DEPARTURES finding, homed here before that record is pruned. Capture only; adoption, horizon and plan belong to this repository.

Planning questions: whether grouping and attached values are handled by one shared pre-pass over the arguments, which would also cover `-t` and other value options, or per option; how `-n` interacts with commands that pass arguments through to Git, where `-n` already has meanings; and whether `-vW` grouping must reject a grouped option that takes a value in the middle of the group. `size: m` is provisional: the grouping pre-pass is the bulk of the work and the three other fixes are small.

### Adoption

Adopted into Soon on 19 October 2026 by the tools-burndown trimga run, under Kris's instruction of 19 October 2026, 23:21 BST, in the [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md): "There are 23 tickets across triage for the tool projects, can we get those triaged immediately?" Not planned. `priority: medium` and `size: m` kept from capture.

### Planning

Promoted from Soon to Next and planned to Ready on 20 October 2026 by the tools-burndown burnmgit run, under Kris's TO-DONE instruction of 20 October 2026, 00:20 BST, in the [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md), which lifts every hold whose condition no longer holds; the promotion condition was answering the three questions at planning. Decided under HIGH-APPLY, 20 October:

- **One pre-pass.** A shared `split_options` before each existing loop, not per-option handling: one rule for every value option (`-t`, `-j`, `--filter`, `--repo`, `--stale-days`) and every command, while each option keeps one parsing path and its existing messages.
- **Where `-n` is claimed.** Only on `register` and `structure`, the commands with `--dry-run`. Never at the top level, and never after the command word of ordinary dispatch, `-B`, `-R` or `learn`, where the words belong to Git or the named command; the pre-pass stops at the command word so `git log -n5` and its kin are untouched.
- **A value option inside a group.** As POSIX `getopt` and the conventions do: the value letter takes the rest of the word as its value, so `-vj2` means `-v -j 2`, and `-jv` gives `-j` the value `v`, which `--jobs` then refuses as not a positive whole number. A value letter ending the group takes the next word.

Sync is done: [KI-TOOL-MGIT-CLI-030](KI-TOOL-MGIT-CLI-030-sync-closing-summary.md) applied SYNC-STREAMS b) on 20 October, so `sync` now puts skip, warning, progress and prompt lines on standard error and needs no stream departure here.
