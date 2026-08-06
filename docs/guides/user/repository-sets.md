# Define a repository set

Without configuration, `mgit` walks the current directory for `.git` entries and drops a repository nested inside another repository. A `.mgit-workspace.toml` manifest at a non-Git container makes the set explicit, deterministic, and reproducible, and can organise it into named groups.

## Generate a manifest

Run `mgit register` from the directory that contains the repository set:

```sh
mgit register
```

It writes `.mgit-workspace.toml` into every non-Git container directory and `.mgit-config.toml` only into repository leaves that own cross-repository symlinks. It stops at repository roots, never descends into a repository, and replaces each container's generated structural `default` group after scanning the current filesystem. Existing non-default groups are preserved.

When Chezmoi is configured, `mgit register` adds generated manifests that are below Chezmoi's target directory to Chezmoi's source state. Manifests outside that target directory, and those generated in Chezmoi's source directory, remain local only.

## Manifest shape

A workspace manifest has schema 1, a configured default group, and path-keyed member maps. Members are either repositories or child workspaces.

```toml
schema = 1
default = "default"

[groups.default.members."platform"]
kind = "repository"
type = "standard"
source = "git@github.com:acme/platform.git"

[groups.default.members."group"]
kind = "workspace"

[groups.ci.members."platform"]
kind = "repository"
```

The structural `default` group is required. Its repository members require `type`, which is `standard`, `nested`, or `bare`, and can have a `source` clone URL. `mgit register` records that URL from `origin` when available. Workspace members have only `kind`; their paths are map keys. Non-default group repository members also have only `kind`; they select already-present repositories and do not declare structure or clone sources.

Member paths are safe relative map keys below the manifest directory. Blank lines and comments are ignored.

## Create an alternative group

Create an empty named group, then add direct members of the structural `default` group without editing TOML:

```bash
mgit group create engineering
mgit group add engineering ki-agentic-harness
mgit group add engineering tools-mgit
mgit group add engineering ki-specifications
```

The group name may contain letters, digits, hyphens, and underscores. `create` refuses an existing name, and `add` rejects a member that is not a direct default-group member. `remove` leaves the group available even when it has no members. To replace a group, delete it first:

```bash
mgit group delete engineering
mgit group create engineering
mgit group add engineering ki-agentic-harness
mgit group add engineering tools-mgit
mgit group add engineering ki-specifications
```

At runtime, `mgit` uses the current workspace's configured default group, or the group selected with `-g` / `--group`. It recursively selects child workspaces using each child's configured default. Filters are applied after this workspace selection.

Repository-owned `.mgit-config.toml` files have a separate, leaf-only purpose: their `symlinks` table maps a symlink owned by that repository to a target in another repository. `mgit` includes the repository containing each declared target. Git restores tracked symlinks after cloning; this metadata lets `mgit` include the linked repository.

## Recreate a workspace

`mgit repair` materializes missing repositories declared by structural `default` groups in the workspace in the current directory:

```sh
mgit repair
```

It clones every missing repository with a `source` URL, following child workspace manifests through their structural `default` groups. Standard repositories use a normal clone, bare repositories use `--bare`, and nested repositories use the `.bare/` plus `main/` layout.

Repair never replaces an existing path. A present repository must match the declared type; a non-repository path or a type mismatch is an error. Child workspace directories and their `.mgit-workspace.toml` manifests must already exist.
