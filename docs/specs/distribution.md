# Distribution — MGIT-DIST

This area specifies how people obtain the published command and select a release.

## Public routes

### MGIT-DIST-001 — Website tool routes

Public installation documentation MUST use `https://knowledgeislands.info/tooling/mgit/` for the human-facing product page and `https://knowledgeislands.info/install/mgit` for the machine-facing installer.

_Conformance:_ conforming

_Verify:_ inspect `README.md`, `docs/guides/user/installation.md`, and `man/mgit.1` for both website routes.

_Evidence:_ The README, installation guide, and manual use the website-owned routes while the release artifacts remain repository-owned.

## Version selection

### MGIT-DIST-002 — Exact positional version

The installer MUST accept one optional positional version in exact `vX.Y.Z` form and MUST reject malformed versions or additional arguments before downloading a release.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `installer installs manual and tolerates older releases without one`; `installer rejects malformed versions and extra arguments`.

_Evidence:_ The named Bats checks exercise a valid positional version, malformed positional and environment values, and surplus arguments.

### MGIT-DIST-003 — Version precedence and default

A positional version MUST take precedence over `MGIT_VERSION`, while an invocation with neither input MUST retain latest-release discovery.

_Conformance:_ conforming

_Verify:_ `bats tests/mgit.bats` — `installer installs manual and tolerates older releases without one`.

_Evidence:_ The installer test supplies conflicting positional and environment versions and observes the positional version; source inspection covers the no-input latest-release branch.
