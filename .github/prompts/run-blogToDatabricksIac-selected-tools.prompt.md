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
1. Run `python .github/skills/blog-to-databricks-iac/scripts/reset_generated.py --force;`
2. Don't capture the existing Terraform and bundle state as a baseline. Treat every run as if it's the first run with no prior state, and generate all expected outputs from scratch.
2. Execute the skill end-to-end.
3. Generate or refresh all expected artifacts (`SPEC.md`, `TODO.md`, Terraform, Databricks bundle, workflows, and plan prompt).
4. Validate outputs:
   - Python compile checks on all generated `.py` files
   - Terraform init/validate
   - YAML parsing on all generated `.yml` files
   - **Templated-not-literal check.** Identifiers in generated workflow files that should vary by run (environment names, resource names, paths) must be expressed as workflow expressions sourcing from inputs, not as literal strings from generator defaults. Generic placeholder strings (e.g. EXAMPLE, PLACEHOLDER, default identifier patterns from script arguments) must not appear in generated output.
   - **Interpolation-constraint check.** In any generated file with known no-interpolation fields (the skills document which fields these are for each artifact type), those fields contain literal values only — no `${...}` of any kind.
   - **Cross-artifact reference balance.** When a generated artifact references identities, resources, or names created in another generated artifact, count the references on both sides; they must match. Unbalanced sets are a generation failure.
   - **Feature completeness.** When a generated file emits a property that requires supporting infrastructure (as documented in the relevant skill), that supporting infrastructure must be present in the same module. Partial feature families are a generation failure.
   - **External dependency documentation.** Every external name a generated workflow references (secret references, environment names, resource IDs not provisioned by the generated code) must appear in TODO.md with operator action documented.
5. Performance regression check by re-running generators and confirming no diffs against the prior generation when inputs are unchanged.
6. Summarize results with pass/fail and list any blockers.
7. Remove temporary files or artifacts that are not part of the expected output.

## Notes
- If something cannot be done due to tool restrictions, explain exactly what is blocked and provide the smallest workaround.
- Respect existing file edits unless they must change for generation correctness.
