# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

Source article:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## Architecture

- High-level pattern: security-first Medallion Architecture (Bronze, Silver, Gold) with Lakeflow job orchestration.
- Named components and roles: source ingestion into Bronze, refinement in Silver, curated analytics in Gold, Unity Catalog for governance, Azure Key Vault for secret management, per-layer identities/storage/compute for isolation.
- Data flow direction and triggers: sequential multi-hop Bronze -> Silver -> Gold with one orchestrator job coordinating per-layer jobs.
- Data volume, frequency, and latency requirements: not stated in article.

## Azure services

- Services explicitly referenced: Azure Databricks, ADLS Gen2 (separate storage per layer), Microsoft Entra ID service principals, Azure Key Vault, Unity Catalog, Lakeflow Jobs.
- Service role/SKU/config: Databricks workspace with dedicated cluster per layer and policy-oriented isolation; Key Vault-backed secret scope; per-layer storage accounts and layer-scoped principals.
- Networking posture: private endpoint/service-endpoint/firewall specifics are not stated in article.
- Region and redundancy (LRS/ZRS/GRS): not stated in article.

## Databricks

- Workspace tier: not stated in article.
- Workspace type: Hybrid (from checklist policy for this run).
- Secure Cluster Connectivity (No Public IP): inferred from security-first posture and dedicated secure layer isolation.
- Unity Catalog usage: yes; separate catalogs for Bronze, Silver, Gold are stated.
- Catalog names, schema names, metastore reference: exact names and metastore ID are not stated in article.
- Compute model: dedicated clusters per layer and one orchestrator Lakeflow job are stated.
- Job orchestration: per-layer jobs plus orchestrator with dependency ordering are stated; concurrency/schedule values are not stated in article.
- Lakeflow pipeline mode (triggered vs continuous): not stated in article.
- Task source format: notebooks are implied for runtime secret retrieval (`dbutils.secrets.get`); Python file packaging details are inferred for generated bundle.
- Libraries/runtime/init scripts: not stated in article.

## Data model

- Source systems and formats: concrete source systems and data formats are not stated in article.
- Layer targets: Bronze raw, Silver refined, Gold curated/serving tables are stated conceptually.
- Partitioning/liquid clustering/Z-order strategy: not stated in article.
- Schema evolution or enforcement rules: not stated in article.
- Data quality expectations: progressive quality checks per layer are stated; exact test rules are not stated in article.

## Security and identity

- Identities used: dedicated Microsoft Entra service principal per layer with least privilege; managed identity concepts and Databricks access connector are described.
- Secrets and storage location: keep secrets in Azure Key Vault and read at runtime through AKV-backed Databricks secret scope.
- RBAC and Unity Catalog grants: least-privilege intent is stated; exact role-assignment matrix and UC grant statements are not stated in article.
- Network boundaries: layer isolation intent is stated; concrete NSG/routing/private-link boundary configuration is not stated in article.

## Operational concerns

- Monitoring and logging: system tables and Jobs monitoring UI are explicitly recommended.
- Cost controls: per-layer cluster isolation is discussed; detailed budget policy and autoscale sizing are not stated in article.
- CI/CD approach: article states Part II will cover CI/CD code; implementation details are not stated in article.
- Backup/retention/disaster recovery strategy: not stated in article.

## Out-of-scope markers

- Data disposition tier is mentioned as outside the shown architecture.
- CI/CD implementation details are deferred to Part II.

## Other observations

- The article explicitly emphasizes separation of duties and blast-radius reduction through identity, storage, and compute isolation.
- Managed tables are preferred for obfuscated physical layout and governance alignment.

## Generation inputs used

- workload: blg
- environment: dev
- azure_region: uksouth
- layer_sp_mode: create
- github_environment: BLG2CODEDEV
