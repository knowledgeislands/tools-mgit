#!/usr/bin/env bats
# A hostile/failed producer stream must never reach command dispatch.
setup() {
  MGIT="$BATS_TEST_DIRNAME/../bin/mgit"
  ROOT="$BATS_TEST_TMPDIR/protocol"
  mkdir -p "$ROOT/bin" "$ROOT/workspace"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
  git init -q "$ROOT/selected"
  git -C "$ROOT/selected" commit -qm init --allow-empty
  ROOT=$(cd "$ROOT" && pwd -P)
  export KI_OUTPUT="$ROOT/roots.nul" KI_EXIT=0
  cat > "$ROOT/bin/ki" <<'KI'
#!/usr/bin/env bash
[ "$1" = territory ] && [ "$2" = roots ] && [ "$3" = --null ] && [ "$4" = --territory ] && [ "$5" = short ] && [ "$#" = 5 ] || exit 64
cat "$KI_OUTPUT"
exit "$KI_EXIT"
KI
  chmod +x "$ROOT/bin/ki"
  export PATH="$ROOT/bin:$PATH"
  cd "$ROOT/workspace"
}
assert_atomic() {
  run "$MGIT" -t short -B git config pilot.dispatched yes
  [ "$status" -ne 0 ]
  ! git -C "$ROOT/selected" config --get pilot.dispatched
}
@test "producer error partial unterminated duplicate empty and invalid roots never dispatch" {
  printf '%s\0' "$ROOT/selected" > "$KI_OUTPUT"
  KI_EXIT=73
  assert_atomic
  KI_EXIT=0
  printf '%s\0%s' "$ROOT/selected" "$ROOT/partial" > "$KI_OUTPUT"
  assert_atomic
  printf '%s\0%s\0' "$ROOT/selected" "$ROOT/selected" > "$KI_OUTPUT"
  assert_atomic
  printf '%s\0\0' "$ROOT/selected" > "$KI_OUTPUT"
  assert_atomic
  printf '%s\0%s\0' "$ROOT/selected" relative > "$KI_OUTPUT"
  assert_atomic
  printf '%s\0%s\0' "$ROOT/selected" "$ROOT/missing" > "$KI_OUTPUT"
  assert_atomic
  printf '%s\0%s\0' "$ROOT/selected" "$ROOT/workspace" > "$KI_OUTPUT"
  assert_atomic
  : > "$KI_OUTPUT"
  assert_atomic
}
@test "local basename prefixes reject empty zero matches and treat glob characters literally" {
  git init -q "$ROOT/workspace/Tool [*] Space"
  git init -q "$ROOT/workspace/tool-lower"
  run "$MGIT" -f 'Tool [*]'
  [ "$status" -eq 0 ]
  [ "$output" = 'Tool [*] Space' ]
  run "$MGIT" -f Tool -f tool
  [ "$status" -eq 0 ]
  [[ "$output" == *'Tool [*] Space'* ]] && [[ "$output" == *tool-lower* ]]
  for prefix in '' '*' TOOL; do
    run "$MGIT" -f "$prefix" -B touch "$ROOT/dispatched"
    [ "$status" -ne 0 ]
    [ ! -e "$ROOT/dispatched" ]
  done
}
