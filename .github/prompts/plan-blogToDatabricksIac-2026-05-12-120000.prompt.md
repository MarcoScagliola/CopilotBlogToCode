---
mode: agent
tools:
  - read_file
  - create_file
  - apply_patch
  - semantic_search
  - grep_search
  - file_search
  - list_dir
  - execution_subagent
---

Use the blog-to-databricks-iac skill on this article:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

Inputs:
- workload: blg
- environment: dev
- azure_region: uksouth
- layer_sp_mode: existing
