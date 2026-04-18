Execution plan:
1. Fetch and parse the source blog content.
2. Regenerate CI workflows (validate, deploy infrastructure, deploy DAB) using configured GitHub environment and secret names.
3. Recreate Terraform files for secure medallion infra with identity modes and required outputs for DAB handoff.
4. Recreate Databricks Asset Bundle files (bundle config, jobs, bronze/silver/gold scripts) with parameterized catalog/schema values.
5. Update README, SPEC, and TODO with assumptions, prerequisites, and unresolved environment-specific values.
6. Run mandatory validations: Python compile checks, Terraform init/validate, YAML parse checks, and workflow generator runtime checks.
