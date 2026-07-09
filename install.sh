#!/usr/bin/env bash
# mgit installer — downloads the mgit script and installs it onto your PATH.
#
#   curl -fsSL https://raw.githubusercontent.com/knowledgeislands/tools-mgit/main/install.sh | bash
#
# Environment overrides:
#   MGIT_INSTALL_DIR   target directory for the mgit binary (default: $HOME/.local/bin)
#   MGIT_VERSION       git ref to install: a tag like v0.1.0, or a branch (default: latest release)
#
# Requires: bash, curl, and git (git is mgit's own runtime dependency).
set -euo pipefail

REPO="knowledgeislands/tools-mgit"
INSTALL_DIR="${MGIT_INSTALL_DIR:-${PREFIX:-$HOME/.local/bin}}"

say()  { printf 'mgit-install: %s\n' "$*"; }
die()  { printf 'mgit-install: error: %s\n' "$*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v git  >/dev/null 2>&1 || say "warning: git not found on PATH — mgit needs git at runtime"

# Resolve the ref to install: an explicit MGIT_VERSION, else the latest release tag.
ref="${MGIT_VERSION:-}"
if [ -z "$ref" ]; then
  ref=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n1) || true
  [ -z "$ref" ] && ref="main"   # no releases yet, or API rate-limited: fall back to main
fi

src="https://raw.githubusercontent.com/$REPO/$ref/bin/mgit"
say "installing mgit ($ref) to $INSTALL_DIR"

mkdir -p "$INSTALL_DIR"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
curl -fsSL "$src" -o "$tmp" || die "download failed: $src"
head -n1 "$tmp" | grep -q '^#!/usr/bin/env bash' || die "downloaded file is not the mgit script"

install -m 0755 "$tmp" "$INSTALL_DIR/mgit"
say "installed $INSTALL_DIR/mgit"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) : ;;
  *) say "note: $INSTALL_DIR is not on your PATH — add it, e.g.:"
     say "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.zshrc" ;;
esac

say "done — run 'mgit --help' to get started"
