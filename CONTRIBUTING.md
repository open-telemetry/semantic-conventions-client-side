# Contributing

## Changelog

[`CHANGELOG.md`](CHANGELOG.md) is generated at release time by
[Towncrier](https://towncrier.readthedocs.io/), the same tool the
[GenAI](https://github.com/open-telemetry/semantic-conventions-genai) and
[mainframe](https://github.com/open-telemetry/semantic-conventions-mainframe) registries use.
Don't edit it directly. Instead, add a fragment under [`changelog.d/`](changelog.d/) to every
pull request that changes something consumers of this registry should notice, which is usually
anything under `model/`.

A fragment is a file named `<pr-number>.<type>.md`, e.g. `changelog.d/52.enhancement.md`,
holding one or two sentences of Markdown. See [`changelog.d/README.md`](changelog.d/README.md)
for the types and naming rules. `make changelog-preview` shows how pending fragments render, and
`make changelog-check` checks that your branch adds one. Both need [uv](https://docs.astral.sh/uv/).

A pull request that doesn't need an entry (tooling, CI, docs typos, …) can put `[chore]` in
its title or get the `Skip Changelog` label instead. Renovate's pull requests are exempt.
The [Changelog workflow](.github/workflows/changelog.yml) enforces all of this.
