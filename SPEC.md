# SPEC — Secure Medallion Architecture Pattern on Azure Databricks (Part I)

Source URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
Inputs: workload=blg, environment=dev, azure_region=uksouth, layer_sp_mode=create

## Architecture
- High-level pattern: medallion architecture (Bronze -> Silver -> Gold).
- Components and roles:
  - ADLS Gen2 accounts per layer.
  - Databricks workspace for compute and orchestration.
  - Lakeflow jobs per layer plus orchestrator.
  - Unity Catalog governance.
  - Azure Key Vault and AKV-backed secret scope.
  - Access Connectors and per-layer Entra service principals.
- Data flow triggers/schedules: not stated in article.
- Volume/frequency/latency: not stated in article.

## Azure services
- Named services: Azure Databricks, ADLS Gen2, Key Vault, Entra ID, Access Connector.
- Network posture: SCC/No Public IP for workspace stated; private endpoint/firewall details not stated in article.
- Region and redundancy from article: not stated in article.

## Databricks
- Workspace tier: Premium (inferred from Unity Catalog requirement).
- SCC/No Public IP: stated.
- Unity Catalog usage: stated; exact catalog/schema names not stated in article.
- Compute model: dedicated cluster per layer stated; exact sizing not stated in article.
- Jobs: three layer jobs plus orchestrator stated.
- Runtime/libs/init scripts: not stated in article.

## Data model
- Source systems and formats: not stated in article.
- Target table names per layer: not stated in article.
- Partitioning/liquid clustering/z-order details: not stated in article.
- Schema evolution/data quality rules: not stated in article.

## Security and identity
- Identities used: per-layer Entra service principals, Access Connector SAMIs.
- Secrets: Key Vault + AKV-backed secret scope at runtime.
- RBAC and UC grant specifics: not stated in article.

## Operational concerns
- Monitoring/system tables/jobs UI mentioned.
- Cost controls details not stated in article.
- CI/CD implementation deferred to Part II.
- Backup/retention/DR not stated in article.

## Out-of-scope markers
- CI/CD code and some operational topics deferred to Part II.

## Other observations
- Managed tables preferred in the article.
- One secret scope per environment recommended.
