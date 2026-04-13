import argparse
from datetime import datetime

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bronze ingestion job")
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--target-table", required=True)
    parser.add_argument("--source-table", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def get_dbutils(spark: SparkSession):
    try:
        return dbutils  # type: ignore[name-defined]
    except NameError:
        from pyspark.dbutils import DBUtils

        return DBUtils(spark)


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()
    utils = get_dbutils(spark)

    jdbc_host = utils.secrets.get(args.secret_scope, "jdbc-host")
    jdbc_database = utils.secrets.get(args.secret_scope, "jdbc-database")
    jdbc_user = utils.secrets.get(args.secret_scope, "jdbc-user")
    jdbc_password = utils.secrets.get(args.secret_scope, "jdbc-password")
    jdbc_url = f"jdbc:sqlserver://{jdbc_host};database={jdbc_database};encrypt=true;trustServerCertificate=false"

    df = (
        spark.read.format("jdbc")
        .option("url", jdbc_url)
        .option("dbtable", args.source_table)
        .option("user", jdbc_user)
        .option("password", jdbc_password)
        .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver")
        .load()
        .withColumn("_ingested_at", F.lit(datetime.utcnow().isoformat()))
    )

    target_table = f"{args.catalog}.{args.schema}.{args.target_table}"
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {args.catalog}.{args.schema}")
    df.write.mode("overwrite").format("delta").saveAsTable(target_table)
    print(f"Bronze ingestion complete: {target_table}")


if __name__ == "__main__":
    main()