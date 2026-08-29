# AGENTS.md — tools-mgit

This is runtime-neutral working convention for `mgit`. [README](README.md) is entry point for user-facing purpose, installation, usage, and discriminated `.mgit.toml` model.

## Repository model

`mgit` is a single standalone command-line tool: a pure-Bash multi-repository Git driver ([bin/mgit](bin/mgit)). One tool lives in this repository. Its only runtime dependencies are `bash` and `git`; do not add an npm toolchain, `package.json`, or TypeScript.

## Governance

This is a Knowledge Islands `tools-*` repository, governed by the `ki-repo-tools` repository-structure skill. It declares `ki-repo`, `ki-repo-project`, and `ki-repo-tools` in [.ki.toml](.ki.toml). Run the native repository audit directly:

```sh
ki repo audit --repo .
```

## Repository shape

- [bin/mgit](bin/mgit) is the executable; it remains executable, carries `MGIT_VERSION`, and answers `--version`.
- [man/mgit.1](man/mgit.1) is the tracked `mgit(1)` manual and must match the command surface.
- [install.sh](install.sh) installs releases and supports `--link` for local development; it honours `MGIT_INSTALL_DIR`, `MGIT_MAN_INSTALL_DIR`, and `MGIT_VERSION`.
- [tests/mgit.bats](tests/mgit.bats) is the Bats smoke suite.
- [.github/workflows/ci.yml](.github/workflows/ci.yml) runs the repository audit, ShellCheck, Bats, and mandoc in CI.
- The [companion Homebrew formula](https://github.com/knowledgeislands/homebrew-tap) distributes `mgit` as `brew install knowledgeislands/tap/mgit`.

## Releasing

1. Bump `MGIT_VERSION` in [bin/mgit](bin/mgit).
2. Before v1.0.0, keep [CHANGELOG.md](CHANGELOG.md) as one curated list of features intended for v1; do not add per-change or per-0.x-release sections. From v1.0.0 onward, add Keep a Changelog- and SemVer-compliant release sections.
3. Tag `vX.Y.Z`, push the tag, then run `gh release create vX.Y.Z`.
4. Update the formula's `url` and `sha256` in the Homebrew tap; that repository is governed by `ki-repo-homebrew-tap`.

## Verification

Run the complete CI-equivalent gate before pushing:

```sh
ki repo audit --repo .
shellcheck bin/mgit install.sh
bats tests/
mandoc -T lint man/mgit.1
```

Install the external checks with `brew install shellcheck bats-core mandoc`.
