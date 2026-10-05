# Release mgit

Use this guide after completing the [definition of done](definition-of-done.md).

Apply the `ki-repo-tools` release-readiness checklist for shared candidate, changelog, documentation, immutability and downstream requirements, and `ki-git` for commit and publication authority. This guide supplies MGIT's version source, publication commands and installation verification.

## Prepare the release

1. Set `MGIT_VERSION` in `bin/mgit` to the intended semantic version without a `v` prefix.
2. Update the candidate version assertions in `tests/mgit.bats` and run the complete gate from the [definition of done](definition-of-done.md).
3. Prepare the reviewed release commit on `main` before creating its tag.

## Publish the release

Publish the candidate with the following tag and GitHub release commands:

```sh
git tag vX.Y.Z
git push origin vX.Y.Z
gh release create vX.Y.Z --generate-notes --title "mgit vX.Y.Z"
```

Verify the exact published tag through the installer in disposable executable and manual destinations. Resolve both installed artifacts by their absolute paths:

```sh
mgit_release_check=$(mktemp -d)
curl -fsSL https://raw.githubusercontent.com/knowledgeislands/tools-mgit/vX.Y.Z/install.sh |
  MGIT_INSTALL_DIR="$mgit_release_check/bin" \
  MGIT_MAN_INSTALL_DIR="$mgit_release_check/man/man1" bash -s -- vX.Y.Z
"$mgit_release_check/bin/mgit" --version
man "$mgit_release_check/man/man1/mgit.1"
```

For a failed release, correct the source on `main`, update `MGIT_VERSION` and the version tests for the next patch, then repeat this procedure under the shared release-recovery policy.

## Complete downstream distribution

The downstream handoff identifies `knowledgeislands/homebrew-tap` and `Formula/mgit.rb`, the exact released tag, `https://raw.githubusercontent.com/knowledgeislands/tools-mgit/vX.Y.Z/install.sh`, and the `/projects/mgit/` and `/install/mgit` website routes. Follow the shared checklist through the actual formula and consumer outcome.

Publishing the GitHub release triggers the `Notify Homebrew tap` workflow, which sends a `tool-release-published` dispatch to `knowledgeislands/homebrew-tap` through the `ki-tools-release-bot` GitHub App; the tap then opens the exact formula pull request and squash-merges it automatically once its required checks pass. The job is skipped until the `KI_TOOLS_RELEASE_BOT_APP_ID` variable and `KI_TOOLS_RELEASE_BOT_PRIVATE_KEY` secret are available to this repository at organisation or repository level (not as `release`-environment secrets); the tap's daily scheduled intake still picks up a published immutable release without the dispatch.
