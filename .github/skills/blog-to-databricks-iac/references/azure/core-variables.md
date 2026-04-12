# Core Variables Policy

These are mandatory baseline inputs for any run:

- TODO_AZURE_TENANT_ID
- TODO_AZURE_SUBSCRIPTION_ID

## Canonical mapping

Use this mapping consistently across artifacts:

- TODO_AZURE_TENANT_ID -> terraform variable: azure_tenant_id -> workflow_dispatch input: azure_tenant_id
- TODO_AZURE_SUBSCRIPTION_ID -> terraform variable: azure_subscription_id -> workflow_dispatch input: azure_subscription_id

## Rules

1. Never hardcode these values in repository files.
2. For this repo workflows, pass these values as required `workflow_dispatch` inputs.
3. If values are unavailable at generation time, keep them unresolved in TODO.md.
4. When creating terraform examples, leave placeholders and document secure value injection.

## CI usage standard

In GitHub Actions workflows, consume:

- github.event.inputs.azure_tenant_id
- github.event.inputs.azure_subscription_id

and pass them to Terraform via environment variables or tfvars generation in workflow steps.
