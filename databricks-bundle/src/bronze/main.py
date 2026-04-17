import argparse

from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    spark = SparkSession.builder.getOrCreate()

    scope = args.secret_scope
    jdbc_host = dbutils.secrets.get(scope, "jdbc-host")  # noqa: F821
    jdbc_db = dbutils.secrets.get(scope, "jdbc-database")  # noqa: F821
    jdbc_user = dbutils.secrets.get(scope, "jdbc-user")  # noqa: F821
    jdbc_pass = dbutils.secrets.get(scope, "jdbc-password")  # noqa: F821

    jdbc_url = f"jdbc:sqlserver://{jdbc_host};databaseName={jdbc_db};encrypt=true;trustServerCertificate=false"

    df = (
        spark.read.format("jdbc")
        .option("url", jdbc_url)
        .option("dbtable", "dbo.source_table")
        .option("user", jdbc_user)
        .option("password", jdbc_pass)
        .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver")
        .load()
    )

    df = df.withColumn("_ingested_at", current_timestamp())
    target = f"`{args.catalog}`.`{args.schema}`.`source_raw`"
    df.write.format("delta").mode("append").saveAsTable(target)


if __name__ == "__main__":
    main()
