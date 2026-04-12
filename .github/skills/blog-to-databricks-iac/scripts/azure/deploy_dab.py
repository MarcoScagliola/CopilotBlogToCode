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

REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent.parent

# Maps Terraform output key → DAB variable name
TF_TO_DAB: dict[str, str] = {
    "databricks_workspace_url": "workspace_host",
    "bronze_sp_client_id":      "bronze_sp_client_id",
    "silver_sp_client_id":      "silver_sp_client_id",
    "gold_sp_client_id":        "gold_sp_client_id",
    "uc_catalog_bronze":        "bronze_catalog",
    "uc_catalog_silver":        "silver_catalog",
    "uc_catalog_gold":          "gold_catalog",
    "secret_scope_name":        "secret_scope",
}


def _fail(reason: str) -> None:
    print(f"ERROR: {reason}", file=sys.stderr)
    sys.exit(1)


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

    return {k: v["value"] for k, v in raw.items()}


def build_dab_vars(tf_outputs: dict[str, str], environment: str) -> dict[str, str]:
    dab_vars: dict[str, str] = {"environment": environment}
    missing: list[str] = []

    for tf_key, dab_key in TF_TO_DAB.items():
        if tf_key not in tf_outputs:
            missing.append(tf_key)
        else:
            dab_vars[dab_key] = str(tf_outputs[tf_key])

    if missing:
        print("WARNING: The following Terraform outputs were not found and will be skipped:", file=sys.stderr)
        for m in missing:
            print(f"  - {m}", file=sys.stderr)
        print("  Run `terraform apply` to ensure all outputs are available.", file=sys.stderr)

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

    if not terraform_dir.is_dir():
        _fail(f"Terraform directory not found: {terraform_dir}")
    if not bundle_dir.is_dir():
        _fail(f"Bundle directory not found: {bundle_dir}")

    print(f"Reading Terraform outputs from: {terraform_dir}")
    try:
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
