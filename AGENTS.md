# AGENTS.md — tools-mgit

This is the runtime-neutral working convention for `mgit`. The [README](README.md) is the entry point for user-facing purpose, installation, usage, and the `.mgit-config.toml` model.

## Repository model

`mgit` is a single standalone command-line tool: a pure-Bash multi-repository Git driver ([bin/mgit](bin/mgit)). One tool lives in this repository. Its only runtime dependencies are `bash` and `git`; do not add an npm toolchain, `package.json`, or TypeScript.

## Governance

This is a Knowledge Islands `tools-*` repository, governed by the `ki-tools` repository-structure skill. It declares `ki-repo` and `ki-tools` in [.ki-config.toml](.ki-config.toml). Run the native repository audit directly:

```sh
ki repo audit --repo .
```

## Repository shape

- [bin/mgit](bin/mgit) is the executable; it remains executable, carries `MGIT_VERSION`, and answers `--version`.
- [man/mgit.1](man/mgit.1) is the tracked `mgit(1)` manual and must match the command surface.
- [install.sh](install.sh) installs releases and supports `--link` for local development; it honours `MGIT_INSTALL_DIR`, `MGIT_MAN_INSTALL_DIR`, and `MGIT_VERSION`.
- [tests/mgit.bats](tests/mgit.bats) is the Bats smoke suite.
- [.github/workflows/ci.yml](.github/workflows/ci.yml) runs ShellCheck and Bats in CI.
- The [companion Homebrew formula](https://github.com/knowledgeislands/homebrew-tap) distributes `mgit` as `brew install knowledgeislands/tap/mgit`.

## Releasing

1. Bump `MGIT_VERSION` in [bin/mgit](bin/mgit) and add a Keep a Changelog- and SemVer-compliant section to [CHANGELOG.md](CHANGELOG.md).
2. Tag `vX.Y.Z`, push the tag, then run `gh release create vX.Y.Z`.
3. Update the formula's `url` and `sha256` in the Homebrew tap; that repository is governed by `ki-homebrew-tap`.

## Verification

Run these checks before pushing; CI runs both:

```sh
shellcheck bin/mgit install.sh
bats tests/
```

Install them with `brew install shellcheck bats-core`.
