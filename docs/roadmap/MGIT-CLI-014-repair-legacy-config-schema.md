---
id: MGIT-CLI-014
area: CLI
title: Repair legacy config schema
theme: cli
horizon: next
status: awaiting-review
blocks: []
blocked_by: []
baseline_ref: 33886541b9036e5714ff32a01d4a2f11fd1b6a88
created_at: 2026-10-03T04:00:16Z
updated_at: 2026-10-03T06:56:28Z
---

## Goal

Keep newly written `.mgit.toml` unversioned and offer an explicit, previewable repair for recognised legacy files carrying `schema = 1`.

## Context

New MGIt configuration already omits a schema field, but the reader still accepts a grouped legacy schema and structural conversion is limited to the default group. The approved estate treatment regards a missing field as the one current v1 input shape, without introducing `latest`, `pre-release`, `0`, or an estate-wide version.

## Boundary

Recognise legacy data by actual shape, not a version label alone. Reject unknown or ambiguous structures. Reading, status and non-interactive commands must not silently rewrite a file or prompt. Do not broaden group semantics as an incidental migration.

## Current state

New writes are unversioned; legacy read and repair behaviour needs a focused audit and explicit user-facing fix path.

## Steps

- [x] Inventory legacy shapes and existing conversion behaviour with fixtures.
- [x] Add `mgit config repair` to preview an exact diff and `mgit config repair --apply` to write only after validating and rechecking the same manifest. Remove the marker from repository-kind files; convert only a workspace's sole structural default group to direct members while preserving other content. Refuse alternative or ambiguous groups.
- [x] Test unknown-shape rejection, unchanged ordinary reads and non-interactive behaviour; align help, completion, manual and guide.

## Files touched

- MGIt config parser and command implementation
- `tests/mgit.bats`
- `docs/guides/user/repository-sets.md`, `man/mgit.1`, help and completion surfaces as needed
- This roadmap item

## Verify

Run the repository audit and complete MGIt gate, then exercise valid legacy, invalid legacy, preview, opt-in repair and non-interactive cases against disposable files.

## Dependencies / blocks

No external dependency. `mgit repair` retains its clone meaning; `mgit config repair` is the separate, explicitly previewed config operation. Ordinary reads remain side-effect-free.

## Documentation impact

### Decision Records

Record a decision only if repair semantics exceed this boundary.

### Specifications

State accepted input shapes and explicit repair behaviour.

### Guides

Explain unversioned input and the previewed legacy repair.

### Roadmap

Record delivery and verification here.

## Review

### Delivered

Against baseline `33886541b9036e5714ff32a01d4a2f11fd1b6a88`, MGIt retains unversioned new manifests and now previews or explicitly repairs recognised legacy schema-1 input. Clone-oriented `mgit repair` and ordinary reads are unchanged. No push or release is included.

### Change Summary

Added `mgit config repair` as an exact Git diff preview and `--apply` as the validated write, with a same-file content recheck and candidate reparse. It removes the marker from repository-kind input and converts only a workspace's sole structural default group. Help, both completions, manual, README, user guides, specification and changelog reflect the command.

### Verification

`bats tests/` passed all 75 tests; focused tests cover preview without a write, explicit repair, normal reads, unknown schema and alternative-group refusal. `bash -n bin/mgit install.sh`, `shellcheck bin/mgit install.sh`, `mandoc -T lint man/mgit.1`, `ki repo audit --repo .`, and `git diff --check` passed.

### Outstanding concerns

The command intentionally does not update Chezmoi's source state; users managing a manifest there must carry the reviewed edit into that source. Alternative-group conversion remains a manual decision, not an untracked follow-up.

### Post-change review

The repair path stays within the approved known-shape boundary and does not broaden group selection or silently rewrite on reads. The new command is distinct from clone repair and has passing tests across the public surfaces. It is ready for acceptance review.

### Mini recap

MGIt can now preview and explicitly repair known legacy configuration while rejecting ambiguous shapes. All local gates passed; the user guidance and specification carry the durable contract, with no separate decision record needed.

## Discussion

The old `schema = 1` marker does not make the file a separate supported input contract. It can be removed only when the actual file structure is known and a user opts in to the proposed change.
