# blg — Secure Medallion Architecture on Azure Databricks

Infrastructure-as-Code and Databricks Asset Bundle generated from:
[Secure Medallion Architecture Pattern on Azure Databricks (Part I)](https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268)

---

## Overview

A security-first medallion data platform (Bronze → Silver → Gold) on Azure Databricks with:

- Per-layer ADLS Gen2 storage accounts (HNS enabled)
- Per-layer Databricks Access Connectors (System-Assigned Managed Identity)
- Per-layer Entra ID Service Principals
- Azure Key Vault-backed Databricks secret scope
- Unity Catalog with per-layer catalogs and schemas
- Secure Cluster Connectivity (No Public IP) Databricks workspace

---

## Prerequisites

| Tool | Version |
|------|---------|
| Terraform | ≥ 1.6 |
| Databricks CLI | ≥ 0.240 |
| Python | ≥ 3.11 |
| Azure CLI | latest |

---

## Repository layout

```
infra/terraform/          Terraform — Azure infrastructure
databricks-bundle/        Databricks Asset Bundle
  databricks.yml          Bundle manifest with variable declarations
  resources/jobs.yml      Lakeflow job definitions (generated)
  src/
    setup/main.py         Setup job — Unity Catalog object registration
    bronze/main.py        Bronze layer ingestion
    silver/main.py        Silver layer transformation
    gold/main.py          Gold layer aggregation
    smoke_test/main.py    Post-pipeline smoke tests
.github/workflows/
  validate-terraform.yml  Terraform plan validation on PR
  deploy-infrastructure.yml  Terraform apply (infrastructure deploy)
  deploy-dab.yml          Databricks Asset Bundle deploy
SPEC.md                   Architecture reference, design decisions, assumptions
TODO.md                   Deferred decisions and post-deploy hardening checklist
```

---

## Inputs used to generate this project

| Variable | Value |
|----------|-------|
| workload | blg |
| environment | dev |
| azure_region | uksouth |
| layer_sp_mode | create |

---

## GitHub Secrets required

Configure the following secrets in the **BLG2CODEDEV** GitHub Environment:

| Secret | Description |
|--------|-------------|
| `AZURE_TENANT_ID` | Azure tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_CLIENT_ID` | Deployment SP application (client) ID |
| `AZURE_CLIENT_SECRET` | Deployment SP client secret |
| `AZURE_SP_OBJECT_ID` | Deployment SP Enterprise Application object ID |
| `EXISTING_LAYER_SP_CLIENT_ID` | Pre-existing layer SP client ID (only when `layer_sp_mode=existing`) |
| `EXISTING_LAYER_SP_OBJECT_ID` | Pre-existing layer SP object ID (only when `layer_sp_mode=existing`) |

---

## Deploying infrastructure

```bash
# 1. Validate Terraform on PR — runs automatically via validate-terraform.yml

# 2. Deploy infrastructure — runs automatically via deploy-infrastructure.yml
#    or manually:
terraform -chdir=infra/terraform init
terraform -chdir=infra/terraform plan -out=tfplan
terraform -chdir=infra/terraform apply tfplan
```

---

## Deploying the Databricks Asset Bundle

```bash
# Runs automatically via deploy-dab.yml after infrastructure deploy.
# Manual run:
cd databricks-bundle
databricks bundle deploy --target dev
databricks bundle run blg-medallion-orchestrator --target dev
```

---

## Post-deploy checklist

See [TODO.md](TODO.md) for deferred hardening steps and decisions that require
a running Databricks workspace (Unity Catalog metastore attachment, External
Locations, compute policies, etc.).
