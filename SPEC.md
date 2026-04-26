# Secure Medallion Architecture Pattern on Azure Databricks (Part I)

Source article:
- URL: https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

## 1. Architecture intent
- Security-first medallion pattern using Bronze, Silver, and Gold layers.
- Least privilege is enforced per layer with isolated identities, storage, and compute.
- Orchestration is handled by a parent Lakeflow job that chains layer jobs.

## 2. Identity and access model
- One execution identity per data layer (Bronze/Silver/Gold), inferred from architecture narrative and diagrams.
- Identity type: Microsoft Entra ID service principals, stated in article.
- Databricks access to storage is mediated with Access Connectors (system-assigned managed identity), stated in article.
- Exact role definition names per scope: not stated in article.

## 3. Data and storage topology
- One ADLS Gen2 storage account per medallion layer, stated in article.
- Layer separation is physical and logical; cross-layer write attempts should be blocked by RBAC, stated in article.
- Naming convention for storage accounts and containers: not stated in article.
- External locations and storage credentials exact object names: not stated in article.

## 4. Databricks workspace and compute
- Azure Databricks workspace is used as the processing platform.
- Three dedicated clusters, one per layer, to isolate execution, stated in article.
- Cluster policy specifics and exact VM sizes: not stated in article.
- Workspace SKU and network topology (for example VNet injection details): not stated in article.

## 5. Pipeline orchestration
- Four-job pattern:
  - Bronze layer job
  - Silver layer job
  - Gold layer job
  - Orchestrator job calling the three jobs in sequence
- Retries/alerts are recommended, but exact thresholds are not stated in article.
- Trigger schedule and cadence are not stated in article.

## 6. Unity Catalog and table strategy
- Catalog.schema.table naming convention is required, stated in article.
- Separate catalogs for Bronze, Silver, and Gold are recommended, stated in article.
- Managed tables are preferred in this design, stated in article.
- Exact schema names and table names per layer are not stated in article.

## 7. Secrets and key management
- Secrets must not be stored in notebooks, repos, or job parameters, stated in article.
- Azure Key Vault with AKV-backed Databricks secret scopes is the recommended pattern, stated in article.
- Runtime secret retrieval via dbutils.secrets.get is required, stated in article.
- Secret key names beyond examples are not stated in article.

## 8. Observability and operations
- Enable Jobs monitoring and system tables for reliability/cost visibility by layer, stated in article.
- Diagnostic log retention policy and alert routing specifics: not stated in article.

## 9. CI/CD implementation assumptions for this repo
- Infrastructure is implemented with Terraform in infra/terraform.
- Databricks runtime assets are implemented with a Databricks Asset Bundle in databricks-bundle.
- Layer identity mode supports create or existing to handle restricted tenants.
- Existing identity mode uses provided service principal identifiers and avoids Graph-dependent principal data lookups during Terraform apply.

## Other observations
- The article is architecture-oriented and intentionally leaves many deployment-specific values open.
- This repo therefore externalizes unresolved values to TODO.md and keeps defaults configurable via Terraform variables and bundle variables.
