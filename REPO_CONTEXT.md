# Repository Context

Generated baseline defaults for the current run:

- Workload: `blg`
- Environment: `dev`
- Azure region: `uksouth`
- GitHub environment: `BLG2CODEDEV`
- Layer SP mode: `create`

Canonical naming contract used by the generated Terraform:

- Resource group: `rg-{workload}-{environment}-{region_abbrev}`
- Key Vault: `kv-{workload}-{environment}-{region_abbrev}`
- Storage account: `st{workload}{environment}{layer}{region_abbrev}`
- Databricks workspace: `dbw-{workload}-{environment}-{region_abbrev}`

Region abbreviation map for this baseline:

- `eastus` -> `eus`
- `eastus2` -> `eus2`
- `westus2` -> `wus2`
- `westeurope` -> `weu`
- `northeurope` -> `neu`
- `uksouth` -> `uks`
- `ukwest` -> `ukw`