---
id: KI-TOOL-MGIT-CLI-017
area: CLI
title: Unify repository members
status: triage
blocks: []
blocked_by: []
baseline_ref: null
created_at: 2026-10-17T10:21:23Z
updated_at: 2026-10-17T10:21:23Z
---

## Goal

Represent every repository in a workspace through one understandable member model, including explicitly registered repositories outside the workspace directory. Each member should be identified by its path and carry the same repository metadata, regardless of how it was discovered.

## Context

The Terra dotfiles checkout lives at `~/.local/share/chezmoi` and has a navigation symlink at `~/workspaces/personal/dotfiles`. Its Git remote is `git@github.com:krisb/dotfiles.git`. Because mGit does not discover symlinked repositories, the physical checkout is explicitly registered from the personal workspace.

The current registration writes `repo:../../.local/share/chezmoi` in `locations` and an empty `registered.members` table keyed by `../../.local/share/chezmoi`. Direct local repository entries instead live under `members` and carry `kind`, `type`, and `source`. The owner considers that split unnecessarily awkward: an external repository is still a member, and its path already identifies it.

The requested direction is to put the external path under ordinary `members`, with `kind = "repository"`, `type = "standard"`, and the Git origin as `source`. Retain discovery intent in `locations` where useful, while making the resulting repository set consistent. See the current [repository-set guide](../guides/user/repository-sets.md) for the distinction this proposal would change.

## Boundary

This capture does not adopt, schedule, implement, or release the schema change. It does not rename the dotfiles checkout, change its remote, enable general symlink discovery, alter repository-selection scope, or introduce another runtime dependency.

The working chezmoi registration and navigation symlink remain in place until a reviewed migration is available. Consumer changes belong to their owning repository; this record grants no authority to apply dotfiles or modify live workspaces.

## Discussion

### Member shape and discovery

Use a single path-keyed repository member representation for local discovery and explicit external registration. Determine how `locations` retains refresh intent without requiring a second member namespace. Preserve the distinction between repository and workspace documents and between repository and child-workspace members.

### Path safety and migration

External paths can legitimately leave the workspace directory, while the current direct-member rules assume containment. Define the validation boundary explicitly rather than weakening all path checks. Review registration, parsing, recursive dispatch, identity resolution, and deduplication together.

Decide how existing `registered.members` manifests are read or migrated, how older consumers encounter the new shape, and whether repository metadata is inferred from the physical checkout at registration time. Do not silently discard saved discovery locations or unrelated members during rewriting.

### Verification and repair

The resulting checkout must be dispatched exactly once from both `~/workspaces/personal` and `~/workspaces`, including when the navigation symlink exists. Exercise the public CLI in disposable repositories with isolated configuration, covering external relative paths, duplicate inclusion, nested workspace traversal, invalid paths, and migration failures.

Preserve repair's existing safety boundary: recording an external repository's `source` must not make repair clone it unexpectedly. Ordinary dispatch should continue to use the saved member set offline.

### Consumer coordination

The concrete consumer source is `workspaces/personal/dot_mgit.toml` in [krisb/dotfiles](https://github.com/krisb/dotfiles). Plan its migration alongside the mGit change, preserving source/live agreement and chezmoi's review-and-apply boundary. Update mGit's schema documentation and affected checks when the implementation is approved.
