---
id: MGIT-CLI-015
area: CLI
title: Territory selection pilot
kind: deliver
purpose: capability
component: cli
status: done
blocks: []
blocked_by: []
baseline_ref: 5b93e761112e47162bfa4e2946b66e6511c96644
created_at: 2026-10-07T21:17:07Z
updated_at: 2026-10-08T19:24:22Z
---

# Territory selection pilot

## Goal

mgit selects territories and the registered estate using the shared literal directory-prefix contract, while saved snapshots continue to work offline.

## Context

Kris approved [ADR-KI-ARCADIA-002](https://github.com/knowledgeislands/ki-arcadia-principal/blob/main/Admin/Governance/Decisions/ADR-KI-ARCADIA-002-territory-derived-repository-selection.md) and its numbered owner decisions with "all agreed". The shared contract in KI-HARNESS-GOV-156 and committed producer in KI-TOOL-CLI-114 are available, with both dependency statuses DONE and contract.ok and ki-pilot.ok present. This ready plan is already approved by the owner. The declared repo_code is MGIT, so the reserved identifier is MGIT-CLI-015.

## Boundary

One caller pilot only: no Project, speculative queue, legacy aliases, filter globs, registry publication, acceptance, pruning, push, release or live estate mutations. Preserve discriminated repository/workspace documents and unrelated Git behaviour. Work exclusively in this run's mgit worktree; fixtures and logs live under the run. Retain the current version because remote collision checks are prohibited.

## Current state

The approved rollout is published through fast-forward task-owned source integration. [KI v0.9.0](https://github.com/knowledgeislands/tools-ki/releases/tag/v0.9.0) and [mgit v0.16.0](https://github.com/knowledgeislands/tools-mgit/releases/tag/v0.16.0) are immutable and exact-tag installations pass. KI has signed archive/checksum verification, successful clean Linux installation and fresh local bootstrap of the pinned territory harness; mgit has absolute executable and manual proof. Installed callers agree for `-t ki -f tools-` and `--estate -f mcp-`, preserving membership and the ki/KIS identities. The automatic [KI formula handoff](https://github.com/knowledgeislands/homebrew-tap/pull/27) and [mgit formula handoff](https://github.com/knowledgeislands/homebrew-tap/pull/29) merged with required checks passing; both exact Homebrew upgrades and user versions are verified. Frozen design evidence, trade routing and Techne Programme Hold remain unchanged. Kris Brown accepted all four territory-selection records on 8 October 2026. The accepted delivery is retained, with local closure recorded below; no records were pruned.

## Steps

- [x] Replace Agora selectors with territory/estate scopes and literal nonempty repeatable directory-basename prefixes; reject ignored and conflicting combinations before execution.
- [x] Call the actual buffered NUL producer with filters; validate complete roots and failures before dispatch and before worktree expansion.
- [x] Cut saved locations over to territory handles, preserving offline snapshots and byte-identical manifests on failed refresh; reject legacy Agora grammar with explicit migration guidance.
- [x] Update help, both completions, manual, README, specifications, guides and changelog, retaining version metadata.
- [x] Run the complete local gate and combined committed producer/caller proof in isolated disposable configuration and repositories, then commit and prepare review evidence.

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

## Review

### Delivered

The approved mgit caller pilot from immutable Ready baseline `5b93e761112e47162bfa4e2946b66e6511c96644` is complete: territory and estate roots come from the committed KI producer, literal basename prefixes are applied before checkout expansion, and saved territory snapshots refresh explicitly while ordinary operations remain offline. Source delivery and all verification stay in the exclusive run-owned worktree. No publication, acceptance, pruning, registry distribution or other repository edits are included.

### Change Summary

- `bin/mgit`: shared territory/estate grammar, early selector eligibility checks, buffered complete NUL roots with filters passed to KI, strict stream/root validation, literal local basename filtering, newline-safe path capture and worktree enumeration, territory locations and actionable rejection of historic Agora grammar.
- `tests/mgit.bats`, `tests/territory-producer.bats` and `tests/territory-protocol.bats`: migrated selector/completion/filter fixtures, a strict protocol double, actual committed producer integration and hostile-stream failure tests. Git mutations occur only in isolated disposable repositories.
- README, changelog, manual, workspace-dispatch specification, running-commands and repository-sets guides and definition of done: public grammar, prefix semantics, current refresh/offline behaviour and explicit previewable user migration without deleting state.
- `docs/roadmap/_ISSUES.md` reserves CLI-015 in its standalone commit. The repository's declared MGIT prefix determines this record's identifier. No Project or additional queue items were created.
- The pilot initially retained `MGIT_VERSION` at `0.15.0`; the coordinator then verified the available next minor and published the final `0.16.0` candidate. Distribution remains the existing installer/manual/Homebrew routes.

### Verification

The source CI continuation found a task-caused local-discovery regression: recognising explicit linked territory checkouts also admitted sibling worktrees as independent local repository units. The bounded correction excludes linked checkouts from local discovery and recursive registration, retains explicit territory roots, and asserts that registration omits the sibling member. The corrected candidate passed all 89 Bats tests with the freshly compiled KI producer, the whole native audit, ShellCheck, Bash syntax, manual lint and diff checks. The fixture run clears inherited KI path overrides so each disposable XDG registry remains authoritative. Required CI is repeated before release publication.

- `shellcheck bin/mgit install.sh`, `/bin/bash -n bin/mgit install.sh`, `mandoc -T lint man/mgit.1` and `git diff --check`: passed. The manual's rendered UTF-8 page was inspected after the layout update.
- `TMPDIR=<run>/mgit-fixtures MGIT_KI_PRODUCER=<run>/worktrees/ki/dist/ki bats tests/`: 89 tests passed with zero skips, executing mgit on macOS Bash 3.2.57. The actual producer is the committed KI pilot binary reporting `0.9.0`.
- The combined executable proof covers distinct Capital and repository registry keys, short handles and physical basenames; repeated, literal, case-sensitive, empty and zero-match filters; spaces and embedded/trailing newlines; excluded and selected unavailable roots; missing registrations; duplicate identities/handles; incompatible or ignored scopes; filtering before worktree expansion; old flags, locations and schema rejection; no dispatch on partial/error/malformed output; byte-identical failed refresh and offline snapshot mutation.
- Focused installed `~/.local/bin/ki repo audit` gates for ki-work, ki-work-roadmap, ki-authoring, ki-repo-tools, ki-specs and ki-guides passed. Whole `~/.local/bin/ki repo audit --repo <worktree>` passed all 19 skills with run-local `XDG_STATE_HOME` registry mapping and mirrored ignored activation links. No live registry/configuration was changed.
- The initial ambient worktree audit identified missing ignored activation links and an unregistered delivery path; these are isolation artefacts, distinct from the delivery's authored Markdown/manual corrections. Final isolated audits are clean. The default user registry intentionally still names the primary checkout.
- Runtime evidence is retained in this delivery run's `mgit.gates.json`, `mgit.audits.json`, gate/audit logs and `mgit.integration.json`; fixtures and logs are outside the repository.

The coordinator fast-forwarded the task-owned reservation, Ready and delivery history into a candidate descending from fetched published main. MGIT_VERSION and its two assertions now prepare 0.16.0, with the single consolidated pre-1.0 baseline updated. ShellCheck, Bash syntax, all 89 tests with the exact combined KI producer, manual lint, diff validation and the whole 19-skill registered-context audit pass. The initial inherited audit-state override was removed only from the disposable test process; fixtures and failed-attempt evidence are preserved.

Final publication evidence: [KI v0.9.0](https://github.com/knowledgeislands/tools-ki/releases/tag/v0.9.0) and [mgit v0.16.0](https://github.com/knowledgeislands/tools-mgit/releases/tag/v0.16.0). [Verified source CI](https://github.com/knowledgeislands/tools-mgit/actions/runs/37695908881) passed. The task-caused local linked-worktree discovery correction passed the repeated source CI and all 89 local Bats tests, including the real committed KI producer. The immutable exact-tag installer produced a byte-identical executable and manual from its canonical source archive; both were verified by absolute path. Both automatic Homebrew formula handoffs merged with passing required checks, exact versions were upgraded, and read-only installed caller parity passed for both approved scopes. Immutable baseline records and original delivery packets remain unchanged.

### Outstanding concerns

Kris Brown accepted the delivery on 8 October 2026. No mandatory rollout gate is failing or unchecked. No record was pruned. Foreign primary-checkout changes and historical user state are preserved. Saved locations containing historic Agora grammar still require the documented explicit migration before refreshing; no historical state was deleted or silently migrated.

### Post-change review

The implementation satisfies the accepted selection boundary without adding dependencies or reading KI configuration directly. Complete producer output is validated before dispatch; selected roots are exact, and checkout expansion follows filtering. Offline snapshots and unrelated Git behaviours retain their native model, supported by the full existing suite. The intentional hard cut-over is the material user-facing change, with rejection tests and previewable guidance. Accepted by Kris Brown on its review packet.

### Mini recap

Delivered one bounded territory caller pilot and committed its review evidence after 89 passing tests and clean required local gates. The accepted ADR remains the durable design source; the specification and migration guide carry product behaviour. No additional learning promotion or backlog is proposed.

## Done

Accepted 2026-10-08 by Kris Brown on the review packet above.

## Discussion

### Authority

The task grants detached local delivery and commits with a Codex co-author trailer, without background subagents or remote calls. The owner already approved the plan; delivery stopped at awaiting-review after verification and Kris Brown accepted it on 8 October 2026. Current closure authority permits no pruning, push or release.
