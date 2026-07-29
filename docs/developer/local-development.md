# Use a local mgit checkout

Use local mode when developing `mgit` and you want the `mgit` command and `mgit(1)` manual to resolve from this checkout rather than from a released Homebrew or installer version.

## Run without installation

Invoke the checked-out executable directly:

```sh
./bin/mgit --version
./bin/mgit status
man -l man/mgit.1
```

This is the clearest option for a one-off test because it cannot be confused with an installed version.

## Link the checkout

From the repository root, create a local-development link:

```sh
./install.sh --link
```

The command creates symlinks for `mgit` and `mgit.1` in the normal installer locations: `~/.local/bin` and `~/.local/share/man/man1`. It does not download a release. Set `MGIT_INSTALL_DIR` and `MGIT_MAN_INSTALL_DIR` to choose different link locations.

Local-link mode refuses to replace a regular file. This protects a Homebrew or released installation; choose a separate directory rather than pointing `MGIT_INSTALL_DIR` at a package-managed path.

## Prefer the local command

The first `mgit` on `PATH` wins. Confirm what your shell resolves:

```sh
command -v mgit
mgit --version
man -w mgit
```

If Homebrew's `/opt/homebrew/bin` appears before `~/.local/bin`, invoke the checkout directly or put the local link directory first for the current shell:

```sh
export PATH="$HOME/.local/bin:$PATH"
hash -r
```

Use `man -l man/mgit.1` to inspect the checked-out manual regardless of your `MANPATH`.

## Verify before sharing changes

```sh
shellcheck bin/mgit install.sh
bats tests/
```
