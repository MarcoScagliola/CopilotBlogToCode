import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def parse_args():
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
    return parser.parse_args()


def main():
    args = parse_args()

    spark = SparkSession.builder.getOrCreate()
    dbutils = spark._jvm.com.databricks.service.DBUtils(spark._jsc.sc())  # noqa: SIM112

    jdbc_host = dbutils.secrets.get(scope=args.secret_scope, key=args.jdbc_host_key)
    jdbc_database = dbutils.secrets.get(scope=args.secret_scope, key=args.jdbc_database_key)
    jdbc_user = dbutils.secrets.get(scope=args.secret_scope, key=args.jdbc_user_key)
    jdbc_password = dbutils.secrets.get(scope=args.secret_scope, key=args.jdbc_password_key)

    jdbc_url = f"jdbc:sqlserver://{jdbc_host};databaseName={jdbc_database};encrypt=true;trustServerCertificate=false"

    df = (
        spark.read.format("jdbc")
        .option("url", jdbc_url)
        .option("dbtable", args.source_query)
        .option("user", jdbc_user)
        .option("password", jdbc_password)
        .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver")
        .load()
    )

    df = df.withColumn("_ingested_at", F.current_timestamp())

    target_table = f"{args.catalog}.{args.schema}.{args.table}"
    df.write.format("delta").mode("append").saveAsTable(target_table)


if __name__ == "__main__":
    main()
