#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent.parent


def _error(code: str, reason: str, details: str = "") -> dict:
    err = {"error": True, "code": code, "reason": reason}
    if details:
        err["details"] = details
    return err


def _fail(code: str, reason: str, details: str = "") -> None:
    print(json.dumps(_error(code, reason, details)), file=sys.stderr)
    sys.exit(1)


# Files generated from the blog-to-code workflow.
GENERATED_FILES = [
    REPO_ROOT / "SPEC.md",
    REPO_ROOT / "TODO.md",
    REPO_ROOT / ".github" / "workflows" / "validate-terraform.yml",
    REPO_ROOT / ".github" / "workflows" / "deploy-infrastructure.yml",
    REPO_ROOT / ".github" / "workflows" / "deploy-dab.yml",
]

# Generated code directories. Their contents will be removed,
# then the folder skeleton will be recreated.
GENERATED_DIRS = [
    REPO_ROOT / "infra" / "terraform",
    REPO_ROOT / "databricks-bundle",
]

# Directories to recreate after cleanup so the repo stays structured.
SKELETON_DIRS = [
    REPO_ROOT / "infra" / "terraform",
    REPO_ROOT / "databricks-bundle",
    REPO_ROOT / "databricks-bundle" / "resources",
    REPO_ROOT / "databricks-bundle" / "src",
]

# Files to recreate as placeholders after reset.
SKELETON_FILES = [
    REPO_ROOT / "infra" / "terraform" / ".gitkeep",
    REPO_ROOT / "databricks-bundle" / ".gitkeep",
    REPO_ROOT / "databricks-bundle" / "resources" / ".gitkeep",
    REPO_ROOT / "databricks-bundle" / "src" / ".gitkeep",
]


def remove_path(path: Path, dry_run: bool) -> None:
    if not path.exists():
        return

    rel = path.relative_to(REPO_ROOT)

    if dry_run:
        print(f"[dry-run] remove {rel}")
        return

    try:
        if path.is_dir():
            shutil.rmtree(path)
            print(f"removed directory: {rel}")
        else:
            path.unlink()
            print(f"removed file: {rel}")
    except PermissionError as e:
        _fail("PERMISSION_ERROR", f"Cannot remove {rel}", str(e))
    except OSError as e:
        _fail("OS_ERROR", f"Failed to remove {rel}", str(e))
    except Exception as e:
        _fail("UNEXPECTED_ERROR", f"Unexpected error removing {rel}", str(e))


def recreate_skeleton(dry_run: bool) -> None:
    for directory in SKELETON_DIRS:
        rel = directory.relative_to(REPO_ROOT)
        if dry_run:
            print(f"[dry-run] create dir {rel}")
        else:
            try:
                directory.mkdir(parents=True, exist_ok=True)
            except PermissionError as e:
                _fail("PERMISSION_ERROR", f"Cannot create directory {rel}", str(e))
            except OSError as e:
                _fail("OS_ERROR", f"Failed to create directory {rel}", str(e))
            except Exception as e:
                _fail("UNEXPECTED_ERROR", f"Unexpected error creating directory {rel}", str(e))

    for file_path in SKELETON_FILES:
        rel = file_path.relative_to(REPO_ROOT)
        if dry_run:
            print(f"[dry-run] create file {rel}")
        else:
            try:
                file_path.parent.mkdir(parents=True, exist_ok=True)
                file_path.touch(exist_ok=True)
            except PermissionError as e:
                _fail("PERMISSION_ERROR", f"Cannot create file {rel}", str(e))
            except OSError as e:
                _fail("OS_ERROR", f"Failed to create file {rel}", str(e))
            except Exception as e:
                _fail("UNEXPECTED_ERROR", f"Unexpected error creating file {rel}", str(e))


def confirm(force: bool) -> None:
    if force:
        return

    print("This will remove generated Terraform, Databricks bundle files, SPEC.md, TODO.md, validate-terraform.yml, deploy-infrastructure.yml, and deploy-dab.yml.")
    print("It will keep the Copilot skill scaffold under .github/skills/.")
    try:
        reply = input("Continue? [y/N]: ").strip().lower()
    except (EOFError, KeyboardInterrupt):
        print("\nAborted.")
        sys.exit(0)
    if reply not in {"y", "yes"}:
        print("Aborted.")
        sys.exit(0)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Remove generated code so you can rerun the workflow with another blog."
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Run without interactive confirmation.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be removed without deleting anything.",
    )
    args = parser.parse_args()

    confirm(force=args.force)

    try:
        _run(args)
    except KeyboardInterrupt:
        print("\nInterrupted. Some files may have been partially removed.")
        sys.exit(1)


def _run(args: argparse.Namespace) -> None:
    if not REPO_ROOT.is_dir():
        _fail("INVALID_ROOT", "Computed REPO_ROOT does not exist", str(REPO_ROOT))

    if not (REPO_ROOT / ".github").is_dir():
        _fail("INVALID_ROOT", "REPO_ROOT does not look like the repo root (.github/ missing)", str(REPO_ROOT))

    for file_path in GENERATED_FILES:
        remove_path(file_path, dry_run=args.dry_run)

    for dir_path in GENERATED_DIRS:
        remove_path(dir_path, dry_run=args.dry_run)

    recreate_skeleton(dry_run=args.dry_run)

    print("Reset complete." if not args.dry_run else "Dry run complete.")


if __name__ == "__main__":
    main()