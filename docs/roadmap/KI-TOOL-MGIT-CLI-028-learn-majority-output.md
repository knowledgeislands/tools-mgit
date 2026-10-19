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
status: ready
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-19T07:58:20Z
updated_at: 2026-10-19T07:58:33Z
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

Planned on 19 October 2026; not started. `learn_verdict` already finds the most common output and its count, so the change is confined to its decision after that count.

## Steps

- [ ] In `learn_verdict`, learn without asking when every repository agrees; when strictly more than half agree, name the differing repositories and, only if standard input is a terminal, ask `[y/N]` before writing; otherwise, or on a declined, empty or ended answer, write nothing and exit `1`.
- [ ] Say in the learned line how many repositories agreed out of how many when not all did.
- [ ] Update `mgit help learn`, the manual, README, running-commands guide, MGIT-WS-026 and the changelog.
- [ ] Add Bats cases for the confirmed, declined and non-terminal majority paths and the half-or-fewer refusal.
- [ ] Run the complete gate.

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

## Discussion

Captured by the tools-burndown mgitlearn run under MGIT-LEARN-MAJORITY, which also authorises delivery to Awaiting review with no release. Adopted into Now and planned to Ready by the same run under that answer.
