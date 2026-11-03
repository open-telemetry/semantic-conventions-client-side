# Changelog

<!--
Do not add changelog entries here directly. This changelog is managed by
Towncrier; add fragments under changelog.d/ instead.
-->

<!-- towncrier release notes start -->

## v0.1.0-dev

### 🚀 New components 🚀

- Add the `browser.console`, `browser.navigation`, `browser.navigation_timing`
  and `browser.resource_timing` events and their `browser.*` attributes.
  ([#14](https://github.com/open-telemetry/semantic-conventions-client-side/pull/14))
- Add `enduser.id` and `enduser.pseudo.id`, moved from the core semantic
  conventions with their types, examples and PII warnings unchanged from core
  v1.44.0. Core deprecates them in favor of this registry in
  [open-telemetry/semantic-conventions#4238](https://github.com/open-telemetry/semantic-conventions/pull/4238);
  the already-deprecated `enduser.role` and `enduser.scope` stay in core.
  ([#33](https://github.com/open-telemetry/semantic-conventions-client-side/pull/33))
