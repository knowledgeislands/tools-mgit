# Definition of done for mgit

Use this checklist before presenting an `mgit` change for review. Release publication has additional requirements in [Release mgit](releasing.md).

Apply the `ki-repo-tools` change-readiness checklist for shared documentation, verification and review requirements, `ki-git` for commit hygiene and authority, and `ki-authoring` for document conventions. This guide supplies MGIT's local checks and executable gates.

## Confirm the change

- `bin/mgit` remains a standalone Bash 3.2-compatible executable with no runtime dependency beyond Bash and Git.
- Changed command behaviour is covered in `tests/mgit.bats`, including invalid syntax and relevant failure paths.
- Repair previews leave manifests and repositories unchanged; apply failures preserve the manifest when preflight rejects a declared member. Diagnostics are read-only and default output excludes local paths and configuration values. Diagnostic fixtures cover linked checkout, receipt-backed and unknown installation provenance; doctor fixtures check the two-unit counts, absent/invalid configuration, failure actions and unchanged files.
- `.mgit.toml` behaviour preserves the documented schema, repository/workspace distinction, and exact repository-selection boundary.

## Verify the repository

Run focused tests while iterating, then the complete gate. Install the external checks with `brew install shellcheck bats-core mandoc` when needed.

```sh
ki repo audit --repo .
shellcheck bin/mgit install.sh
bash -n bin/mgit install.sh
bats tests/
mandoc -T lint man/mgit.1
git diff --check
```

After a manual layout change, inspect the rendered page:

```sh
mandoc -T utf8 man/mgit.1 | col -b
```

Exercise affected commands in disposable repositories with isolated configuration. Do not run mutating Git commands across an unintended live repository set.

## Territory caller proof

For selector changes, run the complete Bats suite with `MGIT_KI_PRODUCER` naming the committed KI pilot executable and `TMPDIR` pointing into the delivery run. `tests/territory-producer.bats` uses only disposable repositories and isolated HOME/XDG directories; `tests/territory-protocol.bats` checks hostile or failed producer streams. The producer proof covers independent registry keys and territory handles, literal repeated filters, missing and ambiguous metadata, spaces/newlines, checkout expansion, old syntax rejection, failed refresh and offline snapshots. Never run mutating commands across a live estate as verification.

```sh
MGIT_KI_PRODUCER=/absolute/path/to/committed/ki TMPDIR=/absolute/run/fixtures bats tests/
```
