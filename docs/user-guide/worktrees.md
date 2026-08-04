# Manage worktrees

`mgit` supports two structures for a logical repository.

A standard repository is an ordinary checkout. `mgit worktree add` places its linked worktrees under `.git/mgit-worktrees/`:

```text
repoB/
├── .git/
│   └── mgit-worktrees/
│       └── featureA/   # optional linked worktree
└── <files>
```

A nested repository uses mgit's colocated layout:

```text
repoA/
├── .bare/      # shared bare Git store
├── .git        # controller file: gitdir: ./.bare
├── main/       # required default checkout
└── <branch>/   # optional branch checkout
```

In both structures, the logical repository is registered once. Git reports its active worktrees at runtime: a standard root and its linked siblings, or a nested `main/` and its child checkouts. The shared `.bare/` directory and outer controller of a nested repository are never targets for normal commands.

## Register and operate across worktrees

From a parent that contains one nested repository and one standard repository:

```text
parent/
├── repoA/                              # nested repository
└── repoB/                              # standard repository
    └── .git/mgit-worktrees/featureA/   # repoB's linked worktree
```

run:

```bash
cd parent
mgit register
```

The generated `.mgit-config.toml` labels the two logical repositories without listing `.bare`, `main`, or branch worktrees:

```toml
version = 1

[members."repoA"]
type = "nested"

[members."repoB"]
type = "standard"
```

At runtime, `mgit status` expands that manifest to every active checkout:

```text
repoA/main
repoA/featureA
repoB
repoB/.git/mgit-worktrees/featureA
```

## Change a repository structure

Change all eligible standard repositories in the current `mgit` set to nested structure with an explicit preview first:

```bash
mgit structure nested --dry-run
mgit structure nested --yes
```

Each candidate must have a clean working tree, an attached branch, and no pre-existing linked worktrees. The current branch becomes `main/`; Git metadata moves into `.bare/`; the former files are retained as a timestamped rollback backup. A conversion failure restores the original checkout where possible and retains failed staging data for inspection.

To return to standard structure, remove every non-`main` worktree, ensure `main/` is clean, then run:

```bash
mgit structure standard --dry-run
mgit structure standard --yes
```

This promotes `main/` back to the repository root and retains the former workspace as a sibling backup.

## Add a branch across either structure

To check out an existing branch from `origin` in every standard and nested repository:

```bash
mgit worktree add featureA
```

For each nested repository, `mgit` creates `<repo>/featureA`; for each standard repository, it creates `<repo>/.git/mgit-worktrees/featureA`. Every checkout is on local branch `featureA` tracking `origin/featureA`. Before making any checkout, `mgit` verifies that every participating repository has the remote branch and no conflicting local branch or directory. Existing linked worktrees remain where Git created them; `mgit` does not move them.

Use `mgit worktree list` or `mgit worktree status` to inspect the resulting checkout set. `mgit worktree remove PATH --yes` remains confirmation-gated and refuses to remove the standard primary checkout or the required nested `main/` checkout.
