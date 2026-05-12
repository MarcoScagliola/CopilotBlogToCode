#!/usr/bin/env bash
#
# validate_bundle_parity.sh
#
# Validates that the DAB deploy bridge (deploy_dab.py) stays in sync with
# the variable declarations in databricks-bundle/databricks.yml and any
# file matched by its include: glob.
#
# Checks performed:
#   1. Every --var <name>=<value> flag emitted by deploy_dab.py has a
#      corresponding declaration under `variables:` in the bundle.
#   2. Every variable declared under `variables:` in the bundle is passed
#      by deploy_dab.py as a --var flag (with the exception of variables
#      that have a `default:`, which the bundle may resolve without an
#      explicit override).
#
# Exit codes:
#   0  all checks passed
#   1  one or more checks failed
#   2  required input files are missing
#
# Run from the repository root.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configurable paths
# ---------------------------------------------------------------------------
DEPLOY_SCRIPT="${DEPLOY_SCRIPT:-.github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py}"
BUNDLE_YML="${BUNDLE_YML:-databricks-bundle/databricks.yml}"
BUNDLE_RESOURCES_DIR="${BUNDLE_RESOURCES_DIR:-databricks-bundle/resources}"

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
fail_count=0

if [ ! -f "$DEPLOY_SCRIPT" ]; then
  echo "ERROR: $DEPLOY_SCRIPT not found. Run from the repository root." >&2
  exit 2
fi

if [ ! -f "$BUNDLE_YML" ]; then
  echo "ERROR: $BUNDLE_YML not found. Author it via the databricks-yml-authoring skill." >&2
  exit 2
fi

echo "Validating bundle parity with deploy_dab.py"
echo "  deploy bridge: $DEPLOY_SCRIPT"
echo "  bundle root:   $BUNDLE_YML"
echo

# ---------------------------------------------------------------------------
# Extract --var names from deploy_dab.py.
#
# Pattern accepted: a literal "--var" token followed (after whitespace,
# which may include line continuations) by "<name>=". We only care about
# the name; the value side is irrelevant for parity.
# ---------------------------------------------------------------------------
cli_vars=()
while IFS= read -r name; do
  [ -n "$name" ] && cli_vars+=("$name")
done < <(
  grep -oE -- '--var[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*=' "$DEPLOY_SCRIPT" \
    | sed -E 's/.*--var[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/' \
    | sort -u
)

# ---------------------------------------------------------------------------
# Extract declared variable names (and whether each has a default) from
# databricks.yml and any *.yml/*.yaml under the resources directory.
#
# A variable is "required" (from the bundle's perspective) if its block
# does NOT include a `default:` key. Variables with a default may legally
# be omitted by the deploy bridge.
# ---------------------------------------------------------------------------
declared_vars=()
required_declared_vars=()

parse_yaml_variables() {
  # Walks a YAML file and emits one line per declared variable in the form
  # "<name>\t<required|default>". Operates on textual indentation; assumes
  # the conventional layout produced by the databricks-yml-authoring skill
  # (top-level `variables:` block, two-space indent per level).
  local file="$1"
  awk '
    BEGIN { in_vars = 0; current = ""; has_default = 0 }
    /^variables:[[:space:]]*$/ { in_vars = 1; next }
    in_vars && /^[^[:space:]]/ {
      if (current != "") print current "\t" (has_default ? "default" : "required");
      in_vars = 0; current = ""; has_default = 0; next
    }
    in_vars && /^  [a-zA-Z_][a-zA-Z0-9_]*:[[:space:]]*$/ {
      if (current != "") print current "\t" (has_default ? "default" : "required");
      sub(/^  /, ""); sub(/:.*$/, "");
      current = $0; has_default = 0; next
    }
    in_vars && /^    default:/ { has_default = 1 }
    END {
      if (current != "") print current "\t" (has_default ? "default" : "required");
    }
  ' "$file"
}

collect_declared() {
  local file="$1"
  while IFS=$'\t' read -r name kind; do
    [ -z "$name" ] && continue
    declared_vars+=("$name")
    if [ "$kind" = "required" ]; then
      required_declared_vars+=("$name")
    fi
  done < <(parse_yaml_variables "$file")
}

collect_declared "$BUNDLE_YML"

if [ -d "$BUNDLE_RESOURCES_DIR" ]; then
  for f in "$BUNDLE_RESOURCES_DIR"/*.yml "$BUNDLE_RESOURCES_DIR"/*.yaml; do
    [ -f "$f" ] || continue
    collect_declared "$f"
  done
fi

# De-duplicate while preserving sortability.
declared_vars=($(printf '%s\n' "${declared_vars[@]:-}" | sort -u | grep -v '^$' || true))
required_declared_vars=($(printf '%s\n' "${required_declared_vars[@]:-}" | sort -u | grep -v '^$' || true))

if [ ${#declared_vars[@]} -eq 0 ]; then
  echo "  WARN: no variables found under \`variables:\` in $BUNDLE_YML"
  echo "        (either the file is empty or its layout is non-conventional)"
fi

# ---------------------------------------------------------------------------
# Check 1: every --var passed by the deploy bridge is declared in the bundle.
# ---------------------------------------------------------------------------
echo "Check 1: every --var emitted by deploy_dab.py is declared in the bundle"

missing_in_bundle=()
for var in "${cli_vars[@]+"${cli_vars[@]}"}"; do
  found=0
  for d in "${declared_vars[@]+"${declared_vars[@]}"}"; do
    if [ "$var" = "$d" ]; then found=1; break; fi
  done
  if [ $found -eq 0 ]; then
    missing_in_bundle+=("$var")
  fi
done

if [ ${#missing_in_bundle[@]} -gt 0 ]; then
  echo "  FAIL: deploy_dab.py passes --var flags with no matching declaration in the bundle:"
  printf '    - %s\n' "${missing_in_bundle[@]}"
  echo
  echo "  Failure mode: 'databricks bundle deploy' will reject the run with"
  echo "  'Error: variable <name> has not been defined' and exit non-zero."
  echo "  Update the databricks-yml-authoring skill to declare every per-layer"
  echo "  variable family at full cardinality, then regenerate databricks.yml."
  fail_count=$((fail_count + 1))
else
  echo "  PASS: all ${#cli_vars[@]} --var flags have matching bundle declarations"
fi
echo

# ---------------------------------------------------------------------------
# Check 2: every required (no-default) bundle variable is passed by the
#          deploy bridge. Variables with a default may legally be omitted.
# ---------------------------------------------------------------------------
echo "Check 2: every required bundle variable is passed by deploy_dab.py"

missing_in_workflow=()
for var in "${required_declared_vars[@]:-}"; do
  found=0
  for c in "${cli_vars[@]:-}"; do
    if [ "$var" = "$c" ]; then found=1; break; fi
  done
  if [ $found -eq 0 ]; then
    missing_in_workflow+=("$var")
  fi
done

if [ ${#missing_in_workflow[@]} -gt 0 ]; then
  echo "  FAIL: bundle declares required variables not passed by deploy_dab.py:"
  printf '    - %s\n' "${missing_in_workflow[@]}"
  echo
  echo "  Failure mode: the bundle will fail at resolve time with an unset"
  echo "  required variable, or worse, will silently inherit a stale value"
  echo "  from a previous deploy. Update deploy_dab.py to emit a --var flag"
  echo "  for each required bundle variable, then regenerate."
  fail_count=$((fail_count + 1))
else
  echo "  PASS: all ${#required_declared_vars[@]} required bundle variables are passed"
fi
echo

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
if [ $fail_count -gt 0 ]; then
  echo "Validation failed: $fail_count check(s) did not pass."
  exit 1
fi

echo "Validation passed: bundle is in sync with deploy_dab.py."
exit 0