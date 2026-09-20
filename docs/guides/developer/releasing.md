# Release mgit

Use this guide only after the candidate satisfies the [definition of done](definition-of-done.md) and publication is explicitly authorised.

## Prepare the release

1. Set `MGIT_VERSION` in `bin/mgit` to the intended semantic version without a `v` prefix.
2. Keep `CHANGELOG.md` as the curated V1 feature baseline while pre-1.0 tags remain recorded in Git history. From `v1.0.0` onward, add the dated release entry required by repository policy.
3. Confirm that help, the README, user guides, `man/mgit.1`, completion, the installer, version tests, and the executable report the same candidate surface and version.
4. Run the complete verification gate from the [developer guide](README.md) on a clean checkout.
5. Commit the release candidate before creating any tag.

## Publish the release

Create and push the exact `vX.Y.Z` tag only with explicit publication authority, then create the matching GitHub release:

```sh
git tag vX.Y.Z
git push origin vX.Y.Z
gh release create vX.Y.Z --generate-notes --title "mgit vX.Y.Z"
```

Verify the immutable tag through the supported installer before treating publication as complete:

```sh
curl -fsSL https://raw.githubusercontent.com/knowledgeislands/tools-mgit/vX.Y.Z/install.sh | bash -s -- vX.Y.Z
mgit --version
man mgit
```

Do not move or recreate a published tag. Correct a failed release from `main` and publish the next patch version.

## Complete downstream distribution

Hand the published tag to `knowledgeislands/homebrew-tap`. The tap owns `Formula/mgit.rb`, the source checksum, executable and manual installation checks, and formula tests; this repository neither writes nor decides the tap's formula.

After the validated formula reaches the tap's `main` branch, the tap dispatches a verified tool-release event to explicitly enrolled consumers. An existing KI Website entry advances through the website's ordinary pull-request review. This repository stores no shared release-App credentials and does not duplicate tap or website verification.

A first-time website entry, a maturity change, or a consumer not enrolled in automation remains an explicit receiver-owned handoff. Supply the exact tag, immutable installer URL, and expected `/tooling/mgit/` and `/install/mgit` routes without transferring release authority.
