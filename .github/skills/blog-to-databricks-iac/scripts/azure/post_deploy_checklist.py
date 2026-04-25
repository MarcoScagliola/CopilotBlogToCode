#!/usr/bin/env python3
"""Validate Terraform outputs and Databricks bundle variable wiring after deploy.

This script checks:
1) Terraform output contract required by deploy bridge
2) Databricks bundle variable declarations
3) Job variable usage vs. available defaults and Terraform-derived values

Examples:
  python .github/skills/blog-to-databricks-iac/scripts/azure/post_deploy_checklist.py --contract-only
  python .github/skills/blog-to-databricks-iac/scripts/azure/post_deploy_checklist.py --outputs-json-file infra/terraform/terraform-outputs.json
  python .github/skills/blog-to-databricks-iac/scripts/azure/post_deploy_checklist.py --terraform-dir infra/terraform
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import yaml

# Reuse deploy bridge contract to avoid drift between deploy and validation logic.
from deploy_dab import (  # pylint: disable=import-error
    OPTIONAL_FLAT_KEYS,
    OPTIONAL_MAP_KEYS,
    REQUIRED_FLAT_KEYS,
    build_dab_vars,
    get_tf_outputs,
    get_tf_outputs_from_file,
)

REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent.parent.parent


def _read_yaml(path: Path) -> dict:
    if not path.is_file():
        raise FileNotFoundError(f"YAML file not found: {path}")
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    return data if isinstance(data, dict) else {}


def _extract_job_vars(jobs_file: Path) -> set[str]:
    text = jobs_file.read_text(encoding="utf-8")
    return set(re.findall(r"\$\{var\.([A-Za-z0-9_]+)\}", text))


def _normalize_bundle_vars(bundle_data: dict) -> dict[str, dict]:
    raw_vars = bundle_data.get("variables", {})
    result: dict[str, dict] = {}
    if not isinstance(raw_vars, dict):
        return result

    for name, value in raw_vars.items():
        if isinstance(value, dict):
            result[name] = value
        else:
            result[name] = {}
    return result


def _print_status(ok: bool, label: str, detail: str = "") -> None:
    status = "PASS" if ok else "FAIL"
    if detail:
        print(f"[{status}] {label}: {detail}")
    else:
        print(f"[{status}] {label}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Run post-deploy contract checks for Terraform -> DAB wiring.")
    parser.add_argument("--terraform-dir", default="infra/terraform", help="Terraform directory relative to repo root")
    parser.add_argument(
        "--outputs-json-file",
        default="",
        help="Optional Terraform output JSON file. If omitted, script runs terraform output -json.",
    )
    parser.add_argument("--bundle-dir", default="databricks-bundle", help="Databricks bundle directory")
    parser.add_argument("--environment", default="dev", help="Environment label for bridge resolution")
    parser.add_argument(
        "--contract-only",
        action="store_true",
        help="Validate contract/declarations only and skip live Terraform output resolution.",
    )
    args = parser.parse_args()

    terraform_dir = REPO_ROOT / args.terraform_dir
    bundle_dir = REPO_ROOT / args.bundle_dir
    databricks_yml = bundle_dir / "databricks.yml"
    jobs_yml = bundle_dir / "resources" / "jobs.yml"

    failures: list[str] = []

    try:
        bundle_data = _read_yaml(databricks_yml)
        _print_status(True, "Bundle config exists", str(databricks_yml))
    except Exception as exc:  # pragma: no cover - defensive
        _print_status(False, "Bundle config exists", str(exc))
        return 1

    if not jobs_yml.is_file():
        _print_status(False, "Jobs file exists", str(jobs_yml))
        return 1
    _print_status(True, "Jobs file exists", str(jobs_yml))

    bundle_vars = _normalize_bundle_vars(bundle_data)
    used_job_vars = _extract_job_vars(jobs_yml)

    undeclared_job_vars = sorted(v for v in used_job_vars if v not in bundle_vars)
    if undeclared_job_vars:
        failures.append("Undeclared variables referenced by jobs.yml: " + ", ".join(undeclared_job_vars))
        _print_status(False, "Job var declarations", ", ".join(undeclared_job_vars))
    else:
        _print_status(True, "Job var declarations", f"{len(used_job_vars)} variables referenced and declared")

    # Variables required by jobs at runtime (no default declared in bundle variables)
    runtime_required = sorted(
        v for v in used_job_vars if "default" not in bundle_vars.get(v, {})
    )
    _print_status(True, "Runtime-required job vars", ", ".join(runtime_required) if runtime_required else "none")

    contract_keys = sorted(
        set(REQUIRED_FLAT_KEYS.keys())
        | set(OPTIONAL_FLAT_KEYS.keys())
        | set(OPTIONAL_MAP_KEYS.keys())
    )
    missing_contract_vars = sorted(v for v in contract_keys if v not in bundle_vars)
    if missing_contract_vars:
        failures.append("Bundle missing deploy-bridge contract vars: " + ", ".join(missing_contract_vars))
        _print_status(False, "Deploy bridge var declarations", ", ".join(missing_contract_vars))
    else:
        _print_status(True, "Deploy bridge var declarations", f"{len(contract_keys)} contract vars declared")

    if args.contract_only:
        _print_status(True, "Terraform output resolution", "skipped by --contract-only")
    else:
        try:
            if args.outputs_json_file:
                tf_outputs = get_tf_outputs_from_file(REPO_ROOT / args.outputs_json_file)
                source = args.outputs_json_file
            else:
                tf_outputs = get_tf_outputs(terraform_dir)
                source = str(terraform_dir)
            _print_status(True, "Terraform outputs loaded", source)
        except SystemExit as exc:
            _print_status(False, "Terraform outputs loaded", f"deploy bridge reported failure (exit {exc.code})")
            return 1
        except Exception as exc:  # pragma: no cover - defensive
            _print_status(False, "Terraform outputs loaded", str(exc))
            return 1

        # Required output keys used by deploy bridge.
        missing_required_outputs: list[str] = []
        for _, candidates in REQUIRED_FLAT_KEYS.items():
            if not any(k in tf_outputs and tf_outputs[k] is not None for k in candidates):
                missing_required_outputs.extend(candidates)

        if missing_required_outputs:
            dedup = sorted(set(missing_required_outputs))
            failures.append("Missing required Terraform outputs: " + ", ".join(dedup))
            _print_status(False, "Required Terraform outputs", ", ".join(dedup))
        else:
            _print_status(True, "Required Terraform outputs", "workspace host/resource outputs present")

        try:
            resolvable_vars = build_dab_vars(tf_outputs, args.environment)
            _print_status(True, "Bridge variable resolution", f"resolved {len(resolvable_vars)} vars")
        except SystemExit as exc:
            failures.append(f"Failed resolving bridge vars from Terraform outputs (exit {exc.code})")
            _print_status(False, "Bridge variable resolution", "deploy bridge contract did not resolve")
            resolvable_vars = {}

        unresolved_runtime_vars = sorted(
            v
            for v in runtime_required
            if v not in resolvable_vars and "default" not in bundle_vars.get(v, {})
        )
        if unresolved_runtime_vars:
            failures.append(
                "Runtime-required job vars not resolvable from Terraform outputs/defaults: "
                + ", ".join(unresolved_runtime_vars)
            )
            _print_status(False, "Runtime var resolution", ", ".join(unresolved_runtime_vars))
        else:
            _print_status(True, "Runtime var resolution", "all runtime-required vars resolvable")

    print("\nSummary")
    if failures:
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("- All post-deploy checklist checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
