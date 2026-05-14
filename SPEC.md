# SPEC.md

## Source
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268
- Fetch artifact: blog_fetch_output.json
- Article title: Secure Medallion Architecture Pattern on Azure Databricks (Part I)

## Architecture
- High-level architecture pattern: Medallion architecture (Bronze, Silver, Gold) with per-layer isolation.
- Named components and roles:
  - Source systems feed raw data into Bronze processing.
  - Bronze, Silver, Gold Lakeflow jobs process data stage-by-stage.
  - Unity Catalog governs catalogs, schemas, and table access.
  - Azure Key Vault stores runtime secrets.
  - ADLS Gen2 stores layer-specific data.
  - An orchestrator Lakeflow job coordinates the three layer jobs.
- Data flow direction and triggers: Layered progression Bronze -> Silver -> Gold, orchestrated by an overarching job (inferred from article prose).
- Data volume, frequency, latency requirements: not stated in article.

## Azure services
- Azure Databricks: central compute and orchestration platform for Lakeflow jobs.
- ADLS Gen2 (Storage Accounts): per-layer storage isolation (one storage account per layer) inferred from architecture description.
- Microsoft Entra ID service principals / managed identities: one identity per layer for least privilege.
- Azure Databricks Access Connector: identity bridge for secure data access from Databricks to Azure resources.
- Azure Key Vault: runtime secret storage and secret rotation locus.
- Networking posture:
  - Secure Cluster Connectivity (No Public IP): stated.
  - Public endpoint/private endpoint model for Storage/Key Vault/Workspace: not stated in article.
  - VNet injection and firewall specifics: not stated in article.
- Region and redundancy:
  - Region name: not stated in article.
  - Redundancy model (LRS/ZRS/GRS): not stated in article.

## Databricks
- Workspace tier: not stated in article.
- Workspace type: Hybrid (from checklist requirement and article context).
- Workspace deployment posture: Secure Cluster Connectivity (No Public IP), stated in article.
- Unity Catalog usage: yes.
  - Catalog naming: separate catalogs for Bronze, Silver, Gold, stated.
  - Schema names: not stated in article.
  - Metastore reference: not stated in article.
- Compute model:
  - Dedicated compute per layer (three isolated clusters), stated.
  - Orchestrator job triggers per-layer jobs, stated.
  - SQL warehouse/serverless specifics: not stated in article.
- Jobs and orchestration:
  - Multi-job architecture with explicit dependencies via an orchestrator, inferred from article text.
  - Schedules and trigger frequencies: not stated in article.
  - Concurrency limits: not stated in article.
- Lakeflow Spark Declarative Pipelines usage and mode: Lakeflow Jobs referenced; triggered vs continuous mode not stated in article.
- Task source format: notebooks referenced for runtime secret reads; full task artifact standard (notebook vs python files) not fully stated in article.
- Libraries/runtime/init scripts: not stated in article.

## Data model
- Source systems and formats: exact source systems and file/message formats not stated in article.
- Target datasets by layer:
  - Bronze/Silver/Gold layers are explicitly required.
  - Exact table names per layer: not stated in article.
- Partitioning strategy: avoid partitioning and use liquid clustering or Z-order only if stated; none explicitly stated in article.
- Schema evolution/enforcement: not stated in article.
- Data quality expectations/tests: progressive quality checks are implied; concrete test definitions and thresholds are not stated in article.

## Security and identity
- Identities used:
  - Dedicated Microsoft Entra ID service principal per medallion layer.
  - Deployment/operator principal concept for provisioning operations (inferred from implementation model).
  - Access connector managed identities for data plane access.
- Secrets and secret storage:
  - Store in Azure Key Vault.
  - Consume at runtime via AKV-backed Databricks secret scopes.
- RBAC and UC grants:
  - Least privilege is explicitly required.
  - Exact Azure RBAC role matrix per principal and scope: not stated in article.
  - Exact Unity Catalog grants per principal/group: not stated in article.
- Network boundaries:
  - Layer and identity isolation are explicit.
  - Exact network path controls and private-link topology are not stated in article.

## Operational concerns
- Monitoring/logging/alerting:
  - Enable system tables and use Jobs monitoring UI, stated.
  - Enable Key Vault diagnostic logs, stated.
  - Concrete alert routing and thresholds: not stated in article.
- Cost controls:
  - Layer-level observability and spend tracking are encouraged.
  - Concrete cluster autoscale bounds, budgets, or reservations are not stated in article.
- CI/CD approach in article: deferred to Part II; specific pipeline implementation is out of scope of Part I.
- Backup/retention/disaster recovery strategy: not stated in article.

## Out-of-scope markers
- The article explicitly frames CI/CD implementation as Part II.
- Several implementation specifics are intentionally deferred to later content.

## Other observations
- Strong emphasis on reducing blast radius by isolating identity, compute, and storage per layer.
- Managed tables are preferred in design rationale due to obfuscated physical paths and governance alignment.
- Runtime secret usage guidance is explicit: no secret literals in code or job parameters; avoid logging secret values.
