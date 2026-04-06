---
name: blog-to-databricks-iac
description: Use this skill when the user provides a technical blog URL and wants Terraform plus Declarative Automation Bundles (DAB) code generated from the article.
---

# Blog URL to Terraform + DAB

This skill converts a technical article into implementation-ready infrastructure code.

## When to use this skill

Use this skill when:
- the user gives a public blog URL
- the user wants Terraform code
- the user wants Databricks Declarative Automation Bundles (DAB) code
- the user wants infra inferred from architecture, setup, pipeline, job, storage, secrets, identities, networking, or deployment details in a blog post

## Goal

Given a blog URL, produce:
1. a concise architecture/spec summary
2. a gap list of unknown values
3. Terraform code
4. a DAB project with `databricks.yml`
5. a README explaining assumptions and deployment steps

## Required behavior

### 1) Fetch and extract the article
Run:

```bash
python .github/skills/blog-to-databricks-iac/scripts/fetch_blog.py "<BLOG_URL>" > /tmp/blog_spec.json