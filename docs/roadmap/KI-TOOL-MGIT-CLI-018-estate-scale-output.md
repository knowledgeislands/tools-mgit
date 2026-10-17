---
id: KI-TOOL-MGIT-CLI-018
area: CLI
title: Estate-scale output
status: triage
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-17T21:31:16Z
updated_at: 2026-10-17T21:31:16Z
---

## Goal

Make `mgit` output readable across a whole estate: progress while it runs, then a concise end-of-run result that names only the repositories that need attention.

## Context

Owner request, 17 October 2026, in Kris's words: "I really want MGIT have much better output ... if I do MGIT status over entire estate, because there's like 50 projects, it scrolls off screen ... I really, really want this kind idea it giving me progress bar ... and then it gives me results end ... anything got no changes, it doesn't tell me about it, it only tells me ... ones that changed ... sync could be way try out first ... if pulls and gets rebase or merge warning, it should effectively automatically abort and give me warning instead ... some this might better off done like we did with Git Almanac, so we can put some code behind it".

Today ordinary pass-through commands such as `mgit status` print a header and Git's full output for every checkout, so a 54-repository estate scrolls off screen. `mgit sync` already names only repositories that pulled, pushed or failed and counts the current ones, and pulls with `--ff-only`, so divergence already fails without a merge or rebase; its per-repository `pulling` lines and Git's detail still stream as it runs. See [Run commands across repositories](../guides/user/running-commands.md).

The reference approach is [Git Almanac](https://github.com/knowledgeislands/tools-git-almanac), a TypeScript/Bun tool that separates a Git adapter, a core model and terminal, JSON and HTML renderers.

## Boundary

This capture does not adopt, schedule, implement or release anything. It does not change the repository-selection boundary, `.mgit.toml` model or exit-status contract, and grants no authority to add a runtime dependency or toolchain.

## Discussion

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
