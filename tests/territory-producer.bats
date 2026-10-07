#!/usr/bin/env bats
# Executable integration gate: MGIT_KI_PRODUCER names the committed KI binary.
# No registry, config, Git mutation or network outside this disposable sandbox.
setup() {
  [ -n "${MGIT_KI_PRODUCER:-}" ] || skip 'set MGIT_KI_PRODUCER to run the real producer proof'
  [ -x "$MGIT_KI_PRODUCER" ]
  MGIT="$BATS_TEST_DIRNAME/../bin/mgit"
  ROOT="$BATS_TEST_TMPDIR/proof"
  mkdir -p "$ROOT/bin" "$ROOT/home" "$ROOT/config" "$ROOT/state/ki" "$ROOT/data" "$ROOT/cache" "$ROOT/workspace"
  ROOT=$(cd "$ROOT" && pwd -P)
  export HOME="$ROOT/home" XDG_CONFIG_HOME="$ROOT/config" XDG_STATE_HOME="$ROOT/state" XDG_DATA_HOME="$ROOT/data" XDG_CACHE_HOME="$ROOT/cache"
  export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
  export GIT_AUTHOR_NAME=pilot GIT_AUTHOR_EMAIL=pilot@example.invalid GIT_COMMITTER_NAME=pilot GIT_COMMITTER_EMAIL=pilot@example.invalid
  ln -s "$MGIT_KI_PRODUCER" "$ROOT/bin/ki"
  export PATH="$ROOT/bin:$PATH"
  CAPITAL="$ROOT/Capital Space"
  MEMBER="$ROOT/nested/Tool [*] Space"
  MISSING="$ROOT/Unavailable Tool"
  init_repo "$CAPITAL"
  init_repo "$MEMBER"
  write_declaration "$MEMBER" member
  write_capital
  write_registry
  cd "$ROOT/workspace"
}

init_repo() {
  git init -q "$1"
  git -C "$1" commit -qm initial --allow-empty
}
quote() {
  local value="$1"
  value=${value//\\/\\\\}; value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}; value=${value//$'\t'/\\t}
  printf '"%s"' "$value"
}
write_declaration() {
  cat > "$1/.ki.toml" <<DECL
[repo]
harnesses = ["example/harness"]
[skills.ki-repo-project]
[skills.ki-repo]
repo_type = "project"
primary_shape = "ki-repo-project"
repository = "https://github.com/example/$2"
title = "Fixture"
capital = "https://github.com/example/capital"
description = "Isolated caller proof"
repo_code = "FIXTURE"
DECL
}
write_capital() {
  write_declaration "$CAPITAL" capital
  cat >> "$CAPITAL/.ki.toml" <<'DECL'
territory_prefix = "short"
territory_name = "Fixture territory"
territory_members = ["https://github.com/example/capital", "https://github.com/example/member", "https://github.com/example/missing"]
DECL
}
registry_entry() {
  printf '[repositories."%s"]\nrepository = "https://github.com/example/%s"\npath = ' "$1" "$2"
  quote "$3"
  printf '\n'
}
write_registry() {
  {
    printf 'schema = 1\n'
    registry_entry capital-registry capital "$CAPITAL"
    registry_entry unrelated-member-key member "$MEMBER"
    registry_entry absent-registration-key missing "$MISSING"
  } > "$XDG_STATE_HOME/ki/registry.toml"
}
assert_no_dispatch() {
  run "$MGIT" "$@" -B git config pilot.dispatched yes
  [ "$status" -ne 0 ]
  ! git -C "$CAPITAL" config --get pilot.dispatched
  ! git -C "$MEMBER" config --get pilot.dispatched
}

@test "real producer uses literal case-sensitive repeated basename prefixes with excluded missing roots" {
  run "$MGIT" -t short -f 'Tool [*]' -f absent -f 'Tool [*]' -B git config pilot.proof yes
  [ "$status" -eq 0 ]
  [ "$(git -C "$MEMBER" config --get pilot.proof)" = yes ]
  ! git -C "$CAPITAL" config --get pilot.proof
  run "$MGIT" --estate -f Capital
  [ "$status" -eq 0 ]
  [ "$output" = '../Capital Space' ]
  for prefix in tool '*' unrelated-member-key ''; do
    assert_no_dispatch -t short -f "$prefix"
  done
  assert_no_dispatch -t capital-registry
}

@test "real NUL transport preserves spaces and embedded and trailing newlines through checkout expansion" {
  MEMBER="$ROOT/nested/Tool [*]"$'\nline\n'
  init_repo "$MEMBER"
  write_declaration "$MEMBER" member
  write_registry
  local linked="$ROOT/runtime checkout"$'\n'
  git -C "$MEMBER" worktree add -qb feature "$linked"
  run "$MGIT" -t short -f 'Tool [*]' -W -B sh -c 'printf "%s\0" "$PWD" >> "$1"' sh "$ROOT/dispatch.nul"
  [ "$status" -eq 0 ]
  local first second
  { IFS= read -r -d '' first; IFS= read -r -d '' second; } < "$ROOT/dispatch.nul"
  [ "$first" = "$MEMBER" ] || { printf 'first=%q expected=%q\n' "$first" "$MEMBER"; return 1; }
  [ "$second" = "$linked" ]
  run "$MGIT" -t short -f 'runtime checkout'
  [ "$status" -ne 0 ]
}

@test "real producer blocks selected missing roots and missing member registrations before dispatch" {
  assert_no_dispatch -t short
  assert_no_dispatch --estate -f Unavailable
  {
    printf 'schema = 1\n'
    registry_entry capital-registry capital "$CAPITAL"
  } > "$XDG_STATE_HOME/ki/registry.toml"
  assert_no_dispatch -t short -f Capital
}

@test "real producer rejects duplicate identities and handles before every Git mutation" {
  registry_entry duplicate-key member "$ROOT/other" >> "$XDG_STATE_HOME/ki/registry.toml"
  assert_no_dispatch -t short -f Capital
  write_registry
  local other="$ROOT/Other Capital"
  init_repo "$other"
  write_declaration "$other" other
  # Another self-declared Capital claiming the same short handle.
  sed 's@https://github.com/example/capital@https://github.com/example/other@g' "$other/.ki.toml" > "$ROOT/other.toml"
  cat "$ROOT/other.toml" > "$other/.ki.toml"
  printf '%s\n' 'territory_prefix = "short"' 'territory_name = "Other"' 'territory_members = ["https://github.com/example/other"]' >> "$other/.ki.toml"
  registry_entry other-registry other "$other" >> "$XDG_STATE_HOME/ki/registry.toml"
  assert_no_dispatch -t short -f Capital
}

@test "real caller rejects invalid and ignored scopes and old selectors before dispatch" {
  assert_no_dispatch -t short --estate
  assert_no_dispatch --estate -t short
  assert_no_dispatch -t ''
  assert_no_dispatch -t short --repo "$MEMBER"
  assert_no_dispatch --repo "$MEMBER" --estate
  assert_no_dispatch -t short --ignore
  assert_no_dispatch -t short --physical
  assert_no_dispatch --agora short
  assert_no_dispatch -a short
  for command in doctor diag repair completion structure worktree; do
    run "$MGIT" -t short "$command"
    [ "$status" -eq 2 ]
  done
  run "$MGIT" --estate register
  [ "$status" -eq 2 ]
}

@test "saved territory refresh is explicit atomic previewable and snapshots operate offline" {
  # Resolve the previously unavailable registered root in this sandbox only.
  init_repo "$MISSING"
  write_declaration "$MISSING" missing
  run "$MGIT" register add -t short --dry-run
  [ "$status" -eq 0 ]
  [ ! -e .mgit.toml ]
  run "$MGIT" register add --territory short
  [ "$status" -eq 0 ]
  cp .mgit.toml "$ROOT/before.toml"
  grep -Fx 'locations = ["local", "territory:short"]' .mgit.toml
  # A registry change cannot affect a saved snapshot until explicit refresh.
  mv "$XDG_STATE_HOME/ki/registry.toml" "$ROOT/registry.saved"
  run "$MGIT" -f 'Tool [*]' -B git config pilot.offline yes
  [ "$status" -eq 0 ]
  [ "$(git -C "$MEMBER" config --get pilot.offline)" = yes ]
  run "$MGIT" register
  [ "$status" -ne 0 ]
  cmp .mgit.toml "$ROOT/before.toml"
  mv "$ROOT/registry.saved" "$XDG_STATE_HOME/ki/registry.toml"
  run "$MGIT" register rm -t short
  [ "$status" -eq 1 ] # no repositories remain after explicit removal
  [ ! -e .mgit.toml ]
}

@test "legacy saved locations and schema are rejected with a reviewed migration route" {
  printf '%s\n' 'kind = "workspace"' 'locations = ["local", "agora:old"]' > .mgit.toml
  cp .mgit.toml "$ROOT/before.toml"
  run "$MGIT" register --dry-run
  [ "$status" -ne 0 ]
  [[ "$output" == *'Agora syntax is retired'* ]]
  cmp .mgit.toml "$ROOT/before.toml"
  printf '%s\n' 'schema = 1' 'kind = "workspace"' 'agora = "old"' '[agora.members."../Capital Space"]' > .mgit.toml
  cp .mgit.toml "$ROOT/before.toml"
  run "$MGIT" repair --apply
  [ "$status" -ne 0 ]
  cmp .mgit.toml "$ROOT/before.toml"
}
