# Define a repository set

Without configuration, `mgit` walks the current directory for `.git` entries and drops a repository nested inside another repository. A `.mgit-workspace.toml` manifest at a non-Git container makes the set explicit, ordered, and reproducible, and can organise it into named groups.

## Generate a manifest

Run `mgit register` from the directory that contains the repository set:

```sh
mgit register
```

It writes `.mgit-workspace.toml` into every non-Git container directory and `.mgit-config.toml` only into repository leaves that own cross-repository symlinks. It stops at repository roots, never descends into a repository, and replaces each container's generated structural `default` group after scanning the current filesystem. Existing non-default groups are preserved.

When Chezmoi is configured, `mgit register` adds generated manifests that are below Chezmoi's target directory to Chezmoi's source state. Manifests outside that target directory, and those generated in Chezmoi's source directory, remain local only.

## Manifest shape

A workspace manifest has schema 1, a configured default group, and ordered member records. Members are either repositories or child workspaces.

```toml
schema = 1
default = "default"

[[groups.default.members]]
kind = "repository"
path = "platform"
type = "standard"
source = "git@github.com:acme/platform.git"

[[groups.default.members]]
kind = "workspace"
path = "group"

[[groups.ci.members]]
kind = "repository"
path = "platform"
```

The structural `default` group is required. Its repository members require `type`, which is `standard`, `nested`, or `bare`, and can have a `source` clone URL. `mgit register` records that URL from `origin` when available. Workspace members have only `kind` and `path`. Non-default group repository members also have only `kind` and `path`; they select already-present repositories and do not declare structure or clone sources.

Member paths are safe relative paths below the manifest directory. Blank lines and comments are ignored.

At runtime, `mgit` uses the current workspace's configured default group, or the group selected with `-g` / `--group`. It recursively selects child workspaces using each child's configured default. Filters are applied after this workspace selection.

Repository-owned `.mgit-config.toml` files have a separate, leaf-only purpose: their `symlinks` table maps a symlink owned by that repository to a target in another repository. `mgit` includes the repository containing each declared target. Git restores tracked symlinks after cloning; this metadata lets `mgit` include the linked repository.

## Recreate a workspace

`mgit repair` materializes missing repositories declared by structural `default` groups in the workspace in the current directory:

```sh
mgit repair
```

It clones every missing repository with a `source` URL, following child workspace manifests through their structural `default` groups. Standard repositories use a normal clone, bare repositories use `--bare`, and nested repositories use the `.bare/` plus `main/` layout.

Repair never replaces an existing path. A present repository must match the declared type; a non-repository path or a type mismatch is an error. Child workspace directories and their `.mgit-workspace.toml` manifests must already exist.
