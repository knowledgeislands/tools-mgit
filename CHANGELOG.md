# Changelog

All notable changes to `mgit` are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.10.0] — 2026-08-10

### Added

- Add `mgit group` commands for creating, deleting, and managing named alternative workspace groups.
- Add `--agora <name>` to run Git or bare commands across the exact local roots resolved by `ki` for an Agora or `estate`.
- Add contextual `mgit help` output and matching Bash and Zsh completion for the command hierarchy and workspace groups.

### Changed

- Apply `mgit structure standard|nested` changes by default; `--dry-run` now provides the explicit preview.
- Remove the `--yes` confirmation requirement from `mgit worktree remove <path>`.

## [0.9.0] — 2026-08-05

### Changed

- Place standard-repository worktrees created by `mgit worktree add` under `.git/mgit-worktrees/<branch>`.
- Require an explicit `list`, `status`, `add`, or `remove` action after `mgit worktree`.

### Fixed

- Correct Zsh completion registration and command candidates.

## [0.8.1] — 2026-07-30

### Changed

- Represent workspace members as path-keyed TOML tables, including nested workspace members.
- Document workspace and repository configuration canonically in `mgit(1)`'s `FILES` section.
