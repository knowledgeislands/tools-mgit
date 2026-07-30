---
id: MGIT-CLI-002
title: Report invalid reserved syntax before help
theme: cli
horizon: next
status: acceptance
blocks: []
blocked-by: []
baseline-ref: a19713db01d1c620b6566e0f3d9804849c73507c
transferred-from: knowledgeislands/tools-ki:KI-TOOL-CLI-013
---

## Context

Make invalid syntax for mGit's reserved commands and options fail explicitly even when a help flag is present. The command must preserve its deliberate generic Git-command pass-through: an unrecognised positional command is not necessarily a mGit error, but malformed `register`, `repair`, `structure`, `worktree`, or `completion` syntax and unknown global options must not appear to succeed by printing help.

## Boundary

Do not reject arbitrary Git subcommands or options that mGit deliberately fans out to Git. Do not add compatibility aliases for removed mGit commands, infer corrections for ambiguous input, or alter valid help and command dispatch.

## Current state

Global option parsing exits successfully as soon as it sees `--help`, even when an earlier or later option is invalid. Reserved-command argument loops use the same early-help pattern, so malformed syntax can be hidden by a help request. The final command grammar after `MGIT-CLI-001` includes `register`, `repair`, `structure`, `worktree`, and `completion`; every other positional command remains Git pass-through.

## Steps

1. Refactor global and reserved-command argument handling so it validates the complete mGit-owned grammar before honouring a help request. Keep a standalone valid `--help` exit at zero.
2. For an invalid global option or malformed `register`, `repair`, `structure`, `worktree`, or `completion` syntax, emit `mgit: error:` with the offending token, return exit 2, then show the applicable usage text.
3. Preserve arbitrary positional Git command and Git-option pass-through unchanged; the parser must not classify those tokens as mGit errors.
4. Add Bats contract cases for invalid options before and after `--help`, invalid reserved-command arguments beside `--help`, valid help, and unchanged pass-through.

## Files touched

- `bin/mgit`
- `tests/mgit.bats`

## Verify

Run focused Bats CLI-contract cases, then `shellcheck bin/mgit install.sh` and `bats tests/`. Confirm an invalid mGit-owned token produces an error and exit 2 before usage, while `mgit status --short` still reaches Git unchanged.

## Dependencies / blocks

No work-item dependency. In the approved batch this item runs after `MGIT-CLI-001`, so its tests and diagnostics use the final `repair` command grammar rather than the removed `bootstrap` spelling.

## Delegation

### Locked decisions

The mGit-owned grammar is exactly global options plus `register`, `repair`, `structure`, `worktree`, and `completion`. Invalid mGit-owned syntax emits an `mgit: error:` usage failure with exit 2 even beside `--help`; arbitrary Git commands and Git options remain pass-through. Do not add a typo-correction alias or treat `bootstrap` as valid.

### Escalate

Stop if the parser cannot distinguish a proposed error case from legitimate Git pass-through without changing the documented public grammar, or if the final `repair` command shape differs from `MGIT-CLI-001`.

### Rounds

1. **Reserved-syntax parser and tests — mechanical, `gpt-5.6-terra`.** After `MGIT-CLI-001` has passed its core integration gate, implement complete owned-grammar validation and Bats cases. Done means every stated invalid case returns error then usage with exit 2, valid help remains zero, and pass-through remains unchanged. Scope: `bin/mgit`, `tests/mgit.bats`. The orchestrator reviews the executable diff adversarially and runs the focused cases plus ShellCheck.
2. **Integration gate — orchestrator.** Run the full stated verification and record acceptance evidence. A failed check or any need to broaden owned syntax stops the item.

## Acceptance

### Delivered

Owned-syntax validation now reports an `mgit: error:` usage failure before help even when `--help` is adjacent to invalid syntax.

### Summary of changes

Global and reserved-command parsing validates complete owned grammar while retaining valid help and generic Git pass-through.

### Verification

`bash -n bin/mgit`, `shellcheck bin/mgit install.sh`, `bats tests/` (35 passing tests), and `git diff --check` passed. Delivery commit: `a0d45fadcacd6a36150f90700938ca86ade843b4`.

### Outstanding concerns

None known. Explicit acceptance remains required before closure.

### Mini recap

The diagnostic boundary is restricted to mGit-owned syntax; arbitrary Git commands remain unmodified.

## Discussion

### Diagnostic contract

For mGit-owned grammar, an unrecognised option or unexpected argument remains a non-zero usage error even when a following or preceding help flag is present. The diagnostic should identify the invalid input and affected command before showing that command's help. A suggestion is appropriate only for an unambiguous, durable correction.

### Relationship to KI

`KI-TOOL-CLI-013` supplies the reproduced CLI-parser concern. mGit has a materially different command model because normal positional input is Git command input, so its local item applies the principle only at the boundary of reserved mGit syntax.
