# Cloud Deployment Model

## Scope
This skill targets Azure only.

## Pre-existing
- Azure tenant
- Azure subscription
- Databricks account
- Unity Catalog metastore

## Created by Terraform
- Resource group
- Databricks workspace
- ADLS Gen2 storage accounts and containers
- Access connectors
- Entra applications and service principals
- Key Vault
- Unity Catalog storage credentials, external locations, catalogs, schemas, grants

## Created by DAB
- Lakeflow jobs
- Job clusters
- Python entrypoints or notebooks

## Boundary rule
Never define Terraform-managed resources in the bundle.
Never define jobs or notebooks in Terraform.