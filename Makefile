# Validation, docs generation and tests for this registry. The same targets are
# run locally and in CI.

SHELL := /usr/bin/env bash

# Weaver and OPA versions, and the shared policy pack, are pinned in versions.env
include versions.env

# Manifests whose dependencies check-policies verifies for schema_url/registry_path agreement.
MANIFESTS := model/manifest.yaml templates_test/fixture/manifest.yaml

.PHONY: all check-policies generate-docs generate-all package test test-templates test-policies \
	update-golden install-weaver install-opa check-weaver check-opa clean help

# Default: validate, then regenerate everything this repo owns.
all: check-policies generate-all

# Validate the model: schema validation, resolution of upstream dependencies, and the shared
# OpenTelemetry policy pack (naming conventions, attribute type rules, stability requirements)
# plus this repo's local policies. Needs network access to fetch the dependencies pinned in
# model/manifest.yaml and the policy pack pinned in versions.env.
#
# Two guards wrap the weaver run:
# - A dependency's schema_url identifies the registry and version, but its registry_path is what
#   weaver actually fetches, and weaver never checks that the two agree. Wherever a registry_path
#   pins a release tag, the schema_url must name the same version. Branch refs have no version to
#   compare, so they are skipped.
# - When the dependency tree requests one registry at different versions (e.g. this registry and
#   one of its dependencies both depend on core), weaver uses the highest and only warns.
#   Treat that as a failure, so the versions declared in model/manifest.yaml are the ones in use.
check-policies: check-weaver
	@set -e; \
	mismatches="$$(awk "$$DEPENDENCY_VERSION_MISMATCHES" $(MANIFESTS))"; \
	if [[ -n "$$mismatches" ]]; then \
	  echo "error: dependency schema_url and registry_path name different releases:" >&2; \
	  echo "$$mismatches" >&2; \
	  echo "Update both fields together." >&2; \
	  exit 1; \
	fi
	@mkdir -p .build
	@set -o pipefail; \
	weaver registry check \
	  -r model \
	  --v2 \
	  --policy "$(POLICY_REPO_URL)@$(POLICY_REPO_REF)[policies/check]" \
	  --policy policies/check/public-attribute-groups 2>&1 | tee .build/check.log
	@if grep -q "Selected version" .build/check.log; then \
	  echo "error: dependencies request different versions of the same registry (see above)." >&2; \
	  echo "Align the version in model/manifest.yaml with the one its other dependents request." >&2; \
	  exit 1; \
	fi

# Regenerate the committed markdown under docs/ from the model. Needs network access. CI fails
# on docs drift, so run this before submitting model or template changes and commit the result.
generate-docs: check-weaver
	rm -rf docs
	weaver registry generate -r model --v2 --templates templates markdown docs

# Every regeneration this repo owns. CI checks that committed output matches this.
generate-all: generate-docs

# Produce the publication manifest and resolved registry under .build/package/. The version is the
# last segment of the schema_url in model/manifest.yaml, and the resolved-registry URI baked into
# the artifacts points at that version's GitHub release, which is where consumers fetch it from.
package: check-weaver
	@set -eu; \
	version="$$(awk '/^schema_url:/ { n = split($$2, parts, "/"); print parts[n]; exit }' model/manifest.yaml)"; \
	repo_url="$$(git remote get-url origin)"; \
	repo_url="$${repo_url%.git}"; \
	case "$$repo_url" in \
	  git@github.com:*) repo_url="https://github.com/$${repo_url#git@github.com:}" ;; \
	esac; \
	rm -rf .build/package; \
	weaver registry package \
	  -r model \
	  --v2 \
	  --resolved-registry-uri "$$repo_url/releases/download/v$$version/resolved.yaml" \
	  -o .build/package; \
	echo "packaged version $$version -> .build/package"

# Every test suite this repo owns. Used locally only, as CI runs these as separate jobs.
test: test-templates test-policies

# Regression test for the doc templates. Compare the docs generated from the fixture with the
# expected golden files, so any change in template output (including imported definitions leaking
# into the docs) shows up as a diff. Run `make update-golden` to update them when a deliberate
# change is made.
test-templates: check-weaver
	@mkdir -p .build
	@rm -rf .build/test-docs
	@set -o pipefail; \
	weaver registry generate \
	  -r templates_test/fixture \
	  --v2 \
	  --templates templates \
	  markdown \
	  .build/test-docs 2>&1 | tee .build/test-templates.log
	@if grep -q "matched nothing" .build/test-templates.log; then \
	  echo "error: a fixture import no longer matches anything upstream." >&2; \
	  echo "The provenance filters are no longer exercised. Update the wildcards in" >&2; \
	  echo "templates_test/fixture/fixture/imports.yaml to match what the pinned dependency exports." >&2; \
	  exit 1; \
	fi
	@if ! git --no-pager diff --no-index --exit-code templates_test/golden .build/test-docs; then \
	  echo "" >&2; \
	  echo "error: generated docs do not match the golden files." >&2; \
	  echo "If the change is intended, refresh them with:" >&2; \
	  echo "    make update-golden" >&2; \
	  exit 1; \
	fi
	@echo "templates OK: fixture output matches templates_test/golden"

# Refresh templates_test/golden/ after a template change that intentionally alters the generated
# output, then review the diff under templates_test/golden/ before committing it.
update-golden: check-weaver
	rm -rf templates_test/golden
	weaver registry generate -r templates_test/fixture --v2 --templates templates markdown templates_test/golden

# Unit-test the local rego policies under policies/ against policies_test/. Pure OPA: no weaver,
# no network. The cases worth covering involve definitions inherited from a dependency, which the
# real model never produces because it declares no `imports` block.
test-policies: check-opa
	opa test --explain fails policies policies_test

# Install the weaver version pinned in versions.env into ~/.local/bin.
install-weaver:
	.github/actions/setup-weaver/install-weaver.sh

# Install the OPA version pinned in versions.env into ~/.local/bin.
install-opa:
	.github/actions/setup-opa/install-opa.sh

# Fail if weaver is not on PATH; warn if it is not the version pinned in versions.env.
check-weaver:
	@command -v weaver >/dev/null 2>&1 || { \
	  echo "error: weaver not found on PATH. Run 'make install-weaver' to install the pinned" >&2; \
	  echo "version, or put a release binary from https://github.com/open-telemetry/weaver/releases on PATH." >&2; \
	  exit 1; \
	}
	@installed="$$(weaver --version | awk '{print $$2}')"; \
	if [[ "$$installed" != "$(WEAVER_VERSION:v%=%)" ]]; then \
	  echo "warning: weaver $$installed installed, but this repo pins $(WEAVER_VERSION:v%=%) (see versions.env)." >&2; \
	fi

# Fail if opa is not on PATH; warn if it is not the version pinned in versions.env.
check-opa:
	@command -v opa >/dev/null 2>&1 || { \
	  echo "error: opa not found on PATH. Run 'make install-opa' to install the pinned version." >&2; \
	  exit 1; \
	}
	@installed="$$(opa version | awk '/^Version:/ { print $$2 }')"; \
	if [[ "$$installed" != "$(OPA_VERSION:v%=%)" ]]; then \
	  echo "warning: opa $$installed installed, but this repo pins $(OPA_VERSION:v%=%) (see versions.env)." >&2; \
	fi

# Remove build output only. docs/ is generated but committed, so it is left alone
clean:
	rm -rf .build

help:
	@echo "check-policies  validate the model (schema + dependencies + policies)"
	@echo "generate-docs   regenerate committed markdown under docs/"
	@echo "generate-all    run every regeneration this repo owns"
	@echo "package         produce the publication artifacts under .build/package/"
	@echo "test            run every test suite (templates + policies)"
	@echo "test-templates  check the doc templates against the golden fixture output"
	@echo "test-policies   unit-test the local rego policies"
	@echo "update-golden   refresh the golden files after an intended template change"
	@echo "install-weaver  install the weaver version pinned in versions.env"
	@echo "install-opa     install the OPA version pinned in versions.env"
	@echo "clean           remove build output"

# awk program for the schema_url/registry_path guard in check-policies: prints one line per
# dependency whose tag-pinned registry_path names a different version than its schema_url.
define DEPENDENCY_VERSION_MISMATCHES
FNR == 1 { url = "" }
/^[[:space:]]*- schema_url:/ { url = $$3; next }
/^[[:space:]]*registry_path:/ && url != "" {
  if (match($$2, /@v[0-9][^[]*\[/)) {
    tag = substr($$2, RSTART + 2, RLENGTH - 3)
    n = split(url, parts, "/")
    if (parts[n] != tag) print "  " FILENAME ": schema_url " url " vs registry_path " $$2
  }
  url = ""
}
endef
export DEPENDENCY_VERSION_MISMATCHES
