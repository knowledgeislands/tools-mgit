# Define a repository set

Without configuration, `mgit` walks current directory for `.git` entries and drops repositories nested inside another repository. A workspace-kind `.mgit.toml` at a non-Git container makes set explicit, deterministic, and reproducible.

## Generate configuration

Run `mgit register` from directory containing repository set:

```sh
mgit register
```

The command writes one filename, `.mgit.toml`, with a discriminator for each role:

- `kind = "workspace"` in non-Git container directories records repository and child-workspace membership.
- `kind = "repository"` in repository leaves records tracked symlinks whose targets live in other repositories.

Registration stops at repository roots, never descends into repository internals, and refreshes each workspace's direct members after scanning its saved locations.

The `locations` list defaults to `local`, which scans the current workspace and descendants. Run `mgit register add --agora personal --repo ../shared-tools` to bind additional search locations, or `mgit register rm --agora personal --repo ../shared-tools` to remove them. Both commands accept repeated, combined `--agora` and `--repo` options and refresh generated entries immediately. `mgit register --agora personal` remains an add shorthand. Adding a `--repo` path requires an existing Git repository; removal also accepts its saved relative path if the repository has disappeared.

Plain `mgit register` refreshes all saved locations. It resolves Agora locations through `ki` and validates repository paths before writing. Ordinary commands use the generated entries without invoking `ki`. The selected set combines local and additional repositories without duplicate dispatch. `mgit repair` uses only direct members; it does not clone repositories from additional locations automatically.

Use `mgit register --dry-run` to preview manifest writes and removals. It also works with `add` and `rm`, and leaves both local manifests and Chezmoi source state untouched. Registration still validates saved locations before the preview.

When Chezmoi is configured, `mgit register` synchronizes generated manifests below Chezmoi target directory into source state. Manifests outside target directory, and manifests generated inside Chezmoi source directory, remain local only.

## Workspace configuration

A workspace document uses an explicit workspace kind and path-keyed direct members:

```toml
kind = "workspace"
locations = ["local", "agora:personal", "repo:../shared-tools"]

[registered.members."../chezmoi"]

[registered.members."../shared-tools"]

[members."platform"]
kind = "repository"
type = "standard"
source = "git@github.com:acme/platform.git"

[members."group"]
kind = "workspace"
```

Repository members require `type`, which is `standard`, `nested`, or `bare`, and may have a `source` clone URL. `mgit register` records the URL from `origin` when available. Workspace members have only `kind`; paths are map keys. Member paths must be safe relative paths below the manifest directory.

The `locations` array is the durable search list; empty `[registered.members."../chezmoi"]` tables are generated repository entries. Their relative paths may reach outside the workspace and change only when registration runs. Older manifests without `locations` default to `local`; older `agora` snapshots are migrated on registration. Blank lines and comments are ignored.

Existing `schema = 1` manifests with grouped members remain readable. Registration rewrites a manifest containing only its structural `default` group into the direct-member format. A manifest with alternative groups must have those tables removed deliberately before registration; `mgit` refuses to discard them silently.

## Repository configuration

A repository document uses the same filename without a schema field and has a distinct top-level kind:

```toml
kind = "repository"

[symlinks]
"shared-config" = "../platform/shared-config"
```

Each key is symlink path owned by repository; value resolves to target in another repository. `mgit` includes repository containing each declared target. Git restores tracked symlink after clone, while metadata lets `mgit` include linked repository.

Workspace tables are invalid in repository document, and `symlinks` table is invalid in workspace document. mgit rejects mixed documents rather guessing intended role.

## Recreate a workspace

`mgit repair` materializes missing repositories declared by direct members in workspace in current directory:

```sh
mgit repair
```

It clones every missing repository from `source` URL and follows child workspace documents through direct members. Standard repositories use normal clone, bare repositories use `--bare`, and nested repositories use `.bare/` plus `main/` layout.

Repair never replaces existing path. Present repository must match declared type; non-repository path or type mismatch is error. Child workspace directories and workspace-kind `.mgit.toml` documents must already exist.

Use `mgit repair --dry-run` to see missing repository clone targets and sources without creating them. Repair still validates the workspace tree before reporting proposed clones. Both commands execute automatically when `--dry-run` is omitted.
