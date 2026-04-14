# Secure Medallion Architecture Specification

## Source
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Title: Secure Medallion Architecture Pattern on Azure Databricks (Part I)

## Short Summary
The source article describes a security-first Azure Databricks medallion architecture where Bronze, Silver, and Gold are isolated by storage, compute, and identity. Each layer runs as its own Lakeflow Job under a dedicated Microsoft Entra service principal, with Unity Catalog providing the governance boundary and Azure Key Vault supplying runtime secrets.

## Inferred Architecture
- One Azure resource group per workload/environment/region.
- One premium Azure Databricks workspace per environment.
- Three ADLS Gen2 storage accounts, one per layer.
- Three Databricks access connectors, one per layer, to back Unity Catalog storage credentials.
- Three Microsoft Entra applications and service principals, one per layer, registered for Databricks job execution.
- One Azure Key Vault per environment, holding runtime JDBC secrets.
- One Unity Catalog metastore assignment for the workspace.
- Three Unity Catalog storage credentials, external locations, catalogs, and schemas.
- One Databricks Asset Bundle containing Bronze, Silver, Gold, and orchestrator jobs.

## Explicit Guidance From The Article
- Separate Bronze, Silver, and Gold by identity, storage, and compute.
- Use least privilege so no single principal can write across all layers.
- Use Azure Key Vault and AKV-backed Databricks secret scopes for runtime secrets.
- Prefer managed tables under Unity Catalog.
- Use one orchestrator job to sequence the three layer jobs.
- Use Photon primarily for Silver and treat Bronze and Gold more conservatively.

## Assumptions In This Repo Implementation
- The workspace is provisioned without VNet injection or private endpoints unless the user extends the Terraform.
- Unity Catalog metastore already exists and is supplied as `DATABRICKS_METASTORE_ID`.
- Databricks account already exists and is supplied as `DATABRICKS_ACCOUNT_ID`.
- JDBC source connectivity is represented with SQL Server style options and can be adapted in the Bronze job if the source system differs.
- The AKV-backed secret scope name defaults to the Key Vault name unless overridden.
- Cluster policies are a follow-on hardening step and are not provisioned in this baseline.

## What Is Missing Or Deferred
- Private networking, customer-managed keys, and outbound lockdown.
- Cluster policies and workspace admin hardening.
- Databricks secret-scope creation itself; the Terraform outputs a convention-aligned scope name, but the scope must still be created against the Key Vault.
- Notification routing, production schedules, and workspace-level admin group assignments.
- Downstream BI/semantic layer assets beyond the Gold managed tables.
