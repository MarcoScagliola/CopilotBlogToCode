#!/usr/bin/env python3
"""
deploy_dab.py — Bridge Terraform outputs to Databricks Asset Bundle deploy.

Reads `terraform output -json` from the Terraform directory and assembles
a `databricks bundle deploy` command with all required -v flags pre-filled
from those outputs. Run with --run to execute immediately, or omit to just
print the generated command.

Usage:
    python scripts/azure/deploy_dab.py [--target dev] [--environment dev] [--run]
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent.parent.parent

# Maps DAB variable name -> Terraform output keys (new names first, then backward-compatible aliases)
DAB_TO_TF_KEYS: dict[str, list[str]] = {
    "workspace_host": ["databricks_workspace_url"],
    "workspace_resource_id": ["databricks_workspace_resource_id"],
    "bronze_sp_client_id": ["bronze_sp_application_id", "bronze_sp_client_id"],
    "silver_sp_client_id": ["silver_sp_application_id", "silver_sp_client_id"],
    "gold_sp_client_id": ["gold_sp_application_id", "gold_sp_client_id"],
    "bronze_catalog": ["bronze_catalog_name", "uc_catalog_bronze"],
    "silver_catalog": ["silver_catalog_name", "uc_catalog_silver"],
    "gold_catalog": ["gold_catalog_name", "uc_catalog_gold"],
    "secret_scope": ["secret_scope_name"],
}


def _fail(reason: str) -> None:
    print(f"ERROR: {reason}", file=sys.stderr)
    sys.exit(1)


def _normalize_tf_output_json(raw: dict) -> dict[str, str]:
    normalized: dict[str, str] = {}
    for k, v in raw.items():
        if isinstance(v, dict) and "value" in v:
            normalized[k] = v["value"]
        else:
            normalized[k] = v
    return normalized


def get_tf_outputs(terraform_dir: Path) -> dict[str, str]:
    tf_bin = shutil.which("terraform")
    if not tf_bin:
        _fail("terraform CLI not found in PATH. Install from https://developer.hashicorp.com/terraform/install")

    try:
        result = subprocess.run(
            [tf_bin, "output", "-json"],
            cwd=terraform_dir,
            capture_output=True,
            text=True,
            check=True,
        )
    except subprocess.CalledProcessError as e:
        _fail(f"terraform output failed:\n{e.stderr.strip()}")
    except FileNotFoundError:
        _fail(f"terraform binary not executable: {tf_bin}")
    except OSError as e:
        _fail(f"Failed to run terraform: {e}")

    if not result.stdout.strip():
        _fail(
            "terraform output returned empty output. "
            "Have you run `terraform apply` in this directory first?"
        )

    try:
        raw = json.loads(result.stdout)
    except json.JSONDecodeError as e:
        _fail(f"Could not parse terraform output JSON: {e}")

    return _normalize_tf_output_json(raw)


def get_tf_outputs_from_file(outputs_json_file: Path) -> dict[str, str]:
    if not outputs_json_file.is_file():
        _fail(f"Terraform outputs JSON file not found: {outputs_json_file}")

    try:
        raw = json.loads(outputs_json_file.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        _fail(f"Could not parse outputs JSON file: {e}")
    except OSError as e:
        _fail(f"Failed reading outputs JSON file: {e}")

    if not isinstance(raw, dict):
        _fail("Outputs JSON file has invalid format: expected object at root")

    return _normalize_tf_output_json(raw)


def build_dab_vars(tf_outputs: dict[str, str], environment: str) -> dict[str, str]:
    dab_vars: dict[str, str] = {"environment": environment}
    missing: list[str] = []

    for dab_key, candidate_tf_keys in DAB_TO_TF_KEYS.items():
        selected_key = next((k for k in candidate_tf_keys if k in tf_outputs), None)
        if not selected_key:
            missing.append(f"{dab_key} (expected one of: {', '.join(candidate_tf_keys)})")
            continue
        dab_vars[dab_key] = str(tf_outputs[selected_key])

    if missing:
        _fail(
            "Missing required Terraform outputs for DAB deployment:\n"
            + "\n".join(f"  - {m}" for m in missing)
        )

    return dab_vars


def build_command(bundle_dir: Path, target: str, dab_vars: dict[str, str]) -> list[str]:
    db_bin = shutil.which("databricks")
    if not db_bin:
        _fail("databricks CLI not found in PATH. Install from https://docs.databricks.com/dev-tools/cli/install.html")

    cmd = [db_bin, "bundle", "deploy", "--target", target]
    for k, v in dab_vars.items():
        cmd += ["-v", f"{k}={v}"]

    return cmd


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Bridge Terraform outputs to databricks bundle deploy.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--terraform-dir",
        default="infra/terraform",
        help="Terraform directory relative to repo root. Default: infra/terraform",
    )
    parser.add_argument(
        "--outputs-json-file",
        default="",
        help="Optional path to a Terraform output -json file. If set, skips calling terraform output.",
    )
    parser.add_argument(
        "--bundle-dir",
        default="databricks-bundle",
        help="DAB directory relative to repo root. Default: databricks-bundle",
    )
    parser.add_argument(
        "--target",
        default="dev",
        choices=["dev", "prd"],
        help="DAB target to deploy to. Default: dev",
    )
    parser.add_argument(
        "--environment",
        default="dev",
        help="Value passed as the 'environment' bundle variable. Default: dev",
    )
    parser.add_argument(
        "--run",
        action="store_true",
        help="Execute the deploy command. Without this flag the command is only printed.",
    )
    args = parser.parse_args()

    terraform_dir = REPO_ROOT / args.terraform_dir
    bundle_dir = REPO_ROOT / args.bundle_dir

    if args.outputs_json_file:
        outputs_json_file = REPO_ROOT / args.outputs_json_file
    else:
        outputs_json_file = None

    if outputs_json_file is None and not terraform_dir.is_dir():
        _fail(f"Terraform directory not found: {terraform_dir}")
    if not bundle_dir.is_dir():
        _fail(f"Bundle directory not found: {bundle_dir}")

    if outputs_json_file is not None:
        print(f"Reading Terraform outputs from JSON file: {outputs_json_file}")
    else:
        print(f"Reading Terraform outputs from: {terraform_dir}")

    try:
        if outputs_json_file is not None:
            tf_outputs = get_tf_outputs_from_file(outputs_json_file)
        else:
            tf_outputs = get_tf_outputs(terraform_dir)
    except SystemExit:
        raise
    except Exception as e:
        _fail(f"Unexpected error reading Terraform outputs: {e}")

    dab_vars = build_dab_vars(tf_outputs, args.environment)
    cmd = build_command(bundle_dir, args.target, dab_vars)

    print("\nGenerated command:")
    print(cmd[0] + " \\\n  " + " \\\n  ".join(cmd[1:]))

    if not args.run:
        print("\nRun with --run to execute the deploy.")
        return

    print("\nRunning deploy...")
    try:
        subprocess.run(cmd, cwd=bundle_dir, check=True)
    except subprocess.CalledProcessError as e:
        print(f"\nERROR: databricks bundle deploy failed (exit code {e.returncode})", file=sys.stderr)
        sys.exit(e.returncode)
    except FileNotFoundError:
        _fail("databricks CLI disappeared after check — ensure it is on PATH")
    except OSError as e:
        _fail(f"Failed to launch databricks CLI: {e}")
    except KeyboardInterrupt:
        print("\nInterrupted.", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
