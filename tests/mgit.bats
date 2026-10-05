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
  FAKE_KI_SECOND_AGORA=second
  FAKE_KI_SECOND_ROOTS=""
  FAKE_KI_FAIL=false
  export FAKE_KI_AGORA FAKE_KI_ROOTS FAKE_KI_SECOND_AGORA FAKE_KI_SECOND_ROOTS FAKE_KI_FAIL
  printf '%s\n' \
    '#!/usr/bin/env bash' \
    '[ "$1" = agora ] && [ "$2" = roots ] && [ "$3" = --null ] || exit 64' \
    'case "$4" in "$FAKE_KI_AGORA") roots="$FAKE_KI_ROOTS" ;; "$FAKE_KI_SECOND_AGORA") roots="$FAKE_KI_SECOND_ROOTS" ;; *) printf "unknown Agora: %s\\n" "$4" >&2; exit 65 ;; esac' \
    '[ "$FAKE_KI_FAIL" = false ] || { printf "fake Agora resolution failed\\n" >&2; exit 73; }' \
    'while IFS= read -r root || [ -n "$root" ]; do printf "%s\\0" "$root"; done <<< "$roots"' \
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
  [[ "$output" == *"--all-worktrees"* ]]
  [[ "$output" == *"--estate"* ]]
  [[ "$output" == *"passed through to Git"* ]]

  run "$MGIT" help register
  [ "$status" -eq 0 ]
  [[ "$output" == *"--agora <name>"* ]]
  [[ "$output" == *"--repo <path>"* ]]
}

@test "--version prints the version" {
  run "$MGIT" --version
  [ "$status" -eq 0 ]
  [[ "$output" == "mgit 0.14.0" ]]
}

@test "diag redacts the working path unless full output is requested" {
  cd "$TREE"
  run "$MGIT" diag
  [ "$status" -eq 0 ]
  [[ "$output" == *'mgit diag: manifest=absent'* ]]
  for label in Tool Version Installation Platform Architecture Runtime Configuration; do
    [[ "$output" == *"$label:"* ]] || false
  done
  [[ "$output" == *'Installation: local'* ]]
  [[ "$output" == *'Runtime: bash '* ]]
  [[ "$output" == *'Configuration: absent'* ]]
  [[ "$output" != *"$TREE"* ]]
  [[ "$output" != *"$BATS_TEST_DIRNAME"* ]]

  run "$MGIT" diag --full
  [ "$status" -eq 0 ]
  [[ "$output" == *"directory=$TREE"* ]]
  [[ "$output" == *'configuration-path='* ]]
  [[ "$output" == *'executable='* ]]
}

@test "diag resolves linked checkouts and does not guess copied executable provenance" {
  cd "$TREE"
  ln -s "$MGIT" linked-mgit
  ln -s linked-mgit second-link
  run "$TREE/second-link" diag
  [ "$status" -eq 0 ]
  [[ "$output" == *'Installation: local'* ]]

  mkdir -p "$TREE/copied/bin"
  cp "$MGIT" "$TREE/copied/bin/mgit"
  run "$TREE/copied/bin/mgit" diag
  [ "$status" -eq 0 ]
  [[ "$output" == *'Installation: unknown'* ]]
  printf '%s\n' '{}' > "$TREE/copied/INSTALL_RECEIPT.json"
  run "$TREE/copied/bin/mgit" diag
  [ "$status" -eq 0 ]
  [[ "$output" == *'Installation: release'* ]]
}

@test "diagnostics redact invalid configuration content and doctor counts failures" {
  cd "$TREE"
  printf '%s\n' 'kind = "private-secret-invalid-kind"' > .mgit.toml
  before=$(cat .mgit.toml)
  run "$MGIT" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *'Configuration: invalid'* ]]
  [[ "$output" == *'Checks: pass=1 warn=0 fail=1 skipped=0'* ]]
  [[ "$output" == *'Verdict: unhealthy'* ]]
  [[ "$output" == *'mgit diag --full'* ]]
  [[ "$output" != *'private-secret-invalid-kind'* ]]
  [[ "$output" != *"$TREE"* ]]
  [ "$(cat .mgit.toml)" = "$before" ]
  run "$MGIT" diag
  [ "$status" -eq 0 ]
  [[ "$output" == *'Configuration: invalid'* ]]
  [[ "$output" != *'private-secret-invalid-kind'* ]]
  run "$MGIT" diag --full
  [ "$status" -eq 0 ]
  [[ "$output" == *'detail=unsupported manifest kind'* ]]
  [[ "$output" != *'private-secret-invalid-kind'* ]]
}

@test "doctor reports a missing Git prerequisite without claiming dependent checks failed" {
  cd "$TREE"
  local fixture_bin="$TREE/no-git-bin" utility
  mkdir -p "$fixture_bin"
  for utility in bash basename dirname readlink uname; do
    ln -s "$(command -v "$utility")" "$fixture_bin/$utility"
  done
  run env PATH="$fixture_bin" /bin/bash "$MGIT" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *'fail git: Git unavailable; install Git and retry.'* ]]
  [[ "$output" == *'Checks: pass=1 warn=0 fail=1 skipped=0'* ]]
  [[ "$output" == *'Configuration: absent'* ]]
}

@test "doctor evaluates the manifest without writing and config repair is retired" {
  cd "$TREE"
  run "$MGIT" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *'filesystem discovery available'* ]]
  [[ "$output" == *'Checks: pass=2 warn=0 fail=0 skipped=0'* ]]
  [[ "$output" == *'Verdict: healthy'* ]]
  [[ "$output" == *'Not checked: package updates'* ]]

  mkrepo "$TREE/a"
  printf '%s\n' 'kind = "workspace"' '[members."a"]' 'kind = "repository"' \
    'type = "standard"' > .mgit.toml
  before=$(cat .mgit.toml)
  run "$MGIT" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *'workspace manifest valid'* ]]
  [ "$(cat .mgit.toml)" = "$before" ]

  mv .mgit.toml manifest.toml
  ln -s absent.toml .mgit.toml
  run "$MGIT" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *'Configuration: invalid'* ]]
  [[ "$output" == *'correct .mgit.toml'* ]]
  run "$MGIT" diag --full
  [ "$status" -eq 0 ]
  [[ "$output" == *'manifest must be a regular file'* ]]
  [[ "$output" == *'mgit diag: manifest=present'* ]]
  rm .mgit.toml
  mv manifest.toml .mgit.toml

  run "$MGIT" config repair
  [ "$status" -eq 2 ]
  [[ "$output" == *"command 'config' removed"* ]]

  run "$MGIT" doctor --help extra
  [ "$status" -eq 2 ]
  run "$MGIT" diag --help extra
  [ "$status" -eq 2 ]
  run "$MGIT" diag --full --full
  [ "$status" -eq 2 ]
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
    MGIT_VERSION=v9.9.9 \
    PATH="$fake_bin:$PATH" \
    "$BATS_TEST_DIRNAME/../install.sh" v1.2.3

  [ "$status" -eq 0 ]
  [[ "$output" == *"installing mgit (v1.2.3)"* ]]
  [ -x "$install_bin/mgit" ]
  cmp "$MGIT" "$install_bin/mgit"
  cmp "$BATS_TEST_DIRNAME/../man/mgit.1" "$install_man/mgit.1"

  run env \
    FAKE_MGIT="$MGIT" \
    FAKE_MAN="" \
    MGIT_INSTALL_DIR="$install_bin" \
    MGIT_MAN_INSTALL_DIR="$missing_man" \
    MGIT_VERSION=v0.1.0 \
    PATH="$fake_bin:$PATH" \
    "$BATS_TEST_DIRNAME/../install.sh"

  [ "$status" -eq 0 ]
  [ -x "$install_bin/mgit" ]
  [ ! -e "$missing_man/mgit.1" ]
  [[ "$output" == *"manual unavailable for v0.1.0"* ]]
}

@test "installer rejects malformed versions and extra arguments" {
  run "$BATS_TEST_DIRNAME/../install.sh" 1.2.3
  [ "$status" -eq 2 ]
  [[ "$output" == *"expected an exact version like vX.Y.Z"* ]]

  run env MGIT_VERSION=main "$BATS_TEST_DIRNAME/../install.sh"
  [ "$status" -eq 2 ]
  [[ "$output" == *"MGIT_VERSION must be an exact version like vX.Y.Z"* ]]

  run "$BATS_TEST_DIRNAME/../install.sh" v1.2.3 extra
  [ "$status" -eq 2 ]
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
  [ "$output" = "mgit 0.14.0" ]
}

@test "completion prints bash and zsh setup" {
  run "$MGIT" completion bash
  [ "$status" -eq 0 ]
  [[ "$output" == *"complete -F _mgit mgit"* ]]
  [[ "$output" == *"structure"* ]]
  [[ "$output" == *"repair"* ]]
  [[ "$output" == *"doctor"* ]]
  [[ "$output" == *"diag"* ]]
  [[ "$output" == *"sync"* ]]
  [[ "$output" == *"--estate"* ]]
  [[ "$output" == *"add rm --agora -a --repo --dry-run --help -h"* ]]
  [[ "$output" == *"--apply"* ]]
  [[ "$output" == *"--all-worktrees"* ]]
  [[ "$output" != *"bootstrap"* ]]
  [[ "$output" != *"convert"* ]]

  run "$MGIT" completion zsh
  [ "$status" -eq 0 ]
  [[ "$output" == *"#compdef mgit"* ]]
  [[ "$output" == *"standard nested"* ]]
  [[ "$output" == *"--estate"* ]]
  [[ "$output" == *"add or remove an Agora location"* ]]
  [[ "$output" == *"add or remove a repository location"* ]]
  [[ "$output" == *"perform validated repairs"* ]]
  [[ "$output" == *"sync:update clean tracking branches"* ]]
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
  assert_usage_error sync extra --help
}

@test "inapplicable global selectors fail before management commands change state" {
  mkrepo "$TREE/repo"
  cd "$TREE"
  for option in -P -L -B -I -W; do
    assert_usage_error "$option" register
    assert_usage_error "$option" repair
  done
  assert_usage_error -f repo register
  assert_usage_error -f repo repair
  assert_usage_error --estate register
  assert_usage_error --estate repair
  assert_usage_error -a focus repair
  [ ! -e "$TREE/.mgit.toml" ]
  [ ! -e "$TREE/repo/.mgit.toml" ]
}

@test "command-specific selectors reject ignored combinations" {
  mkrepo "$TREE/repo"
  cd "$TREE"
  assert_usage_error -B
  assert_usage_error -B sync
  assert_usage_error -B structure nested
  assert_usage_error -B worktree list
  assert_usage_error -W structure nested
  assert_usage_error -W worktree list
  assert_usage_error -a focus structure nested
  assert_usage_error -a focus worktree list
  assert_usage_error -f repo completion bash
  [ -d "$TREE/repo/.git" ]
  [ ! -e "$TREE/repo/.bare" ]
}

@test "help and version remain available with selectors" {
  run "$MGIT" -B --version
  [ "$status" -eq 0 ]
  [[ "$output" == mgit\ * ]]
  run "$MGIT" -W help structure
  [ "$status" -eq 0 ]
  [[ "$output" == Usage:\ mgit\ structure* ]]
}

@test "standalone reserved-command help exits 0" {
  for command in register repair doctor diag sync structure worktree completion; do
    run "$MGIT" "$command" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: mgit"* ]]
  done
}

@test "help is contextual for reserved commands and their subcommands" {
  run "$MGIT" register -h
  [ "$status" -eq 0 ]
  [[ "$output" == "Usage: mgit register [add|rm] [options]"* ]]
  [[ "$output" != *"Commands:"* ]]

  run "$MGIT" help sync
  [ "$status" -eq 0 ]
  [[ "$output" == "Usage: mgit sync"* ]]

  run "$MGIT" help worktree remove
  [ "$status" -eq 0 ]
  [[ "$output" == "Usage: mgit worktree remove <path> [--force]"* ]]
}

@test "reserved command trees reject unknown subcommands" {
  run "$MGIT" structure sideways
  [ "$status" -eq 2 ]
  [[ "$output" == *"structure: unknown command: sideways"* ]]
}

@test "removed group interface is absent from help and completion" {
  run "$MGIT" --group focus status
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown option: --group"* ]]

  run "$MGIT" help group
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown mgit command: group"* ]]

  run "$MGIT" completion bash
  [ "$status" -eq 0 ]
  [[ "$output" != *"--group"* ]]
  [[ "$output" != *"group:create"* ]]

  run "$MGIT" completion zsh
  [ "$status" -eq 0 ]
  [[ "$output" != *"--group"* ]]
  [[ "$output" != *"group:create"* ]]
}

@test "ordinary Git command options remain pass-through" {
  mkrepo "$TREE/repo"
  cd "$TREE/repo"

  run "$MGIT" status --short

  [ "$status" -eq 0 ]
  [[ "$output" == *"git status --short"* ]]
}

@test "fan-out reports an early failure after a successful final checkout" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  git -C "$TREE/b" branch only-b
  touch "$TREE/b/success"
  cd "$TREE"

  run "$MGIT" rev-parse --verify only-b
  [ "$status" -eq 1 ]
  plain_output=${output//$'\033[1m'/}
  plain_output=${plain_output//$'\033[33m'/}
  plain_output=${plain_output//$'\033[0m'/}
  [[ "$plain_output" == *"a: git rev-parse --verify only-b"* ]]
  [[ "$plain_output" == *"b: git rev-parse --verify only-b"* ]]

  run "$MGIT" -B sh -c 'test -f success'
  [ "$status" -eq 1 ]
  plain_output=${output//$'\033[1m'/}
  plain_output=${plain_output//$'\033[33m'/}
  plain_output=${plain_output//$'\033[0m'/}
  [[ "$plain_output" == *"a: sh -c"* ]]
  [[ "$plain_output" == *"b: sh -c"* ]]
}

@test "sync rolls up current repositories and shows dirty worktrees" {
  local seed="$BATS_TEST_TMPDIR/seed"
  local origin="$BATS_TEST_TMPDIR/origin.git"
  make_origin "$seed" "$origin" baseline
  git clone -q "$origin" "$TREE/current"
  git clone -q "$origin" "$TREE/dirty"
  printf 'local\n' >> "$TREE/dirty/payload"

  cd "$TREE"
  run "$MGIT" sync

  [ "$status" -eq 1 ]
  [[ "$output" == *"mgit sync: [1/2] current: checking"* ]]
  [[ "$output" == *"mgit sync: [2/2] dirty: checking"* ]]
  [[ "$output" == *"mgit sync: dirty: local changes (skipped)"* ]]
  [[ "$output" == *" M payload"* ]]
  [[ "$output" == *"mgit sync: 1 repository already in sync"* ]]
  [[ "$output" != *"mgit sync: current: pulled"* ]]
  [[ "$output" != *"mgit sync: current: pushed"* ]]
}

@test "sync pulls incoming commits and pushes outgoing commits" {
  local incoming_seed="$BATS_TEST_TMPDIR/incoming-seed"
  local incoming_origin="$BATS_TEST_TMPDIR/incoming.git"
  local outgoing_seed="$BATS_TEST_TMPDIR/outgoing-seed"
  local outgoing_origin="$BATS_TEST_TMPDIR/outgoing.git"
  make_origin "$incoming_seed" "$incoming_origin" incoming
  make_origin "$outgoing_seed" "$outgoing_origin" outgoing
  git clone -q "$incoming_origin" "$TREE/incoming"
  git clone -q "$outgoing_origin" "$TREE/outgoing"

  git -C "$incoming_seed" commit -q --allow-empty -m incoming-update
  git -C "$incoming_seed" push -q
  git -C "$TREE/outgoing" commit -q --allow-empty -m outgoing-update

  cd "$TREE"
  run "$MGIT" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"mgit sync: incoming: pulled 1 commit"* ]]
  [[ "$output" == *"mgit sync: outgoing: pushed 1 commit"* ]]
  [[ "$output" == *"mgit sync: incoming: pulling"* ]]
  [[ "$output" == *"mgit sync: outgoing: pushing"* ]]
  [[ "$output" != *"[y/N]"* ]]
  [[ "$output" == *"mgit sync: 0 repositories already in sync"* ]]
  [ "$(git -C "$TREE/incoming" rev-parse HEAD)" = "$(git --git-dir="$incoming_origin" rev-parse HEAD)" ]
  [ "$(git -C "$TREE/outgoing" rev-parse HEAD)" = "$(git --git-dir="$outgoing_origin" rev-parse HEAD)" ]
}

@test "sync interactive mode confirms pull and push separately" {
  local seed="$BATS_TEST_TMPDIR/seed"
  local origin="$BATS_TEST_TMPDIR/origin.git"
  local before
  make_origin "$seed" "$origin" baseline
  git clone -q "$origin" "$TREE/repo"
  git -C "$TREE/repo" commit -q --allow-empty -m local-update
  before=$(git --git-dir="$origin" rev-parse HEAD)

  cd "$TREE"
  run bash -c 'printf "n\n" | "$1" sync -i' _ "$MGIT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mgit sync: repo: pull skipped"* ]]
  [[ "$output" == *"mgit sync: 1 action skipped by user"* ]]
  [[ "$output" != *"mgit sync: repo: pushing"* ]]
  [ "$(git --git-dir="$origin" rev-parse HEAD)" = "$before" ]

  run bash -c 'printf "y\nn\n" | "$1" sync -i' _ "$MGIT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mgit sync: repo: pull "*"? [y/N]"* ]]
  [[ "$output" == *"mgit sync: repo: push 1 commit? [y/N]"* ]]
  [[ "$output" == *"mgit sync: repo: push skipped (1 commit ahead)"* ]]
  [[ "$output" == *"mgit sync: 1 action skipped by user"* ]]
  [ "$(git --git-dir="$origin" rev-parse HEAD)" = "$before" ]

  run bash -c 'printf "y\ny\n" | "$1" sync --interactive' _ "$MGIT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mgit sync: repo: pushed 1 commit"* ]]
  [ "$(git --git-dir="$origin" rev-parse HEAD)" = "$(git -C "$TREE/repo" rev-parse HEAD)" ]
}

@test "sync interactive mode stops when input ends before confirmation" {
  local seed="$BATS_TEST_TMPDIR/seed"
  local origin="$BATS_TEST_TMPDIR/origin.git"
  make_origin "$seed" "$origin" baseline
  git clone -q "$origin" "$TREE/repo"

  cd "$TREE"
  run bash -c '"$1" sync -i < /dev/null' _ "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"mgit sync: interactive input ended"* ]]
  [[ "$output" != *"mgit sync: repo: pulling"* ]]
}

@test "sync reports no-upstream bare and divergent repositories" {
  local seed="$BATS_TEST_TMPDIR/diverged-seed"
  local origin="$BATS_TEST_TMPDIR/diverged.git"
  make_origin "$seed" "$origin" baseline
  git clone -q "$origin" "$TREE/diverged"
  mkrepo "$TREE/no-upstream"
  mkbare "$TREE/archive.git"

  git -C "$seed" commit -q --allow-empty -m remote-update
  git -C "$seed" push -q
  git -C "$TREE/diverged" commit -q --allow-empty -m local-update
  local before
  before=$(git -C "$TREE/diverged" rev-parse HEAD)

  cd "$TREE"
  run "$MGIT" sync

  [ "$status" -eq 1 ]
  [[ "$output" == *"mgit sync: archive.git: bare repository (skipped)"* ]]
  [[ "$output" == *"mgit sync: diverged: pull failed"* ]]
  [[ "$output" == *"mgit sync: no-upstream: branch "*" has no upstream (skipped)"* ]]
  [ "$(git -C "$TREE/diverged" rev-parse HEAD)" = "$before" ]
}

@test "sync honors repository filters" {
  local seed="$BATS_TEST_TMPDIR/filter-seed"
  local origin="$BATS_TEST_TMPDIR/filter.git"
  make_origin "$seed" "$origin" baseline
  git clone -q "$origin" "$TREE/selected"
  git clone -q "$origin" "$TREE/omitted"
  printf 'selected\n' >> "$TREE/selected/payload"
  printf 'omitted\n' >> "$TREE/omitted/payload"

  cd "$TREE"
  run "$MGIT" --filter selected sync

  [ "$status" -eq 1 ]
  [[ "$output" == *"mgit sync: [1/1] selected: checking"* ]]
  [[ "$output" == *"mgit sync: selected: local changes (skipped)"* ]]
  [[ "$output" != *"omitted"* ]]
}

@test "captured command output has no color and sync uses checkout labels" {
  mkrepo "$TREE/standard"
  mkrepo "$TREE/nested"
  make_managed_worktree_repo "$TREE/nested"
  git -C "$TREE/standard" worktree add -q -b topic "$TREE/storage-topic"
  cd "$TREE"

  run "$MGIT" status --short
  [ "$status" -eq 0 ]
  [[ "$output" != *$'\033['* ]]

  run "$MGIT" --all-worktrees sync
  [ "$status" -eq 1 ]
  [[ "$output" == *"standard [topic]: checking"* ]]
  [[ "$output" == *"nested/main: checking"* ]]
  [[ "$output" != *"storage-topic"* ]]
  [[ "$output" != *$'\033['* ]]
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

@test "register binds Agora locations alongside local repositories and refreshes them" {
  mkrepo "$TREE/local"
  mkrepo "$BATS_TEST_TMPDIR/external"
  mkrepo "$BATS_TEST_TMPDIR/replacement"
  make_fake_ki
  FAKE_KI_ROOTS="$TREE/local"$'\n'"$BATS_TEST_TMPDIR/external"

  cd "$TREE"
  run "$MGIT" register add --agora focus
  [ "$status" -eq 0 ]
  grep -Fx 'locations = ["local", "agora:focus"]' "$TREE/.mgit.toml"
  grep -Fx '[registered.members."../external"]' "$TREE/.mgit.toml"

  FAKE_KI_FAIL=true
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = $'local\n../external' ]
  grep -Fx 'locations = ["local", "agora:focus"]' "$TREE/.mgit.toml"
  before=$(cat "$TREE/.mgit.toml")
  run "$MGIT" register
  [ "$status" -eq 1 ]
  [ "$(cat "$TREE/.mgit.toml")" = "$before" ]

  FAKE_KI_FAIL=false
  FAKE_KI_ROOTS="$TREE/local"$'\n'"$BATS_TEST_TMPDIR/replacement"
  run "$MGIT" register
  [ "$status" -eq 0 ]
  grep -Fx '[members."local"]' "$TREE/.mgit.toml"
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = $'local\n../replacement' ]
}

@test "register can create a workspace containing only Agora members" {
  mkrepo "$BATS_TEST_TMPDIR/external"
  make_fake_ki
  FAKE_KI_ROOTS="$BATS_TEST_TMPDIR/external"

  cd "$TREE"
  run "$MGIT" register --agora focus
  [ "$status" -eq 0 ]
  grep -Fx 'locations = ["local", "agora:focus"]' "$TREE/.mgit.toml"
  grep -Fx '[members]' "$TREE/.mgit.toml"
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = '../external' ]
}

@test "register add and rm accept repeated mixed locations and refresh entries" {
  mkrepo "$TREE/local"
  mkrepo "$BATS_TEST_TMPDIR/first"
  mkrepo "$BATS_TEST_TMPDIR/second"
  mkrepo "$BATS_TEST_TMPDIR/one"
  mkrepo "$BATS_TEST_TMPDIR/two"
  make_fake_ki
  FAKE_KI_ROOTS="$BATS_TEST_TMPDIR/first"
  FAKE_KI_SECOND_ROOTS="$BATS_TEST_TMPDIR/second"

  cd "$TREE"
  run "$MGIT" register add --agora focus --repo ../one --agora second --repo ../two
  [ "$status" -eq 0 ]
  grep -Fx 'locations = ["local", "agora:focus", "repo:../one", "agora:second", "repo:../two"]' "$TREE/.mgit.toml"
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = $'local\n../first\n../one\n../second\n../two' ]

  mv "$BATS_TEST_TMPDIR/two" "$BATS_TEST_TMPDIR/moved"
  run "$MGIT" register rm --agora focus --repo ../one --agora second --repo ../two
  [ "$status" -eq 0 ]
  grep -Fx 'locations = ["local"]' "$TREE/.mgit.toml"
  ! grep -Fq '[registered.members.' "$TREE/.mgit.toml"
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = 'local' ]
}

@test "register can bind an external repository without an Agora" {
  mkrepo "$BATS_TEST_TMPDIR/external space"
  cd "$TREE"
  run "$MGIT" register add --repo "$BATS_TEST_TMPDIR/external space"
  [ "$status" -eq 0 ]
  grep -Fx 'locations = ["local", "repo:../external space"]' "$TREE/.mgit.toml"
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = '../external space' ]
}

@test "register migrates a legacy Agora snapshot into locations" {
  mkrepo "$TREE/local"
  mkrepo "$BATS_TEST_TMPDIR/external"
  make_fake_ki
  FAKE_KI_ROOTS="$BATS_TEST_TMPDIR/external"
  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "default"' \
    'agora = "focus"' \
    '[agora.members."../external"]' \
    '[groups.default.members."local"]' \
    'kind = "repository"' \
    'type = "standard"' > "$TREE/.mgit.toml"

  cd "$TREE"
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = $'local\n../external' ]
  run "$MGIT" register
  [ "$status" -eq 0 ]
  grep -Fx 'locations = ["local", "agora:focus"]' "$TREE/.mgit.toml"
  ! grep -Fq 'agora = ' "$TREE/.mgit.toml"
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = $'local\n../external' ]
}

@test "register rejects invalid location sources before rewriting the manifest" {
  mkrepo "$TREE/local"
  cd "$TREE"
  "$MGIT" register >/dev/null
  before=$(cat "$TREE/.mgit.toml")

  mkdir "$BATS_TEST_TMPDIR/not-a-repo"
  run "$MGIT" register add --repo "$BATS_TEST_TMPDIR/not-a-repo"
  [ "$status" -eq 1 ]
  [ "$(cat "$TREE/.mgit.toml")" = "$before" ]

  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "default"' \
    'locations = ["local", 3]' \
    '[groups.default]' > "$TREE/.mgit.toml"
  before=$(cat "$TREE/.mgit.toml")
  run "$MGIT" register
  [ "$status" -eq 1 ]
  [ "$(cat "$TREE/.mgit.toml")" = "$before" ]
}

@test "register rejects a stray argument" {
  run "$MGIT" register extra
  [ "$status" -eq 2 ]
  assert_usage_error register --agora ''
}

@test "register writes unversioned group-free workspaces in physical postorder" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  mkrepo "$TREE/sub/c"
  ( cd "$TREE" && run_ok "$MGIT" register )

  [ -f "$TREE/.mgit.toml" ]
  [ -f "$TREE/sub/.mgit.toml" ]
  ! grep -Fq 'schema =' "$TREE/.mgit.toml"
  ! grep -Fq 'default =' "$TREE/.mgit.toml"
  [ "$(grep -cFx 'kind = "repository"' "$TREE/.mgit.toml")" -eq 2 ]
  grep -Fx 'kind = "workspace"' "$TREE/.mgit.toml"
  grep -Fx '[members."sub"]' "$TREE/.mgit.toml"
  grep -Fx '[members."c"]' "$TREE/sub/.mgit.toml"

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
  run "$MGIT" repair --apply

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

@test "register dry-run previews add and rm without changing manifests or Chezmoi" {
  make_fake_chezmoi
  mkrepo "$TREE/repo"
  mkrepo "$BATS_TEST_TMPDIR/external"
  cd "$TREE"
  run "$MGIT" register add --repo "$BATS_TEST_TMPDIR/external" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would write ./.mgit.toml"* ]]
  [ ! -e "$TREE/.mgit.toml" ]
  [ ! -e "$CHEZMOI_LOG" ]
  "$MGIT" register add --repo "$BATS_TEST_TMPDIR/external" >/dev/null
  cp "$TREE/.mgit.toml" "$TREE/saved.toml"
  : > "$CHEZMOI_LOG"
  run "$MGIT" register rm --repo "$BATS_TEST_TMPDIR/external" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would write ./.mgit.toml"* ]]
  cmp "$TREE/saved.toml" "$TREE/.mgit.toml"
  [ ! -s "$CHEZMOI_LOG" ]
}

@test "register dry-run previews repository manifest removal without deleting it" {
  mkrepo "$TREE/repo"
  printf 'kind = "repository"\n' > "$TREE/repo/.mgit.toml"
  cd "$TREE"
  run "$MGIT" register --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would remove ./repo/.mgit.toml"* ]]
  [ -f "$TREE/repo/.mgit.toml" ]
}

@test "repair previews missing clone targets without creating them" {
  make_origin "$TREE/source" "$TREE/origin.git" payload
  mkdir "$TREE/workspace"
  printf '%s\n' 'kind = "workspace"' '[members."missing"]' 'kind = "repository"' \
    'type = "standard"' "source = \"$TREE/origin.git\"" > "$TREE/workspace/.mgit.toml"
  cd "$TREE/workspace"
  run "$MGIT" repair
  [ "$status" -eq 0 ]
  [[ "$output" == *"would clone standard repository"* ]]
  [ ! -e "$TREE/workspace/missing" ]
  run "$MGIT" repair --apply
  [ "$status" -eq 0 ]
  [ -f "$TREE/workspace/missing/payload" ]
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

  run "$MGIT" repair --apply
  [ "$status" -eq 1 ]
  grep -Fx 'schema = 1' .mgit.toml
  [ ! -e "$TREE/missing-repo" ]

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

@test "register migrates a legacy structural group to direct members" {
  mkrepo "$TREE/a"
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
  [ "$output" = a ]

  run "$MGIT" register
  [ "$status" -eq 0 ]
  grep -Fx '[members."a"]' "$TREE/.mgit.toml"
  ! grep -Fq 'schema =' "$TREE/.mgit.toml"
  ! grep -Fq '[groups.' "$TREE/.mgit.toml"

  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = a ]
}

@test "repair previews and explicitly converts only a structural default workspace" {
  mkrepo "$TREE/a"
  printf '%s\n' \
    '# Preserve this note' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "default"' \
    '' \
    '[groups.default.members."a"]' \
    'kind = "repository"' \
    'type = "standard"' > "$TREE/.mgit.toml"
  cd "$TREE"
  before=$(cat .mgit.toml)
  run "$MGIT" repair
  [ "$status" -eq 0 ]
  [[ "$output" == *'-schema = 1'* ]]
  [[ "$output" == *'+[members."a"]'* ]]
  [[ "$output" == *'preview only'* ]]
  [ "$(cat .mgit.toml)" = "$before" ]
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = a ]
  run "$MGIT" repair --apply
  [ "$status" -eq 0 ]
  grep -Fx '# Preserve this note' .mgit.toml
  grep -Fx '[members."a"]' .mgit.toml
  ! grep -Fq 'schema =' .mgit.toml
  ! grep -Fq '[groups.' .mgit.toml
  run "$MGIT" repair
  [ "$status" -eq 0 ]
  [[ "$output" == *'already unversioned'* ]]
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = a ]
}

@test "repair keeps repository metadata and refuses unknown or alternative shapes" {
  mkrepo "$TREE/a"
  printf '%s\n' 'schema = 1' 'kind = "repository"' > "$TREE/a/.mgit.toml"
  cd "$TREE/a"
  run "$MGIT" repair
  [ "$status" -eq 0 ]
  grep -Fx 'schema = 1' .mgit.toml
  run "$MGIT" repair --apply
  [ "$status" -eq 0 ]
  grep -Fx 'kind = "repository"' .mgit.toml
  ! grep -Fq 'schema =' .mgit.toml
  printf '%s\n' 'schema = 2' 'kind = "repository"' > .mgit.toml
  run "$MGIT" repair --apply
  [ "$status" -eq 1 ]
  grep -Fx 'schema = 2' .mgit.toml

  cd "$TREE"
  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "focus"' \
    '[groups.default.members."a"]' \
    'kind = "repository"' \
    'type = "standard"' \
    '[groups.focus.members."a"]' \
    'kind = "repository"' > .mgit.toml
  before=$(cat .mgit.toml)
  run "$MGIT" repair --apply
  [ "$status" -eq 1 ]
  [[ "$output" == *'alternative groups need a deliberate manual decision'* ]]
  [ "$(cat .mgit.toml)" = "$before" ]
}

@test "register refuses to discard legacy alternative groups" {
  mkrepo "$TREE/a"
  printf '%s\n' \
    'schema = 1' \
    'kind = "workspace"' \
    'default = "focus"' \
    '' \
    '[groups.default.members."a"]' \
    'kind = "repository"' \
    'type = "standard"' \
    '' \
    '[groups.focus.members."a"]' \
    'kind = "repository"' > "$TREE/.mgit.toml"

  cd "$TREE"
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = a ]
  before=$(cat "$TREE/.mgit.toml")
  run "$MGIT" register
  [ "$status" -eq 1 ]
  [[ "$output" == *"remove alternative groups before migrating"* ]]
  [ "$(cat "$TREE/.mgit.toml")" = "$before" ]
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

@test "workspace selection rejects mixed formats and unsafe workspace cycles" {
  mkrepo "$TREE/a"
  mkdir "$TREE/child"
  ln -s .. "$TREE/child/loop"
  printf '%s\n' \
    'kind = "workspace"' \
    '[members."child"]' \
    'kind = "workspace"' > "$TREE/.mgit.toml"
  printf '%s\n' \
    'kind = "workspace"' \
    '[members."loop"]' \
    'kind = "workspace"' > "$TREE/child/.mgit.toml"

  cd "$TREE"
  printf '\n[groups.default]\n' >> "$TREE/.mgit.toml"
  run "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unversioned workspace requires direct members and no groups"* ]]

  printf '%s\n' \
    'kind = "workspace"' \
    '[members."child"]' \
    'kind = "workspace"' > "$TREE/.mgit.toml"

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
  grep -Fx '[members."repoA"]' "$TREE/.mgit.toml"
  grep -Fx 'type = "nested"' "$TREE/.mgit.toml"
  grep -Fx '[members."repoB"]' "$TREE/.mgit.toml"
  grep -Fx 'type = "standard"' "$TREE/.mgit.toml"
  ! grep -Fx '[members."main"]' "$TREE/.mgit.toml"
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

@test "normal commands use primary checkouts unless all worktrees are requested" {
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
  [[ "$output" != *"repoA/branch-b"* ]]
  [[ "$output" == *"repoB"* ]]
  [[ "$output" != *"repoB-branch-c"* ]]
  [[ "$output" != *"repoA/.bare"* ]]

  run "$MGIT" --all-worktrees
  [ "$status" -eq 0 ]
  [[ "$output" == *"repoA/main"* ]]
  [[ "$output" == *"repoA/branch-b"* ]]
  [[ "$output" == *"repoB"* ]]
  [[ "$output" == *"repoB [branch-c]"* ]]
  [[ "$output" != *"repoA/.bare"* ]]

  run "$MGIT" -W
  [ "$status" -eq 0 ]
  [[ "$output" == *"repoA/branch-b"* ]]
  [[ "$output" == *"repoB [branch-c]"* ]]

  run "$MGIT" worktree list
  [ "$status" -eq 0 ]
  [[ "$output" == *"repoA/main"* ]]
  [[ "$output" == *"repoA/branch-b"* ]]
}

@test "external worktree labels hide storage paths without changing execution targets" {
  mkrepo "$TREE/repo A"
  mkrepo "$TREE/repoB"
  local storage="$BATS_TEST_TMPDIR/runtime storage/company-uuid"
  git -C "$TREE/repo A" worktree add -q -b GOV-104 "$storage/one"
  git -C "$TREE/repoB" worktree add -q -b GOV-104 "$storage/two"
  git -C "$TREE/repo A" worktree add -q --detach "$storage/held work"
  git -C "$TREE/repoB" worktree add -q -b hidden "$TREE/repoB/.git/mgit-worktrees/hidden"

  cd "$TREE"
  "$MGIT" register >/dev/null
  run "$MGIT" -W
  [ "$status" -eq 0 ]
  [[ "$output" == *"repo A [GOV-104]"* ]]
  [[ "$output" == *"repoB [GOV-104]"* ]]
  [[ "$output" == *"repo A [detached:held work@"* ]]
  [[ "$output" == *"repoB [hidden]"* ]]
  [[ "$output" != *"company-uuid"* ]]
  [[ "$output" != *".git/mgit-worktrees"* ]]

  run "$MGIT" -W -f 'repo A' rev-parse --show-toplevel
  [ "$status" -eq 0 ]
  [[ "$output" == *"repo A [GOV-104]: git rev-parse --show-toplevel"* ]]
  [[ "$output" == *"$storage/one"* ]]
  [[ "$output" != *"$storage/two"* ]]

  run "$MGIT" -W --bare pwd -P
  [ "$status" -eq 0 ]
  [[ "$output" == *"repoB [GOV-104]: pwd -P"* ]]
  [[ "$output" == *"$storage/two"* ]]

  run "$MGIT" worktree list
  [ "$status" -eq 0 ]
  [[ "$output" == *"runtime storage/company-uuid/one"* ]]
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

@test "--filter selects whole repos before optional worktree expansion" {
  mkrepo "$TREE/mcp-a"
  make_managed_worktree_repo "$TREE/mcp-a"
  git -C "$TREE/mcp-a" worktree add -q "$TREE/mcp-a/featureA" -b featureA
  mkrepo "$TREE/tools-b"

  cd "$TREE"
  run "$MGIT" -f 'mcp-*'
  [ "$status" -eq 0 ]
  [[ "$output" == *"mcp-a/main"* ]]
  [[ "$output" != *"mcp-a/featureA"* ]]
  [[ "$output" != *"tools-b"* ]]

  run "$MGIT" -f 'mcp-*' --all-worktrees
  [ "$status" -eq 0 ]
  [[ "$output" == *"mcp-a/main"* ]]
  [[ "$output" == *"mcp-a/featureA"* ]]
  [[ "$output" != *"tools-b"* ]]
}

# Helper: run a command, failing the test if it errors (for use inside subshells
# where bats' own `run` isn't available).
run_ok() { "$@"; }
