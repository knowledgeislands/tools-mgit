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

mkbare() {
  git init -q --bare "$1"
}

make_managed_worktree_repo() {
  local root="$1" branch stage
  branch=$(git -C "$root" branch --show-current)
  stage="$root.mgit-stage"
  mv "$root" "$stage"
  mkdir "$root"
  mv "$stage/.git" "$root/.bare"
  git --git-dir="$root/.bare" config core.bare true
  printf 'gitdir: ./.bare\n' > "$root/.git"
  git -C "$root" worktree add -q main "$branch"
  mv "$stage" "$root/.mgit-backup-test"
}

add_origin_branch() {
  local root="$1" branch="$2" base
  base=$(git -C "$root" branch --show-current)
  git init -q --bare "$TREE/origin.git"
  git -C "$root" remote add origin "$TREE/origin.git"
  git -C "$root" push -q -u origin "$base"
  git -C "$root" checkout -q -b "$branch"
  git -C "$root" commit -q --allow-empty -m "$branch"
  git -C "$root" push -q -u origin "$branch"
  git -C "$root" checkout -q "$base"
}

@test "--help prints usage and exits 0" {
  run "$MGIT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: mgit"* ]]
}

@test "--version prints the version" {
  run "$MGIT" --version
  [ "$status" -eq 0 ]
  [[ "$output" == "mgit 0.3.1" ]]
}

@test "completion prints bash and zsh setup" {
  run "$MGIT" completion bash
  [ "$status" -eq 0 ]
  [[ "$output" == *"complete -F _mgit mgit"* ]]

  run "$MGIT" completion zsh
  [ "$status" -eq 0 ]
  [[ "$output" == *"#compdef mgit"* ]]

  run "$MGIT" completion fish
  [ "$status" -eq 2 ]
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

@test "register records a managed workspace once and standard repo once" {
  mkrepo "$TREE/repoA"
  make_managed_worktree_repo "$TREE/repoA"
  mkrepo "$TREE/repoB"

  cd "$TREE"
  run "$MGIT" register

  [ "$status" -eq 0 ]
  grep -qx "repoA" "$TREE/.mgitconfig"
  grep -qx "repoB" "$TREE/.mgitconfig"
  ! grep -q "main" "$TREE/.mgitconfig"
}

@test "normal commands expand a managed workspace to all child worktrees" {
  mkrepo "$TREE/repoA"
  make_managed_worktree_repo "$TREE/repoA"
  git -C "$TREE/repoA" worktree add -q -b branch-b "$TREE/repoA/branch-b"
  mkrepo "$TREE/repoB"

  cd "$TREE"
  "$MGIT" register >/dev/null
  run "$MGIT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"repoA/main"* ]]
  [[ "$output" == *"repoA/branch-b"* ]]
  [[ "$output" == *"repoB"* ]]
  [[ "$output" != *"repoA/.bare"* ]]

  run "$MGIT" worktree list
  [ "$status" -eq 0 ]
  [[ "$output" == *"repoA/main"* ]]
  [[ "$output" == *"repoA/branch-b"* ]]
}

@test "convert worktree previews then converts every standard repo in the set" {
  mkrepo "$TREE/repo A"
  mkrepo "$TREE/repoB"

  cd "$TREE"
  "$MGIT" register >/dev/null
  run "$MGIT" convert worktree --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would convert $TREE/repo A"* ]]
  [[ "$output" == *"would convert $TREE/repoB"* ]]

  run "$MGIT" convert worktree --yes
  [ "$status" -eq 0 ]
  [ -d "$TREE/repo A/.bare" ]
  [ -f "$TREE/repo A/.git" ]
  [ -f "$TREE/repo A/main/.git" ]
  [ -d "$TREE/repoB/.bare" ]
  [ -f "$TREE/repoB/main/.git" ]

  run "$MGIT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"repo A/main"* ]]
  [[ "$output" == *"repoB/main"* ]]
}

@test "worktree add creates a colocated branch tracking origin across the set" {
  mkrepo "$TREE/repoA"
  add_origin_branch "$TREE/repoA" featureA
  make_managed_worktree_repo "$TREE/repoA"
  mkrepo "$TREE/repoB"

  cd "$TREE"
  "$MGIT" register >/dev/null
  run "$MGIT" worktree add featureA

  [ "$status" -eq 0 ]
  [ -f "$TREE/repoA/featureA/.git" ]
  [ "$(git -C "$TREE/repoA/featureA" branch --show-current)" = "featureA" ]
  [ "$(git -C "$TREE/repoA/featureA" rev-parse --abbrev-ref '@{upstream}')" = "origin/featureA" ]
  [ ! -e "$TREE/repoB/featureA" ]
}

@test "convert standard restores a managed repository with only main" {
  mkrepo "$TREE/repoA"
  make_managed_worktree_repo "$TREE/repoA"

  cd "$TREE"
  "$MGIT" register >/dev/null
  run "$MGIT" convert standard --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would convert $TREE/repoA"* ]]

  run "$MGIT" convert standard --yes
  [ "$status" -eq 0 ]
  [ -d "$TREE/repoA/.git" ]
  [ ! -d "$TREE/repoA/.bare" ]
  [ "$(git -C "$TREE/repoA" status --porcelain)" = "" ]
}

# Helper: run a command, failing the test if it errors (for use inside subshells
# where bats' own `run` isn't available).
run_ok() { "$@"; }
