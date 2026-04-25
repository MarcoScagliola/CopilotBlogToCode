# Blog analysis checklist

Use this checklist when executing step 2 of the blog-to-databricks-iac
skill. Record one answer per item in `SPEC.md`, preserving the section
headings below.

## Architecture

- High-level architecture pattern (e.g. medallion, lambda, event-driven ingestion, batch ELT)
- Named components and the role each one plays (source systems, landing zone, transformation layer, serving layer, BI consumers)
- Data flow direction and triggers (scheduled batch, event-driven, streaming, on-demand)
- Stated or implied data volume, frequency, and latency requirements

## Azure services

- Every Azure service named in the article or depicted in diagrams (Storage Account, Key Vault, Event Hubs, Data Factory, SQL DB, Synapse, Log Analytics, Application Insights, etc.)
- For each service: its role in the architecture, and any stated SKU, tier, or configuration
- Networking posture: public endpoints, private endpoints, do not use VNet injection, deploy the Azure Workspace, Allow Public Network Access, firewall rules, service endpoints — or `not stated in the article`. NSG Rules are not required
- Region and redundancy: region name if stated, LRS/ZRS/GRS/RA-GRS if stated

## Databricks

- Workspace tier if stated (Standard, Premium)
- Workspace type Hybrid
- Deploy the Azure Databricks workspace with Secure Cluster Connectivity (No Public IP)
- Unity Catalog usage (yes, no, not stated). If yes: catalog name, schema names, metastore reference
- Compute model: all-purpose clusters, job clusters, serverless, SQL warehouses, Lakeflow Spark Declarative Pipelines
- Jobs and orchestration: single-task jobs, multi-task jobs, dependencies, schedules, triggers, concurrency
- Lakeflow Spark Declarative Pipelines usage and mode (triggered vs continuous) if applicable
- Task source format: notebooks, Python files, SQL files, JAR, wheel
- Libraries, runtime version, init scripts if specified

## Data model

- Source systems and formats (CSV, JSON, Parquet, Avro, CDC stream, JDBC, REST)
- Target tables or datasets grouped by layer (bronze, silver, gold, or the article's equivalent naming)
- Do not apply Partitioning and rather use Liquid Clustering  or Z-ordering strategy only if stated in the blog 
- Schema evolution or enforcement rules if stated
- Data quality expectations or test rules if stated

## Security and identity

- Identities used (managed identity, service principal, user groups, customer-managed keys)
- Secrets referenced and where they are stored (Azure Key Vault, Databricks secret scope)
- RBAC assignments and Unity Catalog grants if stated
- Network boundaries: which components can reach which, and through what path

## Operational concerns

- Monitoring, logging, alerting services referenced
- Cost controls if stated (auto-termination, spot instances, budgets,reserved capacity)
- CI/CD or deployment approach described in the article (informational only — this skill generates its own workflows)
- Backup, retention, or disaster recovery strategy if stated

## Out-of-scope markers

- Anything the article explicitly calls out as out of scope, deferred, or "left as an exercise for the reader"

## Other observations

- Anything interesting the article mentions that does not fit a section above and may affect implementation