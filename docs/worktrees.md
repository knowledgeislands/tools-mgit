# Managed worktree repositories

`mgit` is opinionated about worktree repositories. A repository is either standard, with a `.git/` directory at its root, or a managed worktree repository using this colocated layout:

```text
repoA/
├── .bare/      # shared bare Git store
├── .git        # controller file: gitdir: ./.bare
├── main/       # required default checkout
└── <branch>/   # optional branch checkout
```

The outer directory is one logical repository in an `mgit` set. `main/` and each child branch directory are its checkouts, not independently registered repositories. The shared `.bare/` directory and outer controller are never targets for normal commands.

## Registering and operating across repositories

From a parent that contains one managed workspace and one standard repository:

```text
parent/
├── repoA/      # managed worktree repository
└── repoB/      # standard repository
```

run:

```bash
cd parent
mgit register
```

The generated `.mgitconfig` contains only `repoA` and `repoB`. It does not list `.bare`, `main`, or branch worktrees. At runtime, `mgit status` expands that manifest to every active checkout:

```text
repoA/main
repoA/featureA
repoB
```

## Convert a set to managed worktrees

Convert all eligible standard repositories in the current `mgit` set with an explicit preview first:

```bash
mgit convert worktree --dry-run
mgit convert worktree --yes
```

Each candidate must have a clean working tree, an attached branch, and no pre-existing linked worktrees. The current branch becomes `main/`; Git metadata moves into `.bare/`; the former files are retained as a timestamped rollback backup. A conversion failure restores the original checkout where possible and retains failed staging data for inspection.

To return to a standard repository, remove every non-`main` worktree, ensure `main/` is clean, then run:

```bash
mgit convert standard --dry-run
mgit convert standard --yes
```

This promotes `main/` back to the repository root and retains the former workspace as a sibling backup.

## Add a branch across the managed set

To check out an existing branch from `origin` in every managed worktree repository:

```bash
mgit worktree add featureA
```

For each managed repository, `mgit` creates `<repo>/featureA` on local branch `featureA` tracking `origin/featureA`. Standard repositories are not changed. Before making any checkout, `mgit` verifies that every managed repository has the remote branch and no conflicting local branch or directory.

Use `mgit worktree list` or `mgit worktree status` to inspect the resulting checkout set. `mgit worktree remove` remains confirmation-gated and refuses to remove the required `main/` checkout.
