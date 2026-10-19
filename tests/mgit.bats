#!/usr/bin/env bats
# Smoke tests for mgit. No network; every test builds a throwaway tree of git
# repos under a temp dir and runs the script against it.

setup() {
  MGIT="$BATS_TEST_DIRNAME/../bin/mgit"
  TREE="$BATS_TEST_TMPDIR/tree"
  mkdir -p "$TREE"
  # Quiet, hermetic git — no user config, no signing, no hints.
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
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
  FAKE_KI_TERRITORY=focus
  FAKE_KI_ROOTS=""
  FAKE_KI_SECOND_TERRITORY=second
  FAKE_KI_SECOND_ROOTS=""
  FAKE_KI_FAIL=false
  export FAKE_KI_TERRITORY FAKE_KI_ROOTS FAKE_KI_SECOND_TERRITORY FAKE_KI_SECOND_ROOTS FAKE_KI_FAIL
  cat > "$bin/ki" <<'KI'
#!/usr/bin/env bash
# Strict protocol double; the integration gate uses the actual producer.
[ "$1" = territory ] && [ "$2" = roots ] && [ "$3" = --null ] || exit 64
shift 3
case "$1" in
  --territory) name="$2"; shift 2 ;;
  --estate) name=estate; shift ;;
  --principals) name=principals; shift ;;
  *) exit 64 ;;
esac
case "$name" in
  "$FAKE_KI_TERRITORY") roots="$FAKE_KI_ROOTS" ;;
  "$FAKE_KI_SECOND_TERRITORY") roots="$FAKE_KI_SECOND_ROOTS" ;;
  *) printf 'unknown territory: %s\n' "$name" >&2; exit 65 ;;
esac
prefixes=()
while [ $# -gt 0 ]; do
  [ "$1" = --filter ] && [ $# -ge 2 ] && [ -n "$2" ] || exit 64
  prefixes+=("$2"); shift 2
done
[ "$FAKE_KI_FAIL" = false ] || { printf 'fake territory resolution failed\n' >&2; exit 73; }
while IFS= read -r root || [ -n "$root" ]; do
  [ -n "$root" ] || continue
  matched=false
  [ ${#prefixes[@]} -gt 0 ] || matched=true
  for prefix in "${prefixes[@]}"; do
    case "${root##*/}" in "$prefix"*) matched=true ;; esac
  done
  [ "$matched" = false ] || printf '%s\0' "$root"
done <<< "$roots"
KI
  chmod +x "$bin/ki"
  PATH="$bin:$PATH"
}

@test "--help prints usage and exits 0" {
  run "$MGIT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: mgit"* ]] || false
  [[ "$output" == *"ignore workspace manifests and discover repositories"* ]] || false
  [[ "$output" == *"--territory <handle>"* ]] || false
  [[ "$output" == *"--all-worktrees"* ]] || false
  [[ "$output" == *"--estate"* ]] || false
  [[ "$output" == *"--principals"* ]] || false
  [[ "$output" == *"passed through to Git"* ]] || false

  run "$MGIT" help register
  [ "$status" -eq 0 ]
  [[ "$output" == *"--territory <handle>"* ]] || false
  [[ "$output" == *"--repo <path>"* ]] || false
}

@test "--version prints the version" {
  run "$MGIT" --version
  [ "$status" -eq 0 ]
  [[ "$output" == "mgit 0.18.0" ]] || false
}

@test "diag redacts the working path unless full output is requested" {
  cd "$TREE"
  run "$MGIT" diag
  [ "$status" -eq 0 ]
  [[ "$output" == *'mgit diag: manifest=absent'* ]] || false
  for label in Tool Version Installation Platform Architecture Runtime Configuration; do
    [[ "$output" == *"$label:"* ]] || false
  done
  [[ "$output" == *'Installation: local'* ]] || false
  [[ "$output" == *'Runtime: bash '* ]] || false
  [[ "$output" == *'Configuration: absent'* ]] || false
  [[ "$output" != *"$TREE"* ]] || false
  [[ "$output" != *"$BATS_TEST_DIRNAME"* ]] || false

  run "$MGIT" diag --full
  [ "$status" -eq 0 ]
  [[ "$output" == *"directory=$TREE"* ]] || false
  [[ "$output" == *'configuration-path='* ]] || false
  [[ "$output" == *'executable='* ]] || false
}

@test "diag resolves linked checkouts and does not guess copied executable provenance" {
  cd "$TREE"
  ln -s "$MGIT" linked-mgit
  ln -s linked-mgit second-link
  run "$TREE/second-link" diag
  [ "$status" -eq 0 ]
  [[ "$output" == *'Installation: local'* ]] || false

  mkdir -p "$TREE/copied/bin"
  cp "$MGIT" "$TREE/copied/bin/mgit"
  run "$TREE/copied/bin/mgit" diag
  [ "$status" -eq 0 ]
  [[ "$output" == *'Installation: unknown'* ]] || false
  printf '%s\n' '{}' > "$TREE/copied/INSTALL_RECEIPT.json"
  run "$TREE/copied/bin/mgit" diag
  [ "$status" -eq 0 ]
  [[ "$output" == *'Installation: release'* ]] || false
}

@test "diagnostics redact invalid configuration content and doctor counts failures" {
  cd "$TREE"
  printf '%s\n' 'kind = "private-secret-invalid-kind"' > .mgit.toml
  before=$(cat .mgit.toml)
  run "$MGIT" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *'Configuration: invalid'* ]] || false
  [[ "$output" == *'Checks: pass=1 warn=0 fail=1 skipped=0'* ]] || false
  [[ "$output" == *'Verdict: unhealthy'* ]] || false
  [[ "$output" == *'mgit diag --full'* ]] || false
  [[ "$output" != *'private-secret-invalid-kind'* ]] || false
  [[ "$output" != *"$TREE"* ]] || false
  [ "$(cat .mgit.toml)" = "$before" ]
  run "$MGIT" diag
  [ "$status" -eq 0 ]
  [[ "$output" == *'Configuration: invalid'* ]] || false
  [[ "$output" != *'private-secret-invalid-kind'* ]] || false
  run "$MGIT" diag --full
  [ "$status" -eq 0 ]
  [[ "$output" == *'detail=unsupported manifest kind'* ]] || false
  [[ "$output" != *'private-secret-invalid-kind'* ]] || false
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
  [[ "$output" == *'fail git: Git unavailable; install Git and retry.'* ]] || false
  [[ "$output" == *'Checks: pass=1 warn=0 fail=1 skipped=0'* ]] || false
  [[ "$output" == *'Configuration: absent'* ]] || false
}

@test "doctor evaluates the manifest without writing and config repair is retired" {
  cd "$TREE"
  run "$MGIT" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *'filesystem discovery available'* ]] || false
  [[ "$output" == *'Checks: pass=2 warn=0 fail=0 skipped=0'* ]] || false
  [[ "$output" == *'Verdict: healthy'* ]] || false
  [[ "$output" == *'Not checked: package updates'* ]] || false

  mkrepo "$TREE/a"
  printf '%s\n' 'kind = "workspace"' '[members."a"]' 'kind = "repository"' \
    'type = "standard"' > .mgit.toml
  before=$(cat .mgit.toml)
  run "$MGIT" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *'workspace manifest valid'* ]] || false
  [ "$(cat .mgit.toml)" = "$before" ]

  mv .mgit.toml manifest.toml
  ln -s absent.toml .mgit.toml
  run "$MGIT" doctor
  [ "$status" -eq 1 ]
  [[ "$output" == *'Configuration: invalid'* ]] || false
  [[ "$output" == *'correct .mgit.toml'* ]] || false
  run "$MGIT" diag --full
  [ "$status" -eq 0 ]
  [[ "$output" == *'manifest must be a regular file'* ]] || false
  [[ "$output" == *'mgit diag: manifest=present'* ]] || false
  rm .mgit.toml
  mv manifest.toml .mgit.toml

  run "$MGIT" config repair
  [ "$status" -eq 2 ]
  [[ "$output" == *"command 'config' removed"* ]] || false

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
  [[ "$output" == *"installing mgit (v1.2.3)"* ]] || false
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
  [[ "$output" == *"manual unavailable for v0.1.0"* ]] || false
}

@test "installer rejects malformed versions and extra arguments" {
  run "$BATS_TEST_DIRNAME/../install.sh" 1.2.3
  [ "$status" -eq 2 ]
  [[ "$output" == *"expected an exact version like vX.Y.Z"* ]] || false

  run env MGIT_VERSION=main "$BATS_TEST_DIRNAME/../install.sh"
  [ "$status" -eq 2 ]
  [[ "$output" == *"MGIT_VERSION must be an exact version like vX.Y.Z"* ]] || false

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
  [ "$output" = "mgit 0.18.0" ]
}

@test "completion prints bash and zsh setup" {
  run "$MGIT" completion bash
  [ "$status" -eq 0 ]
  [[ "$output" == *"complete -F _mgit mgit"* ]] || false
  [[ "$output" == *"structure"* ]] || false
  [[ "$output" == *"repair"* ]] || false
  [[ "$output" == *"doctor"* ]] || false
  [[ "$output" == *"diag"* ]] || false
  [[ "$output" == *"sync"* ]] || false
  [[ "$output" == *"--estate --principals"* ]] || false
  [[ "$output" == *"add rm --territory -t --repo --dry-run --help -h"* ]] || false
  [[ "$output" == *"--apply"* ]] || false
  [[ "$output" == *"--all-worktrees"* ]] || false
  [[ "$output" != *"bootstrap"* ]] || false
  [[ "$output" != *"convert"* ]] || false
  [[ "$output" == *"-B --bypass -R --raw -j"* ]] || false
  [[ "$output" == *"--learn"* ]] || false
  [[ "$output" == *"overview structure worktree learn completion"* ]] || false
  [[ "$output" == *"--list --forget --help -h"* ]] || false
  [[ "$output" != *"--bare"* ]] || false
  [[ "$output" != *"-G"* ]] || false
  [[ "$output" != *"--git "* ]] || false

  run "$MGIT" completion zsh
  [ "$status" -eq 0 ]
  [[ "$output" == *"#compdef mgit"* ]] || false
  [[ "$output" == *"standard nested"* ]] || false
  [[ "$output" == *"--estate"* ]] || false
  [[ "$output" == *"--principals[select the territory Capitals in KI order]"* ]] || false
  [[ "$output" == *"add or remove a territory location"* ]] || false
  [[ "$output" == *"add or remove a repository location"* ]] || false
  [[ "$output" == *"perform validated repairs"* ]] || false
  [[ "$output" == *"sync:update clean tracking branches"* ]] || false
  [[ "$output" == *"compdef _mgit mgit"* ]] || false
  [[ "$output" == *"'--raw[run an ordinary command without git prefix]'"* ]] || false
  [[ "$output" == *"'-B[run a Git subcommand even when mgit owns the name]'"* ]] || false
  [[ "$output" == *"'--bypass[run a Git subcommand even when mgit owns the name]'"* ]] || false
  [[ "$output" == *"'--learn[learn the normal output of a Git command]'"* ]] || false
  [[ "$output" == *"'learn:learn the normal output of a Git command'"* ]] || false
  [[ "$output" != *"'-G["* ]] || false
  [[ "$output" != *"'--git["* ]] || false
  [[ "$output" != *"'--bare["* ]] || false
  [[ "$output" != *'_mgit "$@"'* ]] || false

  run "$MGIT" completion fish
  [ "$status" -eq 2 ]
}

@test "zsh completion evaluates and registers mgit" {
  run zsh -f -c '
    autoload -Uz compinit && compinit -C
    eval "$("$1" completion zsh)"
    [[ ${_comps[mgit]} == _mgit ]] || false
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
  [[ "$output" == *"worktree: expected list, status, add, or remove"* ]] || false
}

assert_usage_error() {
  run "$MGIT" "$@"
  [ "$status" -eq 2 ]
  [[ "$output" == mgit:\ error:* ]] || false
  [[ "$output" == *"Usage: mgit"* ]] || false
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
  for option in -P -L -R -I -W; do
    assert_usage_error "$option" register
    assert_usage_error "$option" repair
  done
  assert_usage_error --filter repo register
  assert_usage_error --filter repo repair
  assert_usage_error --estate register
  assert_usage_error --estate repair
  assert_usage_error --principals register
  assert_usage_error --principals repair
  assert_usage_error --principals doctor
  assert_usage_error --principals diag
  assert_usage_error --principals completion bash
  assert_usage_error -a focus repair
  [ ! -e "$TREE/.mgit.toml" ]
  [ ! -e "$TREE/repo/.mgit.toml" ]
}

@test "command-specific selectors reject ignored combinations" {
  mkrepo "$TREE/repo"
  cd "$TREE"
  assert_usage_error -R
  assert_usage_error -R sync
  assert_usage_error -R structure nested
  assert_usage_error -R worktree list
  assert_usage_error -W structure nested
  assert_usage_error -W worktree list
  assert_usage_error -a focus structure nested
  assert_usage_error -a focus worktree list
  assert_usage_error --filter repo completion bash
  [ -d "$TREE/repo/.git" ]
  [ ! -e "$TREE/repo/.bare" ]
}

@test "help and version remain available with selectors" {
  run "$MGIT" -R --version
  [ "$status" -eq 0 ]
  [[ "$output" == mgit\ * ]] || false
  run "$MGIT" -W help structure
  [ "$status" -eq 0 ]
  [[ "$output" == Usage:\ mgit\ structure* ]] || false
}

@test "standalone reserved-command help exits 0" {
  for command in register repair doctor diag sync overview structure worktree learn completion; do
    run "$MGIT" "$command" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: mgit"* ]] || false
  done
}

@test "help is contextual for reserved commands and their subcommands" {
  run "$MGIT" register -h
  [ "$status" -eq 0 ]
  [[ "$output" == "Usage: mgit register [add|rm] [options]"* ]] || false
  [[ "$output" != *"Commands:"* ]] || false

  run "$MGIT" help sync
  [ "$status" -eq 0 ]
  [[ "$output" == "Usage: mgit sync"* ]] || false

  run "$MGIT" help worktree remove
  [ "$status" -eq 0 ]
  [[ "$output" == "Usage: mgit worktree remove <path> [--force]"* ]] || false
}

@test "reserved command trees reject unknown subcommands" {
  run "$MGIT" structure sideways
  [ "$status" -eq 2 ]
  [[ "$output" == *"structure: unknown command: sideways"* ]] || false
}

@test "removed group interface is absent from help and completion" {
  run "$MGIT" --group focus status
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown option: --group"* ]] || false

  run "$MGIT" help group
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown mgit command: group"* ]] || false

  run "$MGIT" completion bash
  [ "$status" -eq 0 ]
  [[ "$output" != *"--group"* ]] || false
  [[ "$output" != *"group:create"* ]] || false

  run "$MGIT" completion zsh
  [ "$status" -eq 0 ]
  [[ "$output" != *"--group"* ]] || false
  [[ "$output" != *"group:create"* ]] || false
}

@test "ordinary Git command options remain pass-through" {
  mkrepo "$TREE/repo"
  : > "$TREE/repo/new"
  cd "$TREE/repo"

  run "$MGIT" status --short

  [ "$status" -eq 0 ]
  [[ "$output" == *"git status --short"* ]] || false
}

@test "--bypass runs Git subcommands that mgit owns" {
  mkrepo "$TREE/alpha"
  mkrepo "$TREE/beta"
  cd "$TREE"

  run "$MGIT" --bypass worktree list --porcelain
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'alpha: git worktree list --porcelain' ]
  [[ "${lines[1]}" == "worktree "*/alpha ]] || false
  [[ "$output" == *$'\nbeta: git worktree list --porcelain\nworktree '*/beta$'\n'* ]] || false
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: 2 repositories: 0 quiet, 2 with output, 0 failed' ]

  run "$MGIT" -B help
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'alpha: git help' ]
  [[ "$output" != *"Usage: mgit"* ]] || false

  run "$MGIT" -B --filter b -j 1 -v structure
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = 'beta: git structure' ]
  [[ "$output" == *"'structure' is not a git command"* ]] || false

  run "$MGIT" -B --json rev-parse --is-inside-work-tree
  [ "$status" -eq 0 ]
  [[ "$output" == *'"command":"git rev-parse --is-inside-work-tree"'* ]] || false

  run "$MGIT" -B -W status --short
  [ "$status" -eq 0 ]
}

@test "--raw runs the argument vector directly" {
  mkrepo "$TREE/alpha"
  mkrepo "$TREE/beta"
  cd "$TREE"
  local physical
  physical=$(pwd -P)

  run "$MGIT" -R pwd -P
  [ "$status" -eq 0 ]
  [ "$output" = "alpha: pwd -P"$'\n'"$physical/alpha"$'\n'"beta: pwd -P"$'\n'"$physical/beta"$'\n''mgit: 2 repositories: 0 quiet, 2 with output, 0 failed' ]

  run "$MGIT" --raw sh -c 'echo a | tr a b'
  [ "$status" -eq 0 ]
  [ "${lines[1]}" = b ]
  run "$MGIT" -R 'echo a'
  [ "$status" -eq 1 ]
  [[ "${lines[${#lines[@]} - 1]}" == *'2 failed: alpha (exit 127), beta (exit 127)' ]] || false
}

@test "--bare, -G and --git are removed and run nothing" {
  mkrepo "$TREE/alpha"
  cd "$TREE"
  assert_usage_error --bare touch marker
  [[ "$output" == *"mgit: error: --bare has been removed; use -R/--raw to run a command directly"* ]] || false
  [[ "$output" != *'alpha'* ]] || false
  for option in -G --git; do
    assert_usage_error "$option" status
    [[ "$output" == *"mgit: error: $option has been removed; use -B/--bypass to run a Git command"* ]] || false
    assert_usage_error "$option" sync
    [[ "$output" == *"$option has been removed"* ]] || false
  done
  assert_usage_error -B --bare status
  [ ! -e "$TREE/alpha/marker" ]

  run "$MGIT" -B rev-parse --is-inside-work-tree
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'alpha: git rev-parse --is-inside-work-tree' ]
}

@test "--bypass and --raw reject invalid combinations" {
  mkrepo "$TREE/repo"
  cd "$TREE"
  assert_usage_error -B
  [[ "$output" == *"--bypass requires a Git command"* ]] || false
  assert_usage_error -B -R status
  [[ "$output" == *"--bypass cannot be combined with --raw"* ]] || false
  assert_usage_error --bypass --raw status
  [[ "$output" == *"--bypass cannot be combined with --raw"* ]] || false
  assert_usage_error -R
  [[ "$output" == *"--raw requires a command"* ]] || false
  assert_usage_error -R overview
  [[ "$output" == *"--raw cannot be used with overview"* ]] || false
  assert_usage_error -R sync
  [[ "$output" == *"--raw cannot be used with sync"* ]] || false
  run "$MGIT" -B -h
  [ "$status" -eq 0 ]
  [[ "$output" == 'Usage: mgit [options] [command]'* ]] || false
  [[ "$output" == *'-B, --bypass'*'-R, --raw'* ]] || false
  [[ "$output" == *'    --learn '* ]] || false
  [[ "$output" == *'  learn '* ]] || false
  [[ "$output" != *'--bare'* ]] || false
  [[ "$output" != *'-G'* ]] || false
  [[ "$output" != *'temporary'* ]] || false
  [[ "$output" == *'when discovering repositories'* ]] || false
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
  [[ "$plain_output" == *"a: git rev-parse --verify only-b"* ]] || false
  [[ "$plain_output" == *"b: git rev-parse --verify only-b"* ]] || false

  run "$MGIT" -R sh -c 'test -f success'
  [ "$status" -eq 1 ]
  plain_output=${output//$'\033[1m'/}
  plain_output=${plain_output//$'\033[33m'/}
  plain_output=${plain_output//$'\033[0m'/}
  [[ "$plain_output" == *"a: sh -c"* ]] || false
  [[ "$plain_output" != *"b: sh -c"* ]] || false
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: 2 repositories: 1 quiet, 0 with output, 1 failed: a (exit 1)' ]

  run "$MGIT" -v -R sh -c 'test -f success'
  [ "$status" -eq 1 ]
  [[ "$output" == *"b: sh -c"* ]] || false
  [[ "$output" != *"mgit: 2 repositories"* ]] || false
}

@test "the runner prints results in selection order and counts quiet checkouts" {
  local name
  for name in a b c d; do mkrepo "$TREE/$name"; done
  printf '0.6\n' > "$TREE/a/delay"
  printf '0.3\n' > "$TREE/b/delay"
  printf '0\n' > "$TREE/c/delay"
  printf '0\n' > "$TREE/d/delay"
  cd "$TREE"

  run "$MGIT" -R sh -c 'sleep "$(cat delay)"; basename "$PWD"'
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 9 ]
  [[ "${lines[0]}" == 'a: sh -c sleep'* ]] || false
  [ "${lines[1]}" = a ]
  [[ "${lines[2]}" == 'b: sh -c sleep'* ]] || false
  [ "${lines[3]}" = b ]
  [ "${lines[5]}" = c ]
  [ "${lines[7]}" = d ]
  [ "${lines[8]}" = 'mgit: 4 repositories: 0 quiet, 4 with output, 0 failed' ]

  run "$MGIT" -R sh -c 'case "${PWD##*/}" in b) echo out ;; c) echo err >&2; exit 3 ;; esac'
  [ "$status" -eq 1 ]
  [[ "${lines[0]}" == 'b: sh -c case'* ]] || false
  [ "${lines[1]}" = out ]
  [[ "${lines[2]}" == 'c: sh -c '* ]] || false
  [ "${lines[3]}" = err ]
  [ "${lines[4]}" = 'mgit: 4 repositories: 2 quiet, 1 with output, 1 failed: c (exit 3)' ]
  [ "${#lines[@]}" -eq 5 ]
}

@test "the runner runs checkouts concurrently up to the job limit" {
  local name
  for name in a b c; do mkrepo "$TREE/$name"; done
  export MARKS="$BATS_TEST_TMPDIR/marks"
  mkdir "$MARKS"
  cd "$TREE"
  # Each worker waits briefly for its siblings, then reports how many started.
  # shellcheck disable=SC2016
  local probe='touch "$MARKS/${PWD##*/}"; n=0; while [ "$(ls "$MARKS" | wc -l)" -lt 3 ] && [ $n -lt 20 ]; do sleep 0.1; n=$((n + 1)); done; ls "$MARKS" | wc -l | tr -d " "'

  run "$MGIT" -j 3 -R sh -c "$probe"
  [ "$status" -eq 0 ]
  [ "${lines[1]}" = 3 ]
  [ "${lines[3]}" = 3 ]
  [ "${lines[5]}" = 3 ]

  rm -f "$MARKS"/*
  run "$MGIT" --jobs 1 -R sh -c "$probe"
  [ "$status" -eq 0 ]
  [ "${lines[1]}" = 1 ]
  [ "${lines[3]}" = 2 ]
  [ "${lines[5]}" = 3 ]
  [ "${lines[6]}" = 'mgit: 3 repositories: 0 quiet, 3 with output, 0 failed' ]
}

# Clean checkouts level with an upstream, on differing branch names.
make_level_pair() {
  local origins="$BATS_TEST_TMPDIR/origins"
  mkdir -p "$origins"
  printf '[alias]\n\tst = status -sb\n\tlg = log --oneline\n' > "$BATS_TEST_TMPDIR/gitconfig"
  export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gitconfig"
  make_origin "$TREE/alpha" "$origins/alpha.git" alpha
  make_origin "$TREE/beta" "$origins/beta.git" beta
  git -C "$TREE/beta" branch -q -m trunk
  git -C "$TREE/beta" push -q -u origin trunk
}

@test "with no templates every checkout with output is shown" {
  make_level_pair
  cd "$TREE"

  run "$MGIT" st
  [ "$status" -eq 0 ]
  [[ "$output" == *'alpha: git st'$'\n''## '*'...origin/'* ]] || false
  [[ "$output" == *'beta: git st'$'\n''## trunk...origin/trunk'* ]] || false
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: 2 repositories: 0 quiet, 2 with output, 0 failed' ]
  [ ! -e "$XDG_CONFIG_HOME/mgit" ]
}

# Run a command on a pseudo-terminal, answering its first [y/N] prompt with $1
# (EOF ends the input instead), and capture its output and exit status.
run_on_terminal() {
  command -v python3 >/dev/null 2>&1 || skip 'python3 is needed for a pseudo-terminal'
  run env NO_COLOR=1 python3 -c '
import os, pty, sys
answer, command = sys.argv[1], sys.argv[2:]
pid, fd = pty.fork()
if pid == 0:
    os.execvp(command[0], command)
out, sent = b"", False
while True:
    try:
        data = os.read(fd, 1024)
    except OSError:
        break
    if not data:
        break
    out += data
    if not sent and b"[y/N]" in out:
        os.write(fd, b"\x04" if answer == "EOF" else answer.encode() + b"\n")
        sent = True
_, code = os.waitpid(pid, 0)
sys.stdout.write(out.decode().replace("\r", ""))
sys.exit(os.WEXITSTATUS(code) if os.WIFEXITED(code) else 1)
' "$@"
}

make_majority_trio() {
  make_level_pair
  make_origin "$TREE/gamma" "$BATS_TEST_TMPDIR/origins/gamma.git" gamma
  : > "$TREE/gamma/new"
}

@test "learn writes a template that later runs count as quiet" {
  local template="$XDG_CONFIG_HOME/mgit/templates/status_-sb.template"
  make_level_pair
  cd "$TREE"

  run "$MGIT" learn st < /dev/null
  [ "$status" -eq 1 ]
  [[ "$output" != *'[y/N]'* ]] || false
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: not learned: 2 of 2 repositories agreed; run it from a terminal to confirm' ]
  [ ! -e "$XDG_CONFIG_HOME/mgit" ]

  run_on_terminal n "$MGIT" learn st
  [ "$status" -eq 1 ]
  [[ "$output" == *'mgit learn: 2 of 2 repositories agreed. Learn this output? [y/N]'* ]] || false
  [[ "$output" == *'mgit: not learned: declined'* ]] || false
  [ ! -e "$XDG_CONFIG_HOME/mgit" ]

  run_on_terminal y "$MGIT" learn st
  [ "$status" -eq 0 ]
  [ "${lines[${#lines[@]} - 1]}" = "mgit: learned 'git status -sb' from 2 repositories: $template" ]
  [ -f "$template" ]
  grep -qx 'command: status -sb' "$template"
  grep -qx 'stdout: ## {branch}...{upstream}' "$template"
  ! grep -q 'trunk\|alpha\|beta' "$template" || false

  git -C "$TREE/beta" commit -q --allow-empty -m ahead
  make_origin "$TREE/delta" "$BATS_TEST_TMPDIR/origins/delta.git" delta
  : > "$TREE/delta/new"
  make_origin "$TREE/gamma" "$BATS_TEST_TMPDIR/origins/gamma.git" gamma
  git -C "$TREE/gamma" checkout -q --detach
  mkrepo "$TREE/local"

  run "$MGIT" st
  [ "$status" -eq 0 ]
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: 5 repositories: 1 quiet, 4 with output, 0 failed' ]
  [[ "$output" != *'alpha: git st'* ]] || false
  [[ "$output" == *'beta: git st'*'[ahead 1]'* ]] || false
  [[ "$output" == *'delta: git st'*'?? new'* ]] || false
  [[ "$output" == *'gamma: git st'* ]] || false
  [[ "$output" == *'local: git st'* ]] || false

  run "$MGIT" status -sb
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: 5 repositories: 1 quiet, 4 with output, 0 failed' ]
  run "$MGIT" status
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: 5 repositories: 0 quiet, 5 with output, 0 failed' ]

  run "$MGIT" -v --filter alpha st
  [ "$status" -eq 0 ]
  [[ "$output" == $'alpha: git st\n## '*'...origin/'* ]] || false
  run "$MGIT" --json --filter alpha st
  [[ "$output" == *'"quiet":true,"stdout":"## '*'...origin/'* ]] || false
}

@test "learn normalises remotes, paths and repository names" {
  make_level_pair
  cd "$TREE"

  run_on_terminal y "$MGIT" --learn remote -v
  [ "$status" -eq 0 ]
  grep -qx 'stdout: {remote}	{remote-url} (fetch)' "$XDG_CONFIG_HOME/mgit/templates/remote_-v.template"
  run "$MGIT" -R git remote -v
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: 2 repositories: 0 quiet, 2 with output, 0 failed' ]
  run "$MGIT" remote -v
  [ "$output" = 'mgit: 2 repositories: 2 quiet, 0 with output, 0 failed' ]

  run_on_terminal y "$MGIT" learn rev-parse --show-toplevel
  [ "$status" -eq 0 ]
  grep -qx 'stdout: {path}' "$XDG_CONFIG_HOME/mgit/templates/rev-parse_--show-toplevel.template"
}

@test "learn names the repositories that differ and writes nothing" {
  make_level_pair
  make_origin "$TREE/gamma" "$BATS_TEST_TMPDIR/origins/gamma.git" gamma
  : > "$TREE/gamma/new"
  cd "$TREE"

  make_origin "$TREE/delta" "$BATS_TEST_TMPDIR/origins/delta.git" delta
  : > "$TREE/delta/other"

  run "$MGIT" learn st < /dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *'gamma: git st'*'?? new'* ]] || false
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: not learned: 2 of 4 repositories differed from the most common output: delta, gamma' ]
  [ ! -e "$XDG_CONFIG_HOME/mgit/templates/status_-sb.template" ]
  rm -rf "$TREE/delta"

  run "$MGIT" learn rev-parse --verify trunk < /dev/null
  [ "$status" -eq 1 ]
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: not learned: 2 repositories failed' ]

  run "$MGIT" learn status --short < /dev/null
  [ "$status" -eq 1 ]
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: not learned: the most common output is empty, which is already quiet; 1 of 3 repositories differed: gamma' ]
  run "$MGIT" --filter alpha --filter beta learn status --short
  [ "$status" -eq 0 ]
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: not learned: no repository printed anything, which is already quiet' ]

  [ ! -e "$XDG_CONFIG_HOME/mgit" ]
}

@test "learn learns from a single repository" {
  local template="$XDG_CONFIG_HOME/mgit/templates/status_-sb.template"
  make_level_pair
  cd "$TREE"

  run "$MGIT" --filter alpha learn st < /dev/null
  [ "$status" -eq 1 ]
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: not learned: 1 of 1 repository agreed; run it from a terminal to confirm' ]
  [ ! -e "$XDG_CONFIG_HOME/mgit" ]

  run_on_terminal y "$MGIT" --filter alpha learn st
  [ "$status" -eq 0 ]
  [[ "$output" == *'mgit learn: 1 of 1 repository agreed. Learn this output? [y/N]'* ]] || false
  [[ "$output" == *"mgit: learned 'git status -sb' from 1 repository: $template"* ]] || false
  grep -qx 'stdout: ## {branch}...{upstream}' "$template"

  run "$MGIT" st
  [ "$output" = 'mgit: 2 repositories: 2 quiet, 0 with output, 0 failed' ]
}

@test "learn asks before writing a majority output" {
  local template="$XDG_CONFIG_HOME/mgit/templates/status_-sb.template"
  make_majority_trio
  cd "$TREE"

  run_on_terminal n "$MGIT" learn st
  [ "$status" -eq 1 ]
  [[ "$output" == *'mgit learn: 2 of 3 repositories agreed and 1 differed: gamma. Learn this output? [y/N]'* ]] || false
  [[ "$output" == *'mgit: not learned: declined'* ]] || false
  [ ! -e "$template" ]

  run_on_terminal '' "$MGIT" learn st
  [ "$status" -eq 1 ]
  [[ "$output" == *'mgit: not learned: declined'* ]] || false
  [ ! -e "$template" ]

  run_on_terminal EOF "$MGIT" learn st
  [ "$status" -eq 1 ]
  [[ "$output" == *'mgit: not learned: interactive input ended'* ]] || false
  [ ! -e "$template" ]

  run_on_terminal y "$MGIT" learn st
  [ "$status" -eq 0 ]
  [[ "$output" == *"mgit: learned 'git status -sb' from 2 of 3 repositories: $template"* ]] || false
  grep -qx 'stdout: ## {branch}...{upstream}' "$template"

  run "$MGIT" st
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: 3 repositories: 2 quiet, 1 with output, 0 failed' ]
  [[ "$output" == *'gamma: git st'*'?? new'* ]] || false
}

@test "learn never asks without a terminal" {
  make_majority_trio
  cd "$TREE"

  run "$MGIT" learn st < /dev/null
  [ "$status" -eq 1 ]
  [[ "$output" != *'[y/N]'* ]] || false
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: not learned: 2 of 3 repositories agreed and 1 differed: gamma; run it from a terminal to confirm' ]
  [ ! -e "$XDG_CONFIG_HOME/mgit" ]

  run bash -c 'printf "y\n" | "$1" learn st' _ "$MGIT"
  [ "$status" -eq 1 ]
  [[ "${lines[${#lines[@]} - 1]}" == 'mgit: not learned: 2 of 3 repositories agreed'* ]] || false
  [ ! -e "$XDG_CONFIG_HOME/mgit" ]

  rm -rf "$TREE/gamma"
  run bash -c 'printf "y\n" | "$1" learn st' _ "$MGIT"
  [ "$status" -eq 1 ]
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: not learned: 2 of 2 repositories agreed; run it from a terminal to confirm' ]
  [ ! -e "$XDG_CONFIG_HOME/mgit" ]
}

@test "a learned standard-error message is quiet only while it matches" {
  make_level_pair
  cd "$TREE"

  run_on_terminal y "$MGIT" learn push
  [ "$status" -eq 0 ]
  grep -qx 'stderr: Everything up-to-date' "$XDG_CONFIG_HOME/mgit/templates/push.template"

  git -C "$TREE/alpha" commit -q --allow-empty -m ahead
  run "$MGIT" push
  [ "$status" -eq 0 ]
  [[ "$output" == 'alpha: git push'* ]] || false
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: 2 repositories: 1 quiet, 1 with output, 0 failed' ]
}

@test "a template never quiets a failed checkout" {
  make_level_pair
  mkdir -p "$XDG_CONFIG_HOME/mgit/templates"
  printf '%s\n' '# hand-written' 'command: rev-parse --verify missing' 'stderr: fatal: Needed a single revision' \
    > "$XDG_CONFIG_HOME/mgit/templates/rev-parse_--verify_missing.template"
  cd "$TREE"

  run "$MGIT" rev-parse --verify missing
  [ "$status" -eq 1 ]
  [ "${lines[${#lines[@]} - 1]}" = 'mgit: 2 repositories: 0 quiet, 0 with output, 2 failed: alpha (exit 128), beta (exit 128)' ]
}

@test "learn lists and forgets templates" {
  local dir="$XDG_CONFIG_HOME/mgit/templates"
  make_level_pair
  cd "$TREE"

  run "$MGIT" learn --list
  [ "$status" -eq 0 ]
  [ -z "$output" ]

  run_on_terminal y "$MGIT" learn st
  [ "$status" -eq 0 ]
  run_on_terminal y "$MGIT" learn remote
  [ "$status" -eq 0 ]
  run "$MGIT" learn --list
  [ "$status" -eq 0 ]
  [ "$output" = "git remote	$dir/remote.template"$'\n'"git status -sb	$dir/status_-sb.template" ]

  run "$MGIT" learn --forget status -sb
  [ "$status" -eq 0 ]
  [ "$output" = "mgit: forgot 'git status -sb': $dir/status_-sb.template" ]
  [ ! -e "$dir/status_-sb.template" ]
  run "$MGIT" learn --forget st
  [ "$status" -eq 1 ]
  [ "$output" = "mgit: no template for 'git status -sb'" ]
}

@test "learn file names encode every argument readably" {
  local dir="$XDG_CONFIG_HOME/mgit/templates"
  make_level_pair
  cd "$TREE"
  run_on_terminal y "$MGIT" learn log -1 --format=%s_x HEAD
  [ "$status" -eq 0 ]
  [ -f "$dir/log_-1_--format=%25s%5Fx_HEAD.template" ]
  grep -qx 'stdout: payload_x' "$dir/log_-1_--format=%25s%5Fx_HEAD.template"
  run_on_terminal y "$MGIT" learn log -1 '--format=tformat:a b/c' HEAD
  [ "$status" -eq 0 ]
  [ -f "$dir/log_-1_--format=tformat%3Aa%20b%2Fc_HEAD.template" ]
  run_on_terminal y "$MGIT" -B --learn config --get remote.origin.fetch
  [ "$status" -eq 0 ]
  grep -qx 'stdout: +refs/heads/\*:refs/remotes/{remote}/\*' "$dir/config_--get_remote.origin.fetch.template"
}

@test "learn options are validated before anything runs" {
  make_level_pair
  cd "$TREE"
  assert_usage_error learn
  [[ "$output" == *'learn requires a command'* ]] || false
  assert_usage_error --learn
  [[ "$output" == *'learn requires a command'* ]] || false
  assert_usage_error learn sync
  [[ "$output" == *'learn: sync is an mgit command; use -B/--bypass to learn the Git command'* ]] || false
  assert_usage_error --learn overview
  [[ "$output" == *'learn: overview is an mgit command'* ]] || false
  assert_usage_error --learn -R pwd
  [[ "$output" == *'--learn cannot be combined with --raw'* ]] || false
  assert_usage_error --learn -v status
  [[ "$output" == *'--learn cannot be combined with --verbose'* ]] || false
  assert_usage_error --learn --json status
  [[ "$output" == *'--learn cannot be combined with --json'* ]] || false
  assert_usage_error --filter alpha learn --list
  [[ "$output" == *'--filter cannot be used with learn --list'* ]] || false
  assert_usage_error learn --list extra
  assert_usage_error learn --forget
  [[ "$output" == *'learn --forget requires a command'* ]] || false
  [ ! -e "$XDG_CONFIG_HOME/mgit" ]

  run "$MGIT" learn --help
  [ "$status" -eq 0 ]
  [[ "$output" == 'Usage: mgit learn'* ]] || false
  run "$MGIT" help learn
  [ "$status" -eq 0 ]
  [[ "$output" == 'Usage: mgit learn'* ]] || false

  run "$MGIT" -B --learn --filter alpha --filter beta config --get branch.trunk.remote
  [ "$status" -eq 1 ]
}

@test "verbose streams every checkout in turn as before" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  cd "$TREE"

  run "$MGIT" -v -R true
  [ "$status" -eq 0 ]
  [ "$output" = $'a: true\nb: true' ]

  run "$MGIT" --verbose -R sh -c 'echo out; echo err >&2'
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 6 ]
  [[ "${lines[0]}" == 'a: sh -c echo'* ]] || false
  [ "${lines[1]}" = out ]
  [ "${lines[2]}" = err ]
  [[ "${lines[3]}" == 'b: sh -c echo'* ]] || false
  [ "${lines[5]}" = err ]

  run "$MGIT" -R true
  [ "$status" -eq 0 ]
  [ "$output" = 'mgit: 2 repositories: 2 quiet, 0 with output, 0 failed' ]
}

@test "json prints ordinary-command results as one document" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  cd "$TREE"

  run "$MGIT" --json -R sh -c 'if [ "${PWD##*/}" = b ]; then printf "x\ty\n"; echo "e\"" >&2; exit 2; fi'
  [ "$status" -eq 1 ]
  [ "${#lines[@]}" -eq 1 ]
  [[ "$output" == '{"tool":"mgit","command":"sh -c '*'","version":"'*'","repositories":[{"label":"a","path":"'*'","exit":0,"quiet":true,"stdout":"","stderr":""},{"label":"b","path":"'*'","exit":2,"quiet":false,"stdout":"x\ty\n","stderr":"e\"\n"}],"summary":{"repositories":2,"quiet":1,"output":0,"failed":1}}' ]] || false
  if command -v python3 >/dev/null 2>&1; then
    printf '%s\n' "$output" | python3 -m json.tool >/dev/null
  fi

  run "$MGIT" --json rev-parse --is-inside-work-tree
  [ "$status" -eq 0 ]
  [[ "$output" == *'"command":"git rev-parse --is-inside-work-tree"'* ]] || false
  [[ "$output" == *'"stdout":"true\n"'* ]] || false
}

@test "workers cannot prompt, open an editor or read the terminal" {
  mkrepo "$TREE/repo"
  cd "$TREE"

  # shellcheck disable=SC2016
  run "$MGIT" -R sh -c 'printf "%s %s %s\n" "$GIT_TERMINAL_PROMPT" "$GIT_EDITOR" "$GIT_SEQUENCE_EDITOR"; if read -r line; then echo read; else echo eof; fi' <<< 'typed'
  [ "$status" -eq 0 ]
  [ "${lines[1]}" = '0 false false' ]
  [ "${lines[2]}" = eof ]

  before=$(git -C "$TREE/repo" rev-parse HEAD)
  run "$MGIT" commit -q --allow-empty
  [ "$status" -eq 1 ]
  [[ "$output" == *'mgit: 1 repository: 0 quiet, 0 with output, 1 failed: repo (exit 1)'* ]] || false
  [ "$(git -C "$TREE/repo" rev-parse HEAD)" = "$before" ]
}

@test "the runner draws no progress off a terminal and removes its files" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  mkdir "$BATS_TEST_TMPDIR/tmp"
  cd "$TREE"

  TMPDIR="$BATS_TEST_TMPDIR/tmp" "$MGIT" -R true > "$BATS_TEST_TMPDIR/out" 2> "$BATS_TEST_TMPDIR/err"
  [ ! -s "$BATS_TEST_TMPDIR/err" ]
  [ "$(cat "$BATS_TEST_TMPDIR/out")" = 'mgit: 2 repositories: 2 quiet, 0 with output, 0 failed' ]
  [ -z "$(ls -A "$BATS_TEST_TMPDIR/tmp")" ]

  TMPDIR="$BATS_TEST_TMPDIR/tmp" "$MGIT" -R sleep 3 > /dev/null 2>&1 &
  pid=$!
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -z "$(ls -A "$BATS_TEST_TMPDIR/tmp")" ] || break
    sleep 0.1
  done
  [ -n "$(ls -A "$BATS_TEST_TMPDIR/tmp")" ]
  kill -TERM "$pid"
  status=0
  wait "$pid" || status=$?
  [ "$status" -eq 143 ]
  [ -z "$(ls -A "$BATS_TEST_TMPDIR/tmp")" ]
}

@test "runner options are validated and rejected where they do not apply" {
  mkrepo "$TREE/repo"
  cd "$TREE"
  for value in 0 -1 abc 007 ''; do
    run "$MGIT" -j "$value" status
    [ "$status" -eq 2 ]
    [[ "$output" == *"--jobs requires a positive whole number"* ]] || false
  done
  run "$MGIT" --jobs
  [ "$status" -eq 2 ]
  [[ "$output" == *"--jobs requires a number of jobs"* ]] || false

  run "$MGIT" -v --json status
  [ "$status" -eq 2 ]
  [[ "$output" == *"--verbose and --json cannot be combined"* ]] || false
  run "$MGIT" -j 2
  [ "$status" -eq 2 ]
  [[ "$output" == *"--jobs cannot be used with listing"* ]] || false
  run "$MGIT" --json sync
  [ "$status" -eq 2 ]
  [[ "$output" == *"--json cannot be used with sync"* ]] || false
  run "$MGIT" --json doctor
  [ "$status" -eq 2 ]
  [[ "$output" == *"--json cannot be used with doctor"* ]] || false
  run "$MGIT" -j 2 worktree list
  [ "$status" -eq 2 ]
  [[ "$output" == *"--jobs cannot be used with worktree"* ]] || false
}

@test "overview runs on the pool and takes the global output options" {
  make_overview_estate
  make_overview_hygiene
  cd "$TREE"
  run "$MGIT" overview
  [ "$status" -eq 0 ]
  expected="$output"
  run "$MGIT" -j 1 overview
  [ "$output" = "$expected" ]
  run "$MGIT" --jobs 3 overview
  [ "$output" = "$expected" ]

  run "$MGIT" overview --json
  expected="$output"
  run "$MGIT" --json overview
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]

  run "$MGIT" overview --verbose
  expected="$output"
  run "$MGIT" -v overview
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
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
  [[ "$output" != *"checking"* ]] || false
  [[ "$output" != *"current"* ]] || false
  [[ "$output" == *"mgit sync: dirty: local changes (skipped)"* ]] || false
  [[ "$output" == *" M payload"* ]] || false
  [[ "$output" == *"mgit sync: 1 repository already in sync"* ]] || false

  run "$MGIT" sync --verbose
  [ "$status" -eq 1 ]
  [[ "$output" == *"mgit sync: [1/2] current: checking"* ]] || false
  [[ "$output" == *"mgit sync: [2/2] dirty: checking"* ]] || false
  [[ "$output" == *"mgit sync: dirty: local changes (skipped)"* ]] || false
  [[ "$output" != *"mgit sync: current: pulled"* ]] || false
  [[ "$output" != *"mgit sync: current: pushed"* ]] || false
  expected="$output"

  run "$MGIT" -v sync
  [ "$status" -eq 1 ]
  [ "$output" = "$expected" ]
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
  [[ "$output" == *"mgit sync: incoming: pulled 1 commit"* ]] || false
  [[ "$output" == *"mgit sync: outgoing: pushed 1 commit"* ]] || false
  [[ "$output" != *"pulling"* ]] || false
  [[ "$output" != *"pushing"* ]] || false
  [[ "$output" != *"[y/N]"* ]] || false
  [[ "$output" == *"mgit sync: 0 repositories already in sync"* ]] || false
  [ "$(git -C "$TREE/incoming" rev-parse HEAD)" = "$(git --git-dir="$incoming_origin" rev-parse HEAD)" ]
  [ "$(git -C "$TREE/outgoing" rev-parse HEAD)" = "$(git --git-dir="$outgoing_origin" rev-parse HEAD)" ]
}

@test "sync interactive mode confirms each pull and push" {
  local seed="$BATS_TEST_TMPDIR/seed"
  local origin="$BATS_TEST_TMPDIR/origin.git"
  local ahead_seed="$BATS_TEST_TMPDIR/ahead-seed"
  local ahead_origin="$BATS_TEST_TMPDIR/ahead.git"
  local before behind_before branch
  make_origin "$seed" "$origin" baseline
  make_origin "$ahead_seed" "$ahead_origin" baseline
  git clone -q "$ahead_origin" "$TREE/ahead"
  git clone -q "$origin" "$TREE/behind"
  git clone -q "$origin" "$TREE/level"
  git -C "$TREE/ahead" commit -q --allow-empty -m local-update
  git -C "$seed" commit -q --allow-empty -m remote-update
  git -C "$seed" push -q
  git -C "$TREE/level" pull -q
  before=$(git --git-dir="$ahead_origin" rev-parse HEAD)
  behind_before=$(git -C "$TREE/behind" rev-parse HEAD)
  branch=$(git -C "$TREE/behind" branch --show-current)

  cd "$TREE"
  run bash -c 'printf "n\n\n" | "$1" sync -i' _ "$MGIT"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'mgit sync: ahead: push 1 commit? [y/N]' ]
  [ "${lines[1]}" = 'mgit sync: ahead: push skipped (1 commit ahead)' ]
  [ "${lines[2]}" = "mgit sync: behind: pull 1 commit into $branch from origin/$branch? [y/N]" ]
  [ "${lines[3]}" = 'mgit sync: behind: pull skipped' ]
  [[ "$output" != *"level"* ]] || false
  [[ "$output" == *"mgit sync: 1 repository already in sync"* ]] || false
  [[ "$output" == *"mgit sync: 2 actions skipped by user"* ]] || false
  [ "$(git --git-dir="$ahead_origin" rev-parse HEAD)" = "$before" ]
  [ "$(git -C "$TREE/behind" rev-parse HEAD)" = "$behind_before" ]

  run bash -c 'printf "y\ny\n" | "$1" sync --interactive' _ "$MGIT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mgit sync: ahead: pushed 1 commit"* ]] || false
  [[ "$output" == *"mgit sync: behind: pulled 1 commit"* ]] || false
  [[ "$output" != *"skipped by user"* ]] || false
  [ "$(git --git-dir="$ahead_origin" rev-parse HEAD)" = "$(git -C "$TREE/ahead" rev-parse HEAD)" ]
  [ "$(git -C "$TREE/behind" rev-parse HEAD)" = "$(git --git-dir="$origin" rev-parse HEAD)" ]
}

@test "sync interactive mode stops when input ends before confirmation" {
  local seed="$BATS_TEST_TMPDIR/seed"
  local origin="$BATS_TEST_TMPDIR/origin.git"
  make_origin "$seed" "$origin" baseline
  git clone -q "$origin" "$TREE/repo"
  git -C "$TREE/repo" commit -q --allow-empty -m local-update

  cd "$TREE"
  run bash -c '"$1" sync -i < /dev/null' _ "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"mgit sync: repo: push 1 commit? [y/N]"* ]] || false
  [[ "$output" == *"mgit sync: interactive input ended"* ]] || false
  [[ "$output" != *"pushed"* ]] || false
  [ "$(git --git-dir="$origin" rev-parse HEAD)" != "$(git -C "$TREE/repo" rev-parse HEAD)" ]
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
  git -C "$TREE/diverged" config pull.rebase true
  local before branch
  before=$(git -C "$TREE/diverged" rev-parse HEAD)
  branch=$(git -C "$TREE/diverged" branch --show-current)

  cd "$TREE"
  run "$MGIT" sync

  [ "$status" -eq 1 ]
  [[ "$output" != *"archive.git"* ]] || false
  [[ "$output" == *"mgit sync: diverged: diverged from origin/$branch, 1 ahead and 1 behind (skipped)"* ]] || false
  [[ "$output" == *"mgit sync: no-upstream: branch "*" has no upstream (skipped)"* ]] || false
  [[ "$output" == *"mgit sync: 0 repositories already in sync"* ]] || false
  [ "${lines[${#lines[@]} - 1]}" = 'mgit sync: 1 bare repository skipped' ]
  [ "$(git -C "$TREE/diverged" rev-parse HEAD)" = "$before" ]
  [ ! -e "$TREE/diverged/.git/rebase-merge" ]
  [ ! -e "$TREE/diverged/.git/rebase-apply" ]
  [ ! -e "$TREE/diverged/.git/MERGE_HEAD" ]

  run "$MGIT" sync --verbose
  [ "$status" -eq 1 ]
  [[ "$output" == *"mgit sync: archive.git: bare repository (skipped)"* ]] || false
  [[ "$output" != *"bare repository skipped"* ]] || false
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
  run "$MGIT" --filter selected sync --verbose

  [ "$status" -eq 1 ]
  [[ "$output" == *"mgit sync: [1/1] selected: checking"* ]] || false
  [[ "$output" == *"mgit sync: selected: local changes (skipped)"* ]] || false
  [[ "$output" != *"omitted"* ]] || false
}

@test "sync fetches every repository before fast-forwarding them in order" {
  local name seed origin
  for name in alpha beta gamma; do
    seed="$BATS_TEST_TMPDIR/$name-seed"
    origin="$BATS_TEST_TMPDIR/$name.git"
    make_origin "$seed" "$origin" "$name"
    git clone -q "$origin" "$TREE/$name"
    git -C "$seed" commit -q --allow-empty -m "$name-update"
    git -C "$seed" commit -q --allow-empty -m "$name-second"
    git -C "$seed" push -q
  done

  cd "$TREE"
  run "$MGIT" -j 3 sync
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'mgit sync: alpha: pulled 2 commits' ]
  [ "${lines[1]}" = 'mgit sync: beta: pulled 2 commits' ]
  [ "${lines[2]}" = 'mgit sync: gamma: pulled 2 commits' ]
  [ "${lines[3]}" = 'mgit sync: 0 repositories already in sync' ]
  [ "${#lines[@]}" -eq 4 ]
  for name in alpha beta gamma; do
    [ "$(git -C "$TREE/$name" rev-parse HEAD)" = "$(git --git-dir="$BATS_TEST_TMPDIR/$name.git" rev-parse HEAD)" ]
  done

  run "$MGIT" sync
  [ "$status" -eq 0 ]
  [ "$output" = 'mgit sync: 3 repositories already in sync' ]
}

@test "sync warns about failed fetches and detached checkouts and leaves them untouched" {
  local seed="$BATS_TEST_TMPDIR/seed"
  local origin="$BATS_TEST_TMPDIR/origin.git"
  local before
  make_origin "$seed" "$origin" baseline
  git clone -q "$origin" "$TREE/detached"
  git clone -q "$origin" "$TREE/lost"
  git clone -q "$origin" "$TREE/working"
  git -C "$TREE/detached" checkout -q --detach
  git -C "$TREE/lost" remote set-url origin "$BATS_TEST_TMPDIR/missing.git"
  git -C "$seed" commit -q --allow-empty -m remote-update
  git -C "$seed" push -q
  before=$(git -C "$TREE/lost" rev-parse HEAD)

  cd "$TREE"
  run "$MGIT" -j 2 sync
  [ "$status" -eq 1 ]
  [[ "$output" == *"mgit sync: detached: detached HEAD (skipped)"* ]] || false
  [[ "$output" == *"mgit sync: lost: fetch from origin failed (skipped)"* ]] || false
  [[ "$output" == *"missing.git"* ]] || false
  [[ "$output" == *"mgit sync: working: pulled 1 commit"* ]] || false
  [ "$(git -C "$TREE/lost" rev-parse HEAD)" = "$before" ]
  [ "$(git -C "$TREE/working" rev-parse HEAD)" = "$(git --git-dir="$origin" rev-parse HEAD)" ]
}

@test "sync fetches a repository once for all its tracked worktrees" {
  local seed="$BATS_TEST_TMPDIR/seed"
  local origin="$BATS_TEST_TMPDIR/origin.git"
  make_origin "$seed" "$origin" baseline
  git -C "$seed" push -q origin HEAD:topic
  git clone -q "$origin" "$TREE/repo"
  git -C "$TREE/repo" worktree add -q --track -b topic "$TREE/repo-topic" origin/topic
  git -C "$seed" commit -q --allow-empty -m main-update
  git -C "$seed" push -q origin HEAD HEAD:topic

  cd "$TREE"
  run "$MGIT" -W -j 4 sync
  [ "$status" -eq 0 ]
  [[ "$output" == *"mgit sync: repo: pulled 1 commit"* ]] || false
  [[ "$output" == *"mgit sync: repo [topic]: pulled 1 commit"* ]] || false
  [[ "$output" != *"failed"* ]] || false
  [ "$(git -C "$TREE/repo-topic" rev-parse HEAD)" = "$(git --git-dir="$origin" rev-parse topic)" ]
}

@test "captured command output has no color and sync uses checkout labels" {
  mkrepo "$TREE/standard"
  mkrepo "$TREE/nested"
  make_managed_worktree_repo "$TREE/nested"
  git -C "$TREE/standard" worktree add -q -b topic "$TREE/storage-topic"
  cd "$TREE"

  run "$MGIT" status --short
  [ "$status" -eq 0 ]
  [[ "$output" != *$'\033['* ]] || false

  run "$MGIT" --all-worktrees sync --verbose
  [ "$status" -eq 1 ]
  [[ "$output" == *"standard [topic]: checking"* ]] || false
  [[ "$output" == *"nested/main: checking"* ]] || false
  [[ "$output" != *"storage-topic"* ]] || false
  [[ "$output" != *$'\033['* ]] || false
}

@test "--territory selects only NUL-delimited roots from ki" {
  mkrepo "$TREE/first"
  mkrepo "$TREE/with space"
  make_fake_ki
  FAKE_KI_ROOTS="$TREE/first"$'\n'"$TREE/with space"

  cd "$TREE"
  run "$MGIT" --territory focus

  [ "$status" -eq 0 ]
  [ "$output" = $'first\nwith space' ]

  run "$MGIT" --territory focus --filter first
  [ "$status" -eq 0 ]
  [ "$output" = "first" ]
}

@test "--estate selects the registered estate" {
  mkrepo "$TREE/first"
  mkrepo "$TREE/with space"
  make_fake_ki
  FAKE_KI_TERRITORY=estate
  FAKE_KI_ROOTS="$TREE/first"$'\n'"$TREE/with space"

  cd "$TREE"
  run "$MGIT" --estate

  [ "$status" -eq 0 ]
  [ "$output" = $'first\nwith space' ]

}

@test "--principals selects the territory Capitals in the producer's order" {
  mkrepo "$TREE/ki-principal"
  mkrepo "$TREE/er-principal"
  mkrepo "$TREE/va-principal"
  make_fake_ki
  FAKE_KI_TERRITORY=principals
  FAKE_KI_ROOTS="$TREE/ki-principal"$'\n'"$TREE/er-principal"$'\n'"$TREE/va-principal"

  cd "$TREE"
  run "$MGIT" --principals

  [ "$status" -eq 0 ]
  [ "$output" = $'ki-principal\ner-principal\nva-principal' ]

  run "$MGIT" --principals --filter va --filter ki
  [ "$status" -eq 0 ]
  [ "$output" = $'ki-principal\nva-principal' ]

  run "$MGIT" --principals -R pwd
  [ "$status" -eq 0 ]
  [[ "$output" == *"$TREE/ki-principal"* ]] || false
  [[ "$output" == *"$TREE/va-principal"* ]] || false
}

@test "--principals composes with sync and all-worktrees like --estate" {
  mkrepo "$TREE/ki-principal"
  make_fake_ki
  FAKE_KI_TERRITORY=principals
  FAKE_KI_ROOTS="$TREE/ki-principal"

  cd "$TREE"
  run "$MGIT" --principals -W
  [ "$status" -eq 0 ]
  [ "$output" = "ki-principal" ]

  run "$MGIT" --principals sync
  [[ "$output" != *"cannot be used"* ]] || false
}

@test "--principals stops before a command when ki cannot resolve roots" {
  mkrepo "$TREE/ki-principal"
  make_fake_ki
  FAKE_KI_TERRITORY=principals
  FAKE_KI_ROOTS="$TREE/ki-principal"
  FAKE_KI_FAIL=true

  cd "$TREE"
  run "$MGIT" --principals status

  [ "$status" -eq 1 ]
  [[ "$output" == *"fake territory resolution failed"* ]] || false
  [[ "$output" != *"git status"* ]] || false
}

@test "--territory preserves its exact roots instead of following symlink metadata" {
  mkrepo "$TREE/selected"
  mkrepo "$TREE/linked"
  mkdir "$TREE/linked/shared"
  ln -s ../linked/shared "$TREE/selected/link"
  printf '%s\n' '[symlinks]' '"link" = "../linked/shared"' > "$TREE/selected/.mgit.toml"
  make_fake_ki
  FAKE_KI_ROOTS="$TREE/selected"

  cd "$TREE"
  run "$MGIT" --territory focus

  [ "$status" -eq 0 ]
  [ "$output" = "selected" ]
}

@test "--territory stops before a command when ki cannot resolve roots" {
  mkrepo "$TREE/selected"
  make_fake_ki
  FAKE_KI_ROOTS="$TREE/selected"
  FAKE_KI_FAIL=true

  cd "$TREE"
  run "$MGIT" --territory focus status

  [ "$status" -eq 1 ]
  [[ "$output" == *"fake territory resolution failed"* ]] || false
  [[ "$output" != *"git status"* ]] || false
}

@test "--territory reports a missing ki command" {
  PATH=/usr/bin:/bin

  run "$MGIT" --territory focus

  [ "$status" -eq 1 ]
  [[ "$output" == *"--territory requires ki on PATH"* ]] || false

  run "$MGIT" --estate

  [ "$status" -eq 1 ]
  [[ "$output" == *"--estate requires ki on PATH"* ]] || false

  run "$MGIT" --principals

  [ "$status" -eq 1 ]
  [[ "$output" == *"--principals requires ki on PATH"* ]] || false
}

@test "--territory rejects incompatible selectors and management commands" {
  assert_usage_error --territory focus --group dev status
  assert_usage_error --territory focus --ignore status
  assert_usage_error --territory focus --follow-symlinks status
  assert_usage_error --territory focus structure standard
  assert_usage_error --estate --territory focus status
  assert_usage_error --territory focus --estate status
  assert_usage_error --estate --estate status
  assert_usage_error --estate --group dev status
  assert_usage_error --estate --ignore status
  assert_usage_error --estate --follow-symlinks status
  assert_usage_error --estate register
  assert_usage_error --estate structure standard
  assert_usage_error --principals --estate status
  assert_usage_error --estate --principals status
  assert_usage_error --principals --territory focus status
  assert_usage_error --territory focus --principals status
  assert_usage_error --principals --principals status
  assert_usage_error --principals --ignore status
  assert_usage_error --principals --follow-symlinks status
  assert_usage_error --principals --physical status
  assert_usage_error --principals --repo . status
  assert_usage_error --principals register
  assert_usage_error --principals register add --repo .
  assert_usage_error --principals structure standard
  assert_usage_error --principals worktree list
}

@test "register binds territory locations alongside local repositories and refreshes them" {
  mkrepo "$TREE/local"
  mkrepo "$BATS_TEST_TMPDIR/external"
  mkrepo "$BATS_TEST_TMPDIR/replacement"
  make_fake_ki
  FAKE_KI_ROOTS="$TREE/local"$'\n'"$BATS_TEST_TMPDIR/external"

  cd "$TREE"
  run "$MGIT" register add --territory focus
  [ "$status" -eq 0 ]
  grep -Fx 'locations = ["local", "territory:focus"]' "$TREE/.mgit.toml"
  grep -A2 -Fx '[members."../external"]' "$TREE/.mgit.toml" | grep -Fx 'type = "standard"'
  [ "$(grep -Fxc '[members."local"]' "$TREE/.mgit.toml")" -eq 1 ]
  ! grep -Fq '[registered.members.' "$TREE/.mgit.toml" || false

  FAKE_KI_FAIL=true
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = $'local\n../external' ]
  grep -Fx 'locations = ["local", "territory:focus"]' "$TREE/.mgit.toml"
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

@test "register can create a workspace containing only territory members" {
  mkrepo "$BATS_TEST_TMPDIR/external"
  make_fake_ki
  FAKE_KI_ROOTS="$BATS_TEST_TMPDIR/external"

  cd "$TREE"
  run "$MGIT" register --territory focus
  [ "$status" -eq 0 ]
  grep -Fx 'locations = ["local", "territory:focus"]' "$TREE/.mgit.toml"
  grep -Fx '[members."../external"]' "$TREE/.mgit.toml"
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
  run "$MGIT" register add --territory focus --repo ../one --territory second --repo ../two
  [ "$status" -eq 0 ]
  grep -Fx 'locations = ["local", "territory:focus", "repo:../one", "territory:second", "repo:../two"]' "$TREE/.mgit.toml"
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = $'local\n../first\n../one\n../second\n../two' ]

  mv "$BATS_TEST_TMPDIR/two" "$BATS_TEST_TMPDIR/moved"
  run "$MGIT" register rm --territory focus --repo ../one --territory second --repo ../two
  [ "$status" -eq 0 ]
  grep -Fx 'locations = ["local"]' "$TREE/.mgit.toml"
  ! grep -Fq '[registered.members.' "$TREE/.mgit.toml" || false
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = 'local' ]
}

@test "register can bind an external repository without a territory" {
  mkrepo "$BATS_TEST_TMPDIR/external space"
  cd "$TREE"
  run "$MGIT" register add --repo "$BATS_TEST_TMPDIR/external space"
  [ "$status" -eq 0 ]
  grep -Fx 'locations = ["local", "repo:../external space"]' "$TREE/.mgit.toml"
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = '../external space' ]
}

# A home-shaped fixture: ~/workspaces/{personal,knowledge-islands} and a
# dotfiles checkout outside the workspace tree at ~/.local/share/chezmoi.
make_external_estate() {
  ESTATE="$BATS_TEST_TMPDIR/home"
  DOTFILES="$ESTATE/.local/share/chezmoi"
  mkdir -p "$ESTATE/workspaces/personal" "$ESTATE/workspaces/knowledge-islands"
  make_origin "$DOTFILES" "$BATS_TEST_TMPDIR/dotfiles.git" dotfiles
  mkrepo "$ESTATE/workspaces/personal/acquire"
  mkrepo "$ESTATE/workspaces/knowledge-islands/tools-mgit"
}

@test "register records an external repository as an ordinary typed member" {
  make_external_estate
  cd "$ESTATE/workspaces/personal"
  run "$MGIT" register add --repo ../../.local/share/chezmoi
  [ "$status" -eq 0 ]
  [[ "$output" == *"recorded 1 local and 1 external member(s)"* ]] || false
  grep -Fx 'locations = ["local", "repo:../../.local/share/chezmoi"]' .mgit.toml
  grep -A3 -Fx '[members."../../.local/share/chezmoi"]' .mgit.toml > "$BATS_TEST_TMPDIR/entry"
  grep -Fx 'kind = "repository"' "$BATS_TEST_TMPDIR/entry"
  grep -Fx 'type = "standard"' "$BATS_TEST_TMPDIR/entry"
  grep -Fx "source = \"$BATS_TEST_TMPDIR/dotfiles.git\"" "$BATS_TEST_TMPDIR/entry"
  ! grep -Fq 'registered' .mgit.toml || false
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = $'acquire\n../../.local/share/chezmoi' ]
}

@test "external members dispatch exactly once with or without a navigation symlink" {
  make_external_estate
  cd "$ESTATE/workspaces/personal"
  "$MGIT" register add --repo ../../.local/share/chezmoi >/dev/null
  # The knowledge-islands workspace binds the same checkout through a second location.
  cd "$ESTATE/workspaces/knowledge-islands"
  "$MGIT" register add --repo "$DOTFILES" >/dev/null
  cd "$ESTATE/workspaces"
  "$MGIT" register >/dev/null
  grep -Fx 'locations = ["local", "repo:../../.local/share/chezmoi"]' personal/.mgit.toml

  for link in absent present; do
    if [ "$link" = present ]; then
      ln -s ../../.local/share/chezmoi "$ESTATE/workspaces/personal/dotfiles"
      cd "$ESTATE/workspaces"
      "$MGIT" register >/dev/null
      ! grep -Fq '[members."dotfiles"]' personal/.mgit.toml || false
    fi
    cd "$ESTATE/workspaces/personal"
    run "$MGIT" -R pwd -P
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | grep -Fxc "$(cd "$DOTFILES" && pwd -P)")" -eq 1 ]
    run "$MGIT"
    [ "$output" = $'acquire\n../../.local/share/chezmoi' ]

    cd "$ESTATE/workspaces"
    run "$MGIT" -R pwd -P
    [ "$status" -eq 0 ]
    [ "$(printf '%s\n' "$output" | grep -Fxc "$(cd "$DOTFILES" && pwd -P)")" -eq 1 ]
    run "$MGIT"
    [ "$output" = $'knowledge-islands/tools-mgit\n../.local/share/chezmoi\npersonal/acquire' ]
  done

  # Discovery that follows the navigation symlink still yields one repository.
  cd "$ESTATE/workspaces/personal"
  run "$MGIT" --ignore --follow-symlinks -R pwd -P
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | grep -Fxc "$(cd "$DOTFILES" && pwd -P)")" -eq 1 ]

  # A location root that local discovery already records is not written twice.
  cd "$ESTATE/workspaces"
  "$MGIT" register add --repo knowledge-islands/tools-mgit >/dev/null
  ! grep -Fq '[members."knowledge-islands/tools-mgit"]' .mgit.toml || false
  run "$MGIT"
  [ "$output" = $'knowledge-islands/tools-mgit\n../.local/share/chezmoi\npersonal/acquire' ]
}

@test "external member paths must climb out and then name a safe repository path" {
  mkrepo "$BATS_TEST_TMPDIR/ext"
  cd "$TREE"
  for path in '../ext/../ext' '../..' '..' '..//ext' '../ext/' '../ext/.' '.../ext'; do
    printf '%s\n' 'kind = "workspace"' "[members.\"$path\"]" 'kind = "repository"' \
      'type = "standard"' > .mgit.toml
    run "$MGIT"
    [ "$status" -eq 1 ]
    [[ "$output" == *"unsafe workspace member path"* || "$output" == *"missing repository path"* ]] || false
  done
  printf '%s\n' 'kind = "workspace"' '[members."../ext"]' 'kind = "workspace"' > .mgit.toml
  run "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unsafe workspace member path: ../ext"* ]] || false
  printf '%s\n' 'kind = "workspace"' '[members."../ext"]' 'kind = "repository"' > .mgit.toml
  run "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"requires type"* ]] || false
  printf '%s\n' 'kind = "workspace"' '[members."../missing"]' 'kind = "repository"' \
    'type = "standard"' > .mgit.toml
  run "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unsafe or missing external repository path"* ]] || false
  printf '%s\n' 'kind = "workspace"' '[members."../ext"]' 'kind = "repository"' \
    'type = "standard"' '[members."../ext"]' 'kind = "repository"' 'type = "standard"' > .mgit.toml
  run "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"duplicate member path"* ]] || false
  printf '%s\n' 'kind = "workspace"' '[members."../ext"]' 'kind = "repository"' \
    'type = "standard"' > .mgit.toml
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = '../ext' ]
}

@test "repair validates external members but never clones a missing one" {
  make_origin "$BATS_TEST_TMPDIR/src" "$BATS_TEST_TMPDIR/origin.git" payload
  mkdir "$TREE/workspace"
  printf '%s\n' 'kind = "workspace"' \
    '[members."local"]' 'kind = "repository"' 'type = "standard"' \
    "source = \"$BATS_TEST_TMPDIR/origin.git\"" \
    '[members."../external"]' 'kind = "repository"' 'type = "standard"' \
    "source = \"$BATS_TEST_TMPDIR/origin.git\"" > "$TREE/workspace/.mgit.toml"
  cd "$TREE/workspace"
  run "$MGIT" repair
  [ "$status" -eq 0 ]
  [[ "$output" == *"would clone standard repository"*"/workspace/local"* ]] || false
  [[ "$output" == *"not cloning missing external member: "*"/external"* ]] || false
  run "$MGIT" repair --apply
  [ "$status" -eq 0 ]
  [ -f "$TREE/workspace/local/payload" ]
  [ ! -e "$TREE/external" ]
  [[ "$output" == *"not cloning missing external member"* ]] || false

  mkbare "$TREE/external"
  run "$MGIT" repair
  [ "$status" -eq 1 ]
  [[ "$output" == *"structure mismatch at "*"/external"* ]] || false
  rm -rf "$TREE/external"
  mkrepo "$TREE/external"
  run "$MGIT" repair
  [ "$status" -eq 0 ]
  [[ "$output" == *"present "*"/external"* ]] || false
}

@test "an external member that resolves back inside its workspace is rejected" {
  mkdir "$TREE/workspace"
  mkrepo "$TREE/workspace/acquire"
  ln -s workspace "$TREE/link"
  cd "$TREE/workspace"
  for path in '../workspace/acquire' '../link/acquire'; do
    printf '%s\n' 'kind = "workspace"' "[members.\"$path\"]" 'kind = "repository"' \
      'type = "standard"' > .mgit.toml
    run "$MGIT"
    [ "$status" -eq 1 ]
    [[ "$output" == *'mgit: external repository path resolves inside the workspace; declare it as the local member "acquire": '*'/workspace/acquire'* ]] || false
    run "$MGIT" -R pwd
    [ "$status" -eq 1 ]
    [[ "$output" != *"/workspace/acquire"$'\n'* ]] || false
    run "$MGIT" repair
    [ "$status" -eq 1 ]
    [[ "$output" == *'mgit repair: external repository path resolves inside the workspace; declare it as the local member "acquire"'* ]] || false
  done
}

@test "register names each hand-written external member it drops" {
  mkrepo "$TREE/local"
  mkrepo "$BATS_TEST_TMPDIR/ext"
  printf '%s\n' 'kind = "workspace"' \
    '[members."local"]' 'kind = "repository"' 'type = "standard"' \
    '[members."../ext"]' 'kind = "repository"' 'type = "standard"' > "$TREE/.mgit.toml"
  cp "$TREE/.mgit.toml" "$BATS_TEST_TMPDIR/before"
  cd "$TREE"
  run "$MGIT" register --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *'mgit register: ./.mgit.toml: would drop external member without a saved location: ../ext (keep it with mgit register add --repo ../ext)'* ]] || false
  [[ "$output" == *"would write ./.mgit.toml (1 local and 0 external member(s))"* ]] || false
  cmp "$TREE/.mgit.toml" "$BATS_TEST_TMPDIR/before"

  "$MGIT" register > "$BATS_TEST_TMPDIR/out" 2> "$BATS_TEST_TMPDIR/err"
  grep -Fx 'mgit register: ./.mgit.toml: dropped external member without a saved location: ../ext (restore it with mgit register add --repo ../ext)' \
    "$BATS_TEST_TMPDIR/err"
  ! grep -Fq '../ext' "$TREE/.mgit.toml" || false

  # A member that a saved location produces is kept without a word.
  run "$MGIT" register add --repo ../ext
  [ "$status" -eq 0 ]
  grep -Fx '[members."../ext"]' "$TREE/.mgit.toml"
  run "$MGIT" register --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" != *"drop"* ]] || false
}

@test "repair warns once about a legacy manifest whichever spelling reached it" {
  mkrepo "$TREE/local"
  mkrepo "$BATS_TEST_TMPDIR/external"
  printf '%s\n' 'kind = "workspace"' 'locations = ["local", "repo:../external"]' \
    '[registered.members."../external"]' '[registered.members."local"]' \
    '[members."local"]' 'kind = "repository"' 'type = "standard"' > "$TREE/.mgit.toml"
  cd "$TREE"
  "$MGIT" repair > "$BATS_TEST_TMPDIR/out" 2> "$BATS_TEST_TMPDIR/err"
  [ "$(grep -c 'deprecated' "$BATS_TEST_TMPDIR/err")" -eq 1 ]
}

@test "legacy registered members stay readable with a warning until register rewrites them" {
  mkrepo "$TREE/local"
  mkrepo "$BATS_TEST_TMPDIR/external"
  printf '%s\n' 'kind = "workspace"' 'locations = ["local", "repo:../external"]' \
    '[registered.members."../external"]' '[registered.members."local"]' \
    '[members."local"]' 'kind = "repository"' 'type = "standard"' > "$TREE/.mgit.toml"
  cp "$TREE/.mgit.toml" "$BATS_TEST_TMPDIR/before"
  cd "$TREE"
  "$MGIT" > "$BATS_TEST_TMPDIR/out" 2> "$BATS_TEST_TMPDIR/err"
  [ "$(cat "$BATS_TEST_TMPDIR/out")" = $'local\n../external' ]
  [ "$(grep -c 'deprecated' "$BATS_TEST_TMPDIR/err")" -eq 1 ]
  run "$MGIT" doctor
  [ "$status" -eq 0 ]
  [[ "$output" == *'warn configuration: workspace manifest uses deprecated [registered.members]'* ]] || false
  [[ "$output" == *'Checks: pass=1 warn=1 fail=0'* ]] || false
  run "$MGIT" repair
  [ "$status" -eq 0 ]
  [[ "$output" != *"would clone"* ]] || false
  [[ "$output" != *"not cloning"* ]] || false

  run "$MGIT" register --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would write ./.mgit.toml (1 local and 1 external member(s))"* ]] || false
  cmp "$TREE/.mgit.toml" "$BATS_TEST_TMPDIR/before"

  "$MGIT" register >/dev/null
  ! grep -Fq 'registered' "$TREE/.mgit.toml" || false
  grep -A1 -Fx '[members."../external"]' "$TREE/.mgit.toml" | grep -Fx 'kind = "repository"'
  "$MGIT" > "$BATS_TEST_TMPDIR/out" 2> "$BATS_TEST_TMPDIR/err"
  [ "$(cat "$BATS_TEST_TMPDIR/out")" = $'local\n../external' ]
  [ ! -s "$BATS_TEST_TMPDIR/err" ]
}

@test "legacy Agora snapshots are rejected without state changes" {
  mkrepo "$TREE/local"
  printf '%s\n' 'schema = 1' 'kind = "workspace"' 'default = "default"' \
    'agora = "focus"' '[agora.members."../external"]' \
    '[groups.default.members."local"]' 'kind = "repository"' 'type = "standard"' > "$TREE/.mgit.toml"
  cp "$TREE/.mgit.toml" "$BATS_TEST_TMPDIR/before"
  cd "$TREE"
  run "$MGIT"
  [ "$status" -ne 0 ]
  [[ "$output" == *'Agora syntax is retired'* ]] || false
  run "$MGIT" register --dry-run
  [ "$status" -ne 0 ]
  cmp "$TREE/.mgit.toml" "$BATS_TEST_TMPDIR/before"
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
  assert_usage_error register --territory ''
}

@test "register writes unversioned group-free workspaces in physical postorder" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  mkrepo "$TREE/sub/c"
  ( cd "$TREE" && run_ok "$MGIT" register )

  [ -f "$TREE/.mgit.toml" ]
  [ -f "$TREE/sub/.mgit.toml" ]
  ! grep -Fq 'schema =' "$TREE/.mgit.toml" || false
  ! grep -Fq 'default =' "$TREE/.mgit.toml" || false
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
  [[ "$output" == *"warning: manifest remains local; chezmoi could not add it"* ]] || false
  [[ "$output" != *"no git repos found"* ]] || false
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
  [[ "$output" == *"warning: manifest removal remains local; chezmoi could not forget it"* ]] || false
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
  [[ "$output" == *"present "*"standard-repo"* ]] || false
}

@test "register dry-run previews add and rm without changing manifests or Chezmoi" {
  make_fake_chezmoi
  mkrepo "$TREE/repo"
  mkrepo "$BATS_TEST_TMPDIR/external"
  cd "$TREE"
  run "$MGIT" register add --repo "$BATS_TEST_TMPDIR/external" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would write ./.mgit.toml"* ]] || false
  [ ! -e "$TREE/.mgit.toml" ]
  [ ! -e "$CHEZMOI_LOG" ]
  "$MGIT" register add --repo "$BATS_TEST_TMPDIR/external" >/dev/null
  cp "$TREE/.mgit.toml" "$TREE/saved.toml"
  : > "$CHEZMOI_LOG"
  run "$MGIT" register rm --repo "$BATS_TEST_TMPDIR/external" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would write ./.mgit.toml"* ]] || false
  cmp "$TREE/saved.toml" "$TREE/.mgit.toml"
  [ ! -s "$CHEZMOI_LOG" ]
}

@test "register dry-run previews repository manifest removal without deleting it" {
  mkrepo "$TREE/repo"
  printf 'kind = "repository"\n' > "$TREE/repo/.mgit.toml"
  cd "$TREE"
  run "$MGIT" register --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would remove ./repo/.mgit.toml"* ]] || false
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
  [[ "$output" == *"would clone standard repository"* ]] || false
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
  [[ "$output" == *"no clone URL"* ]] || false

  run "$MGIT" repair --apply
  [ "$status" -eq 1 ]
  grep -Fx 'schema = 1' .mgit.toml
  [ ! -e "$TREE/missing-repo" ]

  touch "$TREE/missing-repo"
  run "$MGIT" repair
  [ "$status" -eq 1 ]
  [ -f "$TREE/missing-repo" ]
  [[ "$output" == *"refusing to replace non-repository path"* ]] || false
}

@test "bare mgit lists the discovered repos" {
  mkrepo "$TREE/a"
  mkrepo "$TREE/b"
  cd "$TREE"
  "$MGIT" register >/dev/null
  ! grep -q "repoB-branch-c" "$TREE/.mgit.toml" || false
  run "$MGIT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"a"* ]] || false
  [[ "$output" == *"b"* ]] || false
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
  [[ "$output" == *"unsupported TOML table: [symlinks]"* ]] || false

  mv "$TREE/.mgit.toml" "$TREE/mixed-workspace.toml"
  printf '%s\n' \
    'schema = 1' \
    'kind = "repository"' \
    '' \
    '[groups.default]' > "$TREE/a/.mgit.toml"

  cd "$TREE/a"
  run "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"repository manifest contains unsupported table: [groups.default]"* ]] || false
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
  ! grep -Fq 'schema =' "$TREE/.mgit.toml" || false
  ! grep -Fq '[groups.' "$TREE/.mgit.toml" || false

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
  [[ "$output" == *'-schema = 1'* ]] || false
  [[ "$output" == *'+[members."a"]'* ]] || false
  [[ "$output" == *'preview only'* ]] || false
  [ "$(cat .mgit.toml)" = "$before" ]
  run "$MGIT"
  [ "$status" -eq 0 ]
  [ "$output" = a ]
  run "$MGIT" repair --apply
  [ "$status" -eq 0 ]
  grep -Fx '# Preserve this note' .mgit.toml
  grep -Fx '[members."a"]' .mgit.toml
  ! grep -Fq 'schema =' .mgit.toml || false
  ! grep -Fq '[groups.' .mgit.toml || false
  run "$MGIT" repair
  [ "$status" -eq 0 ]
  [[ "$output" == *'already unversioned'* ]] || false
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
  ! grep -Fq 'schema =' .mgit.toml || false
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
  [[ "$output" == *'alternative groups need a deliberate manual decision'* ]] || false
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
  [[ "$output" == *"remove alternative groups before migrating"* ]] || false
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
  [[ "$output" == *"unsafe workspace member path"* ]] || false

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
  [[ "$output" == *"duplicate member path"* ]] || false
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
  [[ "$output" == *"unversioned workspace requires direct members and no groups"* ]] || false

  printf '%s\n' \
    'kind = "workspace"' \
    '[members."child"]' \
    'kind = "workspace"' > "$TREE/.mgit.toml"

  run "$MGIT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unsafe or missing workspace path"* ]] || false
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
  [[ "$output" == *"../b"* ]] || false
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
  ! grep -Fx '[members."main"]' "$TREE/.mgit.toml" || false
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
  [[ "$output" == *"repoA"* ]] || false
}

@test "normal commands use primary checkouts unless all worktrees are requested" {
  mkrepo "$TREE/repoA"
  make_managed_worktree_repo "$TREE/repoA"
  git -C "$TREE/repoA" worktree add -q -b branch-b "$TREE/repoA/branch-b"
  mkrepo "$TREE/repoB"
  git -C "$TREE/repoB" worktree add -q -b branch-c "$TREE/repoB-branch-c"

  cd "$TREE"
  "$MGIT" register >/dev/null
  ! grep -F '[members."repoB-branch-c"]' "$TREE/.mgit.toml" || false
  run "$MGIT"

  [ "$status" -eq 0 ]
  [[ "$output" == *"repoA/main"* ]] || false
  [[ "$output" != *"repoA/branch-b"* ]] || false
  [[ "$output" == *"repoB"* ]] || false
  [[ "$output" != *"repoB-branch-c"* ]] || false
  [[ "$output" != *"repoA/.bare"* ]] || false

  run "$MGIT" --all-worktrees
  [ "$status" -eq 0 ]
  [[ "$output" == *"repoA/main"* ]] || false
  [[ "$output" == *"repoA/branch-b"* ]] || false
  [[ "$output" == *"repoB"* ]] || false
  [[ "$output" == *"repoB [branch-c]"* ]] || false
  [[ "$output" != *"repoA/.bare"* ]] || false

  run "$MGIT" -W
  [ "$status" -eq 0 ]
  [[ "$output" == *"repoA/branch-b"* ]] || false
  [[ "$output" == *"repoB [branch-c]"* ]] || false

  run "$MGIT" worktree list
  [ "$status" -eq 0 ]
  [[ "$output" == *"repoA/main"* ]] || false
  [[ "$output" == *"repoA/branch-b"* ]] || false
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
  [[ "$output" == *"repo A [GOV-104]"* ]] || false
  [[ "$output" == *"repoB [GOV-104]"* ]] || false
  [[ "$output" == *"repo A [detached:held work@"* ]] || false
  [[ "$output" == *"repoB [hidden]"* ]] || false
  [[ "$output" != *"company-uuid"* ]] || false
  [[ "$output" != *".git/mgit-worktrees"* ]] || false

  run "$MGIT" -W --filter 'repo A' rev-parse --show-toplevel
  [ "$status" -eq 0 ]
  [[ "$output" == *"repo A [GOV-104]: git rev-parse --show-toplevel"* ]] || false
  [[ "$output" == *"$storage/one"* ]] || false
  [[ "$output" != *"$storage/two"* ]] || false

  run "$MGIT" -W --raw pwd -P
  [ "$status" -eq 0 ]
  [[ "$output" == *"repoB [GOV-104]: pwd -P"* ]] || false
  [[ "$output" == *"$storage/two"* ]] || false

  run "$MGIT" worktree list
  [ "$status" -eq 0 ]
  [[ "$output" == *"runtime storage/company-uuid/one"* ]] || false
}

@test "structure nested previews then restructures every standard repo in the set" {
  mkrepo "$TREE/repo A"
  mkrepo "$TREE/repoB"

  cd "$TREE"
  "$MGIT" register >/dev/null
  run "$MGIT" structure nested --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would restructure "*"/tree/repo A ("* ]] || false
  [[ "$output" == *"would restructure "*"/tree/repoB ("* ]] || false

  run "$MGIT" structure nested
  [ "$status" -eq 0 ]
  [ -d "$TREE/repo A/.bare" ]
  [ -f "$TREE/repo A/.git" ]
  [ -f "$TREE/repo A/main/.git" ]
  [ -d "$TREE/repoB/.bare" ]
  [ -f "$TREE/repoB/main/.git" ]

  run "$MGIT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"repo A/main"* ]] || false
  [[ "$output" == *"repoB/main"* ]] || false
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
  [[ "$output" == *"primary working tree"* ]] || false
}

@test "structure standard restores a nested repository with only main" {
  mkrepo "$TREE/repoA"
  make_managed_worktree_repo "$TREE/repoA"

  cd "$TREE"
  "$MGIT" register >/dev/null
  run "$MGIT" structure standard --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"would restructure "*"/tree/repoA ("* ]] || false

  run "$MGIT" structure standard
  [ "$status" -eq 0 ]
  [ -d "$TREE/repoA/.git" ]
  [ ! -d "$TREE/repoA/.bare" ]
  [ "$(git -C "$TREE/repoA" status --porcelain)" = "" ]
}

@test "--filter limits the repo set by literal basename prefixes" {
  mkrepo "$TREE/mcp-a"
  mkrepo "$TREE/mcp-b"
  mkrepo "$TREE/sub/mcp-c"
  mkrepo "$TREE/tools-d"

  cd "$TREE"
  run "$MGIT" --filter 'mcp-'
  [ "$status" -eq 0 ]
  [[ "$output" == *"mcp-a"* ]] || false
  [[ "$output" == *"mcp-b"* ]] || false
  [[ "$output" == *"sub/mcp-c"* ]] || false
  [[ "$output" != *"tools-d"* ]] || false

  run "$MGIT" --filter 'mcp-a' --filter 'tools-'
  [ "$status" -eq 0 ]
  [[ "$output" == *"mcp-a"* ]] || false
  [[ "$output" != *"mcp-b"* ]] || false
  [[ "$output" == *"tools-d"* ]] || false
}

@test "--filter applies to bare commands and requires a pattern" {
  mkrepo "$TREE/mcp-a"
  mkrepo "$TREE/tools-b"

  cd "$TREE"
  run "$MGIT" --filter 'mcp-' -R pwd
  [ "$status" -eq 0 ]
  [[ "$output" == *"$TREE/mcp-a"* ]] || false
  [[ "$output" != *"$TREE/tools-b"* ]] || false

  run "$MGIT" --filter
  [ "$status" -eq 2 ]
}

@test "-f is not a short filter and runs nothing" {
  mkrepo "$TREE/mcp-a"
  cd "$TREE"
  assert_usage_error -f 'mcp-' -R touch marker
  [[ "$output" == *"mgit: error: -f has been removed; use --filter to select repositories"* ]] || false
  assert_usage_error -f 'mcp-' status
  assert_usage_error -f
  [ ! -e "$TREE/mcp-a/marker" ]

  run "$MGIT" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *'      --filter <prefix>'* ]] || false
  [[ "$output" != *'-f, --filter'* ]] || false

  run "$MGIT" completion bash
  [[ "$output" != *' -f --filter '* ]] || false
  [[ "$output" != *'-f|--filter'* ]] || false
  run "$MGIT" completion zsh
  [[ "$output" == *"'--filter["* ]] || false
  [[ "$output" != *"'-f["* ]] || false
}

@test "--filter selects whole repos before optional worktree expansion" {
  mkrepo "$TREE/mcp-a"
  make_managed_worktree_repo "$TREE/mcp-a"
  git -C "$TREE/mcp-a" worktree add -q "$TREE/mcp-a/featureA" -b featureA
  mkrepo "$TREE/tools-b"

  cd "$TREE"
  run "$MGIT" --filter 'mcp-'
  [ "$status" -eq 0 ]
  [[ "$output" == *"mcp-a/main"* ]] || false
  [[ "$output" != *"mcp-a/featureA"* ]] || false
  [[ "$output" != *"tools-b"* ]] || false

  run "$MGIT" --filter 'mcp-' --all-worktrees
  [ "$status" -eq 0 ]
  [[ "$output" == *"mcp-a/main"* ]] || false
  [[ "$output" == *"mcp-a/featureA"* ]] || false
  [[ "$output" != *"tools-b"* ]] || false
}

# Helper: run a command, failing the test if it errors (for use inside subshells
# where bats' own `run` isn't available).
run_ok() { "$@"; }

# Overview fixtures keep their origins outside $TREE so discovery never lists
# them as bare repositories.
make_overview_estate() {
  local origins="$BATS_TEST_TMPDIR/origins"
  mkdir -p "$origins"
  make_origin "$TREE/clean" "$origins/clean.git" clean
  make_origin "$TREE/dirty" "$origins/dirty.git" dirty
  printf 'staged\n' > "$TREE/dirty/staged"
  git -C "$TREE/dirty" add staged
  printf 'changed\n' >> "$TREE/dirty/payload"
  printf 'new\n' > "$TREE/dirty/untracked"
  make_origin "$TREE/ahead" "$origins/ahead.git" ahead
  git -C "$TREE/ahead" commit -q --allow-empty -m ahead
  make_origin "$TREE/behind" "$origins/behind.git" behind
  git -C "$TREE/behind" commit -q --allow-empty -m behind
  git -C "$TREE/behind" push -q
  git -C "$TREE/behind" reset -q --hard HEAD~1
  mkrepo "$TREE/local"
}

# A clone with origin/HEAD and one branch of each obsolete kind, plus branches
# that must not be reported: a recent unmerged one and one checked out in a
# linked worktree.
make_overview_hygiene() {
  local origins="$BATS_TEST_TMPDIR/origins" repo="$TREE/hygiene" base
  mkdir -p "$origins"
  make_origin "$BATS_TEST_TMPDIR/seed" "$origins/hygiene.git" seed
  git clone -q "$origins/hygiene.git" "$repo"
  base=$(git -C "$repo" branch --show-current)
  git -C "$repo" branch merged
  git -C "$repo" checkout -q -b equivalent
  printf 'equivalent\n' > "$repo/equivalent"
  git -C "$repo" add equivalent
  GIT_COMMITTER_DATE='2026-01-01T00:00:00Z' git -C "$repo" commit -q -m equivalent
  git -C "$repo" checkout -q "$base"
  git -C "$repo" cherry-pick equivalent >/dev/null
  git -C "$repo" push -q origin "$base"
  git -C "$repo" checkout -q -b stale "$base~1"
  GIT_COMMITTER_DATE='2020-01-01T00:00:00Z' git -C "$repo" commit -q --allow-empty -m stale
  git -C "$repo" push -q origin stale:refs/heads/automation/old
  git -C "$repo" checkout -q -b gone "$base"
  git -C "$repo" commit -q --allow-empty -m gone
  git -C "$repo" push -q -u origin gone
  git -C "$repo" push -q origin --delete gone
  git -C "$repo" push -q origin merged
  git -C "$repo" checkout -q -b fresh "$base"
  git -C "$repo" commit -q --allow-empty -m fresh
  git -C "$repo" checkout -q "$base"
  git -C "$repo" worktree add -q -b inuse "$BATS_TEST_TMPDIR/inuse" "$base"
}

@test "overview names only checkouts that need attention and counts the rest" {
  make_overview_estate
  mkbare "$TREE/store.git"
  cd "$TREE"
  run "$MGIT" overview
  [ "$status" -eq 0 ]
  [ "$output" = $'ahead: ahead 1\nbehind: behind 1\ndirty: 1 staged, 1 modified, 1 untracked\nlocal: no upstream\nmgit overview: 6 repositories: 2 clean, 4 need attention, 0 failed' ]
  run "$MGIT" overview --verbose
  [ "$status" -eq 0 ]
  [[ "$output" == *$'\nclean: clean\n'* ]] || false
  [[ "$output" == *$'\nstore.git: clean\n'* ]] || false
  run "$MGIT" --filter d overview
  [ "$status" -eq 0 ]
  [ "$output" = $'dirty: 1 staged, 1 modified, 1 untracked\nmgit overview: 1 repository: 0 clean, 1 need attention, 0 failed' ]
}

@test "overview reports obsolete branches by the clean-down criteria" {
  make_overview_hygiene
  cd "$TREE"
  run "$MGIT" overview
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'hygiene: 6 obsolete branches' ]
  [ "${lines[1]}" = '  equivalent (local): equivalent' ]
  [ "${lines[2]}" = '  gone (local): gone' ]
  [ "${lines[3]}" = '  merged (local): merged' ]
  [[ "${lines[4]}" == '  stale (local): stale, '*' days old' ]] || false
  [[ "${lines[5]}" == '  origin/automation/old (remote): stale, '*' days old, automation' ]] || false
  [ "${lines[6]}" = '  origin/merged (remote): merged' ]
  [ "${lines[7]}" = 'mgit overview: 1 repository: 0 clean, 1 need attention, 0 failed' ]
  [[ "$output" != *fresh* ]] || false
  [[ "$output" != *inuse* ]] || false

  run "$MGIT" overview --stale-days 100000
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'hygiene: 4 obsolete branches' ]
  [[ "$output" != *stale* ]] || false
}

@test "overview reports stashes, detached checkouts and worktrees once per repository" {
  mkrepo "$TREE/repo"
  printf 'stash\n' > "$TREE/repo/stashed"
  git -C "$TREE/repo" stash -q -u
  git -C "$TREE/repo" worktree add -q --detach "$BATS_TEST_TMPDIR/detached"
  git -C "$TREE/repo" worktree add -q "$BATS_TEST_TMPDIR/gone-wt"
  rm -rf "$BATS_TEST_TMPDIR/gone-wt"
  mkrepo "$TREE/loose"
  git -C "$TREE/loose" checkout -q --detach
  cd "$TREE"
  run "$MGIT" overview
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = 'loose: detached HEAD' ]
  [ "${lines[1]}" = 'repo: 1 prunable worktree, 1 detached worktree, no upstream, 1 stash' ]
  run "$MGIT" -W overview
  [ "$status" -eq 0 ]
  [[ "$output" == *$'\nrepo [detached:detached@'*$']: detached HEAD\n'* ]] || false
  [ "$(printf '%s\n' "$output" | grep -c 'stash')" -eq 1 ]
}

@test "overview prints one JSON document" {
  make_overview_estate
  make_overview_hygiene
  cd "$TREE"
  run "$MGIT" overview --json
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  [[ "$output" == '{"tool":"mgit","command":"overview","version":"'*'","stale_days":30,"repositories":[{"label":"ahead",'* ]] || false
  [[ "$output" == *'"upstream":{"state":"tracking","name":"origin/'*'","ahead":1,"behind":0}'* ]] || false
  [[ "$output" == *'"changes":{"staged":1,"modified":1,"untracked":1,"conflicted":0}'* ]] || false
  [[ "$output" == *'{"name":"origin/automation/old","scope":"remote","reasons":["stale"],"age_days":'*',"automation":true}'* ]] || false
  [[ "$output" == *'{"name":"gone","scope":"local","reasons":["gone"],"age_days":0,"automation":false}'* ]] || false
  [[ "$output" == *'"summary":{"repositories":6,"clean":1,"attention":5,"failed":0}}' ]] || false
  if command -v python3 >/dev/null 2>&1; then
    printf '%s\n' "$output" | python3 -m json.tool >/dev/null
  fi
}

@test "overview reads Git state without changing it" {
  make_overview_estate
  make_overview_hygiene
  cd "$TREE"
  snapshot() {
    local repo
    for repo in "$TREE"/*/; do
      (
        cd "$repo"
        git for-each-ref --format='%(refname) %(objectname)'
        git stash list
        if [ -e "$(git rev-parse --git-path index)" ]; then
          cksum < "$(git rev-parse --git-path index)"
        else
          printf 'no index\n'
        fi
        [ ! -e "$(git rev-parse --git-path FETCH_HEAD)" ] || printf 'FETCH_HEAD\n'
      )
    done
  }
  # A changed timestamp on an unchanged file makes plain git status refresh,
  # and so rewrite, the index.
  touch -t 202001010000 "$TREE/clean/payload"
  snapshot > "$BATS_TEST_TMPDIR/before"
  "$MGIT" overview >/dev/null
  "$MGIT" -W overview --json >/dev/null
  snapshot > "$BATS_TEST_TMPDIR/after"
  cmp "$BATS_TEST_TMPDIR/before" "$BATS_TEST_TMPDIR/after"
  ! grep -q FETCH_HEAD "$BATS_TEST_TMPDIR/after" || false
}

@test "overview fails only for unreadable checkouts and validates its options" {
  mkrepo "$TREE/good"
  mkrepo "$TREE/broken"
  printf 'garbage\n' > "$TREE/broken/.git/index"
  cd "$TREE"
  run "$MGIT" overview
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = 'broken: failed: cannot read status' ]
  [ "${lines[2]}" = 'mgit overview: 2 repositories: 0 clean, 1 need attention, 1 failed' ]
  run "$MGIT" overview --json
  [ "$status" -eq 1 ]
  [[ "$output" == *'{"label":"broken","path":"'*'","state":"failed","error":"cannot read status"}'* ]] || false

  for value in 0 -1 abc 007 ''; do
    run "$MGIT" overview --stale-days "$value"
    [ "$status" -eq 2 ]
    [[ "$output" == *"--stale-days requires a positive whole number of days"* ]] || false
  done
  run "$MGIT" overview --stale-days
  [ "$status" -eq 2 ]
  run "$MGIT" overview --fetch
  [ "$status" -eq 2 ]
  [[ "$output" == *"overview: unexpected argument: --fetch"* ]] || false
  run "$MGIT" -R overview
  [ "$status" -eq 2 ]
  [[ "$output" == *"--raw cannot be used with overview"* ]] || false
  run "$MGIT" help overview
  [ "$status" -eq 0 ]
  [[ "$output" == 'Usage: mgit overview [--json] [-v|--verbose] [--stale-days <days>]'* ]] || false
}
