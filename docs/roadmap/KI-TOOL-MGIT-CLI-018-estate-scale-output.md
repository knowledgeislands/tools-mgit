---
id: KI-TOOL-MGIT-CLI-018
area: CLI
title: Estate-scale output
kind: deliver
purpose: capability
component: cli
status: done
blocks: []
blocked_by: []
baseline_ref: b8e591181c7e60f5f52e8a8a25c132bcb12cbea9
created_at: 2026-10-17T21:31:16Z
updated_at: 2026-10-18T08:38:21Z
---

## Goal

Give `mgit` one shared runner and output layer that every multi-repository command uses: a bounded parallel worker pool, progress while it runs, then a concise end-of-run result that names only the repositories that need attention, with `--verbose` and `--json` alternatives.

## Context

Owner request, 17 October 2026, in Kris's words: "I really want MGIT have much better output ... if I do MGIT status over entire estate, because there's like 50 projects, it scrolls off screen ... I really, really want this kind idea it giving me progress bar ... and then it gives me results end ... anything got no changes, it doesn't tell me about it, it only tells me ... ones that changed ... sync could be way try out first ... if pulls and gets rebase or merge warning, it should effectively automatically abort and give me warning instead ... some this might better off done like we did with Git Almanac, so we can put some code behind it".

Today ordinary pass-through commands such as `mgit status` print a header and Git's full output for every checkout, so a 54-repository estate scrolls off screen. `mgit sync` already names only repositories that pulled, pushed or failed and counts the current ones, and pulls with `--ff-only`, so divergence already fails without a merge or rebase; its per-repository `pulling` lines and Git's detail still stream as it runs. See [Run commands across repositories](../guides/user/running-commands.md).

The reference approach is [Git Almanac](https://github.com/knowledgeislands/tools-git-almanac), a TypeScript/Bun tool that separates a Git adapter, a core model and terminal, JSON and HTML renderers.

## Boundary

- **In:** one shared runner in `bin/mgit`: a bounded worker pool (`-j/--jobs N`, default 8), captured per-checkout results in a private temporary directory, a single progress line on stderr when stderr is a terminal, and results rendered in selection order once every worker finishes. Ordinary Git pass-through and direct-command dispatch move onto it, as does the `overview` collector from [KI-TOOL-MGIT-CLI-021](KI-TOOL-MGIT-CLI-021-estate-overview.md). Checkouts with nothing to report collapse into one count; `status` counts as quiet when the working tree is clean and level with its upstream. Global `-v/--verbose` restores today's streaming, serial, every-checkout output, and global `--json` prints pass-through results as one document.
- **Out:** `sync`, which [KI-TOOL-MGIT-CLI-020](KI-TOOL-MGIT-CLI-020-safe-parallel-sync.md) moves onto the runner; the escape-hatch names of [KI-TOOL-MGIT-CLI-019](KI-TOOL-MGIT-CLI-019-pass-through-escape-hatch.md); TypeScript, Bun or any new runtime dependency; any change to repository selection, the `.mgit.toml` model or the exit-status contract (status `1` when any checkout fails). No release.

## Current state

Pass-through and `-B` dispatch run one checkout at a time in the main loop at the end of `bin/mgit`, streaming a bold header and the child's output for every checkout, and return `1` if any child failed. Nothing is captured, so a 54-repository `mgit status` scrolls off screen. `overview` (KI-TOOL-MGIT-CLI-021) runs its collector serially. Bash 3.2 has no `wait -n`.

## Steps

- [x] Add the runner: launch one background worker per checkout up to the job limit, freeing a slot by waiting on the oldest running worker; each worker runs with stdin from `/dev/null`, `GIT_TERMINAL_PROMPT=0` and `GIT_EDITOR`/`GIT_SEQUENCE_EDITOR` set to `false`, so nothing interactive can hang or proceed unseen, and writes its stdout, stderr and exit status to files in a private `mktemp -d` directory removed on exit or interrupt.
- [x] Draw one progress line on stderr only when stderr is a terminal, `[#####-----] 27/54 label`, and clear it before results print.
- [x] Add global `-j/--jobs N` (positive integer) and `-v/--verbose`, and global `--json` for pass-through, each rejected as a usage error where it does not apply.
- [x] Render pass-through results in selection order: a checkout with output or a non-zero status prints its header and captured output as today; a checkout with exit `0` and no output, or a quiet `git status`, counts only; then one summary line, naming each failed checkout with its exit status. Exit `1` when any failed.
- [x] Keep `-v/--verbose` byte-for-byte today's serial streaming dispatch.
- [x] Move the `overview` collector onto the runner.
- [x] Add Bats cases: results in selection order under parallel workers, quiet collapse and count, the `status` quiet rule, failure naming and exit status, `-j` validation and `-j 1`, verbose streaming, JSON shape, no progress when stderr is not a terminal, editor and prompt guards, and overview under the pool.
- [x] Update help, manual, completion, README, running-commands guide, workspace-dispatch specification and changelog.
- [x] Run the complete gate.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes: `ki repo audit --repo .`, `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `bats tests/`, `mandoc -T lint man/mgit.1` and `git diff --check`, all in disposable fixtures.

## Dependencies / blocks

Blocks [KI-TOOL-MGIT-CLI-020](KI-TOOL-MGIT-CLI-020-safe-parallel-sync.md), which builds sync on this runner. Builds after [KI-TOOL-MGIT-CLI-021](KI-TOOL-MGIT-CLI-021-estate-overview.md) in the agreed order, so it adopts that collector rather than waiting for it.

## Documentation impact

### Decision Records

None. The route keeps the pure-Bash rule [AGENTS.md](../../AGENTS.md) already sets and borrows only Git Almanac's adapter, model and renderer separation; moving to TypeScript/Bun would need a Decision Record, and is not taken.

### Specifications

MGIT-WS-013, MGIT-WS-014, MGIT-WS-019, MGIT-WS-020 and MGIT-WS-022 change to the captured, summarised dispatch with the verbose escape and the new global options.

### Guides

Running commands describes progress, the quiet count, `--verbose`, `--jobs` and `--json`, and that interactive commands need `--verbose`.

### Roadmap

Unblocks KI-TOOL-MGIT-CLI-020.

## Review

### Delivered

From the Ready baseline `b8e5911`, ordinary Git and `-B` dispatch run on one shared runner in `bin/mgit`: a pool of at most `-j/--jobs N` background workers (default 8) that frees a slot by waiting on the oldest worker, since Bash 3.2 has no `wait -n`. Each worker runs with standard input from `/dev/null`, `GIT_TERMINAL_PROMPT=0` and `GIT_EDITOR`/`GIT_SEQUENCE_EDITOR` set to `false`, and writes its output and exit status to a private `mktemp -d` directory that is removed on exit, interrupt (status `130`) or termination (status `143`). One progress line, `[#####-----] 2/4 label`, is drawn on standard error only when it is a terminal. When every worker has finished, checkouts with output or a failure print today's header and captured output in selection order; the rest count as quiet, and any `git status` is quiet exactly when the checkout has no change entries and is level with an upstream. A closing line such as `mgit: 4 repositories: 2 quiet, 1 with output, 1 failed: c (exit 3)` follows, and the exit status stays `1` when any checkout fails. Global `-v/--verbose` runs today's serial streaming loop unchanged, and global `--json` prints one document. `overview` collection runs on the same pool, with its rendering unchanged, and takes the global `-v` and `--json` as its own options. The runner options are a usage error for listing, `sync`, `structure`, `worktree` and the management commands. No version bump, release or tag.

### Change Summary

The commit `feat(cli): add the KI-TOOL-MGIT-CLI-018 shared runner` adds the runner, progress line, captured and streaming dispatch, JSON output, the global `-j/--jobs`, `-v/--verbose` and `--json` options with their rejections, usage text and Bash and Zsh completion to `bin/mgit`, and moves `overview` collection onto the pool. It adds nine Bats cases and updates the fan-out case for the quiet count, and updates the manual, README, running-commands guide, changelog, MGIT-WS-019, MGIT-WS-020 and MGIT-WS-022, and a new MGIT-WS-025 in the workspace-dispatch specification.

### Verification

`ki repo audit --repo .` passes with the existing HOOK-1 warning; `shellcheck`, `bash -n`, `mandoc -T lint` and `git diff --check` are clean; `bats tests/` passes 116 of 116. Run against the baseline `bin/mgit`, the nine new cases and the updated fan-out case all fail. Ordering is proved with checkouts that finish in reverse order, concurrency with shared start markers under `-j 3` and `-j 1`, and cleanup by a termination signal sent mid-run. A run under a pseudo-terminal drew and cleared the progress line. All runs used disposable fixtures with isolated Git configuration.

### Outstanding concerns

Each is provisional, for Kris to confirm:

- **Captured output loses colour.** Git sees no terminal, so status and diff colour is gone by default; `-v` restores it.
- **Interactive commands need `-v`.** A command that needs an editor or a credential prompt fails rather than waiting, for example `mgit commit` without `-m`. An SSH passphrase prompt reads the terminal directly and is not suppressed; that needs an agent or `-v`.
- **The closing line goes to standard output.** Scripts that read ordinary-command output now see one more line; `--json` is the stable interface for tools.
- **No upstream is never quiet.** A clean `git status --short` in a checkout without an upstream prints its header with no output, as a flag that the work is not on a remote.
- **Interrupts stop workers, not their children.** A termination signal kills the worker subshells and removes the files, but a Git process a worker started may run to completion; an interrupt from the terminal reaches the whole process group.
- **The oldest worker gates the pool.** A slow early checkout holds back free slots until it finishes; at the default of eight this costs little, and `-j` raises the limit.

Human acceptance is outstanding.

### Post-change review

The runner takes a worker function and an index, so `overview` and the KI-TOOL-MGIT-CLI-020 sync fetch can reuse it without new plumbing. Repository-wide `overview` facts are still decided serially before the pool starts, so `-W` output is the same at every job count. The serial loop is kept as its own function, so `-v` is exactly today's behaviour rather than a rendering of captured results.

### Mini recap

Ordinary commands now run in parallel and report only what needs attention, with `-v` for the old stream and `--json` for tools.

## Done

Accepted 2026-10-18 by Kris on the review packet above, in the owner answers, batch 5, of the [ways-of-working decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.ways-of-working/decisions.md) (ACCEPT-018 to -022): "as it is, we accept what's there basically, and then anything else I come back with, we can do remedial work ... so we can accept everything." The provisional adoption, plan and choices under Outstanding concerns are confirmed as built. Treating normal no-change output such as "Already up to date." as quiet is [KI-TOOL-MGIT-CLI-024](KI-TOOL-MGIT-CLI-024-quiet-normal-git-output.md). Kris's hands-on check, and any remedial work it finds, is [KI-TOOL-MGIT-CLI-023](KI-TOOL-MGIT-CLI-023-hands-on-behaviour-check.md).

## Discussion

### Scope (provisional)

The tools-burndown roadmap overview of 17 October proposed an mgit plan that splits this capture three ways. Its MGIT-RECORDS query recommended a), and the tools-burndown run of 18 October took it, with ESTATE-HOME a), ESCAPE-NAMES a) and OVERVIEW-VERB a), under Kris's overnight instruction to take the recommended course on a judgement call ("provisional, for Kris to confirm"):

- **This record:** the shared runner and output. `-j/--jobs N` bounds a worker pool (about 8 by default) in which each worker writes one result file; one progress line goes to stderr on a terminal only; results come at the end, naming only repositories with something to say; `-v/--verbose` shows every repository and `--json` serves tools such as `ki` and git-almanac.
- **[KI-TOOL-MGIT-CLI-020](KI-TOOL-MGIT-CLI-020-safe-parallel-sync.md):** sync's parallel fetch, classification and fast-forward-only action on this runner.
- **[KI-TOOL-MGIT-CLI-021](KI-TOOL-MGIT-CLI-021-estate-overview.md):** the read-only `mgit overview` estate view on this runner.

mgit stays pure Bash, as [AGENTS.md](../../AGENTS.md) requires, borrowing only Git Almanac's adapter, model and renderer separation and its output conventions. Bash 3.2 has no `wait -n`, so the pool is background jobs writing result files with a job-slot poll; if that proves fragile, moving the core to TypeScript/Bun is a separate owner decision. The Implementation route section below records the question this answers.

### Shape

```text
 select set ──> run per checkout (captured) ──> classify ──> summary
                      │                                       │
                      └── progress line on a TTY ──┐          ├── changed / needs attention: named, with detail
                          [#####-----] 27/54 tools-ki         ├── unchanged: one count only
                                                   │          └── failed / warned: named, exit 1
                          plain lines when not a TTY
```

- **Progress.** A single redrawn progress line on a terminal; captured or `NO_COLOR`-style plain output keeps a stable line-oriented form for scripts.
- **Quiet by default for clean repositories.** Unchanged checkouts appear only in a count. Decide per command what "changed" means (`status`: dirty, ahead or behind; `sync`: pulled, pushed, skipped or failed) and whether arbitrary pass-through commands can be classified at all, or only by exit status and non-empty output.
- **Sync first.** Kris's "sync could be way try out first" is read as piloting the new output on `sync`, which already has a result model; confirm this reading.
- **Abort on merge or rebase.** Any pull that would merge or rebase stops for that repository with a one-line warning in the summary, leaving the checkout unchanged. Confirm whether this is already satisfied by `--ff-only` plus a summary-level warning, or whether configured `pull.rebase` or interactive flows need explicit guarding and `merge --abort`/`rebase --abort` recovery.
- **Verbose escape.** Keep a flag that restores today's full per-repository output.

### Implementation route

Kris suggests code "like we did with Git Almanac". [AGENTS.md](../../AGENTS.md) currently requires `mgit` to stay pure Bash with only `bash` and `git` at runtime and forbids an npm toolchain, `package.json` or TypeScript. Adopting the Git Almanac route therefore needs an owner decision, recorded as a Decision Record, before planning: either keep Bash and borrow only Git Almanac's adapter/model/renderer separation, or move `mgit` (or an output layer) to TypeScript/Bun with the distribution, installer and Homebrew consequences that brings.

### Relationships

Interacts with [KI-TOOL-MGIT-CLI-019](KI-TOOL-MGIT-CLI-019-pass-through-escape-hatch.md): summarised output applies to mgit-owned and pass-through commands, while `--bare` and `--raw` dispatch probably keep raw streaming output.

### Adoption (provisional, for Kris to confirm)

Adopted into Next and planned to Ready on 18 October 2026 by the ways-of-working mgit-build run, provisionally on Fable's opinion of 18 October (fable-opinion-2, option a), under Kris's KEEP-PUSHING and FABLE-OPINION answers. Building stops at Awaiting review, pure Bash with Bats fixtures only, with no release. Kris confirms or reverses the adoption and plan by editing this record. The Implementation route is settled as keep Bash, so no Decision Record is needed; the runner design in the plan is provisional, for Kris to confirm. Built to Awaiting review the same day; the choices in Outstanding concerns are provisional, for Kris to confirm.
