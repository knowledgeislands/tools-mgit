---
id: KI-TOOL-MGIT-CLI-028
area: CLI
title: Learn majority output
kind: deliver
purpose: capability
component: cli
priority: medium
size: s
horizon: now
status: awaiting-review
blocks: []
blocked_by: []
baseline_ref: f2286d264c63a28d1e5cf55ce38a1aadf2e6252f
created_at: 2026-10-19T07:58:20Z
updated_at: 2026-10-19T08:05:16Z
---

# Learn Majority Output

## Goal

`mgit learn <command>` writes a template when strictly more than half of the selected repositories print the same normalised output, after the user confirms it, rather than only when every repository agrees. A run that cannot ask writes nothing and never waits for input.

## Context

Kris, 19 October 2026 (MGIT-LEARN-MAJORITY, ki.tools-burndown decisions log): "on mgit learn, if more than 50% are the same (ie. > 50%) then it should learn that but prompt for confirmation."

Today `learn_verdict` in `bin/mgit` learns one value, the normalised standard output and standard error of the Git command, from the selected repositories (at least two). It writes a template only when every repository's output is the same; otherwise it names the repositories that differed from the most common output and writes nothing. Any failed repository blocks learning. MGIT-WS-026 specifies this rule.

## Boundary

- In: the agreement rule in `learn_verdict` (unanimous: learn without asking, as today; strictly more than half but not all: name the differing repositories and ask; half or fewer: not learned); a confirmation read only when standard input is a terminal; help, manual, README, running-commands guide, MGIT-WS-026, changelog and Bats cases.
- Out: counting failed repositories as differing (any failure still blocks learning); a flag to accept the majority without asking; partial-output templates; release.

## Current state

Delivered on 19 October 2026 by the tools-burndown mgitlearn run; awaiting Kris's review. `learn_verdict` asks before writing a majority output, only on a terminal.

## Steps

- [x] In `learn_verdict`, learn without asking when every repository agrees; when strictly more than half agree, name the differing repositories and, only if standard input is a terminal, ask `[y/N]` before writing; otherwise, or on a declined, empty or ended answer, write nothing and exit `1`.
- [x] Say in the learned line how many repositories agreed out of how many when not all did.
- [x] Update `mgit help learn`, the manual, README, running-commands guide, MGIT-WS-026 and the changelog.
- [x] Add Bats cases for the confirmed, declined and non-terminal majority paths and the half-or-fewer refusal.
- [x] Run the complete gate.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes, in disposable fixtures with an isolated `XDG_CONFIG_HOME`: two of three agreeing on a terminal with `y` writes the majority template and names the differing repository; `n` or an empty answer writes nothing; with standard input not a terminal the run writes nothing, says how to confirm, and returns without reading input; one of two, or two of four, agreeing is refused as before; unanimous learning is unchanged and never asks.

## Dependencies / blocks

None.

## Documentation impact

### Decision Records

None.

### Specifications

MGIT-WS-026 gains the majority rule and its confirmation.

### Guides

Running commands, "Learn normal output", describes the majority confirmation.

### Roadmap

None.

## Review

### Delivered

Within the approved boundary, `mgit learn <command>` still learns without asking when every repository agrees. When strictly more than half, but not all, print the same non-empty normalised output, it names the differing repositories and asks `Learn the majority output? [y/N]` when standard input is a terminal; `y` writes the template and the learned line reads "from N of M repositories". Any other answer, ended input or a non-terminal standard input writes nothing and exits `1`, and a non-terminal run never reads its input. Half or fewer agreeing is refused as before. Excluded as planned: counting failures as differing, a flag to accept the majority unattended, partial templates and any release. Baseline `f2286d264c63a28d1e5cf55ce38a1aadf2e6252f`; the delivery commit follows it.

### Change Summary

- `bin/mgit`: new `learn_confirm_majority`; `learn_verdict` applies the strict-majority rule, refuses an empty majority output, and reports the agreeing count; `mgit help learn` text.
- `tests/mgit.bats`: `run_on_terminal`, a Python `pty` helper skipped when `python3` is absent, and `make_majority_trio`; new cases `learn asks before writing a majority output` and `learn never asks without a terminal`; the difference case now uses a two-of-four split and covers the empty majority.
- `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md` (MGIT-WS-026), `CHANGELOG.md`.

### Verification

- `MGIT_KI_PRODUCER=<ki> TMPDIR=<run temp> bats tests/` under macOS Bash 3.2: 133 of 134 pass. The one failure, `--filter applies to bare commands and requires a pattern`, asserts that the output does not contain `tools-b`, and the run's temporary path contains `tools-burndown`; with the default `TMPDIR` it passes. The learn cases also pass with bats itself on a pseudo-terminal, so none waits for input.
- `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `mandoc -T lint man/mgit.1`, `git diff --check`: pass.
- `ki repo audit --repo .`: FAIL=0, the same 7 warnings as at baseline.

### Outstanding concerns

- The terminal cases need `python3`; without it they skip. CI's Ubuntu image has it.
- Unattended runs cannot accept a majority; a later record could add an explicit flag if Kris wants one.
- Any failed repository still blocks learning, as before; the instruction did not cover failures.
- The `tools-b` fixture assertion collides with temporary paths that contain that text; a small test fix, not in this record.

### Post-change review

The goal holds: a majority is learned only after a yes on a terminal, unanimous learning is unchanged, and a script or pipe gets a clear refusal without waiting. Scope stayed inside the boundary. Regression risk is low: the only changed outcome is for runs where more than half but not all agree, which used to refuse outright and still do when not on a terminal. Ready for acceptance review.

### Mini recap

Added majority learning with confirmation to `mgit learn`, documented it in help, the manual, README, guide, MGIT-WS-026 and the changelog, and covered it with terminal and non-terminal Bats cases. No release.

## Discussion

Captured by the tools-burndown mgitlearn run under MGIT-LEARN-MAJORITY, which also authorises delivery to Awaiting review with no release. Adopted into Now and planned to Ready by the same run under that answer.
