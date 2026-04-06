# CopilotBlogToCode

Turn a technical blog post into deployment-ready infrastructure code — Terraform for Azure resources and Databricks Declarative Automation Bundles (DAB) for workspace-level objects — using a GitHub Copilot custom skill.

## What this repo does

You give it a blog URL. It:

1. **Fetches & parses** the article (`fetch_blog.py`) into structured JSON (headings, paragraphs, code blocks, cloud hint).
2. **Generates Terraform** (`infra/terraform/`) for all Azure and Unity Catalog infrastructure inferred from the article.
3. **Generates a DAB project** (`databricks-bundle/`) for Databricks jobs, clusters, and notebook source code.
4. **Produces a gap list** of values you still need to fill in (region, workspace URL, service principal IDs, etc.).

Terraform and DAB responsibilities are kept strictly separate — Terraform owns cloud resources and Unity Catalog objects; DAB owns jobs and notebooks.

## Repo structure

```
.github/skills/blog-to-databricks-iac/
  SKILL.md                  # Copilot skill definition
  scripts/fetch_blog.py     # Blog fetcher / HTML parser
  templates/output-contract.md  # Output structure contract
infra/terraform/            # Generated Terraform (versions, providers, variables, main, outputs)
databricks-bundle/          # Generated DAB project (databricks.yml, resources/, src/)
```

## How to use

### Prerequisites

- Python 3.9+
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Databricks CLI](https://docs.databricks.com/dev-tools/cli/install.html) >= 0.218
- GitHub Copilot with custom skills enabled (VS Code)

### 1. Fetch a blog

```bash
python .github/skills/blog-to-databricks-iac/scripts/fetch_blog.py "<BLOG_URL>"
```

The script outputs structured JSON. On error it returns a JSON object with `error`, `code`, and `reason` fields and exits with code 1.

### 2. Generate code via Copilot

In VS Code with Copilot, ask:

> Use the /blog-to-databricks-iac skill on this blog URL: `<BLOG_URL>`

Copilot will read the skill definition, fetch the article, and generate Terraform + DAB files following the output contract.

### 3. Deploy Terraform

```bash
cd infra/terraform
# Fill in terraform.tfvars with your subscription, region, workspace URL, etc.
terraform init
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
```

### 4. Deploy DAB

```bash
cd databricks-bundle
# Set variables (workspace_url, SP IDs, secret scope) via --var flags or databricks.yml
databricks bundle validate -t dev
databricks bundle deploy -t dev
databricks bundle run <job_name> -t dev
```

## Error codes (fetch_blog.py)

| Code | Meaning |
|------|---------|
| `USAGE` | Wrong number of arguments |
| `INVALID_URL` | URL doesn't start with `http://` or `https://` |
| `HTTP_<status>` | Server returned an HTTP error (e.g. `HTTP_404`) |
| `URL_ERROR` | DNS failure or host unreachable |
| `TIMEOUT` | No response within 30 seconds |
| `PARSE_ERROR` | HTML parsing failed |
| `EMPTY_CONTENT` | Page returned no extractable content |
