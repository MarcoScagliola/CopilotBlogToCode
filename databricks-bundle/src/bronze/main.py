from __future__ import annotations

import argparse
import logging

from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp, lit


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bronze ingestion job")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--table", required=True)
    parser.add_argument("--secret-scope", required=True)
    parser.add_argument("--jdbc-host-key", required=True)
    parser.add_argument("--jdbc-database-key", required=True)
    parser.add_argument("--jdbc-user-key", required=True)
    parser.add_argument("--jdbc-password-key", required=True)
    parser.add_argument("--source-query", required=True)
    parser.add_argument("--jdbc-driver", default="com.microsoft.sqlserver.jdbc.SQLServerDriver")
    return parser.parse_args()


def get_dbutils(spark: SparkSession):
    if "dbutils" in globals():
        return globals()["dbutils"]

    from pyspark.dbutils import DBUtils

    return DBUtils(spark)


def build_jdbc_url(host: str, database: str) -> str:
    return (
        f"jdbc:sqlserver://{host}:1433;"
        f"database={database};"
        "encrypt=true;"
        "trustServerCertificate=false;"
        "hostNameInCertificate=*.database.windows.net;"
        "loginTimeout=30;"
    )


def main() -> None:
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    args = parse_args()
    spark = SparkSession.builder.appName("secure-medallion-bronze").getOrCreate()
    dbutils = get_dbutils(spark)

    host = dbutils.secrets.get(args.secret_scope, args.jdbc_host_key)
    database = dbutils.secrets.get(args.secret_scope, args.jdbc_database_key)
    username = dbutils.secrets.get(args.secret_scope, args.jdbc_user_key)
    password = dbutils.secrets.get(args.secret_scope, args.jdbc_password_key)
    target_table = f"{args.catalog}.{args.schema}.{args.table}"

    logging.info("Reading source data for Bronze layer")
    frame = (
        spark.read.format("jdbc")
        .option("url", build_jdbc_url(host, database))
        .option("dbtable", args.source_query)
        .option("user", username)
        .option("password", password)
        .option("driver", args.jdbc_driver)
        .load()
        .withColumn("medallion_layer", lit("bronze"))
        .withColumn("ingested_at", current_timestamp())
    )

    logging.info("Writing Bronze managed table %s", target_table)
    frame.write.mode("append").option("mergeSchema", "true").saveAsTable(target_table)


if __name__ == "__main__":
    main()