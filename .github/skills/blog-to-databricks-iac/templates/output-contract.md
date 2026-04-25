# Output contract

Return results in this exact order.

## 1. SPEC.md

Include:
- source URL
- short summary of the article
- inferred architecture
- what is explicit
- what is assumed
- what is missing

## 2. TODO.md

Include only unresolved inputs such as:
- region
- workspace URL
- catalog/schema names
- secret scope names
- service principal identifiers
- schedules
- networking IDs
- storage bucket/container names

## 3. Terraform

Generate:
- `infra/terraform/versions.tf`
- `infra/terraform/providers.tf`
- `infra/terraform/variables.tf`
- `infra/terraform/main.tf`
- `infra/terraform/outputs.tf`

## 4. DAB

Generate:
- `databricks-bundle/databricks.yml`
- `databricks-bundle/resources/jobs.yml`
- `databricks-bundle/resources/pipelines.yml` if needed
- `databricks-bundle/src/main.py` or notebooks if required

## 5. README.md

Include:
- Design of the architecture
- how to fill variables
- Terraform apply steps
- Databricks bundle validate/deploy/run steps
- assumption notes