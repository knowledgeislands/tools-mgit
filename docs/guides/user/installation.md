# Install and configure mgit

`mgit` requires Bash 3.2 or later and Git. The macOS system Bash is supported.

## Homebrew

On macOS or Linux, install the published release with:

```sh
brew install knowledgeislands/tap/mgit
```

## Installer

On any system with Bash and Git, install the current release with:

```sh
curl -fsSL https://knowledgeislands.info/install/mgit | bash
```

The website route redirects to the installer from the release currently recommended on the [mgit tool page](https://knowledgeislands.info/tooling/mgit/). Pin an exact release with:

```sh
curl -fsSL https://knowledgeislands.info/install/mgit | bash -s -- vX.Y.Z
```

The positional version takes precedence over `MGIT_VERSION`, which remains available as an environment-variable alias. With neither, the installer discovers the latest release. Both version inputs require an exact `vX.Y.Z` value.

The installer writes `mgit` to `~/.local/bin` by default. Set `MGIT_INSTALL_DIR` to choose another binary directory. It installs the `mgit(1)` manual alongside the binary when that version provides one; set `MGIT_MAN_INSTALL_DIR` to choose another manual directory.

Ensure the binary directory is on your `PATH`. For the default location, add this to your shell configuration if necessary:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

## Shell completion

For Bash, add this to your shell configuration:

```bash
source <(mgit completion bash)
```

For Zsh, add this:

```zsh
mkdir -p ~/.zsh/completions
mgit completion zsh > ~/.zsh/completions/_mgit
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
```

Set `fpath` before `compinit` runs. Run the first two commands again after upgrading `mgit` to refresh the generated completion.

## Confirm the installation

```sh
mgit --version
mgit --help
man mgit
```
