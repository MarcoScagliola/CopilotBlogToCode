"""Run quick row-count checks across medallion tables."""

import argparse
import logging
from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _count_rows(spark: SparkSession, fq_table: str) -> int:
    return spark.table(fq_table).count()


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate bronze/silver/gold tables contain rows.")
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument("--min-row-count", required=True, type=int)
    args = parser.parse_args()

    spark = SparkSession.builder.getOrCreate()

    checks = {
        "bronze": f"`{args.bronze_catalog}`.`{args.bronze_schema}`.`orders_raw`",
        "silver": f"`{args.silver_catalog}`.`{args.silver_schema}`.`orders_curated`",
        "gold": f"`{args.gold_catalog}`.`{args.gold_schema}`.`daily_sales`",
    }

    for layer, table_name in checks.items():
        rows = _count_rows(spark, table_name)
        if rows < args.min_row_count:
            raise RuntimeError(f"Smoke test failed for {layer}: {rows} rows in {table_name}")
        log.info("Smoke test passed for %s (%s rows)", layer, rows)


if __name__ == "__main__":
    main()
