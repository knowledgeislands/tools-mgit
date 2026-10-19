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
updated_at: 2026-10-19T08:13:03Z
---

# Learn Majority Output

## Goal

`mgit learn <command>` writes a template when every selected repository, or strictly more than half, print the same normalised output, and always only after the user confirms it, unanimous agreement included. One repository is enough to learn from. A run that cannot ask writes nothing and never waits for input.

## Context

Kris, 19 October 2026 (MGIT-LEARN-MAJORITY, ki.tools-burndown decisions log): "on mgit learn, if more than 50% are the same (ie. > 50%) then it should learn that but prompt for confirmation."

Kris refined it the same day, after the first delivery (MGIT-LEARN-MAJORITY, refined): "perhaps it should always prompt with a 100% match too, just in case... and I don't see the issue with single repos either".

Before this record, `learn_verdict` in `bin/mgit` learned one value, the normalised standard output and standard error of the Git command, from the selected repositories (at least two). It wrote a template only when every repository's output was the same; otherwise it named the repositories that differed from the most common output and wrote nothing. Any failed repository blocks learning. MGIT-WS-026 specifies this rule.

## Boundary

- In: the agreement rule in `learn_verdict` (every repository or strictly more than half agreeing: say how many agreed out of how many, name any differing repositories and ask; half or fewer: not learned); a confirmation read only when standard input is a terminal; learning from a single repository, dropping the at-least-two rule; help, manual, README, running-commands guide, MGIT-WS-026, changelog and Bats cases; the one-line fix to the `--filter` test whose `tools-b` assertion collided with temporary paths.
- Out: counting failed repositories as differing (any failure still blocks learning); a flag to accept without asking; partial-output templates; release.

## Current state

Delivered on 19 October 2026 by the tools-burndown mgitlearn run and refined by the mgitlearn2 run under Kris's refinement; awaiting Kris's review. `learn_verdict` always asks before writing a template, only on a terminal, and learns from one repository or more.

## Steps

- [x] In `learn_verdict`, when every repository or strictly more than half agree on non-empty output, name any differing repositories and, only if standard input is a terminal, ask `[y/N]` before writing; otherwise, or on a declined, empty or ended answer, write nothing and exit `1`.
- [x] Say in the prompt, and in the non-terminal refusal, how many repositories agreed out of how many; say it in the learned line when not all did.
- [x] Allow learning from a single repository; keep a refusal when none is selected.
- [x] Update `mgit help learn`, the manual, README, running-commands guide, MGIT-WS-026 and the changelog.
- [x] Add Bats cases for the confirmed, declined and non-terminal paths, unanimous and majority, the half-or-fewer refusal and the single repository; confirm on a terminal in the existing learning cases.
- [x] Make the `--filter applies to bare commands` assertion match the fixture's full path.
- [x] Run the complete gate.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, `CHANGELOG.md` and this record.

## Verify

The [definition of done](../guides/developer/definition-of-done.md) gate passes, in disposable fixtures with an isolated `XDG_CONFIG_HOME`: two of two agreeing on a terminal asks `2 of 2 repositories agreed. Learn this output? [y/N]` and writes the template on `y`, and `n` writes nothing; two of three agreeing asks with the differing repository named, `y` writes the majority template, and `n`, an empty answer or ended input writes nothing; with standard input not a terminal, unanimous or majority, the run writes nothing, says how many agreed and how to confirm, and returns without reading input; one of two, or two of four, agreeing is refused as before; a single repository is asked `1 of 1 repository agreed` and learned on `y`.

## Dependencies / blocks

None.

## Documentation impact

### Decision Records

None.

### Specifications

MGIT-WS-026 gains the confirmation for unanimous and majority output, its non-terminal refusal and learning from one repository.

### Guides

Running commands, "Learn normal output", describes the confirmation and single-repository learning.

### Roadmap

None.

## Review

### Delivered

Within the approved boundary, `mgit learn <command>` asks before writing any template. When every repository, or strictly more than half, print the same non-empty normalised output, it asks `mgit learn: N of M repositories agreed[ and K differed: names]. Learn this output? [y/N]` when standard input is a terminal; `y` writes the template, and the learned line reads "from N of M repositories" when not all agreed. Any other answer, ended input or a non-terminal standard input writes nothing and exits `1`, and a non-terminal run never reads its input but says how many agreed and to run it from a terminal to confirm. Half or fewer agreeing is refused as before, and output that is empty everywhere is still already quiet, without asking. A single repository is enough to learn from; selecting none is refused. Excluded as planned: counting failures as differing, a flag to accept unattended, partial templates and any release. Baseline `f2286d264c63a28d1e5cf55ce38a1aadf2e6252f`; the first delivery commit and the refinement commit follow it.

### Change Summary

- `bin/mgit`: `learn_confirm` (was `learn_confirm_majority`) asks for unanimous and majority output alike; `learn_verdict` applies the strict-majority rule, refuses an empty majority output, and reports the agreeing count; the at-least-two guard becomes a no-repository guard; `mgit help learn` text.
- `tests/mgit.bats`: `run_on_terminal`, a Python `pty` helper skipped when `python3` is absent, and `make_majority_trio`, now defined before the first learning case; `learn asks before writing a majority output`, `learn never asks without a terminal` and the new `learn learns from a single repository`; the unanimous case covers the non-terminal refusal and a declined prompt; existing learning cases confirm on a terminal; the `--filter` case asserts on `$TREE/tools-b`.
- `man/mgit.1`, `README.md`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md` (MGIT-WS-026), `CHANGELOG.md`.

### Verification

- `MGIT_KI_PRODUCER=<ki> TMPDIR=<run temp> bats tests/` under macOS Bash 3.2: 135 of 135 pass, none skipped, with a temporary path containing `tools-burndown`.
- `shellcheck bin/mgit install.sh`, `bash -n bin/mgit install.sh`, `mandoc -T lint man/mgit.1`, `git diff --check`: pass.
- `ki repo audit --repo .`: FAIL=0, the same 7 warnings as at baseline.

### Outstanding concerns

- Learning now always needs a terminal: a script that used to learn a unanimous output unattended now writes nothing and exits `1`. A later record could add an explicit flag if Kris wants one.
- The learning cases need `python3` for the terminal; without it they skip. CI's Ubuntu image has it.
- Any failed repository still blocks learning, as before; the instruction did not cover failures.

### Post-change review

The goal holds: no template is written without a yes on a terminal, unanimous or majority, one repository can be learned from, and a script or pipe gets a clear refusal without waiting. Scope stayed inside the boundary. Regression risk is low but deliberate: unattended unanimous learning, which used to write, now refuses with a hint, as Kris asked. Ready for acceptance review.

### Mini recap

Made `mgit learn` always confirm before writing, naming how many agreed and any that differed, and learn from a single repository; documented it in help, the manual, README, guide, MGIT-WS-026 and the changelog, covered it with terminal and non-terminal Bats cases, and fixed the `tools-b` path collision in the `--filter` test. No release.

## Discussion

Captured by the tools-burndown mgitlearn run under MGIT-LEARN-MAJORITY, which also authorises delivery to Awaiting review with no release. Adopted into Now and planned to Ready by the same run under that answer. Kris's refinement reached the record after the first delivery; the tools-burndown mgitlearn2 run folded it into this record and delivery under the same authority.
