# Changelog Fragments

Add one [Towncrier](https://towncrier.readthedocs.io/) fragment for each change
that consumers of this registry should notice, which is usually anything under
`model/`. Editorial changes, typo fixes, pure rewording, and repo tooling
changes do not need fragments.

Fragment filenames use this form:

```text
<pr-number>.<type>.md
```

Use `<pr-number>.<type>.<counter>.md` when one pull request needs multiple
fragments of the same type. Use `+.<type>.md` or `+.<type>.<counter>.md` only
when there is no pull request number yet.

Supported types:

- `breaking` - breaking changes
- `deprecation` - deprecations
- `component` - new components
- `enhancement` - enhancements
- `bugfix` - bug fixes
- `clarification` - clarifications

The content is one or two sentences of Markdown, written for someone consuming
the conventions. Preview the next changelog section with `make changelog-preview`
(needs [uv](https://docs.astral.sh/uv/)).
