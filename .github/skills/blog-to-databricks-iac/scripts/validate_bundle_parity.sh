#!/usr/bin/env bash
set -euo pipefail

DEPLOY_SCRIPT="${DEPLOY_SCRIPT:-.github/skills/blog-to-databricks-iac/scripts/azure/deploy_dab.py}"
BUNDLE_YML="${BUNDLE_YML:-databricks-bundle/databricks.yml}"

if [ ! -f "$DEPLOY_SCRIPT" ]; then
  echo "ERROR: $DEPLOY_SCRIPT not found. Run from the repository root." >&2
  exit 2
fi

if [ ! -f "$BUNDLE_YML" ]; then
  echo "ERROR: $BUNDLE_YML not found. Author it via the databricks-yml-authoring skill." >&2
  exit 2
fi

python - "$DEPLOY_SCRIPT" "$BUNDLE_YML" <<'PY'
import ast
import sys
from pathlib import Path

try:
    import yaml
except Exception as exc:  # noqa: BLE001
    print(f"ERROR: PyYAML import failed: {exc}")
    sys.exit(1)

deploy_script = Path(sys.argv[1])
bundle_yml = Path(sys.argv[2])

print("Validating bundle parity with deploy_dab.py")
print(f"  deploy bridge: {deploy_script.as_posix()}")
print(f"  bundle root:   {bundle_yml.as_posix()}")
print()

src = deploy_script.read_text(encoding="utf-8")
mod = ast.parse(src, filename=str(deploy_script))

bridge_vars = set()

def collect_keys_from_dict_node(node):
    if not isinstance(node, ast.Dict):
        return
    for k in node.keys:
        if isinstance(k, ast.Constant) and isinstance(k.value, str):
            bridge_vars.add(k.value)

for node in mod.body:
    if isinstance(node, ast.Assign):
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id in {
                "REQUIRED_FLAT_KEYS",
                "OPTIONAL_FLAT_KEYS",
                "OPTIONAL_MAP_KEYS",
            }:
                collect_keys_from_dict_node(node.value)
    elif isinstance(node, ast.AnnAssign):
        target = node.target
        if isinstance(target, ast.Name) and target.id in {
            "REQUIRED_FLAT_KEYS",
            "OPTIONAL_FLAT_KEYS",
            "OPTIONAL_MAP_KEYS",
        }:
            collect_keys_from_dict_node(node.value)

bundle_doc = yaml.safe_load(bundle_yml.read_text(encoding="utf-8")) or {}
variables = bundle_doc.get("variables", {})
if not isinstance(variables, dict):
    variables = {}

declared_vars = set(variables.keys())
required_vars = set()
for name, body in variables.items():
    if isinstance(body, dict) and "default" in body:
        continue
    required_vars.add(name)

missing_in_bundle = sorted(bridge_vars - declared_vars)
missing_in_bridge = sorted(required_vars - bridge_vars)

print("Check 1: every variable known to deploy_dab.py is declared in the bundle")
if missing_in_bundle:
    print("  FAIL: deploy_dab.py expects variables with no matching declaration in the bundle:")
    for item in missing_in_bundle:
        print(f"    - {item}")
else:
    print(f"  PASS: all {len(bridge_vars)} bridge variables have matching bundle declarations")

print()
print("Check 2: every required bundle variable is passed by deploy_dab.py")
if missing_in_bridge:
    print("  FAIL: bundle declares required variables not passed by deploy_dab.py:")
    for item in missing_in_bridge:
        print(f"    - {item}")
else:
    print(f"  PASS: all {len(required_vars)} required bundle variables are passed")

print()
if missing_in_bundle or missing_in_bridge:
    print("Validation failed: 2 check(s) did not pass.")
    sys.exit(1)

print("Validation passed: bundle is in sync with deploy_dab.py.")
PY
