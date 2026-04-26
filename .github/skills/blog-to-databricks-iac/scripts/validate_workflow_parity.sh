#!/usr/bin/env bash
#
# validate_workflow_parity.sh
#
# Validates that the deploy-infrastructure workflow stays in sync with
# infra/terraform/variables.tf, and that terraform apply invocations
# fail fast in CI.
#
# Checks performed:
#   1. Every required variable (no default) declared in variables.tf has a
#      corresponding TF_VAR_<name>: export in the workflow.
#   2. Every `terraform ... apply` invocation in the workflow includes
#      -input=false (so any future variable mismatch fails immediately
#      instead of hanging on interactive prompts).
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
VARIABLES_TF="${VARIABLES_TF:-infra/terraform/variables.tf}"
WORKFLOW_FILE="${WORKFLOW_FILE:-.github/workflows/deploy-infrastructure.yml}"

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
fail_count=0

if [ ! -f "$VARIABLES_TF" ]; then
  echo "ERROR: $VARIABLES_TF not found. Run from the repository root." >&2
  exit 2
fi

if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "ERROR: $WORKFLOW_FILE not found. Generate it first with generate_deploy_workflow.py." >&2
  exit 2
fi

echo "Validating workflow parity with variables.tf"
echo "  variables.tf: $VARIABLES_TF"
echo "  workflow:     $WORKFLOW_FILE"
echo

# ---------------------------------------------------------------------------
# Check 1: every required variable in variables.tf has a TF_VAR_<name>
#          export in the workflow.
# ---------------------------------------------------------------------------
echo "Check 1: TF_VAR_* parity with variables.tf required variables"

# Extract required variable names. A variable is required if its block
# does NOT contain a `default` line. We walk the file block by block.
required_vars=()
current_var=""
in_block=0
has_default=0

while IFS= read -r line; do
  if [[ "$line" =~ ^variable[[:space:]]+\"([^\"]+)\" ]]; then
    # Closing the previous block (if any) without seeing a default.
    if [ $in_block -eq 1 ] && [ $has_default -eq 0 ] && [ -n "$current_var" ]; then
      required_vars+=("$current_var")
    fi
    current_var="${BASH_REMATCH[1]}"
    in_block=1
    has_default=0
  elif [ $in_block -eq 1 ] && [[ "$line" =~ ^\}[[:space:]]*$ ]]; then
    if [ $has_default -eq 0 ] && [ -n "$current_var" ]; then
      required_vars+=("$current_var")
    fi
    current_var=""
    in_block=0
    has_default=0
  elif [ $in_block -eq 1 ] && [[ "$line" =~ ^[[:space:]]+default[[:space:]]*= ]]; then
    has_default=1
  fi
done < "$VARIABLES_TF"

# Catch the trailing block if the file does not end with a closing brace
# on its own line.
if [ $in_block -eq 1 ] && [ $has_default -eq 0 ] && [ -n "$current_var" ]; then
  required_vars+=("$current_var")
fi

if [ ${#required_vars[@]} -eq 0 ]; then
  echo "  WARN: no required variables found in $VARIABLES_TF"
  echo "        (either every variable has a default, or the file is empty)"
fi

missing=()
for var in "${required_vars[@]}"; do
  if ! grep -qE "TF_VAR_${var}:" "$WORKFLOW_FILE"; then
    missing+=("$var")
  fi
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "  FAIL: variables.tf declares required variables with no TF_VAR_* export in workflow:"
  printf '    - %s\n' "${missing[@]}"
  echo
  echo "  Failure mode: terraform apply will fall back to interactive prompts"
  echo "  in CI and hang until runner timeout. Update generate_deploy_workflow.py"
  echo "  to emit TF_VAR_<name>: for each required variable, then regenerate."
  fail_count=$((fail_count + 1))
else
  echo "  PASS: all ${#required_vars[@]} required Terraform variables have TF_VAR_* exports"
fi
echo

# ---------------------------------------------------------------------------
# Check 2: every `terraform ... apply` invocation in the workflow has
#          -input=false. Without it, future variable drift hangs CI on
#          interactive prompts.
# ---------------------------------------------------------------------------
echo "Check 2: -input=false on every terraform apply invocation"

# Match lines that invoke `terraform apply`, allowing flags between the two
# words (e.g. `terraform -chdir=infra/terraform apply`). Excludes lines that
# already contain -input=false.
bad_lines=$(grep -nE 'terraform([[:space:]]+-[^[:space:]]+)*[[:space:]]+apply' "$WORKFLOW_FILE" \
  | grep -v -- '-input=false' || true)

if [ -n "$bad_lines" ]; then
  echo "  FAIL: terraform apply invocations missing -input=false:"
  echo "$bad_lines" | while IFS= read -r line; do
    echo "    $line"
  done
  echo
  echo "  Failure mode: a future variable mismatch will hang the runner on"
  echo "  interactive prompts instead of failing in seconds."
  fail_count=$((fail_count + 1))
else
  echo "  PASS: all terraform apply invocations use -input=false"
fi
echo

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------
if [ $fail_count -gt 0 ]; then
  echo "Validation failed: $fail_count check(s) did not pass."
  exit 1
fi

echo "Validation passed: workflow is in sync with variables.tf."
exit 0