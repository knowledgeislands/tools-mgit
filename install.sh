#!/usr/bin/env bash
# mgit installer — downloads the mgit script and installs it onto your PATH.
#
#   curl -fsSL https://raw.githubusercontent.com/knowledgeislands/tools-mgit/main/install.sh | bash
#   ./install.sh --link
#
# Environment overrides:
#   MGIT_INSTALL_DIR       target directory for the mgit binary (default: $HOME/.local/bin)
#   MGIT_MAN_INSTALL_DIR   target directory for mgit(1) (default: matching share/man/man1 directory)
#   MGIT_VERSION           git ref to install: a tag like v0.1.0, or a branch (default: latest release)
#
# Requires: bash, curl, and git (git is mgit's own runtime dependency).
set -euo pipefail

REPO="knowledgeislands/tools-mgit"
INSTALL_DIR="${MGIT_INSTALL_DIR:-${PREFIX:-$HOME/.local/bin}}"
MAN_INSTALL_DIR="${MGIT_MAN_INSTALL_DIR:-$(dirname "$INSTALL_DIR")/share/man/man1}"
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

say()  { printf 'mgit-install: %s\n' "$*"; }
die()  { printf 'mgit-install: error: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: ./install.sh [--link]

Install the latest released mgit, or use --link from a local checkout to link
the executable and manual to that checkout without downloading a release.
EOF
}

if [ "$#" -gt 1 ]; then
  usage >&2
  exit 2
fi

case "${1:-}" in
  '') mode="release" ;;
  --link) mode="link" ;;
  -h|--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

command -v git  >/dev/null 2>&1 || say "warning: git not found on PATH — mgit needs git at runtime"

if [ "$mode" = link ]; then
  source_bin="$SCRIPT_DIR/bin/mgit"
  source_man="$SCRIPT_DIR/man/mgit.1"
  [ -f "$source_bin" ] || die "local source executable not found: $source_bin"
  [ -f "$source_man" ] || die "local source manual not found: $source_man"
  mkdir -p "$INSTALL_DIR" "$MAN_INSTALL_DIR"
  for target in "$INSTALL_DIR/mgit" "$MAN_INSTALL_DIR/mgit.1"; do
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      die "refusing to replace regular file in --link mode: $target"
    fi
  done
  ln -sfn "$source_bin" "$INSTALL_DIR/mgit"
  ln -sfn "$source_man" "$MAN_INSTALL_DIR/mgit.1"
  say "linked $INSTALL_DIR/mgit -> $source_bin"
  say "linked $MAN_INSTALL_DIR/mgit.1 -> $source_man"
  case ":$PATH:" in
    *":$INSTALL_DIR:"*) : ;;
    *) say "note: $INSTALL_DIR is not on your PATH — add it, e.g.:"
       say "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.zshrc" ;;
  esac
  say "done — run 'mgit --help' to get started"
  exit 0
fi

command -v curl >/dev/null 2>&1 || die "curl is required"

# Resolve the ref to install: an explicit MGIT_VERSION, else the latest release tag.
ref="${MGIT_VERSION:-}"
if [ -z "$ref" ]; then
  ref=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n1) || true
  [ -z "$ref" ] && ref="main"   # no releases yet, or API rate-limited: fall back to main
fi

src="https://raw.githubusercontent.com/$REPO/$ref/bin/mgit"
man_src="https://raw.githubusercontent.com/$REPO/$ref/man/mgit.1"
say "installing mgit ($ref) to $INSTALL_DIR"

mkdir -p "$INSTALL_DIR"
mkdir -p "$MAN_INSTALL_DIR"
tmp=$(mktemp)
man_tmp=$(mktemp)
trap 'rm -f "$tmp" "$man_tmp"' EXIT
curl -fsSL "$src" -o "$tmp" || die "download failed: $src"
head -n1 "$tmp" | grep -q '^#!/usr/bin/env bash' || die "downloaded file is not the mgit script"

install -m 0755 "$tmp" "$INSTALL_DIR/mgit"
say "installed $INSTALL_DIR/mgit"
if curl -fsSL "$man_src" -o "$man_tmp"; then
  head -n1 "$man_tmp" | grep -q '^\.TH MGIT 1' || die "downloaded file is not the mgit manual"
  install -m 0644 "$man_tmp" "$MAN_INSTALL_DIR/mgit.1"
  say "installed $MAN_INSTALL_DIR/mgit.1"
else
  say "warning: manual unavailable for $ref; installed the executable only"
fi

case ":$PATH:" in
  *":$INSTALL_DIR:"*) : ;;
  *) say "note: $INSTALL_DIR is not on your PATH — add it, e.g.:"
     say "  echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.zshrc" ;;
esac

say "done — run 'mgit --help' to get started"
