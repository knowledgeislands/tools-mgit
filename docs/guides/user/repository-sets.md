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

The `locations` list defaults to `local`, which scans the current workspace and descendants. Run `mgit register add --territory short --repo ../shared-tools` to bind additional search locations, or `mgit register rm --territory short --repo ../shared-tools` to remove them. Both commands accept repeated, combined `--territory` and `--repo` options and refresh generated entries immediately. `mgit register --territory short` is an add shorthand. Adding a `--repo` path requires an existing Git repository; removal also accepts its saved relative path if the repository has disappeared.

Plain `mgit register` refreshes all saved locations. It resolves territory handles through `ki territory roots --null --territory HANDLE` and validates repository paths before writing. Each location root outside the workspace becomes an ordinary external member; a root that local discovery already records is not written again. Ordinary commands use the generated members without invoking `ki`. A repository is identified by its physical path, so one reached from several workspaces, or through a navigation symlink, is dispatched once. `mgit repair` validates present external members but never clones a missing one.

Use `mgit register --dry-run` to preview manifest writes and removals. It also works with `add` and `rm`, and leaves both local manifests and Chezmoi source state untouched. Registration still validates saved locations before the preview.

When Chezmoi is configured, `mgit register` synchronizes generated manifests below Chezmoi target directory into source state. Manifests outside target directory, and manifests generated inside Chezmoi source directory, remain local only.

## Workspace configuration

A workspace document uses an explicit workspace kind and path-keyed direct members:

```toml
kind = "workspace"
locations = ["local", "repo:../../.local/share/chezmoi"]

[members."../../.local/share/chezmoi"]
kind = "repository"
type = "standard"
source = "git@github.com:acme/dotfiles.git"

[members."platform"]
kind = "repository"
type = "standard"
source = "git@github.com:acme/platform.git"

[members."group"]
kind = "workspace"
```

Repository members require `type`, which is `standard`, `nested`, or `bare`, and may have a `source` clone URL. `mgit register` records the URL from `origin` when available. Workspace members have only `kind`; paths are map keys. Member paths must be safe relative paths below the manifest directory, except that a repository member may be external: one or more leading `../` segments followed by a safe relative path.

The `locations` array is the durable search list, and external members are generated from it: `repo:` and `territory:` locations say where to look, and registration records what it found as members. A hand-written external member without a matching location is dropped at the next registration, which names it; `mgit register --dry-run` names it before it goes, and `mgit register add --repo PATH` keeps it as a saved location. An external path that resolves back inside the workspace, such as `../personal/acquire` written in `personal`, is rejected with the local member name to declare instead. A missing external member fails selection for the whole set, as a missing local member does, so declare one only in manifests used on machines that have the checkout. Manifests without `locations` default to `local`.

Earlier releases wrote external roots as empty `[registered.members."PATH"]` tables. Those remain readable for selection with a deprecation warning, and `mgit doctor` reports them; preview the rewrite with `mgit register --dry-run`, then run `mgit register` to replace them with typed members. If Chezmoi manages the manifest, registration updates its source state too; check that the installed `mgit` on every machine applying that source reads external members before committing it. Old `agora:` locations, `agora` fields and `[agora.members]` snapshots are rejected, including the old schema-1 Agora form; they are never migrated automatically. Blank lines and comments are ignored.

Existing `schema = 1` manifests with grouped members remain readable. Registration rewrites a manifest containing only its structural `default` group into the direct-member format. A manifest with alternative groups must have those tables removed deliberately before registration; `mgit` refuses to discard them silently.

For a focused migration, run `mgit repair` in the directory containing the manifest. It prints the proposed config diff and missing clone targets without changing them. `mgit repair --apply` revalidates and writes only a recognised repository-kind file or a workspace containing just the structural default group, then clones missing declared repositories. Unknown schema values, mixed shapes and alternative groups are refused. This command does not refresh members or update Chezmoi's source; if Chezmoi owns the file, carry the reviewed change into its source before applying that source again.

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

`mgit repair` previews missing repositories declared by direct members in the workspace in the current directory:

```sh
mgit repair
```

Add `--apply` to clone every missing local repository from its `source` URL and follow child workspace documents through direct members. A missing external member is reported and never cloned. Standard repositories use normal clone, bare repositories use `--bare`, and nested repositories use `.bare/` plus `main/` layout.

Repair never replaces existing path. Present repository must match declared type; non-repository path or type mismatch is error. Child workspace directories and workspace-kind `.mgit.toml` documents must already exist.

Repair validates the workspace tree before reporting proposed clones. Without `--apply`, it never creates a repository or changes a manifest.

## Migrate Agora locations

The cut-over removes `-a/--agora`, saved `agora:NAME` locations, the `agora` field and `[agora.members."PATH"]` tables. Existing schema-1 documents that do not contain Agora grammar retain their existing repair path. Old names are not territory aliases and glob filters are not supported.

1. Back up your `.mgit.toml` and its Chezmoi source, if managed. Keep that copy until the migrated selection is reviewed.
2. Inspect `ki territory roots --null --territory HANDLE` using the intended handle; an old Agora name does not establish the new territorial membership. Replace saved locations explicitly with `territory:HANDLE` in a reviewed copy. For an old Agora snapshot, remove the `agora` field and its `[agora.members."PATH"]` tables in that copy; preserve local members and other user settings. Do not apply a global text replacement or delete user state.
3. Run `mgit register --dry-run` from the workspace containing your edited copy, and inspect the proposed generated membership. A resolution failure writes nothing. Carry approved edits into the Chezmoi source when applicable.
4. Once the preview is correct, run `mgit register` explicitly, then `mgit` to review the resulting selection. Ordinary saved-snapshot operations remain offline until another explicit registration refresh.

Replace glob examples such as `-f 'tools-*'` with the literal prefix `-f 'tools-'`. Repeated filters mean OR, matching directory basenames case-sensitively before worktree expansion; an empty prefix or zero matches fails before a command runs.
