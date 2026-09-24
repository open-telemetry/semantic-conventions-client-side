# Client-Side Semantic Conventions for OpenTelemetry

A federated OpenTelemetry semantic convention registry for instrumentation that target
client-side applications running on mobile phones, browsers, desktop computers, or
any other end-user device.

This registry follows the federated model established by [OTEP 4815](https://github.com/open-telemetry/opentelemetry-specification/blob/main/oteps/4815-semantic-conventions-schema-v2.md) and augments
general OTel semantic conventions that are mostly defined with backend applications in
mind with ones that are unique to and common amongst client-side application platforms.

It contains YAMLs that defines the semantic conventions for namespaces that it owns
and the associated Markdown files for those conventions. It will host and publish
version-stamped schema URLs representing the public-facing surface of the manifest,
but it does not generate or publish language-specific binaries that make the hosted
conventions consumable in instrumentation.

## Structure

Semantic conventions owned by this registry are defined in YAML files under `/model`.
Using templates defined in `/templates`, Weaver-based tooling will crawl through all
the files in that directory and create the appropriate documentation in `/docs`.

The conventions by which the files and directories within `/model` are organized is
under discussion.

## Versioning

The registry's identity and its version both come from the `schema_url` in
`/model/manifest.yaml`: everything before the last `/` names the registry and the last
segment is its version. Only that last segment ever moves. Changing any part before it
does not produce a new version of this registry, it produces a different registry, and
consumers pinning the old one never see the change.

That name may carry a maturity suffix, which selects which conventions the registry
contains rather than how finished it is. `client-side-dev` holds every convention
whatever its stability. When used without a suffix (i.e. `client-side`), the registry
would hold only the stable subset.

`client-side-dev` and `client-side` are treated as separate registries, published
alongside each other from the same model and versioned in lockstep. The suffix belongs
on both halves of the URL (`client-side-dev/0.1.0-dev`). A registry mixing suffixed and
unsuffixed versions breaks the SemVer ordering that dependency resolution relies on.

Only `client-side-dev` is published today, as nothing here is stable yet. See
[OTEP 4815](https://github.com/open-telemetry/opentelemetry-specification/blob/main/oteps/4815-semantic-conventions-schema-v2.md#schema-url-structure)
for the full rules, and [RELEASING.md](RELEASING.md) for how a version is cut.

## Consuming this registry

Another semantic conventions registry can consume this one by pinning both fields to the same
release in its manifest:

```yaml
- schema_url: https://opentelemetry.io/schemas/client-side-dev/<version>
  registry_path: https://github.com/open-telemetry/semantic-conventions-client-side@v<version>[model]
```

`schema_url` identifies the registry and its version, while `registry_path` is where the
files are actually fetched from. Weaver does not check that the two agree while resolving
a dependency (it will warn though), so bumping one without the other could result in an
unexpected version being pulled in (i.e. the one in `registry_path` will be used).

## Roadmap

We are still in the process of bootstrapping this repo. More details about the roadmap
will follow. If you are interested in participating, join the
[#otel-client-side-telemetry](https://cloud-native.slack.com/archives/C0239SYARD2)
Slack channel or attend the [Client Instrumentation SIG meeting](https://github.com/open-telemetry/community/blob/main/sigs.md#client-instrumentation).

## Maintainers

- [Hanson Ho](https://github.com/bidetofevil), Embrace (Palo Alto Networks)
- [Jared Freeze](https://github.com/overbalance), Embrace (Palo Alto Networks)
- [Martin Kuba](https://github.com/martinkuba), Grafana

For more information about the maintainer role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#maintainer).
