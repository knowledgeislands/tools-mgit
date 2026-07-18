# Changelog

All notable changes to `mgit` are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- `mgit bootstrap` clones missing manifest members from recorded `origin` URLs and recreates standard, nested, and bare layouts without replacing existing paths.

### Changed

- Generated typed repository entries now include ` -> <origin-url>` when an `origin` remote is configured.

## [0.4.1] — 2026-07-16

### Changed

- Generated `.mgitconfig` files now label repository members as `standard`, `nested`, or `bare`, and directory members as `dir`.
- Existing untyped member entries remain valid; Git continues to verify each repository's live structure at runtime.

## [0.4.0] — 2026-07-16

### Changed

- Replaced `mgit convert` with `mgit structure standard|nested`; there are no compatibility aliases.
- Renamed the opinionated colocated layout to the `nested` structure.
- Normal multi-repository commands now expand standard repositories to their active sibling linked worktrees as well as nested repositories to their child checkouts.
- `mgit worktree add` and `remove` support both structures, selecting sibling paths for standard repositories and child paths for nested repositories.

## [0.3.1] — 2026-07-15

### Added

- `mgit completion bash` and `mgit completion zsh` for command, option, and worktree subcommand completion.

## [0.3.0] — 2026-07-15

### Changed

- Worktree repositories now use mgit's opinionated colocated `.bare/`, `.git`, and `main/` layout.
- `mgit register` records each managed worktree repository once, while normal operations expand it to every active checkout.

### Added

- `mgit convert worktree` and `mgit convert standard`, both preview- and confirmation-gated.
- Bulk remote-tracking `mgit worktree add <branch>` for every managed repository in the current set.

## [0.2.0] — 2026-07-15

### Added

- Git-aware repository discovery for normal checkouts, linked worktrees, and bare `*.git` stores.
- `mgit worktree list` and `mgit worktree status`, grouped by each repository's shared Git common directory.
- Safe `mgit worktree add` and confirmation-gated `mgit worktree remove` commands, including optional grouped workspace placement through `MGIT_WORKTREE_ROOT`.
- A staged worktree migration guide that leaves existing repositories in place until the user explicitly retires them.

## [0.1.0] — 2026-07-09

Initial public release.

### Added

- `mgit [command]` — run a git (or, with `-B`, bare) command across every repo in a tree,
  discovered by walking for `.git` or pinned by a `.mgitconfig` manifest.
- `mgit register` — generate `.mgitconfig` manifests across a directory tree, recording
  container/leaf members and cross-repo symlinks.
- Options: `-P/--physical`, `-L/--follow-symlinks`, `-B/--bare`, `-I/--ignore`,
  `-h/--help`, `-V/--version`.
- Homebrew tap install (`knowledgeislands/tap/mgit`) and a `curl | bash` installer.

[0.1.0]: https://github.com/knowledgeislands/tools-mgit/releases/tag/v0.1.0
[0.2.0]: https://github.com/knowledgeislands/tools-mgit/releases/tag/v0.2.0
[0.3.0]: https://github.com/knowledgeislands/tools-mgit/releases/tag/v0.3.0
[0.3.1]: https://github.com/knowledgeislands/tools-mgit/releases/tag/v0.3.1
