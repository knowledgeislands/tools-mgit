# AGENTS.md — tools-mgit

This is runtime-neutral working convention for `mgit`. [README](README.md) is entry point for user-facing purpose, installation, usage, and discriminated `.mgit.toml` model.

## Repository model

`mgit` is a single standalone command-line tool: a pure-Bash multi-repository Git driver ([bin/mgit](bin/mgit)). One tool lives in this repository. Its only runtime dependencies are `bash` and `git`; do not add an npm toolchain, `package.json`, or TypeScript.

## Governing sources

Use `ki-repo-tools` for the shared CLI, distribution, change-readiness and release-readiness contracts; `ki-git` for Git hygiene and commit/publication authority; and `ki-authoring` for Markdown and TOML conventions. Repository shape and authority follow `ki-repo` and `ki-repo-project`.

Use the [definition of done](docs/guides/developer/definition-of-done.md) for MGIT's checks and executable verification gate, and [Release mgit](docs/guides/developer/releasing.md) for its version source and publication procedure.

## Local boundaries

`bin/mgit` owns `MGIT_VERSION`. Preserve the discriminated `.mgit.toml` repository/workspace model and exact repository-selection boundary. Exercise mutating behaviour in disposable Git repositories with isolated configuration.
