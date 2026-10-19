---
id: KI-TOOL-MGIT-CLI-028
area: CLI
title: Learn majority output
purpose: capability
priority: medium
size: s
status: triage
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-19T07:58:20Z
updated_at: 2026-10-19T07:58:20Z
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

## Dependencies / blocks

None.

## Discussion

Captured by the tools-burndown mgitlearn run under MGIT-LEARN-MAJORITY, which also authorises delivery to Awaiting review with no release.
