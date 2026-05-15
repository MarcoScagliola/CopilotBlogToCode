# Run Blog To Databricks IaC (Selected Tools)

Use the `blog-to-databricks-iac` skill on this article:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Inputs
- workload: blg
- environment: dev
- azure_region: uksouth
- github_environment: BLG2CODEDEV

## Tool Policy
Use only the tools selected in Configure Tools for this run:
- Built in
- Azure resources
- GitHub Copilot for Azure
- Python

Do not use tools outside the selected set unless I explicitly ask.

## Execution Requirements
1. Run `python .github/skills/blog-to-databricks-iac/scripts/reset_generated.py --force`
2. Do not capture existing Terraform or bundle files as a baseline; treat this as a first-run generation with no prior state.
3. Execute the skill end-to-end.
4. Generate or refresh all expected artifacts (`SPEC.md`, `TODO.md`, Terraform, Databricks bundle, workflows, and plan prompt).
5. Validate outputs:
   - Python compile checks on all generated `.py` files
   - Terraform init/validate
   - YAML parsing on all generated `.yml` files
   - **Templated-not-literal check.** In generated workflow files, run-varying identifiers (environment names, resource names, and mutable paths) must be expressed as workflow expressions sourced from run inputs. Hard-coded generator defaults are a failure unless a field is explicitly documented as literal-only.
   - **Interpolation-constraint check.** In generated fields documented as non-interpolated, values must be literal only; any `${...}` usage in those fields is a failure.
   - **Cross-artifact reference balance.** When a generated artifact references identities, resources, or names created in another generated artifact, count the references on both sides; they must match. Unbalanced sets are a generation failure.
   - **Feature completeness.** When a generated file emits a property that requires supporting infrastructure (as documented in the relevant skill), that supporting infrastructure must be present in the same module. Partial feature families are a generation failure.
   - **External dependency documentation.** Every external name a generated workflow references (secret references, environment names, resource IDs not provisioned by the generated code) must appear in TODO.md with operator action documented.
6. Performance regression check: re-run generators with unchanged inputs and confirm zero diffs against the immediately previous generation.
7. Emit a pass/fail summary and list blockers.
8. Remove temporary files or artifacts that are not part of the expected output.

## Notes
- If something cannot be done due to tool restrictions, explain exactly what is blocked and provide the smallest workaround.
- Respect existing file edits unless they must change for generation correctness.

---

## Additional Test Prompt: Generalization Pass (Non-Overfitting)

Run the same `blog-to-databricks-iac` skill and process as above, but execute this as a separate pass with a different input set. Do not reuse literals from prior runs unless they are immutable platform constants or explicitly required by this run's inputs.

### Inputs (Generalization Pass)
- workload: wkx
- environment: qa
- azure_region: westeurope
- github_environment: OPS-QA-ENV

### Additional Execution Requirements
1. Start from a clean slate using the same reset behavior as the main run.
2. Regenerate all expected artifacts from scratch.
3. Enforce input-driven generation:
   - Any value that should vary by run must be derived from current inputs.
   - Prior-run literals (e.g., `blg`, `dev`, `uksouth`, `BLG2CODEDEV`) must not appear in generated outputs unless required by immutable platform rules.
4. Enforce no placeholder leakage:
   - Placeholder/example/default tokens must not appear in generated outputs.
5. Enforce cross-run sensitivity:
   - Re-run generators with unchanged inputs and confirm zero diffs.
   - Change exactly one input (`environment` from `qa` to `prd`), regenerate, and confirm only expected environment-dependent fields change.
6. Enforce schema-aware interpolation rules:
   - Fields documented as non-interpolated must be literal.
   - Fields documented as templated must use input-sourced expressions.
7. Apply deterministic diff acceptance for the one-input change (`qa` -> `prd`):
   - Allowed changes: values and identifiers that directly encode `environment`.
   - Allowed transitive changes: names, tags, paths, or references derived from those environment-encoded identifiers.
   - Forbidden changes: workload, region, tenant/subscription/client identifiers, tool selection, and unrelated structural edits.
8. Emit a single machine-readable pass/fail summary in this exact shape:
   - `overall_pass`: boolean
   - `checks`: array of objects with `name`, `status` (`pass` or `fail`), `evidence`
   - `failures`: array of objects with `file`, `field_or_rule`, `reason`, `minimal_fix`
   - `blockers`: array of strings
9. If a rule cannot be evaluated due to tool restrictions, set that check to `fail` and include the blocked capability in `reason`.

### Failure Policy
If any check fails, mark the run failed and provide the minimum corrective action without changing unrelated files.
