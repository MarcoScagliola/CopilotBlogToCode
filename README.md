# Secure Medallion Architecture on Azure Databricks

This repository implements the architecture from:
https://techcommunity.microsoft.com/blog/analyticsonazure/secure-medallion-architecture-pattern-on-azure-databricks-part-i/4459268

It deploys a security-first Medallion design where Bronze, Silver, and Gold run as isolated jobs with dedicated identities and tightly scoped access.

## Prerequisites
- Azure service principal with required RBAC permissions
- GitHub Environment configured with Azure secrets
- Terraform and Databricks CLI available in CI/CD

## Required GitHub Secrets
### Always Required
- AZURE_TENANT_ID
- AZURE_SUBSCRIPTION_ID
- AZURE_CLIENT_ID
- AZURE_CLIENT_SECRET
- AZURE_SP_OBJECT_ID

### Conditional (layer_sp_mode=existing)
- EXISTING_LAYER_SP_CLIENT_ID
- EXISTING_LAYER_SP_OBJECT_ID

### Runtime (in Azure Key Vault)
- jdbc-host
- jdbc-database
- jdbc-user
- jdbc-password

## Workflows
- Validate Terraform: `.github/workflows/validate-terraform.yml`
- Deploy Infrastructure: `.github/workflows/deploy-infrastructure.yml`
- Deploy DAB: `.github/workflows/deploy-dab.yml`

## Deployment Flow
1. Run Validate Terraform.
2. Run Deploy Infrastructure with desired inputs.
3. Populate JDBC secrets in Key Vault.
4. Run Deploy DAB.

## References
- [SPEC.md](SPEC.md)
- [TODO.md](TODO.md)
