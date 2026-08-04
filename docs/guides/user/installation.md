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
curl -fsSL https://raw.githubusercontent.com/knowledgeislands/tools-mgit/main/install.sh | bash
```

The installer writes `mgit` to `~/.local/bin` by default. Set `MGIT_INSTALL_DIR` to choose another binary directory, or `MGIT_VERSION` to install a specific tag. It installs the `mgit(1)` manual alongside the binary when that version provides one; set `MGIT_MAN_INSTALL_DIR` to choose another manual directory.

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
