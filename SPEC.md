# SPEC — Secure Medallion Architecture Pattern on Azure Databricks (Part I)

Source URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
Inputs: workload=blg, environment=dev, azure_region=uksouth, layer_sp_mode=create

## Architecture
- Pattern: Medallion architecture (Bronze -> Silver -> Gold).
- Components and roles:
  - ADLS Gen2 per layer for isolation.
  - Azure Databricks workspace for jobs and compute.
  - Lakeflow jobs: one per layer plus orchestrator.
  - Unity Catalog governance model.
  - Azure Key Vault and AKV-backed secret scope.
  - Access Connectors + Entra service principals per layer.
- Flow triggers/schedules: not stated in article.
- Volume/frequency/latency: not stated in article.

## Azure services
- Azure Databricks, ADLS Gen2, Azure Key Vault, Entra ID, Databricks Access Connector.
- Workspace SCC / No Public IP is stated.
- Region/redundancy details in article: not stated in article.

## Databricks
- Workspace tier: Premium (inferred from Unity Catalog usage).
- SCC / No Public IP: stated.
- Unity Catalog: stated; exact catalog/schema names not stated in article.
- Compute model: dedicated cluster per layer stated; exact sizing not stated in article.
- Jobs: Bronze, Silver, Gold + orchestrator stated.
- Runtime/library/init-script specifics: not stated in article.

## Data model
- Source systems and formats: not stated in article.
- Exact target table names by layer: not stated in article.
- Partitioning/Liquid clustering/Z-order specifics: not stated in article.
- Schema evolution/data quality rules: not stated in article.

## Security and identity
- Identities: per-layer Entra service principals and access connector managed identities.
- Secrets: Key Vault, consumed via AKV-backed secret scope.
- Detailed RBAC and Unity Catalog grants: not stated in article.

## Operational concerns
- Monitoring mentions: jobs UI and system tables.
- Detailed cost controls: not stated in article.
- CI/CD implementation deferred to Part II.
- Backup/retention/DR: not stated in article.

## Out-of-scope markers
- CI/CD code details deferred to Part II.
- Cluster reuse/environment promotion challenges deferred to Part II.

## Canonical naming for this run
- Resource group: rg-blg-dev-uks
- Key Vault: kv-blg-dev-uks
- Databricks workspace: dbw-blg-dev-uks
- Storage: stblgdevbronzeuks, stblgdevsilveruks, stblgdevgolduks
- Access connectors: ac-blg-dev-bronze-uks, ac-blg-dev-silver-uks, ac-blg-dev-gold-uks
- Layer SP display names: sp-blg-dev-bronze-uks, sp-blg-dev-silver-uks, sp-blg-dev-gold-uks
- Secret scope name: kv-dev-scope
