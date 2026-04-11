## Plan: Generate Azure Medallion IaC + DAB

Implement the architecture from the blog into Terraform + Databricks DAB outputs, following updated Azure references and policies.

Inputs used for this run:
- `azure_region`: `uksouth`
- `workload`: `blg`
- `environment`: `dev`

### Steps
1. Fetch and parse the blog article into structured signals.
2. Validate against Azure cloud deployment boundaries.
3. Apply Azure region policy (explicit region provided).
4. Apply Azure naming conventions and derive all names in `locals.tf`.
5. Generate artifacts in required order:
   - `SPEC.md`
   - `TODO.md`
   - Terraform files under `infra/terraform/`
   - DAB files under `databricks-bundle/`
   - `README.md`
6. Validate syntax and ownership boundaries.

### Validation checklist
1. `terraform -chdir=infra/terraform init -backend=false`
2. `terraform -chdir=infra/terraform validate`
3. `databricks bundle validate` from `databricks-bundle`
4. Ensure no Terraform-managed resources are defined in DAB files.
5. Ensure no jobs/notebooks are defined in Terraform files.