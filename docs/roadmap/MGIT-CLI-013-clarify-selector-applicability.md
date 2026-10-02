---
id: MGIT-CLI-013
area: CLI
title: Clarify selector applicability
theme: cli
horizon: now
status: done
blocks: []
blocked_by: []
baseline_ref: 4f4f6e5597a2ef5ec9aa8bec6cdb98b1b1bf6989
created_at: 2026-09-28T09:26:16Z
updated_at: 2026-10-02T20:44:47Z
---

## Goal

Make it clear which repository-selection options affect each command, so a command cannot silently operate on a broader set than the user expected.

## Context

`--filter` narrows ordinary dispatch, `sync`, `structure`, and `worktree`, but does not change what `register` or `repair` reads. `--all-worktrees` affects listing, ordinary dispatch, and `sync`, but not `structure` or worktree management. These exceptions are documented, yet the global parser still accepts option combinations whose effect may be absent or surprising.

## Boundary

Do not silently apply filtering to registration or repair as part of this intake item. The separate MGIT-CLI-009 record owns any schema or named-group simplification.

## Current state

The global parser accepts combinations whose selectors are ignored by reserved commands. Registration and repair can therefore act on a broader set than a caller expects.

## Steps

- [x] Define applicability for each global selector across listing, ordinary dispatch, `register`, `repair`, `sync`, `structure`, and `worktree`.
- [x] Reject selectors ignored by the selected command with a namespaced usage error before discovery or mutation; preserve meaningful combinations and help/version behavior.
- [x] Test invalid combinations and no-side-effect behavior, then align help, completion guidance, manual, and user guides.

## Files touched

`bin/mgit`, `tests/mgit.bats`, `man/mgit.1`, `docs/guides/user/running-commands.md`, `docs/specs/workspace-dispatch.md`, and `CHANGELOG.md`.

## Verify

Run a selector-by-command Bats matrix and the complete `tools-mgit` gate.

## Dependencies / blocks

The removed `--group` selector is already reflected in the delivered manifest item. No build-order dependency remains.

## Documentation impact

### Decision Records

No separate decision record is needed; this item records the command applicability contract.

### Specifications

Specify the rejection policy and valid selector combinations.

### Guides

Clarify which selectors apply to each command and how inapplicable combinations fail.

### Roadmap

No follow-on roadmap item is expected.

## Review

### Delivered

From baseline `4f4f6e5597a2ef5ec9aa8bec6cdb98b1b1bf6989`, global selectors that have no effect on the selected command fail before repository discovery or management work. Help and version remain available.

### Change Summary

`bin/mgit` validates selector applicability across listing, pass-through, and reserved commands. Bats covers invalid combinations and unchanged state; help, Zsh completion descriptions, manual, running-commands guide, changelog, and workspace-dispatch specification describe the contract.

### Verification

Focused selector Bats cases and the full Bats suite passed. The repository audit, ShellCheck, Bash syntax, mandoc lint, and `git diff --check` passed.

### Outstanding concerns

None.

### Post-change review

`register --agora` remains a saved-location shorthand, while `repair` rejects all global selectors. Ordinary Git and `-B` pass-through retain their selection behavior.

### Mini recap

Selector applicability is explicit and ready for human review; no follow-on work was identified.

## Done

Accepted 2026-10-02 by Kris Brown on the review packet above.

## Discussion

### Option contract

Review each global selector against the command groups. Decide whether an inapplicable combination should be rejected, warned about, or given a defined effect; account for compatibility with existing scripts. Keep help, completion, guides, and tests aligned with the chosen contract.
