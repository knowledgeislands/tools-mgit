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
  local root="$1" branch="$2" base origin
  base=$(git -C "$root" branch --show-current)
  origin="$TREE/$(basename "$root").origin.git"
  git init -q --bare "$origin"
  git -C "$root" remote add origin "$origin"
  git -C "$root" push -q -u origin "$base"
  git -C "$root" checkout -q -b "$branch"
  git -C "$root" commit -q --allow-empty -m "$branch"
  git -C "$root" push -q -u origin "$branch"
  git -C "$root" checkout -q "$base"
}

make_origin() {
  local checkout="$1" origin="$2" contents="$3"
  mkrepo "$checkout"
  printf '%s\n' "$contents" > "$checkout/payload"
  git -C "$checkout" add payload
  git -C "$checkout" commit -q -m payload
  git init -q --bare "$origin"
  git -C "$checkout" remote add origin "$origin"
  git -C "$checkout" push -q -u origin HEAD
}

make_fake_chezmoi() {
  local bin="$TREE/fake-bin"
  CHEZMOI_TARGET=$(cd "$TREE" && pwd -P)
  CHEZMOI_SOURCE="$CHEZMOI_TARGET/dotfiles"
  CHEZMOI_LOG="$TREE/chezmoi.log"
  export CHEZMOI_SOURCE CHEZMOI_TARGET CHEZMOI_LOG
  mkdir -p "$bin" "$CHEZMOI_SOURCE"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'source_for() {' \
    '  local target="$1" relative parent name' \
    '  case "$target" in "$CHEZMOI_TARGET"/*) ;; *) return 1 ;; esac' \
    '  relative="${target#"$CHEZMOI_TARGET"/}"' \
    '  parent=$(dirname "$relative")' \
    '  name=$(basename "$relative")' \
    '  [ "$parent" = . ] && parent="" || parent="$parent/"' \
    '  printf "%s/%sdot_%s\\n" "$CHEZMOI_SOURCE" "$parent" "${name#.}"' \
    '}' \
    'case "${1:-}" in' \
    '  source-path)' \
    '    if [ "$#" -eq 1 ]; then printf "%s\\n" "$CHEZMOI_SOURCE"; exit 0; fi' \
    '    source=$(source_for "$2") || exit 1' \
    '    [ -e "$source" ] || exit 1' \
    '    printf "%s\\n" "$source"' \
    '    ;;' \
    '  target-path) printf "%s\\n" "$CHEZMOI_TARGET" ;;' \
    '  add)' \
    '    [ "${CHEZMOI_FAIL_ADD:-false}" = true ] && exit 1' \
    '    source=$(source_for "$2") || exit 1' \
    '    mkdir -p "$(dirname "$source")"' \
    '    cp "$2" "$source"' \
    '    printf "add %s\\n" "$2" >> "$CHEZMOI_LOG"' \
    '    ;;' \
    '  forget)' \
    '    source=$(source_for "$2") || exit 1' \
    '    rm -f "$source"' \
    '    printf "forget %s\\n" "$2" >> "$CHEZMOI_LOG"' \
    '    ;;' \
    '  *) exit 2 ;;' \
    'esac' > "$bin/chezmoi"
  chmod +x "$bin/chezmoi"
  PATH="$bin:$PATH"
}

@test "--help prints usage and exits 0" {
  run "$MGIT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: mgit"* ]]
}

@test "--version prints the version" {
  run "$MGIT" --version
  [ "$status" -eq 0 ]
  [[ "$output" == "mgit 0.5.1" ]]
}

@test "completion prints bash and zsh setup" {
  run "$MGIT" completion bash
  [ "$status" -eq 0 ]
  [[ "$output" == *"complete -F _mgit mgit"* ]]
  [[ "$output" == *"structure"* ]]
  [[ "$output" == *"bootstrap"* ]]
  [[ "$output" != *"convert"* ]]

  run "$MGIT" completion zsh
  [ "$status" -eq 0 ]
  [[ "$output" == *"#compdef mgit"* ]]
  [[ "$output" == *"standard nested"* ]]

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
  grep -qx "standard a" "$TREE/.mgitconfig"
  grep -qx "standard b" "$TREE/.mgitconfig"
  grep -qx "dir sub" "$TREE/.mgitconfig"
  grep -qx "standard c" "$TREE/sub/.mgitconfig"
}

@test "register records origin URLs for typed repository members" {
  make_origin "$TREE/repoA" "$TREE/repoA.origin.git" payload

  ( cd "$TREE" && run_ok "$MGIT" register )

  grep -Fx "standard repoA -> $TREE/repoA.origin.git" "$TREE/.mgitconfig"
}

@test "register synchronizes generated manifests with chezmoi" {
  make_fake_chezmoi
  make_origin "$TREE/repoA" "$BATS_TEST_TMPDIR/repoA.origin.git" payload

  cd "$TREE"
  run "$MGIT" register

  [ "$status" -eq 0 ]
  cmp "$TREE/.mgitconfig" "$CHEZMOI_SOURCE/dot_mgitconfig"
  grep -Fx "standard repoA -> $BATS_TEST_TMPDIR/repoA.origin.git" "$CHEZMOI_SOURCE/dot_mgitconfig"
  grep -Fx "add $CHEZMOI_TARGET/.mgitconfig" "$CHEZMOI_LOG"

  mv "$TREE/repoA" "$BATS_TEST_TMPDIR/removed-repoA"
  run "$MGIT" register

  [ "$status" -eq 1 ]
  [ ! -e "$TREE/.mgitconfig" ]
  [ ! -e "$CHEZMOI_SOURCE/dot_mgitconfig" ]
  grep -Fx "forget $CHEZMOI_TARGET/.mgitconfig" "$CHEZMOI_LOG"
}

@test "register reports chezmoi synchronization failures" {
  make_fake_chezmoi
  export CHEZMOI_FAIL_ADD=true
  mkrepo "$TREE/repoA"

  cd "$TREE"
  run "$MGIT" register

  [ "$status" -eq 2 ]
  [[ "$output" == *"failed to add manifest to chezmoi"* ]]
  [[ "$output" != *"no git repos found"* ]]
}

@test "register does not manage manifests inside the chezmoi source directory" {
  make_fake_chezmoi
  mkrepo "$CHEZMOI_SOURCE/repoA"

  cd "$CHEZMOI_SOURCE"
  run "$MGIT" register

  [ "$status" -eq 0 ]
  [ -f "$CHEZMOI_SOURCE/.mgitconfig" ]
  [ ! -e "$CHEZMOI_LOG" ]
}

@test "bootstrap clones typed manifest members and recreates nested layout" {
  make_origin "$TREE/source-standard" "$TREE/standard.origin.git" standard
  make_origin "$TREE/source-nested" "$TREE/nested.origin.git" nested
  mkdir -p "$TREE/workspace/group"
  printf 'standard standard-repo -> %s\nnested nested-repo -> %s\nbare bare-repo.git -> %s\ndir group\n' \
    "$TREE/standard.origin.git" "$TREE/nested.origin.git" "$TREE/standard.origin.git" > "$TREE/workspace/.mgitconfig"
  printf 'standard grouped-repo -> %s\n' "$TREE/standard.origin.git" > "$TREE/workspace/group/.mgitconfig"

  cd "$TREE/workspace"
  run "$MGIT" bootstrap

  [ "$status" -eq 0 ]
  [ "$(cat "$TREE/workspace/standard-repo/payload")" = standard ]
  [ -d "$TREE/workspace/nested-repo/.bare" ]
  [ -f "$TREE/workspace/nested-repo/main/.git" ]
  [ "$(cat "$TREE/workspace/nested-repo/main/payload")" = nested ]
  [ "$(git -C "$TREE/workspace/bare-repo.git" rev-parse --is-bare-repository)" = true ]
  [ "$(cat "$TREE/workspace/group/grouped-repo/payload")" = standard ]

  run "$MGIT" bootstrap
  [ "$status" -eq 0 ]
  [[ "$output" == *"present "*"standard-repo"* ]]
}

@test "bootstrap refuses a missing member without a clone URL" {
  printf 'standard missing-repo\n' > "$TREE/.mgitconfig"

  cd "$TREE"
  run "$MGIT" bootstrap

  [ "$status" -eq 1 ]
  [ ! -e "$TREE/missing-repo" ]
  [[ "$output" == *"no clone URL"* ]]
}

@test "bare mgit lists the discovered repos" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  cd "$TREE"
  "$MGIT" register >/dev/null
  ! grep -q "repoB-branch-c" "$TREE/.mgitconfig"
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

@test "register records nested and standard structures once" {
  mkrepo "$TREE/repoA"
  make_managed_worktree_repo "$TREE/repoA"
  mkrepo "$TREE/repoB"

  cd "$TREE"
  run "$MGIT" register

  [ "$status" -eq 0 ]
  grep -qx "nested repoA" "$TREE/.mgitconfig"
  grep -qx "standard repoB" "$TREE/.mgitconfig"
  ! grep -Eq '^(standard|nested|bare|dir) main$' "$TREE/.mgitconfig"
}

@test "legacy untyped config members remain valid" {
  mkrepo "$TREE/repoA"
  printf 'repoA\n' > "$TREE/.mgitconfig"

  cd "$TREE"
  run "$MGIT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"repoA"* ]]
}

@test "normal commands expand a managed workspace to all child worktrees" {
  mkrepo "$TREE/repoA"
  make_managed_worktree_repo "$TREE/repoA"
  git -C "$TREE/repoA" worktree add -q -b branch-b "$TREE/repoA/branch-b"
  mkrepo "$TREE/repoB"
  git -C "$TREE/repoB" worktree add -q -b branch-c "$TREE/repoB-branch-c"

  cd "$TREE"
  "$MGIT" register >/dev/null
  run "$MGIT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"repoA/main"* ]]
  [[ "$output" == *"repoA/branch-b"* ]]
  [[ "$output" == *"repoB"* ]]
  [[ "$output" == *"repoB-branch-c"* ]]
  [[ "$output" != *"repoA/.bare"* ]]

  run "$MGIT" worktree list
  [ "$status" -eq 0 ]
  [[ "$output" == *"repoA/main"* ]]
  [[ "$output" == *"repoA/branch-b"* ]]
}

@test "structure nested previews then restructures every standard repo in the set" {
  mkrepo "$TREE/repo A"
  mkrepo "$TREE/repoB"

  cd "$TREE"
  "$MGIT" register >/dev/null
  run "$MGIT" structure nested --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would restructure $TREE/repo A"* ]]
  [[ "$output" == *"would restructure $TREE/repoB"* ]]

  run "$MGIT" structure nested --yes
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

@test "worktree add uses nested and sibling destinations across the set" {
  mkrepo "$TREE/repoA"
  add_origin_branch "$TREE/repoA" featureA
  make_managed_worktree_repo "$TREE/repoA"
  mkrepo "$TREE/repoB"
  add_origin_branch "$TREE/repoB" featureA

  cd "$TREE"
  "$MGIT" register >/dev/null
  run "$MGIT" worktree add featureA

  [ "$status" -eq 0 ]
  [ -f "$TREE/repoA/featureA/.git" ]
  [ "$(git -C "$TREE/repoA/featureA" branch --show-current)" = "featureA" ]
  [ "$(git -C "$TREE/repoA/featureA" rev-parse --abbrev-ref '@{upstream}')" = "origin/featureA" ]
  [ -f "$TREE/repoB-featureA/.git" ]
  [ "$(git -C "$TREE/repoB-featureA" branch --show-current)" = "featureA" ]
  [ "$(git -C "$TREE/repoB-featureA" rev-parse --abbrev-ref '@{upstream}')" = "origin/featureA" ]
}

@test "worktree remove supports a standard sibling and protects the primary checkout" {
  mkrepo "$TREE/repoA"
  git -C "$TREE/repoA" worktree add -q -b featureA "$TREE/repoA-featureA"

  cd "$TREE/repoA"
  run "$MGIT" worktree remove "$TREE/repoA-featureA" --yes
  [ "$status" -eq 0 ]
  [ ! -e "$TREE/repoA-featureA" ]

  run "$MGIT" worktree remove "$TREE/repoA" --yes
  [ "$status" -eq 1 ]
  [[ "$output" == *"primary working tree"* ]]
}

@test "structure standard restores a nested repository with only main" {
  mkrepo "$TREE/repoA"
  make_managed_worktree_repo "$TREE/repoA"

  cd "$TREE"
  "$MGIT" register >/dev/null
  run "$MGIT" structure standard --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would restructure $TREE/repoA"* ]]

  run "$MGIT" structure standard --yes
  [ "$status" -eq 0 ]
  [ -d "$TREE/repoA/.git" ]
  [ ! -d "$TREE/repoA/.bare" ]
  [ "$(git -C "$TREE/repoA" status --porcelain)" = "" ]
}

# Helper: run a command, failing the test if it errors (for use inside subshells
# where bats' own `run` isn't available).
run_ok() { "$@"; }
