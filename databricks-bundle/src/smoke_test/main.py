"""Run lightweight post-orchestrator checks for Bronze, Silver, and Gold tables."""

import argparse
import logging
import sys

from pyspark.sql import SparkSession

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")


def _quote(identifier: str) -> str:
    return f"`{identifier}`"


def _table_name(catalog: str, schema: str, table: str) -> str:
    return f"{_quote(catalog)}.{_quote(schema)}.{_quote(table)}"


def _read_count(spark: SparkSession, table_name: str) -> int:
    return spark.table(table_name).count()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate medallion output tables after orchestrator execution."
    )
    parser.add_argument("--bronze-catalog", required=True)
    parser.add_argument("--bronze-schema", required=True)
    parser.add_argument("--silver-catalog", required=True)
    parser.add_argument("--silver-schema", required=True)
    parser.add_argument("--gold-catalog", required=True)
    parser.add_argument("--gold-schema", required=True)
    parser.add_argument(
        "--min-row-count",
        type=int,
        default=1,
        help="Minimum row count required for each validation table.",
    )
    args = parser.parse_args()

    spark = SparkSession.builder.appName("medallion-smoke-test").getOrCreate()

    checks = [
        ("bronze", _table_name(args.bronze_catalog, args.bronze_schema, "raw_events")),
        ("silver", _table_name(args.silver_catalog, args.silver_schema, "events")),
        ("gold", _table_name(args.gold_catalog, args.gold_schema, "event_summary")),
    ]

    failures = []
    for layer, table in checks:
        try:
            count = _read_count(spark, table)
            if count < args.min_row_count:
                failures.append(
                    f"{layer} table {table} has {count} rows, expected at least {args.min_row_count}"
                )
            else:
                log.info("Smoke test passed for %s table %s with %s rows", layer, table, count)
        except Exception as exc:
            failures.append(f"{layer} table {table} check failed: {exc}")

    if failures:
        for failure in failures:
            log.error(failure)
        sys.exit(1)

    log.info("Smoke test passed for Bronze, Silver, and Gold tables.")


if __name__ == "__main__":
    main()
