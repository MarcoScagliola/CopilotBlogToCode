from __future__ import annotations

import argparse
from pathlib import Path


def build_jobs_yaml() -> str:
    return """resources:
  jobs:
    setup_job:
      name: medallion-setup-${bundle.target}
      max_concurrent_runs: 1
      tags:
        layer: setup
        environment: ${bundle.target}
      job_clusters:
        - job_cluster_key: setup_cluster
          new_cluster:
            spark_version: 13.3.x-scala2.12
            node_type_id: Standard_DS3_v2
            num_workers: 1
            autotermination_minutes: 20
            data_security_mode: USER_ISOLATION
            custom_tags:
              layer: setup
      tasks:
        - task_key: setup_task
          job_cluster_key: setup_cluster
          spark_python_task:
            python_file: ../src/setup/main.py
            parameters:
              - --workspace-resource-id
              - ${var.workspace_resource_id}
              - --bronze-catalog
              - ${var.bronze_catalog}
              - --silver-catalog
              - ${var.silver_catalog}
              - --gold-catalog
              - ${var.gold_catalog}
              - --bronze-schema
              - ${var.bronze_schema}
              - --silver-schema
              - ${var.silver_schema}
              - --gold-schema
              - ${var.gold_schema}
              - --bronze-storage-account
              - ${var.bronze_storage_account}
              - --silver-storage-account
              - ${var.silver_storage_account}
              - --gold-storage-account
              - ${var.gold_storage_account}
              - --bronze-access-connector-id
              - ${var.bronze_access_connector_id}
              - --silver-access-connector-id
              - ${var.silver_access_connector_id}
              - --gold-access-connector-id
              - ${var.gold_access_connector_id}
              - --bronze-principal-client-id
              - ${var.bronze_principal_client_id}
              - --silver-principal-client-id
              - ${var.silver_principal_client_id}
              - --gold-principal-client-id
              - ${var.gold_principal_client_id}

    bronze_job:
      name: bronze-layer-${bundle.target}
      max_concurrent_runs: 1
      run_as:
        service_principal_name: ${var.bronze_principal_client_id}
      tags:
        layer: bronze
        environment: ${bundle.target}
      job_clusters:
        - job_cluster_key: bronze_cluster
          new_cluster:
            spark_version: 13.3.x-scala2.12
            node_type_id: Standard_DS3_v2
            num_workers: 1
            autotermination_minutes: 20
            data_security_mode: USER_ISOLATION
            custom_tags:
              layer: bronze
      tasks:
        - task_key: bronze_task
          job_cluster_key: bronze_cluster
          spark_python_task:
            python_file: ../src/bronze/main.py
            parameters:
              - --catalog
              - ${var.bronze_catalog}
              - --schema
              - ${var.bronze_schema}
              - --secret-scope
              - ${var.secret_scope}

    silver_job:
      name: silver-layer-${bundle.target}
      max_concurrent_runs: 1
      run_as:
        service_principal_name: ${var.silver_principal_client_id}
      tags:
        layer: silver
        environment: ${bundle.target}
      job_clusters:
        - job_cluster_key: silver_cluster
          new_cluster:
            spark_version: 13.3.x-scala2.12
            node_type_id: Standard_DS3_v2
            num_workers: 1
            autotermination_minutes: 20
            data_security_mode: USER_ISOLATION
            custom_tags:
              layer: silver
      tasks:
        - task_key: silver_task
          job_cluster_key: silver_cluster
          spark_python_task:
            python_file: ../src/silver/main.py
            parameters:
              - --source-catalog
              - ${var.bronze_catalog}
              - --source-schema
              - ${var.bronze_schema}
              - --target-catalog
              - ${var.silver_catalog}
              - --target-schema
              - ${var.silver_schema}

    gold_job:
      name: gold-layer-${bundle.target}
      max_concurrent_runs: 1
      run_as:
        service_principal_name: ${var.gold_principal_client_id}
      tags:
        layer: gold
        environment: ${bundle.target}
      job_clusters:
        - job_cluster_key: gold_cluster
          new_cluster:
            spark_version: 13.3.x-scala2.12
            node_type_id: Standard_DS3_v2
            num_workers: 1
            autotermination_minutes: 20
            data_security_mode: USER_ISOLATION
            custom_tags:
              layer: gold
      tasks:
        - task_key: gold_task
          job_cluster_key: gold_cluster
          spark_python_task:
            python_file: ../src/gold/main.py
            parameters:
              - --source-catalog
              - ${var.silver_catalog}
              - --source-schema
              - ${var.silver_schema}
              - --target-catalog
              - ${var.gold_catalog}
              - --target-schema
              - ${var.gold_schema}

    smoke_test_job:
      name: medallion-smoke-test-${bundle.target}
      max_concurrent_runs: 1
      tags:
        layer: smoke-test
        environment: ${bundle.target}
      job_clusters:
        - job_cluster_key: smoke_test_cluster
          new_cluster:
            spark_version: 13.3.x-scala2.12
            node_type_id: Standard_DS3_v2
            num_workers: 1
            autotermination_minutes: 20
            data_security_mode: USER_ISOLATION
            custom_tags:
              layer: smoke-test
      tasks:
        - task_key: smoke_test_task
          job_cluster_key: smoke_test_cluster
          spark_python_task:
            python_file: ../src/smoke_test/main.py
            parameters:
              - --bronze-catalog
              - ${var.bronze_catalog}
              - --bronze-schema
              - ${var.bronze_schema}
              - --silver-catalog
              - ${var.silver_catalog}
              - --silver-schema
              - ${var.silver_schema}
              - --gold-catalog
              - ${var.gold_catalog}
              - --gold-schema
              - ${var.gold_schema}
              - --min-row-count
              - "1"

    orchestrator_job:
      name: medallion-orchestrator-${bundle.target}
      max_concurrent_runs: 1
      tags:
        layer: orchestrator
        environment: ${bundle.target}
      tasks:
        - task_key: run_setup
          run_job_task:
            job_id: ${resources.jobs.setup_job.id}
        - task_key: run_bronze
          depends_on:
            - task_key: run_setup
          run_job_task:
            job_id: ${resources.jobs.bronze_job.id}
        - task_key: run_silver
          depends_on:
            - task_key: run_bronze
          run_job_task:
            job_id: ${resources.jobs.silver_job.id}
        - task_key: run_gold
          depends_on:
            - task_key: run_silver
          run_job_task:
            job_id: ${resources.jobs.gold_job.id}
        - task_key: run_smoke_test
          depends_on:
            - task_key: run_gold
          run_job_task:
            job_id: ${resources.jobs.smoke_test_job.id}
"""


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate databricks-bundle/resources/jobs.yml"
    )
    parser.add_argument(
        "--output",
        default="databricks-bundle/resources/jobs.yml",
        help="Output path for generated DAB jobs YAML.",
    )
    args = parser.parse_args()

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(build_jobs_yaml(), encoding="utf-8")

    print(f"Generated jobs bundle: {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())