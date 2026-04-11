# SPEC — Secure Medallion Architecture on Azure Databricks

**Source URL:** https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268  
**Generated:** 2026-04-11

---

## Short Summary

The article describes a security-first, greenfield deployment pattern for Azure Databricks that
implements the Medallion Architecture (Bronze → Silver → Gold). The core principle is **one identity,
one cluster, one job per layer** with strictly scoped least-privilege access so that a breach or bug
in one layer cannot pollute the others.

---

## Inferred Architecture

| Component | Count | Detail |
|---|---|---|
| ADLS Gen2 storage accounts | 3 | One per medallion layer, HNS enabled |
| ADLS Gen2 filesystem containers | 3 | One per storage account (`bronze` / `silver` / `gold`) |
| Databricks Access Connectors (SAMI) | 3 | One per layer; SAMI grants Unity Catalog access to storage |
| Entra ID App Registrations | 3 | One per layer; used as run-as identity for Lakeflow jobs |
| Entra ID Service Principals | 3 | Bound to the app registrations above |
| Azure Key Vault | 1 | RBAC-enabled; holds SP credentials, source secrets |
| Databricks Workspace | 1 | Premium SKU; required for Unity Catalog |
| Unity Catalog storage credentials | 3 | Each backed by one access connector SAMI |
| Unity Catalog external locations | 3 | Each pointing to one ADLS Gen2 container |
| Unity Catalog catalogs | 3 | `bronze_catalog`, `silver_catalog`, `gold_catalog` |
| Unity Catalog schemas | 3 | `raw` (bronze), `clean` (silver), `serving` (gold) |
| Databricks secret scope | 1 | AKV-backed; one scope per environment |
| Lakeflow jobs | 4 | Bronze ingestion, Silver transform, Gold aggregate, Orchestrator |
| Job clusters | 3 | One per layer; ephemeral (job cluster mode) |

---

## What Is Explicit in the Blog

- Three medallion layers: Bronze (raw ingest), Silver (cleansed/enriched), Gold (aggregated/serving)
- Per-layer isolation enforced by separate Entra ID service principals
- Azure Databricks Access Connectors with system-assigned managed identities (SAMI)
- Managed Tables in Unity Catalog (GUID-based ADLS paths)
- Separate storage accounts per layer (not a single multi-container account)
- Azure Key Vault for secrets; AKV-backed Databricks secret scopes
- `dbutils.secrets.get()` at runtime; no hardcoded credentials
- One Lakeflow Job per layer + one orchestrator job chaining them
- Apply least-privilege across Unity Catalog catalogs/schemas
- Enable system tables for observability (`system.lakeflow.*`, `system.billing.*`)
- AKV diagnostic logs for audit

---

## What Is Assumed

- **Region:** `uksouth` (default; blog does not specify)
- **Workspace SKU:** `premium` (required for Unity Catalog)
- **Storage replication:** `LRS` (minimally specified; upgrade to `ZRS`/`GRS` for production DR)
- **Managed tables** chosen (blog explicitly states this preference)
- **Cluster SKU:** `Standard_DS3_v2`, runtime `15.4.x-scala2.12` — numbers not in blog; these are reasonable defaults
- **Unity Catalog metastore:** Pre-existing at Azure account level (one per region is standard)
- **Orchestrator run-as:** Runs as the Databricks workspace admin/caller identity; blog does not define a dedicated orchestrator SP
- **No VNet injection** — blog does not request private networking; skipped per skill policy
- **One secret scope per environment** — per blog guidance

---

## What Is Missing (see TODO.md)

- Azure subscription ID
- Azure Entra ID tenant ID
- Databricks account ID
- Databricks Unity Catalog metastore ID
- SP client IDs / secrets (computed by Terraform, not pre-known)
- Workspace URL (computed by Terraform)
- Catalog names in DAB variables (must match Terraform-computed names)
- Job schedules (cron)
- Alert e-mail address
- Source system connection details (URL, credentials) for Bronze ingest
- Target table names
- Secret key names in AKV for source credentials
