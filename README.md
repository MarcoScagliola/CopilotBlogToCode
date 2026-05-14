# Secure Medallion Architecture Pattern on Azure Databricks

This repository implements the Azure Databricks pattern described in [Secure Medallion Architecture Pattern on Azure Databricks (Part I)](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268). The generated baseline focuses on a security-first medallion design with three isolated layers, three storage accounts, three Azure Databricks Access Connectors, and three Microsoft Entra ID service principals created at deployment time for Bronze, Silver, and Gold processing.

The implementation is split across Terraform under `infra/terraform/` and a Databricks Asset Bundle under `databricks-bundle/`. The source article gives the architecture and control objectives; where it leaves values unspecified, those gaps are recorded in `SPEC.md` and turned into operator actions in `TODO.md`.

## What this repository deploys

- An Azure resource group in `uksouth` by default, named from the canonical `rg-{workload}-{environment}-{region_abbrev}` pattern.
- Three ADLS Gen2 storage accounts, one per medallion layer.
- One Azure Key Vault with RBAC enabled and purge protection enabled.
- One Premium Azure Databricks workspace with Secure Cluster Connectivity (`no_public_ip = true`).
- Three Databricks Access Connectors, one per layer.
- Three Microsoft Entra ID app registrations and service principals, one per layer, because this run was generated for `layer_sp_mode=create`.
- Azure RBAC assignments that keep Bronze, Silver, and Gold isolated while allowing downstream read access where the article calls for it.
- A Databricks Asset Bundle with setup, bronze, silver, gold, smoke-test, and orchestrator jobs.
- Three GitHub Actions workflows: Terraform validation, infrastructure deployment, and DAB deployment.

## Repository layout

```
.
├── infra/terraform/              Azure infrastructure baseline
├── databricks-bundle/            Databricks jobs, variables, and entrypoints
├── .github/workflows/            Generated CI/CD workflows
├── SPEC.md                       Article analysis and explicit vs inferred architecture details
├── TODO.md                       Operator actions for unresolved and post-deploy work
└── README.md                     Deployment and validation guide
```

## Prerequisites

### Azure and Entra ID

- A subscription in which the deployment principal can create resource groups, storage accounts, Key Vault, Databricks, app registrations, service principals, and role assignments.
- GitHub Environment `BLG2CODEDEV` with these secrets or environment variables: `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, and `AZURE_SP_OBJECT_ID`.
- The deployment principal must have `Contributor` and `User Access Administrator` on the target scope.
- Because this run targets `layer_sp_mode=create`, the deployment principal also needs directory permissions that allow app registration and service principal creation.

### Local validation tools

- Python 3.11+
- Terraform 1.6+
- Git Bash on Windows for the parity shell scripts

## Workflow overview

### Validate Terraform

The `validate-terraform.yml` workflow runs `terraform init -backend=false` and `terraform validate` without touching Azure resources. It resolves tenant and subscription identifiers from GitHub Secrets or Environment Variables, with secrets preferred.

### Deploy Infrastructure

The `deploy-infrastructure.yml` workflow:

1. Resolves Azure credentials from `BLG2CODEDEV`.
2. Computes canonical resource names once and shares them through `GITHUB_ENV`.
3. Logs into Azure for preflight checks.
4. Handles ephemeral reruns with `state_strategy`.
5. Applies Terraform with deterministic Key Vault recovery handling.
6. Uploads `terraform-outputs` and `deploy-context` artifacts for the DAB workflow.

Dispatch inputs:

- `target`: `dev` or `prd`
- `workload`: defaults to `blg`
- `environment`: defaults to `dev`
- `azure_region`: defaults to `uksouth`
- `key_vault_recovery_mode`: `auto`, `recover`, or `fresh`
- `state_strategy`: `fail` or `recreate_rg`

### Deploy DAB

The `deploy-dab.yml` workflow downloads the two infrastructure artifacts, checks out the matching commit, exports Databricks auth context through environment variables, and runs the deploy bridge script. It does not use a Databricks PAT.

## Validation commands

The required post-generation checks for this repository are:

```bash
python -m py_compile .github/skills/blog-to-databricks-iac/scripts/azure/*.py
find databricks-bundle/src -name 'main.py' -exec python -m py_compile {} +
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
python -c "import yaml, glob; [yaml.safe_load(open(f, encoding='utf-8')) for f in glob.glob('.github/workflows/*.yml')]"
python -c "import yaml, glob; [yaml.safe_load(open(f, encoding='utf-8')) for f in glob.glob('databricks-bundle/**/*.yml', recursive=True)]"
```

On Windows, run the parity scripts through Git Bash:

```powershell
& "C:\Program Files\Git\bin\bash.exe" .github/skills/blog-to-databricks-iac/scripts/validate_workflow_parity.sh
& "C:\Program Files\Git\bin\bash.exe" .github/skills/blog-to-databricks-iac/scripts/validate_bundle_parity.sh
& "C:\Program Files\Git\bin\bash.exe" .github/skills/blog-to-databricks-iac/scripts/validate_handler_coverage.sh
```

## Deployment notes

- The article explicitly prefers separate storage, compute, and identities per medallion layer. This baseline encodes that separation in both Azure RBAC and job topology.
- The article does not specify private endpoints, storage redundancy, exact runtime versions, concrete source systems, or final dataset names. Those decisions are deferred to `TODO.md`.
- The Databricks bundle avoids auth interpolation in `databricks.yml`; `DATABRICKS_HOST` and `DATABRICKS_AZURE_RESOURCE_ID` are exported by the deploy bridge at runtime.
- Terraform state is intentionally local-only in this generated baseline. Remote backend setup is listed as a deferred architecture decision in `TODO.md`.

## Next operator actions

Work through `TODO.md` in order. The minimum path to a first successful orchestrator run is:

1. Confirm Azure RBAC and Entra permissions for the deployment principal.
2. Create the GitHub Environment secrets and validate workflow access.
3. Decide the remaining unresolved architecture details from the article, especially networking hardening, table naming, and observability sinks.
4. Deploy infrastructure.
5. Configure the Key Vault-backed secret scope, Unity Catalog objects and grants, and runtime secrets.
6. Deploy the DAB and run the orchestrator job.
