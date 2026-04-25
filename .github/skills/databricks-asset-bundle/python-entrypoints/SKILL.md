---
name: python-entrypoints
description: "Author or update Python entrypoint files for Databricks Asset Bundle jobs (typically src/<job>/main.py). Use when creating, replacing, or modifying any runtime entrypoint invoked by a spark_python_task. Enforces full-file replacement, single-main singleton structure, explicit argparse contracts, and runtime-only secret handling. Companion to the broader databricks-asset-bundle skill."
---

# Python Entrypoint Authoring

## Purpose
This skill governs the authoring of a single class of file: Python entrypoints invoked by Databricks job tasks. The conventional location is `src/<job>/main.py`, but the path varies by repository. Follow the repo's existing structure rather than imposing a fixed layout.
This skill is a companion to the broader `databricks-asset-bundle` skill. Use this skill whenever the task touches an entrypoint file specifically. Defer to the broader skill for job topology, parameter flow across the full chain, and bundle-level coordination.

## Singleton Rule
Every Python entrypoint is a singleton artifact. Each file must contain at most one of each of the following top-level definitions:
- module docstring
- `def main(...)` function
- `if __name__ == "__main__":` guard
- `argparse.ArgumentParser` construction (located inside `main()`)

When re-authoring an entrypoint:
1. Always replace the entire file. Never append to it, and never patch around content that exists below the first `main()`.
2. Before writing, discard the previous contents rather than treating them as a substrate to edit.
3. After writing, scan the file and fail if any of the listed structural elements appears more than once, or if any executable code appears below the `__main__` guard.

A file with two `main()` definitions is functionally broken even when the parser tolerates it: only one is reachable, argument contracts can drift between the two without raising errors, and runtime behavior depends on definition order. Treat this as the same class of bug as duplicated top-level keys in a YAML singleton.

## Tool Selection
Entrypoint files have replacement semantics, not patch semantics. The entire file is the authoring agent's responsibility on every change.

Choose tools accordingly:
1. Prefer a file-creation or overwrite tool that writes complete content in one operation.
2. Avoid patch- or diff-shaped tools (range replace, hunk apply) for these files. They create opportunities to leave stale content below the modified region.
3. If a patch tool fails or is unavailable, fall back immediately to full-file write rather than chaining further patches.

This is a hard rule. Do not optimize for "minimal diff" on entrypoint files — minimal diffs are the mechanism that produces stale tails.

## Required Structure
Every entrypoint this skill produces follows this shape, in this order:

```python
"""<module docstring describing what the job does>"""

import argparse
import logging
# other imports

# module-level helpers (private, prefixed with _)

def main() -> None:
    parser = argparse.ArgumentParser(...)
    parser.add_argument(...)
    args = parser.parse_args()

    # job logic, using args

if __name__ == "__main__":
    main()
```

Sections that must not appear:
- Code below the `__main__` guard
- A second `def main(`
- A second `if __name__ == "__main__":` guard
- Hardcoded credentials, tokens, or connection strings
- Hardcoded environment-specific values (catalog names, schema names, hostnames, scope names) when the same values are also passed as arguments

## Authoring Procedure
Follow these steps in order.

### Step 1. Establish the argument contract
Before writing any code, identify the full list of arguments the entrypoint will accept. Sources:
- the parameter list passed to this entrypoint in the bundle's resource files
- any documented contract in the broader `.github\skills\databricks-asset-bundle\` skill or repo docs
- the values the deploy bridge maps from infrastructure outputs

Every value the job needs at runtime should be either:
1. an explicit argparse argument, or
2. a runtime secret read from a secret store (never an argument)

No environment-specific value should be hardcoded in the file.

### Step 2. Choose argument naming
Use `--kebab-case` flag names, which argparse maps to `snake_case` attributes on `args`. Names should describe what the value *is*, not its source — `--catalog` not `--bronze-catalog-from-tf`.

If the resource file passes a parameter as `${var.bronze_catalog}` to a `--catalog` flag, that mapping is explicit in the resource file. The entrypoint sees only `--catalog`. The bundle variable's name and the entrypoint's flag name need not match, but the mapping in the resource file must be unambiguous.

### Step 3. Write the entrypoint
Construct the file content in full before writing. The file should:

1. Open with a module docstring summarizing the job's purpose and outputs.
2. Import only what is used.
3. Configure logging at module load. Do not configure logging inside `main()`.
4. Define helpers at module level, prefixed with `_` to mark them as private.
5. Define `main()` with explicit argument parsing as its first action.
6. End with the `__main__` guard. Nothing follows it.

### Step 4. Handle secrets at runtime
If the job needs a secret:
1. Read it inside `main()` via the platform's secret utility, using a scope and key passed as arguments.
2. Never accept the secret value itself as an argument.
3. Never log, print, or include the secret in error messages.
4. Never write the secret to any output the job produces.

The argparse contract may include `--secret-scope` and key-name arguments, but never the secret material.

### Step 5. Build object names from arguments
When the job reads or writes named objects (tables, paths, topics, etc.), construct the fully-qualified name from arguments rather than embedding any component as a literal:

```python
target_table = f"`{args.catalog}`.`{args.schema}`.<table-name>"
```

The static component (the leaf table name in this example) may be a literal when it is part of the job's contract. Environment-varying components (catalog, schema, storage account, scope) must come from arguments.

### Step 6. Final validation
After writing, verify:

1. Exactly one module docstring at the top.
2. Exactly one `def main(`.
3. Exactly one `if __name__ == "__main__":` guard.
4. No code below the `__main__` guard.
5. No `def main(` or `if __name__` appears anywhere except the canonical location.
6. No hardcoded secrets or environment-specific literals.
7. Every `args.<name>` reference corresponds to an `add_argument` call in the same file.
8. The argparse arguments correspond to the parameters passed to this entrypoint by its resource file.

If any check fails, rewrite the file fully. Do not patch.

## Minimal Template
The following is the smallest correct shape. Adapt the docstring, arguments, and body to the job.

```python
"""<one-sentence purpose>. <one-sentence output description>."""

import argparse
import logging

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def main() -> None:
    parser = argparse.ArgumentParser(description="<job description>")
    parser.add_argument("--<flag>", required=True, help="<what this is>")
    args = parser.parse_args()

    log.info("<job> started")
    # job logic
    log.info("<job> complete")


if __name__ == "__main__":
    main()
```

## Anti-Patterns to Reject
Reject any proposed change that would produce:

1. Two or more `def main(` in one file.
2. Two or more `if __name__ == "__main__":` guards in one file.
3. Executable code below the `__main__` guard.
4. Hardcoded secrets, tokens, connection strings, or credentials.
5. Hardcoded environment-specific values that are also passed as arguments.
6. A patch that leaves stale content below the modified region.
7. argparse arguments that have no consumer in the function body.
8. Function-body references to `args.<name>` with no corresponding `add_argument` call.
9. Logging or printing of secret values.
10. Mixing orchestration with business logic — entrypoints are leaves in the job graph; calling other jobs belongs in the bundle's resource files via `run_job_task`, not in Python.

## Relationship to Other Skills
- The broader `databricks-asset-bundle` skill owns job topology, the bundle's resource files, and end-to-end parameter flow. This skill defers to it for anything outside an individual entrypoint file.
- The `databricks-yml-authoring` skill owns `databricks.yml`. Variable names declared there must be reachable through the resource file's parameter list to argparse arguments here, but spellings need not match across the boundary as long as the resource file makes the mapping explicit.
- Any deploy bridge sits upstream of all of this. This skill does not interact with it directly.

## Review Checklist
- [ ] File fully replaced, not appended.
- [ ] Exactly one `def main(`.
- [ ] Exactly one `if __name__ == "__main__":` guard.
- [ ] No code below the `__main__` guard.
- [ ] All argparse arguments are consumed in the function body.
- [ ] All `args.<name>` references have a matching `add_argument` call.
- [ ] argparse contract matches the parameters passed by the resource file.
- [ ] Secrets read at runtime, not accepted as arguments.
- [ ] No secrets logged, printed, or returned.
- [ ] No hardcoded environment-specific values where arguments exist for them.
- [ ] Object names built from arguments rather than embedded literals.
- [ ] No orchestration of other jobs from within Python.