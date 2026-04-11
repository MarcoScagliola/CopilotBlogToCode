# Region Policy

Reference for valid Azure regions:
- https://learn.microsoft.com/azure/reliability/regions-list

Operational rules:
- Use the explicit region from the blog when present.
- If no region is present, require user-provided azure_region.
- Do not assume a default region.
- If region is still missing, add `TODO_AZURE_REGION` to `TODO.md` and stop generation.