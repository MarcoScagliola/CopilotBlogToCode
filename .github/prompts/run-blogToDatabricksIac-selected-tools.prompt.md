# Run Blog To Databricks IaC (Selected Tools)

Use the `blog-to-databricks-iac` skill on this article:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Inputs
- workload: blg
- environment: dev
- azure_region: uksouth
- layer_sp_mode: create
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
4. Validate outputs with Python compile checks, Terraform init/validate, YAML parsing, and environment/placeholder checks.
5. Summarize results with pass/fail and list any blockers.
6. Remove temporary files or artifacts that are not part of the expected output.

## Notes
- If something cannot be done due to tool restrictions, explain exactly what is blocked and provide the smallest workaround.
- Respect existing file edits unless they must change for generation correctness.
