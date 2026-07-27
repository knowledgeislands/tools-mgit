# CLAUDE.md — tools-mgit

Guidance for Claude Code working in this repo. The user-facing tool surface — what `mgit` does, install, usage, the `.mgitconfig` model — lives in [README.md](./README.md); this file covers what isn't there and isn't derivable from one grep.

## What this repo is

A single standalone command-line tool: `mgit`, a pure-bash multi-repo git driver ([bin/mgit](./bin/mgit)). One tool per repo. Its only runtime dependencies are `bash` and `git`. There is **no `package.json` and no TypeScript** — this is deliberate; do not add an npm toolchain.

## Governance

This is a Knowledge Islands `tools-*` repo, governed by the **`ki-tools`** repo-structure skill (see the [ki-agentic-harness](https://github.com/knowledgeislands/ki-agentic-harness)). It declares `[ki-repo]` + `[ki-tools]` in [.ki-config.toml](./.ki-config.toml). It has no `package.json`; run the native repository audit directly:

```sh
ki repo audit --repo .
```

## Shape (what ki-tools expects)

- [bin/mgit](./bin/mgit) — the executable (chmod +x); carries `MGIT_VERSION` and answers `--version`.
- [man/mgit.1](./man/mgit.1) — the tracked `mgit(1)` manual, which must match the current command surface.
- [install.sh](./install.sh) — the `curl | bash` installer; honours `MGIT_INSTALL_DIR`, `MGIT_MAN_INSTALL_DIR`, and `MGIT_VERSION`.
- [tests/mgit.bats](./tests/mgit.bats) — the bats smoke suite.
- [.github/workflows/ci.yml](./.github/workflows/ci.yml) — CI: `shellcheck` + `bats`.
- Distribution: a companion formula in the [homebrew-tap](https://github.com/knowledgeislands/homebrew-tap) repo (`brew install knowledgeislands/tap/mgit`).

## Releasing a new version

1. Bump `MGIT_VERSION` in [bin/mgit](./bin/mgit) and add a section to [CHANGELOG.md](./CHANGELOG.md) (keep-a-changelog + semver).
2. Tag `vX.Y.Z`, push the tag, `gh release create vX.Y.Z`.
3. Update `url` + `sha256` in the tap's `Formula/mgit.rb` (governed by `ki-homebrew-tap`).

## Local checks

`shellcheck bin/mgit install.sh` and `bats tests/` must be clean before pushing (CI runs both). Install them with `brew install shellcheck bats-core`.
