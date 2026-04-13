"""
Bronze ingestion layer – reads source data via JDBC and writes to Bronze managed table.

Usage (via Databricks job parameters):
  --catalog         Bronze Unity Catalog name
  --schema          Bronze schema name
  --secret_scope    Databricks secret scope (Key Vault-backed)
  --source_table_name  Source table to ingest
"""

import argparse
from pyspark.sql import SparkSession


def parse_args():
    parser = argparse.ArgumentParser(description="Bronze ingestion job")
    parser.add_argument("--catalog", required=True, help="Bronze Unity Catalog name")
    parser.add_argument("--schema", required=True, help="Bronze schema name")
    parser.add_argument("--secret_scope", required=True, help="Databricks secret scope name")
    parser.add_argument("--source_table_name", required=True, help="Source table name to ingest")
    return parser.parse_args()


def get_jdbc_options(secret_scope: str, spark: SparkSession) -> dict:
    host = spark.conf.get("spark.databricks.bronze.jdbcHost",
                          dbutils.secrets.get(secret_scope, "jdbc-host"))  # noqa: F821
    database = spark.conf.get("spark.databricks.bronze.jdbcDatabase",
                               dbutils.secrets.get(secret_scope, "jdbc-database"))  # noqa: F821
    user = dbutils.secrets.get(secret_scope, "jdbc-user")  # noqa: F821
    password = dbutils.secrets.get(secret_scope, "jdbc-password")  # noqa: F821

    return {
        "url": f"jdbc:sqlserver://{host};databaseName={database}",
        "user": user,
        "password": password,
        "driver": "com.microsoft.sqlserver.jdbc.SQLServerDriver",
    }


def main():
    args = parse_args()

    spark = SparkSession.builder.getOrCreate()
    spark.conf.set("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")

    jdbc_opts = get_jdbc_options(args.secret_scope, spark)

    # Read from JDBC source
    source_df = (
        spark.read.format("jdbc")
        .option("url", jdbc_opts["url"])
        .option("dbtable", args.source_table_name)
        .option("user", jdbc_opts["user"])
        .option("password", jdbc_opts["password"])
        .option("driver", jdbc_opts["driver"])
        .load()
    )

    # Write to Bronze managed Delta table
    target_table = f"`{args.catalog}`.`{args.schema}`.`{args.source_table_name}`"

    (
        source_df.write.format("delta")
        .mode("append")
        .option("mergeSchema", "true")
        .saveAsTable(target_table)
    )

    print(f"[bronze] Wrote {source_df.count()} rows to {target_table}")


if __name__ == "__main__":
    main()
