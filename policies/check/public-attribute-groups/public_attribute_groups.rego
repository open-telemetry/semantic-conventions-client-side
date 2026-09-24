package after_resolution

import rego.v1

# Public attribute groups are this registry's stable export surface. Consumers
# import attributes by group id, so an attribute missing from its domain's
# group is silently invisible downstream. This policy makes that an error,
# meaning every locally-defined attribute must be referenced by at least one
# attribute group.
#
# Only `visibility: public` groups can satisfy this. Weaver erases
# `visibility: internal` groups during resolution, so they never reach this
# policy's input at all.
#
# Local vs. dependency is decided by `provenance.source`, which holds the
# dependency's schema URL and is empty only for definitions this registry owns.
#
# Every collection read here is fetched with a default, so a registry that omits
# one (or an empty registry) is evaluated rather than skipped.

# Attribute keys exported by an attribute group this registry defines. Groups
# imported from a dependency are not our export surface, so they do not count.
group_member_keys contains key if {
	some group in object.get(input, ["registry", "attribute_groups"], [])
	is_local(group)
	some attr in object.get(group, "attributes", [])
	key := attr.key
}

deny contains finding if {
	some attr in object.get(input, ["registry", "attributes"], [])
	is_local(attr)
	not group_member_keys[attr.key]

	finding := {
		"id": "attribute_not_exported",
		"context": {"attribute_key": attr.key},
		"message": sprintf(
			"Attribute '%s' is not referenced by any attribute group. Add it to its domain's public group or consumers will not receive it.",
			[attr.key],
		),
		"level": "violation",
	}
}

# An entry defined by this registry rather than inherited from a dependency.
is_local(entry) if {
	object.get(entry, ["provenance", "source"], null) == null
}
