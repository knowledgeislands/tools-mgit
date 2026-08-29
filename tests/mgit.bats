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
    '    [ "${CHEZMOI_FAIL_FORGET:-false}" = true ] && exit 1' \
    '    target="${3:-$2}"' \
    '    source=$(source_for "$target") || exit 1' \
    '    rm -f "$source"' \
    '    printf "forget %s\\n" "$target" >> "$CHEZMOI_LOG"' \
    '    ;;' \
    '  *) exit 2 ;;' \
    'esac' > "$bin/chezmoi"
  chmod +x "$bin/chezmoi"
  PATH="$bin:$PATH"
}

make_fake_ki() {
  local bin="$TREE/fake-ki-bin"
  mkdir -p "$bin"
  FAKE_KI_AGORA=focus
  FAKE_KI_ROOTS=""
  FAKE_KI_FAIL=false
  export FAKE_KI_AGORA FAKE_KI_ROOTS FAKE_KI_FAIL
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    '[ "$1" = agora ] && [ "$2" = roots ] && [ "$3" = --null ] || exit 64' \
    '[ "$4" = "$FAKE_KI_AGORA" ] || { printf "unknown Agora: %s\\n" "$4" >&2; exit 65; }' \
    '[ "$FAKE_KI_FAIL" = false ] || { printf "fake Agora resolution failed\\n" >&2; exit 73; }' \
    'while IFS= read -r root || [ -n "$root" ]; do printf "%s\\0" "$root"; done <<< "$FAKE_KI_ROOTS"' \
    > "$bin/ki"
  chmod +x "$bin/ki"
  PATH="$bin:$PATH"
}

@test "--help prints usage and exits 0" {
  run "$MGIT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: mgit"* ]]
  [[ "$output" == *"ignore workspace manifests and discover repositories"* ]]
  [[ "$output" == *"--agora <name>"* ]]
  [[ "$output" == *"--estate"* ]]
  [[ "$output" == *"passed through to Git"* ]]
}

@test "--version prints the version" {
  run "$MGIT" --version
  [ "$status" -eq 0 ]
  [[ "$output" == "mgit 0.12.0" ]]
}

@test "installer installs the manual and tolerates older releases without one" {
  local fake_bin="$BATS_TEST_TMPDIR/fake-bin"
  local install_bin="$BATS_TEST_TMPDIR/bin"
  local install_man="$BATS_TEST_TMPDIR/man/man1"
  local missing_man="$BATS_TEST_TMPDIR/missing-man/man1"
  mkdir -p "$fake_bin"
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    'case "$2" in' \
    '  */bin/mgit) cp "$FAKE_MGIT" "$4" ;;' \
    '  */man/mgit.1) [ -n "$FAKE_MAN" ] || exit 22; cp "$FAKE_MAN" "$4" ;;' \
    '  *) exit 1 ;;' \
    'esac' > "$fake_bin/curl"
  chmod +x "$fake_bin/curl"

  run env \
    FAKE_MGIT="$MGIT" \
    FAKE_MAN="$BATS_TEST_DIRNAME/../man/mgit.1" \
    MGIT_INSTALL_DIR="$install_bin" \
    MGIT_MAN_INSTALL_DIR="$install_man" \
    MGIT_VERSION=test \
    PATH="$fake_bin:$PATH" \
    "$BATS_TEST_DIRNAME/../install.sh"

  [ "$status" -eq 0 ]
  [ -x "$install_bin/mgit" ]
  cmp "$MGIT" "$install_bin/mgit"
  cmp "$BATS_TEST_DIRNAME/../man/mgit.1" "$install_man/mgit.1"

  run env \
    FAKE_MGIT="$MGIT" \
    FAKE_MAN="" \
    MGIT_INSTALL_DIR="$install_bin" \
    MGIT_MAN_INSTALL_DIR="$missing_man" \
    MGIT_VERSION=older-release \
    PATH="$fake_bin:$PATH" \
    "$BATS_TEST_DIRNAME/../install.sh"

  [ "$status" -eq 0 ]
  [ -x "$install_bin/mgit" ]
  [ ! -e "$missing_man/mgit.1" ]
  [[ "$output" == *"manual unavailable for older-release"* ]]
}

@test "installer --link links the local executable and manual" {
  local install_bin="$BATS_TEST_TMPDIR/bin"
  local install_man="$BATS_TEST_TMPDIR/man/man1"

  run env \
    MGIT_INSTALL_DIR="$install_bin" \
    MGIT_MAN_INSTALL_DIR="$install_man" \
    "$BATS_TEST_DIRNAME/../install.sh" --link

  [ "$status" -eq 0 ]
  [ -L "$install_bin/mgit" ]
  [ -L "$install_man/mgit.1" ]
  cmp "$MGIT" "$install_bin/mgit"
  cmp "$BATS_TEST_DIRNAME/../man/mgit.1" "$install_man/mgit.1"
  run "$install_bin/mgit" --version
  [ "$status" -eq 0 ]
  [ "$output" = "mgit 0.12.0" ]
}

@test "completion prints bash and zsh setup" {
  run "$MGIT" completion bash
  [ "$status" -eq 0 ]
  [[ "$output" == *"complete -F _mgit mgit"* ]]
  [[ "$output" == *"structure"* ]]
  [[ "$output" == *"repair"* ]]
  [[ "$output" == *"--estate"* ]]
  [[ "$output" != *"bootstrap"* ]]
  [[ "$output" != *"convert"* ]]

  run "$MGIT" completion zsh
  [ "$status" -eq 0 ]
  [[ "$output" == *"#compdef mgit"* ]]
  [[ "$output" == *"standard nested"* ]]
  [[ "$output" == *"--estate"* ]]
  [[ "$output" == *"compdef _mgit mgit"* ]]
  [[ "$output" != *'_mgit "$@"'* ]]

  run "$MGIT" completion fish
  [ "$status" -eq 2 ]
}

@test "zsh completion evaluates and registers mgit" {
  run zsh -f -c '
    autoload -Uz compinit && compinit -C
    eval "$("$1" completion zsh)"
    [[ ${_comps[mgit]} == _mgit ]]
  ' zsh "$MGIT"

  [ "$status" -eq 0 ]
}

@test "zsh completion passes worktree commands to _describe as an array" {
  run zsh -f -c '
    autoload -Uz compinit && compinit -C
    eval "$("$1" completion zsh)"
    _describe() { print -r -- "$@"; }
    words=(mgit worktree "")
    _mgit
  ' zsh "$MGIT"

  [ "$status" -eq 0 ]
  [ "$output" = '-t commands worktree command worktree_commands' ]
}

@test "zsh completion dispatches root commands to _describe directly" {
  run zsh -f -c '
    autoload -Uz compinit && compinit -C
    eval "$("$1" completion zsh)"
    _arguments() { state=(command); }
    _describe() { print -r -- "$@"; }
    words=(mgit "")
    _mgit
  ' zsh "$MGIT"

  [ "$status" -eq 0 ]
  [ "$output" = '-t commands command global_commands' ]
}

@test "unknown option exits 2" {
  run "$MGIT" --nope
  [ "$status" -eq 2 ]
}

@test "worktree requires an explicit action" {
  run "$MGIT" worktree
  [ "$status" -eq 2 ]
  [[ "$output" == *"worktree: expected list, status, add, or remove"* ]]
}

assert_usage_error() {
  run "$MGIT" "$@"
  [ "$status" -eq 2 ]
  [[ "$output" == mgit:\ error:* ]]
  [[ "$output" == *"Usage: mgit"* ]]
}

@test "invalid owned syntax wins over help" {
  assert_usage_error --nope --help
  assert_usage_error --help --nope
  assert_usage_error register extra --help
  assert_usage_error register --help extra
  assert_usage_error repair extra --help
  assert_usage_error repair --help extra
  assert_usage_error completion fish --help
  assert_usage_error completion --help fish
  assert_usage_error structure sideways --help
  assert_usage_error structure nested --wat --help
  assert_usage_error structure nested --yes
  assert_usage_error worktree nope --help
  assert_usage_error worktree remove --wat --help
  assert_usage_error worktree remove --yes
}

@test "standalone reserved-command help exits 0" {
  for command in register repair group structure worktree completion; do
    run "$MGIT" "$command" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: mgit"* ]]
  done
}

@test "help is contextual for reserved commands and their subcommands" {
  run "$MGIT" register -h
  [ "$status" -eq 0 ]
  [[ "$output" == "Usage: mgit register [options]"* ]]
  [[ "$output" != *"Commands:"* ]]

  run "$MGIT" help group create
  [ "$status" -eq 0 ]
  [[ "$output" == "Usage: mgit group create <name>"* ]]

  run "$MGIT" help group add
  [ "$status" -eq 0 ]
  [[ "$output" == "Usage: mgit group add <name> <member>"* ]]

  run "$MGIT" help worktree remove
  [ "$status" -eq 0 ]
  [[ "$output" == "Usage: mgit worktree remove <path> [--force]"* ]]
}

@test "reserved command trees reject unknown subcommands" {
  run "$MGIT" group unknown
  [ "$status" -eq 2 ]
  [[ "$output" == *"group: unknown command: unknown"* ]]

  run "$MGIT" structure sideways
  [ "$status" -eq 2 ]
  [[ "$output" == *"structure: unknown command: sideways"* ]]
}

@test "bash completion includes group commands" {
  mkrepo "$TREE/a"
  cd "$TREE"
  "$MGIT" register >/dev/null
  "$MGIT" group create engineering >/dev/null
  eval "$("$MGIT" completion bash)"
  COMP_WORDS=(mgit group "")
  COMP_CWORD=2
  _mgit
  [[ " ${COMPREPLY[*]} " == *" create "* ]]
  [[ " ${COMPREPLY[*]} " == *" delete "* ]]
  [[ " ${COMPREPLY[*]} " == *" add "* ]]
  [[ " ${COMPREPLY[*]} " == *" remove "* ]]

  COMP_WORDS=(mgit --group e)
  COMP_CWORD=2
  _mgit
  [[ " ${COMPREPLY[*]} " == *" engineering "* ]]

  COMP_WORDS=(mgit group add "")
  COMP_CWORD=3
  _mgit
  [[ " ${COMPREPLY[*]} " == *" engineering "* ]]

  COMP_WORDS=(mgit group add engineering "")
  COMP_CWORD=4
  _mgit
  [[ " ${COMPREPLY[*]} " == *" a "* ]]
}

@test "zsh completion exposes the complete group command inventory" {
  run zsh -f -c '
    autoload -Uz compinit && compinit -C
    eval "$("$1" completion zsh)"
    _describe() { print -r -- "$@"; }
    words=(mgit group "")
    _mgit
  ' zsh "$MGIT"

  [ "$status" -eq 0 ]
  [ "$output" = '-t commands group command group_commands' ]

  run "$MGIT" completion zsh
  [ "$status" -eq 0 ]
  [[ "$output" == *"'create:create a named alternative group'"* ]]
  [[ "$output" == *"'delete:delete a named alternative group'"* ]]
  [[ "$output" == *"'add:add a default-group member to a group'"* ]]
  [[ "$output" == *"'remove:remove a member from a group'"* ]]
}

@test "group commands reject incomplete and surplus arguments" {
  mkrepo "$TREE/a"
  cd "$TREE"
  "$MGIT" register >/dev/null

  assert_usage_error group create
  assert_usage_error group create engineering a
  assert_usage_error group delete
  assert_usage_error group add
  assert_usage_error group add engineering
  assert_usage_error group add engineering a extra
  assert_usage_error group remove
  assert_usage_error group remove engineering
  assert_usage_error group remove engineering a extra
}

@test "ordinary Git command options remain pass-through" {
  mkrepo "$TREE/repo"
  cd "$TREE/repo"

  run "$MGIT" status --short

  [ "$status" -eq 0 ]
  [[ "$output" == *"git status --short"* ]]
}

@test "--agora selects only NUL-delimited roots from ki" {
  mkrepo "$TREE/first"
  mkrepo "$TREE/with space"
  make_fake_ki
  FAKE_KI_ROOTS="$TREE/first"$'\n'"$TREE/with space"

  cd "$TREE"
  run "$MGIT" --agora focus

  [ "$status" -eq 0 ]
  [ "$output" = $'first\nwith space' ]

  run "$MGIT" --agora focus -f first
  [ "$status" -eq 0 ]
  [ "$output" = "first" ]
}

@test "--estate selects the same exact roots as --agora estate" {
  mkrepo "$TREE/first"
  mkrepo "$TREE/with space"
  make_fake_ki
  FAKE_KI_AGORA=estate
  FAKE_KI_ROOTS="$TREE/first"$'\n'"$TREE/with space"

  cd "$TREE"
  run "$MGIT" --estate

  [ "$status" -eq 0 ]
  [ "$output" = $'first\nwith space' ]
  local estate_output="$output"

  run "$MGIT" --agora estate

  [ "$status" -eq 0 ]
  [ "$output" = "$estate_output" ]
}

@test "--agora preserves its exact roots instead of following symlink metadata" {
  mkrepo "$TREE/selected"
  mkrepo "$TREE/linked"
  mkdir "$TREE/linked/shared"
  ln -s ../linked/shared "$TREE/selected/link"
  printf '%s\n' '[symlinks]' '"link" = "../linked/shared"' > "$TREE/selected/.mgit.toml"
  make_fake_ki
  FAKE_KI_ROOTS="$TREE/selected"

  cd "$TREE"
  run "$MGIT" --agora focus

  [ "$status" -eq 0 ]
  [ "$output" = "selected" ]
}

@test "--agora stops before a command when ki cannot resolve roots" {
  mkrepo "$TREE/selected"
  make_fake_ki
  FAKE_KI_ROOTS="$TREE/selected"
  FAKE_KI_FAIL=true

  cd "$TREE"
  run "$MGIT" --agora focus status

  [ "$status" -eq 1 ]
  [[ "$output" == *"fake Agora resolution failed"* ]]
  [[ "$output" != *"git status"* ]]
}

@test "--agora reports a missing ki command" {
  PATH=/usr/bin:/bin

  run "$MGIT" --agora focus

  [ "$status" -eq 1 ]
  [[ "$output" == *"--agora requires ki on PATH"* ]]

  run "$MGIT" --estate

  [ "$status" -eq 1 ]
  [[ "$output" == *"--estate requires ki on PATH"* ]]
}

@test "--agora rejects incompatible selectors and management commands" {
  assert_usage_error --agora focus --group dev status
  assert_usage_error --agora focus --ignore status
  assert_usage_error --agora focus --follow-symlinks status
  assert_usage_error --agora focus register
  assert_usage_error --agora focus structure standard
  assert_usage_error --estate --agora focus status
  assert_usage_error --agora focus --estate status
  assert_usage_error --estate --estate status
  assert_usage_error --estate --group dev status
  assert_usage_error --estate --ignore status
  assert_usage_error --estate --follow-symlinks status
  assert_usage_error --estate register
  assert_usage_error --estate structure standard
}

@test "register rejects a stray argument" {
  run "$MGIT" register extra
  [ "$status" -eq 2 ]
}

@test "register writes schema-1 workspaces in physical postorder" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  mkrepo "$TREE/sub/c"
  ( cd "$TREE" && run_ok "$MGIT" register )

  [ -f "$TREE/.mgit.toml" ]
  [ -f "$TREE/sub/.mgit.toml" ]
  grep -Fx 'schema = 1' "$TREE/.mgit.toml"
  grep -Fx 'default = "default"' "$TREE/.mgit.toml"
  [ "$(grep -cFx 'kind = "repository"' "$TREE/.mgit.toml")" -eq 2 ]
  grep -Fx 'kind = "workspace"' "$TREE/.mgit.toml"
  grep -Fx '[groups.default.members."sub"]' "$TREE/.mgit.toml"
  grep -Fx '[groups.default.members."c"]' "$TREE/sub/.mgit.toml"

  cd "$TREE"
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = $'a\nb\nsub/c' ]
}

@test "register records origin URLs for typed repository members" {
  make_origin "$TREE/repoA" "$TREE/repoA.origin.git" payload

  ( cd "$TREE" && run_ok "$MGIT" register )

  grep -Fx "source = \"$TREE/repoA.origin.git\"" "$TREE/.mgit.toml"
}

@test "register replaces parent configs and synchronizes workspaces with chezmoi" {
  make_fake_chezmoi
  make_origin "$TREE/repoA" "$BATS_TEST_TMPDIR/repoA.origin.git" payload

  cd "$TREE"
  run "$MGIT" register

  [ "$status" -eq 0 ]
  cmp "$TREE/.mgit.toml" "$CHEZMOI_SOURCE/dot_mgit.toml"
  grep -Fx "source = \"$BATS_TEST_TMPDIR/repoA.origin.git\"" "$CHEZMOI_SOURCE/dot_mgit.toml"
  grep -Fx "add $CHEZMOI_TARGET/.mgit.toml" "$CHEZMOI_LOG"

  mv "$TREE/repoA" "$BATS_TEST_TMPDIR/removed-repoA"
  run "$MGIT" register

  [ "$status" -eq 1 ]
  [ ! -e "$TREE/.mgit.toml" ]
  [ ! -e "$CHEZMOI_SOURCE/dot_mgit.toml" ]
  grep -Fx "forget $CHEZMOI_TARGET/.mgit.toml" "$CHEZMOI_LOG"
}

@test "register warns but succeeds when chezmoi cannot add a manifest" {
  make_fake_chezmoi
  export CHEZMOI_FAIL_ADD=true
  mkrepo "$TREE/repoA"

  cd "$TREE"
  run "$MGIT" register

  [ "$status" -eq 0 ]
  [ -f "$TREE/.mgit.toml" ]
  [[ "$output" == *"warning: manifest remains local; chezmoi could not add it"* ]]
  [[ "$output" != *"no git repos found"* ]]
}

@test "register warns but removes a local manifest when chezmoi cannot forget it" {
  make_fake_chezmoi
  mkrepo "$TREE/repoA"

  cd "$TREE"
  run "$MGIT" register
  [ "$status" -eq 0 ]
  [ -f "$TREE/.mgit.toml" ]

  export CHEZMOI_FAIL_FORGET=true
  mv "$TREE/repoA" "$BATS_TEST_TMPDIR/removed-repoA"
  run "$MGIT" register

  [ "$status" -eq 1 ]
  [ ! -e "$TREE/.mgit.toml" ]
  [ -e "$CHEZMOI_SOURCE/dot_mgit.toml" ]
  [[ "$output" == *"warning: manifest removal remains local; chezmoi could not forget it"* ]]
}

@test "register does not manage manifests inside the chezmoi source directory" {
  make_fake_chezmoi
  mkrepo "$CHEZMOI_SOURCE/repoA"

  cd "$CHEZMOI_SOURCE"
  run "$MGIT" register

  [ "$status" -eq 0 ]
  [ -f "$CHEZMOI_SOURCE/.mgit.toml" ]
  [ ! -e "$CHEZMOI_LOG" ]
}

@test "repair materializes structural defaults and recreates nested layout" {
  make_origin "$TREE/source-standard" "$TREE/standard.origin.git" standard
  make_origin "$TREE/source-nested" "$TREE/nested.origin.git" nested
  mkdir -p "$TREE/workspace/group"
  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "default"' \
    '' \
    '[groups.default.members."standard-repo"]' \
    'kind = "repository"' \
    'type = "standard"' \
    "source = \"$TREE/standard.origin.git\"" \
    '' \
    '[groups.default.members."nested-repo"]' \
    'kind = "repository"' \
    'type = "nested"' \
    "source = \"$TREE/nested.origin.git\"" \
    '' \
    '[groups.default.members."bare-repo.git"]' \
    'kind = "repository"' \
    'type = "bare"' \
    "source = \"$TREE/standard.origin.git\"" \
    '' \
    '[groups.default.members."group"]' \
    'kind = "workspace"' \
    > "$TREE/workspace/.mgit.toml"
  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "default"' \
    '' \
    '[groups.default.members."grouped-repo"]' \
    'kind = "repository"' \
    'type = "standard"' \
    "source = \"$TREE/standard.origin.git\"" > "$TREE/workspace/group/.mgit.toml"

  cd "$TREE/workspace"
  run "$MGIT" repair

  [ "$status" -eq 0 ]
  [ "$(cat "$TREE/workspace/standard-repo/payload")" = standard ]
  [ -d "$TREE/workspace/nested-repo/.bare" ]
  [ -f "$TREE/workspace/nested-repo/main/.git" ]
  [ "$(cat "$TREE/workspace/nested-repo/main/payload")" = nested ]
  [ "$(git -C "$TREE/workspace/bare-repo.git" rev-parse --is-bare-repository)" = true ]
  [ "$(cat "$TREE/workspace/group/grouped-repo/payload")" = standard ]

  run "$MGIT" repair
  [ "$status" -eq 0 ]
  [[ "$output" == *"present "*"standard-repo"* ]]
}

@test "repair refuses a missing member without a clone URL" {
  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "default"' \
    '' \
    '[groups.default.members."missing-repo"]' \
    'kind = "repository"' \
    'type = "standard"' \
    > "$TREE/.mgit.toml"

  cd "$TREE"
  run "$MGIT" repair

  [ "$status" -eq 1 ]
  [ ! -e "$TREE/missing-repo" ]
  [[ "$output" == *"no clone URL"* ]]

  touch "$TREE/missing-repo"
  run "$MGIT" repair
  [ "$status" -eq 1 ]
  [ -f "$TREE/missing-repo" ]
  [[ "$output" == *"refusing to replace non-repository path"* ]]
}

@test "bare mgit lists the discovered repos" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  cd "$TREE"
  "$MGIT" register >/dev/null
  ! grep -q "repoB-branch-c" "$TREE/.mgit.toml"
  run "$MGIT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"a"* ]]
  [[ "$output" == *"b"* ]]
}

@test "--ignore bypasses workspace selection for discovery" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "default"' \
    '' \
    '[groups.default.members."a"]' \
    'kind = "repository"' \
    'type = "standard"' > "$TREE/.mgit.toml"

  cd "$TREE"
  run "$MGIT"

  [ "$status" -eq 0 ]
  [ "$output" = "a" ]

  run "$MGIT" --ignore

  [ "$status" -eq 0 ]
  [ "$output" = $'a\nb' ]
}

@test "--physical and --follow-symlinks control container traversal" {
  mkdir -p "$TREE/root" "$TREE/target"
  mkrepo "$TREE/target/repo"
  ln -s ../target "$TREE/root/linked"

  cd "$TREE/root"
  run "$MGIT" --physical

  [ "$status" -eq 0 ]
  [ -z "$output" ]

  run "$MGIT" --follow-symlinks

  [ "$status" -eq 0 ]
  [ "$output" = "../target/repo" ]
}

@test "register is idempotent" {
  mkrepo "$TREE/a"
  cd "$TREE"
  "$MGIT" register >/dev/null
  first=$(cat "$TREE/.mgit.toml")
  "$MGIT" register >/dev/null
  second=$(cat "$TREE/.mgit.toml")
  [ "$first" = "$second" ]
}

@test "discriminated manifests reject mixed document kinds" {
  mkrepo "$TREE/a"
  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "default"' \
    '' \
    '[symlinks]' \
    '"link" = "a"' > "$TREE/.mgit.toml"

  cd "$TREE"
  run "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unsupported TOML table: [symlinks]"* ]]

  mv "$TREE/.mgit.toml" "$TREE/mixed-workspace.toml"
  printf '%s\n' \
    'schema = 1' \
    'kind = "repository"' \
    '' \
    '[groups.default]' > "$TREE/a/.mgit.toml"

  cd "$TREE/a"
  run "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"repository manifest contains unsupported table: [groups.default]"* ]]
}

@test "register preserves named groups and their selected order" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "focus"' \
    '' \
    '[groups.default.members."a"]' \
    'kind = "repository"' \
    'type = "standard"' \
    '' \
    '[groups.focus.members."b"]' \
    'kind = "repository"' \
    '' \
    '[groups.focus.members."a"]' \
    'kind = "repository"' > "$TREE/.mgit.toml"

  cd "$TREE"
  run "$MGIT" register
  [ "$status" -eq 0 ]
  grep -Fx 'default = "focus"' "$TREE/.mgit.toml"
  grep -Fx '[groups.focus.members."a"]' "$TREE/.mgit.toml"
  grep -Fx '[groups.focus.members."b"]' "$TREE/.mgit.toml"

  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = $'a\nb' ]

  run "$MGIT" --group default
  [ "$status" -eq 0 ]
  [ "$output" = $'a\nb' ]
}

@test "group commands manage alternative workspace groups" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  cd "$TREE"
  "$MGIT" register >/dev/null

  run "$MGIT" group create engineering
  [ "$status" -eq 0 ]
  grep -Fx '[groups.engineering]' "$TREE/.mgit.toml"

  run "$MGIT" register
  [ "$status" -eq 0 ]
  grep -Fx '[groups.engineering]' "$TREE/.mgit.toml"

  run "$MGIT" group create engineering
  [ "$status" -eq 1 ]
  [[ "$output" == *"group already exists"* ]]

  run "$MGIT" group add engineering b
  [ "$status" -eq 0 ]
  run "$MGIT" group add engineering a
  [ "$status" -eq 0 ]
  grep -Fx '[groups.engineering.members."a"]' "$TREE/.mgit.toml"
  grep -Fx '[groups.engineering.members."b"]' "$TREE/.mgit.toml"

  run "$MGIT" --group engineering
  [ "$status" -eq 0 ]
  [ "$output" = $'a\nb' ]

  before=$(cat "$TREE/.mgit.toml")
  run "$MGIT" group add engineering a
  [ "$status" -eq 1 ]
  [[ "$output" == *"member already belongs"* ]]
  [ "$(cat "$TREE/.mgit.toml")" = "$before" ]

  run "$MGIT" group add engineering absent
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a direct default-group member"* ]]
  [ "$(cat "$TREE/.mgit.toml")" = "$before" ]

  run "$MGIT" group add default a
  [ "$status" -eq 2 ]

  run "$MGIT" group remove engineering a
  [ "$status" -eq 0 ]
  grep -Fx '[groups.engineering.members."b"]' "$TREE/.mgit.toml"
  ! grep -Fq '[groups.engineering.members."a"]' "$TREE/.mgit.toml"

  run "$MGIT" group delete engineering
  [ "$status" -eq 0 ]
  ! grep -Fq '[groups.engineering.members.' "$TREE/.mgit.toml"
}

@test "workspace selection rejects malformed, duplicate, and unsafe paths" {
  mkrepo "$TREE/a"
  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "default"' \
    '[groups.default.members."../a"]' \
    'kind = "repository"' \
    'type = "standard"' > "$TREE/.mgit.toml"

  cd "$TREE"
  run "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unsafe workspace member path"* ]]

  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "default"' \
    '[groups.default.members."a"]' \
    'kind = "repository"' \
    'type = "standard"' \
    '[groups.default.members."a"]' \
    'kind = "repository"' \
    'type = "standard"' > "$TREE/.mgit.toml"
  run "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"duplicate member path"* ]]
}

@test "workspace selection rejects invalid groups and unsafe workspace cycles" {
  mkrepo "$TREE/a"
  mkdir "$TREE/child"
  ln -s .. "$TREE/child/loop"
  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "default"' \
    '[groups.default.members."child"]' \
    'kind = "workspace"' > "$TREE/.mgit.toml"
  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "default"' \
    '[groups.default.members."loop"]' \
    'kind = "workspace"' > "$TREE/child/.mgit.toml"

  cd "$TREE"
  run "$MGIT" --group absent
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown workspace group"* ]]

  run "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unsafe or missing workspace path"* ]]
}

@test "a cross-repo symlink is recorded as a TOML entry" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  mkdir -p "$TREE/b/shared"                        # link target must be a real dir in repo b
  ( cd "$TREE/a" && ln -s ../b/shared link-to-b )
  cd "$TREE"
  "$MGIT" register >/dev/null
  [ -f "$TREE/a/.mgit.toml" ]
  grep -Fx '[symlinks]' "$TREE/a/.mgit.toml"
  grep -Fx '"link-to-b" = "../b/shared"' "$TREE/a/.mgit.toml"

  cd "$TREE/a"
  run "$MGIT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"../b"* ]]
}

@test "register records nested and standard structures once" {
  mkrepo "$TREE/repoA"
  make_managed_worktree_repo "$TREE/repoA"
  mkrepo "$TREE/repoB"

  cd "$TREE"
  run "$MGIT" register

  [ "$status" -eq 0 ]
  grep -Fx '[groups.default.members."repoA"]' "$TREE/.mgit.toml"
  grep -Fx 'type = "nested"' "$TREE/.mgit.toml"
  grep -Fx '[groups.default.members."repoB"]' "$TREE/.mgit.toml"
  grep -Fx 'type = "standard"' "$TREE/.mgit.toml"
  ! grep -Fx '[groups.default.members."main"]' "$TREE/.mgit.toml"
}

@test "workspace members are read" {
  mkrepo "$TREE/repoA"
  printf '%s\n' \
    '# A comment with a # inside a string stays valid: "repo#A".' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "default"' \
    '' \
    '[groups.default.members."repoA"]' \
    'kind = "repository"' \
    'type = "standard"' \
    '# inline comments are allowed' > "$TREE/.mgit.toml"

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

  run "$MGIT" structure nested
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

@test "worktree add uses nested and standard-repository destinations across the set" {
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
  [ -f "$TREE/repoB/.git/mgit-worktrees/featureA/.git" ]
  [ "$(git -C "$TREE/repoB/.git/mgit-worktrees/featureA" branch --show-current)" = "featureA" ]
  [ "$(git -C "$TREE/repoB/.git/mgit-worktrees/featureA" rev-parse --abbrev-ref '@{upstream}')" = "origin/featureA" ]
  [ ! -e "$TREE/repoB-featureA" ]
}

@test "worktree remove supports a standard sibling and protects the primary checkout" {
  mkrepo "$TREE/repoA"
  git -C "$TREE/repoA" worktree add -q -b featureA "$TREE/repoA-featureA"

  cd "$TREE/repoA"
  run "$MGIT" worktree remove "$TREE/repoA-featureA"
  [ "$status" -eq 0 ]
  [ ! -e "$TREE/repoA-featureA" ]

  run "$MGIT" worktree remove "$TREE/repoA"
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

  run "$MGIT" structure standard
  [ "$status" -eq 0 ]
  [ -d "$TREE/repoA/.git" ]
  [ ! -d "$TREE/repoA/.bare" ]
  [ "$(git -C "$TREE/repoA" status --porcelain)" = "" ]
}

@test "--filter limits the repo set by glob" {
  mkrepo "$TREE/mcp-a"
  mkrepo "$TREE/mcp-b"
  mkrepo "$TREE/sub/mcp-c"
  mkrepo "$TREE/tools-d"

  cd "$TREE"
  run "$MGIT" -f 'mcp-*'
  [ "$status" -eq 0 ]
  [[ "$output" == *"mcp-a"* ]]
  [[ "$output" == *"mcp-b"* ]]
  [[ "$output" == *"sub/mcp-c"* ]]
  [[ "$output" != *"tools-d"* ]]

  run "$MGIT" -f 'mcp-a' -f 'tools-*'
  [ "$status" -eq 0 ]
  [[ "$output" == *"mcp-a"* ]]
  [[ "$output" != *"mcp-b"* ]]
  [[ "$output" == *"tools-d"* ]]
}

@test "--filter applies to bare commands and requires a pattern" {
  mkrepo "$TREE/mcp-a"
  mkrepo "$TREE/tools-b"

  cd "$TREE"
  run "$MGIT" -f 'mcp-*' -B pwd
  [ "$status" -eq 0 ]
  [[ "$output" == *"$TREE/mcp-a"* ]]
  [[ "$output" != *"tools-b"* ]]

  run "$MGIT" --filter
  [ "$status" -eq 2 ]
}

@test "--filter selects whole repos, keeping their linked worktrees" {
  mkrepo "$TREE/mcp-a"
  make_managed_worktree_repo "$TREE/mcp-a"
  git -C "$TREE/mcp-a" worktree add -q "$TREE/mcp-a/featureA" -b featureA
  mkrepo "$TREE/tools-b"

  cd "$TREE"
  run "$MGIT" -f 'mcp-*'
  [ "$status" -eq 0 ]
  [[ "$output" == *"mcp-a/main"* ]]
  [[ "$output" == *"mcp-a/featureA"* ]]
  [[ "$output" != *"tools-b"* ]]
}

# Helper: run a command, failing the test if it errors (for use inside subshells
# where bats' own `run` isn't available).
run_ok() { "$@"; }
