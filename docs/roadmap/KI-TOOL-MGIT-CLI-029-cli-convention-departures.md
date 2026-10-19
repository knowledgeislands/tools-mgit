---
id: KI-TOOL-MGIT-CLI-029
area: CLI
title: CLI convention departures
purpose: debt
component: cli
priority: medium
size: m
status: triage
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-19T18:26:00Z
updated_at: 2026-10-19T18:26:00Z
---

# CLI Convention Departures

## Goal

mgit's option parsing follows the `ki-repo-tools` [command-line conventions](/Users/krisbrown/.local/share/ki/harnesses/knowledgeislands/ki-agentic-harness/skills/repo-structure/ki-repo-tools/references/standards-cli-conventions.md) in the four places it departs from them today, so `--jobs=2`, `-j2`, `-vW`, `-n` and `worktree remove -f` work as a user of other conventional tools expects.

## Context

[KI-HARNESS-GOV-218](/Users/krisbrown/workspaces/knowledge-islands/ki-agentic-harness/docs/roadmap/KI-HARNESS-GOV-218-cli-conventions.md) audited the house tools against the command-line conventions. Kris decided on 18 October 2026, CLI-DEPARTURES a) in the [tools-burndown decisions log](/Users/krisbrown/workspaces/knowledge-islands/ki-principal/+/_WORK/ki.tools-burndown/decisions.md) ("CLI-DEPARTURES"), that each departure is recorded on the record owning the command, as a fix for the tool's next change, not built at once. For mgit that record was [KI-TOOL-MGIT-CLI-023](KI-TOOL-MGIT-CLI-023-hands-on-behaviour-check.md), whose Remedial findings hold the finding. That record is Awaiting review and will be pruned after acceptance, so the finding moves here under the coordinator's MGIT-DEPARTURES-HOME a) answer of 19 October 2026.

mgit departs in four ways:

- `-j/--jobs` takes its value only as a separate word, so `--jobs=2` and `-j2` are refused.
- Short options without arguments do not group, so `-vW` is refused where it should mean `-v -W`.
- `--dry-run` has no `-n` short letter.
- `worktree remove --force` has no `-f` short letter, which the CLI-F-FILTER fix on KI-TOOL-MGIT-CLI-023 left free for force.

`-f, --filter` is not a departure: under CLI-F-FILTER `-f` is a usage error at the top level, and `--filter` keeps no short letter.

## Boundary

- **In:** the four fixes above in `bin/mgit`, each with its Bats case in disposable fixtures, and the matching help, Bash and Zsh completion, manual, user guide, specification and changelog updates.
- **Out:** a top-level `-f` for `--filter`; other departures the conventions might later name; other tools' departures, which live on their own records.

## Dependencies / blocks

None. Blocks nothing. It does not block the v0.18.0 release.

## Discussion

Origin: KI-TOOL-MGIT-CLI-023's CLI-DEPARTURES finding, homed here before that record is pruned. Capture only; adoption, horizon and plan belong to this repository.

Planning questions: whether grouping and attached values are handled by one shared pre-pass over the arguments, which would also cover `-t` and other value options, or per option; how `-n` interacts with commands that pass arguments through to Git, where `-n` already has meanings; and whether `-vW` grouping must reject a grouped option that takes a value in the middle of the group. `size: m` is provisional: the grouping pre-pass is the bulk of the work and the three other fixes are small.
