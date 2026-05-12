# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

This repository implements deployment-ready infrastructure and Databricks bundle assets derived from the article:

- https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## What this repository deploys

- Terraform infrastructure in `infra/terraform/`:
	- Resource group
	- Three ADLS Gen2 storage accounts (bronze/silver/gold)
	- One Azure Key Vault
	- One Azure Databricks workspace (Premium, SCC / no public IP)
	- Three Databricks access connectors (system-assigned managed identity)
	- Per-layer Entra ID app registrations and service principals when `layer_sp_mode=create`
- Databricks Asset Bundle in `databricks-bundle/`:
	- Bundle root config (`databricks.yml`)
	- Generated jobs definition (`resources/jobs.yml`)
	- Python entrypoints for setup, bronze, silver, gold, and smoke test
- CI/CD workflows in `.github/workflows/`:
	- Validate Terraform
	- Deploy Infrastructure
	- Deploy DAB

For assumptions and unresolved values, see `SPEC.md` and `TODO.md`.

## Inputs for this run

- `workload`: `blg`
- `environment`: `dev`
- `azure_region`: `uksouth`
- `layer_sp_mode`: `create`
- GitHub environment: `BLG2CODEDEV`

## Required GitHub secrets

- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_SP_OBJECT_ID`

Optional for `layer_sp_mode=existing`:

- `EXISTING_LAYER_SP_CLIENT_ID`
- `EXISTING_LAYER_SP_OBJECT_ID`

## Generation and validation flow

1. Fetch article and produce `SPEC.md`.
2. Generate workflows via script generators.
3. Generate `databricks-bundle/resources/jobs.yml` via generator.
4. Validate Python syntax, Terraform, YAML parsing, and parity scripts.

## Local validation commands

```bash
python -m py_compile .github/skills/blog-to-databricks-iac/scripts/azure/*.py
find databricks-bundle/src -name 'main.py' -exec python -m py_compile {} +

terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate

python -c "import yaml, glob; [yaml.safe_load(open(f)) for f in glob.glob('.github/workflows/*.yml')]"
python -c "import yaml, glob; [yaml.safe_load(open(f)) for f in glob.glob('databricks-bundle/**/*.yml', recursive=True)]"

bash .github/skills/blog-to-databricks-iac/scripts/validate_workflow_parity.sh
bash .github/skills/blog-to-databricks-iac/scripts/validate_bundle_parity.sh
```

## Notes

- Generated files are intended to be reproducible. Prefer changing generator scripts over editing generated output manually.
- `workspace_host` and `workspace_resource_id` in `databricks.yml` are populated at deploy time by the deploy bridge/workflow path.
