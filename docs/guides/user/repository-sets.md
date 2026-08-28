# Define a repository set

Without configuration, `mgit` walks current directory for `.git` entries and drops repositories nested inside another repository. A workspace-kind `.mgit.toml` at a non-Git container makes set explicit, deterministic, reproducible, and divisible into named groups.

## Generate configuration

Run `mgit register` from directory containing repository set:

```sh
mgit register
```

The command writes one filename, `.mgit.toml`, with a discriminator for each role:

- `kind = "workspace"` in non-Git container directories records repository and child-workspace membership.
- `kind = "repository"` in repository leaves records tracked symlinks whose targets live in other repositories.

Registration stops at repository roots, never descends into repository internals, and replaces each workspace's generated structural `default` group after scanning current filesystem. Existing non-default groups are preserved.

When Chezmoi is configured, `mgit register` synchronizes generated manifests below Chezmoi target directory into source state. Manifests outside target directory, and manifests generated inside Chezmoi source directory, remain local only.

## Workspace configuration

A workspace document uses schema 1, explicit workspace kind, configured default group, and path-keyed member maps:

```toml
schema = 1
kind = "workspace"
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

Structural `default` group is required. Repository members require `type`, which is `standard`, `nested`, or `bare`, and may have a `source` clone URL. `mgit register` records URL from `origin` when available. Workspace members have only `kind`; paths are map keys. Non-default group repository members also have only `kind` because they select already-present repositories rather than declaring structure or clone sources.

Member paths must be safe relative map keys below manifest directory. Blank lines and comments are ignored.

## Repository configuration

A repository document uses same filename and schema but a distinct top-level kind:

```toml
schema = 1
kind = "repository"

[symlinks]
"shared-config" = "../platform/shared-config"
```

Each key is symlink path owned by repository; value resolves to target in another repository. `mgit` includes repository containing each declared target. Git restores tracked symlink after clone, while metadata lets `mgit` include linked repository.

Workspace tables are invalid in repository document, and `symlinks` table is invalid in workspace document. mgit rejects mixed documents rather guessing intended role.

## Migrate legacy files

Run `mgit register` to migrate either old filename:

- `.mgit-workspace.toml` becomes workspace-kind `.mgit.toml`, retaining configured default and named groups while refreshing structural membership.
- `.mgit-config.toml` becomes repository-kind `.mgit.toml`, refreshing symlink metadata from tracked repository state.

The canonical file is written and synchronized before legacy file is removed. Ordinary commands, `group`, and `repair` do not maintain a compatibility read path; they stop with migration guidance when legacy file remains.

Registration also stops without modifying files when one directory contains canonical and legacy configuration together, both legacy filenames, or a manifest kind that does not match directory role. Resolve conflict explicitly, then rerun `mgit register`; mgit never applies silent precedence or dual writes.

## Create an alternative group

Create empty named group, then add direct members of structural `default` group without editing TOML:

```bash
mgit group create engineering
mgit group add engineering ki-agentic-harness
mgit group add engineering tools-mgit
mgit group add engineering ki-specifications
```

Group name may contain letters, digits, hyphens, and underscores. `create` refuses existing name, and `add` rejects member not direct default-group member. `remove` leaves group available even when it has no members. To replace group, delete it first:

```bash
mgit group delete engineering
mgit group create engineering
mgit group add engineering ki-agentic-harness
mgit group add engineering tools-mgit
mgit group add engineering ki-specifications
```

At runtime, `mgit` uses current workspace's configured default group or group selected with `-g` / `--group`. It recursively selects child workspaces using each child's configured default. Filters are applied after workspace selection.

## Recreate a workspace

`mgit repair` materializes missing repositories declared by structural `default` groups in workspace in current directory:

```sh
mgit repair
```

It clones every missing repository from `source` URL and follows child workspace documents through structural `default` groups. Standard repositories use normal clone, bare repositories use `--bare`, and nested repositories use `.bare/` plus `main/` layout.

Repair never replaces existing path. Present repository must match declared type; non-repository path or type mismatch is error. Child workspace directories and workspace-kind `.mgit.toml` documents must already exist.
