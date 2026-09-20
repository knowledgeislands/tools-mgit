# Definition of done for mgit

Use this checklist before presenting an `mgit` change for review. Release publication has additional requirements in [Release mgit](releasing.md).

## Confirm the change

- `bin/mgit` remains a standalone Bash 3.2-compatible executable with no runtime dependency beyond Bash and Git.
- Changed command behaviour is covered in `tests/mgit.bats`, including invalid syntax and relevant failure paths.
- `mgit help`, command help, the README, user guides, `man/mgit.1`, completion output, and the active changelog baseline remain aligned where affected.
- `.mgit.toml` behaviour preserves the documented schema, repository/workspace distinction, and exact repository-selection boundary.
- Removed behaviour leaves no obsolete alias, documentation, completion branch, or unreachable code.

## Verify the repository

Run the complete gate:

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

## Prepare review

- Commit one coherent, verified unit with only the intended paths staged.
- Record unavailable checks or receiver-owned follow-up explicitly.
- Do not push, tag, publish, release, accept roadmap work, or change the Homebrew tap or website without separate authority.
