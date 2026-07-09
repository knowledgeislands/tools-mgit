# Changelog

All notable changes to `mgit` are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
