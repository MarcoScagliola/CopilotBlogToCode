import argparse
from pyspark.sql import SparkSession
from pyspark.sql.functions import current_timestamp


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog", required=True)
    parser.add_argument("--schema", required=True)
    parser.add_argument("--secret-scope", required=True)
    return parser.parse_args()


def main():
    args = parse_args()
    spark = SparkSession.builder.appName("bronze-ingest").getOrCreate()

    jdbc_url = dbutils.secrets.get(args.secret_scope, "jdbc-connection-string")
    jdbc_user = dbutils.secrets.get(args.secret_scope, "jdbc-username")
    jdbc_password = dbutils.secrets.get(args.secret_scope, "jdbc-password")
    source_table = dbutils.secrets.get(args.secret_scope, "source-table-name")

    df = (
        spark.read.format("jdbc")
        .option("url", jdbc_url)
        .option("dbtable", source_table)
        .option("user", jdbc_user)
        .option("password", jdbc_password)
        .load()
        .withColumn("ingestion_ts", current_timestamp())
    )

    target_table = f"{args.catalog}.{args.schema}.raw_data"
    df.write.format("delta").mode("append").saveAsTable(target_table)


if __name__ == "__main__":
    main()
