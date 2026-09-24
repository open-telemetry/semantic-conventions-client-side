# Releasing

Releases are cut from `main` as GitHub prereleases with the OTEP 4815 publication
artifacts attached: the publication manifest (`manifest.yaml`, `file_format:
manifest/2.0`) and the resolved registry (`resolved.yaml`, `file_format:
resolved/2.0`), both produced by `make package`.

The single source of truth for the release version is the version segment of
the `schema_url` in [`model/manifest.yaml`](model/manifest.yaml), e.g.
`…/client-side-dev/0.1.0-dev` releases as tag `v0.1.0-dev`. Everything else
that requires the version derives it by parsing that file.

We only have one release workflow: for the `dev` family (i.e. `client-side-dev`). Once
we have stable conventions, we will add a stable workflow that releases `client-side`
artifacts.

## How to release

1. Bump the version segment of `schema_url` in `model/manifest.yaml`
   - e.g. `1.1.0-dev` → `1.2.0-dev`.
2. Prepare a [draft release](https://github.com/open-telemetry/semantic-conventions-client-side/releases/new):
   - Tag: `v<version>` matching the bumped `schema_url` (e.g. `v1.2.0-dev`),
     choosing `Create new tag on publish`.
   - Description: what changed in `model/` since the last release. The
     `Generate release notes` button fills in the merged PRs as a starting point.
   - Save the release as draft. Do not publish!
3. Run the [`Release (dev)` workflow](https://github.com/open-telemetry/semantic-conventions-client-side/actions/workflows/release-dev.yml)
   from the Actions tab (`workflow_dispatch`). It will:
   - Derive the tag from the manifest. The dev release will fail if the version lacks the
     `-dev` suffix, if the git tag already exists, or if no matching draft is waiting.
     The latter should be created in step #2.
   - Validate the registry (i.e. running `make check-policies`), including the shared policy pack.
   - Package the publication artifacts (i.e. running `make package`).
   - Attach `manifest.yaml` and `resolved.yaml` to the draft and publish it as a
     prerelease, creating the `v<version>` tag at the workflow's commit.

To be clear: the workflow never creates a release of its own end to end. It
only edits, adds to, and publishes the draft a human created in step #2. The
involvement of an actual person beyond clicking a button is intentional.

## Why prereleases for dev

Every dev release is published as a GitHub prerelease. That is a flag on the GitHub
release, not a property of the tag, which works like any other GH tag: it should be
permanent, immutable, and safe to depend on in perpetuity (if we follow our own
conventions). The difference is that a prerelease is labelled as such in the UI and
is left out of `/releases/latest`. It will also be assumed to be not stable, so it
may be flagged as such by other tooling and not be automatically consumed.

When the registry starts including stable conventions, a stable publishing workflow
will be added that will not mark its releases as prereleases. Until then, folks
consuming conventions in this registry should be aware that they can change or be
removed in the next version without adhering to SemVer guidelines regarding breaking
changes.

It is also the safe direction to start from. We can choose to drop the prerelease
flag later for the dev stream if we so choose, which increases stability guarantees
for the stream, not the other way around. It's a much easier sell to consumers to
say that what they are using is more stable than less stable.

## Rules

- Once published, releases and tags should be considered immutable and should not be
  rolled back. The way to fix a bad release is by releasing a newer patch version.
  The only way through is forward. Document that fact and move on.
- Releases generally should only change the version segment of `schema_url`.
  Everything before it is the registry's identity, and changing that has broad
  implications which have to be managed closely. See [Versioning](README.md#versioning)
  for details.