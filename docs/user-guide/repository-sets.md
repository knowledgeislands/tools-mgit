# Define a repository set

Without configuration, `mgit` walks the current directory for `.git` entries and drops a repository nested inside another repository. A `.mgit-config.toml` manifest makes the set explicit and reproducible, and can point to repositories outside the current tree.

## Generate a manifest

Run `mgit register` from the directory that contains the repository set:

```sh
mgit register
```

It writes `.mgit-config.toml` into every container directory and into repository roots that own cross-repository symlinks. It stops at repository roots, never descends into a repository, and overwrites generated manifests after scanning the current filesystem.

When Chezmoi is configured, `mgit register` adds generated manifests that are below Chezmoi's target directory to Chezmoi's source state. Manifests outside that target directory, and those generated in Chezmoi's source directory, remain local only.

## Manifest shape

A manifest maps each child repository or container directory under `members`, and maps each repository-owned symlink to its target under `symlinks`.

```toml
version = 1

[members."platform"]
type = "standard"
source = "git@github.com:acme/platform.git"

[members."group"]
type = "dir"

[symlinks]
"link-to-platform" = "../platform/shared"
```

`type` is `standard`, `nested`, or `bare` for a repository, and `dir` for a child container. The quoted member-table key is the required path. Repository members may have an optional `source` clone URL; `mgit register` records it from `origin` when available.

Paths are relative to the manifest directory by default. Absolute paths and `~/` paths are also accepted. Blank lines and comments are ignored.

At runtime, `mgit` recurses through container members, operates on repository members, and includes the repository containing each declared symlink target. Git restores tracked symlinks after cloning; the manifest records their destination so `mgit` can include the linked repository.

## Recreate a workspace

`mgit bootstrap` materializes repositories declared by the manifest in the current directory:

```sh
mgit bootstrap
```

It clones every missing repository with a `source` URL, following manifests that arrive with those clones. Standard repositories use a normal clone, bare repositories use `--bare`, and nested repositories use the `.bare/` plus `main/` layout.

Bootstrap never replaces an existing path. A present repository must match the declared type; a non-repository path or a type mismatch is an error. Directory members must already exist because they have no clone source.
