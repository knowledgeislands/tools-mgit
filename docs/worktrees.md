# Worktree workflow and staged migration

Git worktrees let several branches share one Git object store while retaining independent files, indexes, and uncommitted changes. They are a good fit for parallel human and agent work: each checkout can be opened and changed independently without switching branches or stashing work.

`mgit` treats the working tree and the Git store as separate identities. A normal repository's `.git` directory is its common directory; a linked worktree's `.git` file points into that same common directory. `mgit worktree list` shows the relationship explicitly.

## Recommended everyday workflow

Keep your primary checkout as it is and add disposable, named worktrees for focused work:

```bash
cd ~/workspaces/kis/knowledgeislands/tools-mgit
mgit worktree add codex
mgit worktree add review main
mgit worktree status
```

This creates sibling checkouts such as `~/workspaces/kis/knowledgeislands/tools-mgit-codex` on `worktree/codex`. The branch namespace makes agent work easy to identify and avoids silently reusing an existing branch.

When a worktree is finished, merge or otherwise preserve its branch first. Then remove the checkout with an explicit confirmation:

```bash
mgit worktree remove ../tools-mgit-codex --yes
```

Use `--force` only when you intentionally want Git to discard uncommitted files in that linked worktree. `mgit` never removes the primary working tree, never removes a worktree without `--yes`, and never automatically prunes stale worktree metadata.

## Adopt a grouped workspace layout without migration

Set `MGIT_WORKTREE_ROOT` when creating worktrees to place them under a common root. This is opt-in and changes no existing checkout:

```bash
export MGIT_WORKTREE_ROOT="$HOME/workspaces/kis"
cd ~/workspaces/kis/knowledgeislands/tools-mgit
mgit worktree add codex
```

The result is `~/workspaces/kis/tools-mgit/codex`. Repeat this from each repository to build a layout such as `~/workspaces/kis/ki-specifications/review` or `~/workspaces/kis/tools-mgit/codex`.

## Staged migration from current repositories

No migration is required to use worktrees. Move gradually, repository by repository, and keep the existing checkout until the replacement has been verified.

1. Inventory the current tree and register its explicit members if that suits your workflow.

   ```bash
   cd ~/workspaces/kis
   mgit
   mgit register
   ```

2. Add and use linked worktrees beside one existing repository. This validates tooling and editor/agent setup while leaving its original `.git` directory untouched.

   ```bash
   cd ~/workspaces/kis/knowledgeislands/tools-mgit
   mgit worktree add codex
   mgit worktree list
   ```

3. Optionally adopt `MGIT_WORKTREE_ROOT` for new worktrees. Existing repository paths and `.mgitconfig` manifests continue to work unchanged.

4. Only when you want every checkout to be symmetric, create a new bare store and add a replacement main worktree. Do not delete or move the original checkout in this step.

   ```bash
   git clone --bare ~/workspaces/kis/knowledgeislands/tools-mgit \
     ~/.local/share/mgit/git-stores/tools-mgit.git
   git --git-dir="$HOME/.local/share/mgit/git-stores/tools-mgit.git" \
     worktree add "$HOME/workspaces/kis/tools-mgit/main" main
   ```

5. Verify the new checkout, its remotes, and its history before retiring anything. For example, run `git -C "$HOME/workspaces/kis/tools-mgit/main" status` and `mgit worktree list` from that checkout. Retire the original only through a separately planned, explicitly confirmed filesystem change.

The bare-store form is supported because `mgit` recognises a bare `*.git` directory and models it by its common Git directory. It remains optional: a normal primary checkout plus linked worktrees has the same shared-history behaviour and is the lowest-risk starting point.
