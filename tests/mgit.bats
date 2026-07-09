#!/usr/bin/env bats
# Smoke tests for mgit. No network; every test builds a throwaway tree of git
# repos under a temp dir and runs the script against it.

setup() {
  MGIT="$BATS_TEST_DIRNAME/../bin/mgit"
  TREE="$BATS_TEST_TMPDIR/tree"
  mkdir -p "$TREE"
  # Quiet, hermetic git — no user config, no signing, no hints.
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t \
         GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
}

# Create a git repo at $1 with one empty commit.
mkrepo() {
  git init -q "$1"
  git -C "$1" commit -q --allow-empty -m init
}

@test "--help prints usage and exits 0" {
  run "$MGIT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: mgit"* ]]
}

@test "--version prints the version" {
  run "$MGIT" --version
  [ "$status" -eq 0 ]
  [[ "$output" == "mgit 0.1.0" ]]
}

@test "unknown option exits 2" {
  run "$MGIT" --nope
  [ "$status" -eq 2 ]
}

@test "register rejects a stray argument" {
  run "$MGIT" register extra
  [ "$status" -eq 2 ]
}

@test "register writes manifests listing members" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  mkrepo "$TREE/sub/c"
  ( cd "$TREE" && run_ok "$MGIT" register )

  [ -f "$TREE/.mgitconfig" ]
  [ -f "$TREE/sub/.mgitconfig" ]
  grep -qx "a" "$TREE/.mgitconfig"
  grep -qx "b" "$TREE/.mgitconfig"
  grep -qx "sub" "$TREE/.mgitconfig"
  grep -qx "c" "$TREE/sub/.mgitconfig"
}

@test "bare mgit lists the discovered repos" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  cd "$TREE"
  "$MGIT" register >/dev/null
  run "$MGIT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"a"* ]]
  [[ "$output" == *"b"* ]]
}

@test "register is idempotent" {
  mkrepo "$TREE/a"
  cd "$TREE"
  "$MGIT" register >/dev/null
  first=$(cat "$TREE/.mgitconfig")
  "$MGIT" register >/dev/null
  second=$(cat "$TREE/.mgitconfig")
  [ "$first" = "$second" ]
}

@test "a cross-repo symlink is recorded as a link line" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  mkdir -p "$TREE/b/shared"                        # link target must be a real dir in repo b
  ( cd "$TREE/a" && ln -s ../b/shared link-to-b )
  cd "$TREE"
  "$MGIT" register >/dev/null
  [ -f "$TREE/a/.mgitconfig" ]
  grep -q -- "link-to-b -> ../b/shared" "$TREE/a/.mgitconfig"
}

# Helper: run a command, failing the test if it errors (for use inside subshells
# where bats' own `run` isn't available).
run_ok() { "$@"; }
