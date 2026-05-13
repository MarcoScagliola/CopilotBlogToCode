#!/usr/bin/env bash
# validate_handler_coverage.sh
# Structural check that deploy-infrastructure recovery handler covers documented
# import/error patterns from the terraform skill.

set -euo pipefail

WORKFLOW_FILE="${WORKFLOW_FILE:-.github/workflows/deploy-infrastructure.yml}"
TF_SKILL_FILE="${TF_SKILL_FILE:-.github/skills/terraform/SKILL.md}"

if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "ERROR: $WORKFLOW_FILE not found." >&2
  exit 2
fi

if [ ! -f "$TF_SKILL_FILE" ]; then
  echo "ERROR: $TF_SKILL_FILE not found." >&2
  exit 2
fi

fail_count=0

echo "Validating recovery handler coverage"
echo "  workflow: $WORKFLOW_FILE"

echo "Check 1: handles Key Vault import pattern"
if grep -q "azurerm_key_vault.main" "$WORKFLOW_FILE"; then
  echo "  PASS"
else
  echo "  FAIL: azurerm_key_vault.main import handling not found"
  fail_count=$((fail_count + 1))
fi

echo "Check 2: handles already-exists error class"
if grep -qi "already exists - to be managed via Terraform" "$WORKFLOW_FILE"; then
  echo "  PASS"
else
  echo "  FAIL: already-exists recovery branch not found"
  fail_count=$((fail_count + 1))
fi

echo "Check 3: fallback branch present for out-of-scope resource imports"
if grep -qi "manual intervention required\|Initial terraform apply failed" "$WORKFLOW_FILE"; then
  echo "  PASS"
else
  echo "  FAIL: no fallback branch detected"
  fail_count=$((fail_count + 1))
fi

if [ $fail_count -gt 0 ]; then
  echo "Validation failed: $fail_count check(s) did not pass."
  exit 1
fi

echo "Validation passed: recovery handler has baseline coverage checks."
