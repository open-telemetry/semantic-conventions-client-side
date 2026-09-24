package after_resolution

import rego.v1

# Unit tests for policies/check/public-attribute-groups.
#
# The cases that matter are the dependency ones. A registry with no `imports`
# block never puts a dependency-sourced entry into these collections, so a policy
# that mixes up local and inherited definitions passes every real check today and
# only breaks the day someone adds `imports`. These tests inject that state
# directly instead of waiting for it.

local_attribute(key) := {
	"key": key,
	"provenance": {"path": "/repo/model/app/registry.yaml"},
}

# Inherited from a dependency: `path` is empty for attributes, `source` is set.
imported_attribute(key) := {
	"key": key,
	"provenance": {"source": "https://opentelemetry.io/schemas/1.44.0"},
}

local_group(keys) := {
	"id": "registry.client_side.app",
	"provenance": {"path": "/repo/model/app/registry.yaml"},
	"attributes": [{"key": key} | some key in keys],
}

# An imported signal group keeps a populated `path` pointing at the upstream
# file, which is why `path` cannot be used to tell local from inherited.
imported_group(keys) := {
	"id": "registry.session",
	"provenance": {
		"path": "https://github.com/open-telemetry/semantic-conventions@v1.44.0[model]/session.yaml",
		"source": "https://opentelemetry.io/schemas/1.44.0",
	},
	"attributes": [{"key": key} | some key in keys],
}

test_passes_when_local_attribute_is_exported if {
	count(deny) == 0 with input as {"registry": {
		"attributes": [local_attribute("app.environment")],
		"attribute_groups": [local_group(["app.environment"])],
	}}
}

test_fails_when_local_attribute_is_not_exported if {
	count(deny) == 1 with input as {"registry": {
		"attributes": [local_attribute("app.environment")],
		"attribute_groups": [local_group([])],
	}}
}

# An inherited attribute is not ours to export, so it must never be flagged.
test_ignores_attributes_inherited_from_a_dependency if {
	count(deny) == 0 with input as {"registry": {
		"attributes": [imported_attribute("session.id")],
		"attribute_groups": [local_group([])],
	}}
}

# A group inherited from a dependency is not this registry's export
# surface, so it cannot satisfy the requirement for a local attribute.
test_imported_group_does_not_export_a_local_attribute if {
	count(deny) == 1 with input as {"registry": {
		"attributes": [local_attribute("app.environment")],
		"attribute_groups": [imported_group(["app.environment"])],
	}}
}

test_mixed_registry_flags_only_the_unexported_local_attribute if {
	findings := deny with input as {"registry": {
		"attributes": [
			local_attribute("app.environment"),
			local_attribute("app.nav.destination"),
			imported_attribute("session.id"),
		],
		"attribute_groups": [local_group(["app.environment"])],
	}}

	count(findings) == 1
	some finding in findings
	finding.context.attribute_key == "app.nav.destination"
}

test_finding_has_the_expected_shape if {
	findings := deny with input as {"registry": {
		"attributes": [local_attribute("app.environment")],
		"attribute_groups": [],
	}}

	some finding in findings
	finding.id == "attribute_not_exported"
	finding.level == "violation"
	finding.context.attribute_key == "app.environment"
}

test_empty_registry_is_clean if {
	count(deny) == 0 with input as {"registry": {"attributes": [], "attribute_groups": []}}
}

# A registry that omits a collection entirely must evaluate, not error.
test_tolerates_missing_collections if {
	count(deny) == 0 with input as {"registry": {}}
	count(deny) == 0 with input as {"registry": {"attribute_groups": [local_group([])]}}
	count(deny) == 1 with input as {"registry": {"attributes": [local_attribute("app.environment")]}}
}

# An attribute carrying no provenance at all is treated as local, so a resolved
# registry that stops emitting provenance fails loudly rather than silently
# passing every attribute.
test_attribute_without_provenance_is_treated_as_local if {
	count(deny) == 1 with input as {"registry": {
		"attributes": [{"key": "app.environment"}],
		"attribute_groups": [],
	}}
}
