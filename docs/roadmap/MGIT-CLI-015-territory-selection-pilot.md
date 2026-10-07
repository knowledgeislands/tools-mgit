---
id: MGIT-CLI-015
area: CLI
title: Territory selection pilot
kind: deliver
purpose: capability
component: cli
horizon: now
status: ready
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-07T21:17:07Z
updated_at: 2026-10-07T21:17:07Z
---

# Territory selection pilot

## Goal

mgit selects territories and the registered estate using the shared literal directory-prefix contract, while saved snapshots continue to work offline.

## Context

Kris approved [ADR-KI-ARCADIA-002](https://github.com/knowledgeislands/ki-arcadia-principal/blob/main/Admin/Governance/Decisions/ADR-KI-ARCADIA-002-territory-derived-repository-selection.md) and its numbered owner decisions with "all agreed". The shared contract in KI-HARNESS-GOV-156 and committed producer in KI-TOOL-CLI-114 are available, with both dependency statuses DONE and contract.ok and ki-pilot.ok present. This ready plan is already approved by the owner. The declared repo_code is MGIT, so the reserved identifier is MGIT-CLI-015.

## Boundary

One caller pilot only: no Project, speculative queue, legacy aliases, filter globs, registry publication, acceptance, pruning, push, release or live estate mutations. Preserve discriminated repository/workspace documents and unrelated Git behaviour. Work exclusively in this run's mgit worktree; fixtures and logs live under the run. Retain the current version because remote collision checks are prohibited.

## Current state

The clean main baseline uses Agora flags and saved locations, a buffered legacy producer and glob filters. Existing distribution is the Bash installer, manual and Homebrew tap. Only Bash 3.2 and Git are baseline runtime dependencies.

## Steps

- [ ] Replace Agora selectors with territory/estate scopes and literal nonempty repeatable directory-basename prefixes; reject ignored and conflicting combinations before execution.
- [ ] Call the actual buffered NUL producer with filters; validate complete roots and failures before dispatch and before worktree expansion.
- [ ] Cut saved locations over to territory handles, preserving offline snapshots and byte-identical manifests on failed refresh; reject legacy Agora grammar with explicit migration guidance.
- [ ] Update help, both completions, manual, README, specifications, guides and changelog, retaining version metadata.
- [ ] Run the complete local gate and combined committed producer/caller proof in isolated disposable configuration and repositories, then commit and prepare review evidence.

## Files touched

bin/mgit, tests/mgit.bats, focused producer-contract tests under tests/, README.md, CHANGELOG.md, man/mgit.1, affected docs/specs/ and docs/guides/, docs/roadmap/_ISSUES.md and this record. Runtime-only evidence and fixtures remain outside the repository.

## Verify

shellcheck bin/mgit install.sh; bash -n bin/mgit install.sh; bats tests/; mandoc -T lint man/mgit.1; git diff --check; focused KI work, roadmap, authoring, tools and specs/guides audits; whole ~/.local/bin/ki repo audit --repo this worktree. Combined proof calls the committed KI worktree executable with isolated XDG state/config, distinct registry keys, Capital key, handle and basenames. Cover repeated/literal/case/empty filters, spaces/newlines, missing selected/excluded roots, missing registrations, duplicate identities/handles, invalid scopes, expansion after filtering, legacy rejection, atomic dispatch failure, failed-refresh manifest preservation and offline operations. Distinguish baseline-only audit failures without claiming a clean gate.

## Dependencies / blocks

Shared contract and producer are committed and their required markers and DONE statuses have been checked. This unit supplies mgit-pilot.ok only after all mandatory gates and executable proof pass and the delivery is committed. Arcadia retirement waits for that marker.

## Documentation impact

### Decision Records

Use the accepted Arcadia ADR without a duplicate decision.

### Specifications

Update workspace dispatch to the exact producer, literal-prefix and hard-cut-over contracts.

### Guides

Explain explicit previewable migration without deleting user state, saved refresh and offline snapshots.

### Roadmap

Keep this single bounded record for review; add no queue items.

## Discussion

### Authority

The task grants detached local delivery and commits with a Codex co-author trailer, without background subagents or remote calls. The owner already approved the plan; delivery stops at awaiting-review after verification.
