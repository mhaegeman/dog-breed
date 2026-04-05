"""
Dog Breed Explorer — dlt ingestion pipeline.

Pulls all breeds from The Dog API and loads them into two destinations:
  1. Cloud Storage  – raw JSONL archived by run date (gs://…/raw/dog_breeds/YYYY-MM-DD/)
  2. BigQuery       – bronze.dog_api_raw (full replace on every run)

Usage (local):
    export DOG_API_KEY="your-key"          # optional but recommended
    export DESTINATION__FILESYSTEM__BUCKET_URL="gs://your-bucket"
    python pipeline.py

In Cloud Functions the same code is called from main.py.
"""

from __future__ import annotations

import logging
import os
from datetime import date, timezone, datetime

import dlt
import requests

logger = logging.getLogger(__name__)

DOG_API_BASE_URL = "https://api.thedogapi.com/v1"


# ---------------------------------------------------------------------------
# dlt resource — fetches all breeds from The Dog API
# ---------------------------------------------------------------------------

@dlt.resource(name="dog_api_raw", write_disposition="replace")
def dog_breeds_resource():
    """Yield every breed returned by the Dog API as individual records.

    The API returns the full breed list in a single JSON array (~170 breeds),
    so pagination is not required.  We use ``write_disposition="replace"`` to
    fully refresh the table on each run.
    """
    api_key = os.getenv("DOG_API_KEY", "")
    headers = {"x-api-key": api_key} if api_key else {}

    response = requests.get(
        f"{DOG_API_BASE_URL}/breeds",
        headers=headers,
        timeout=30,
    )
    response.raise_for_status()

    breeds = response.json()
    logger.info("Fetched %d breeds from The Dog API", len(breeds))

    yield breeds


# ---------------------------------------------------------------------------
# Pipeline orchestration
# ---------------------------------------------------------------------------

def run_pipeline() -> dict:
    """Execute the dual-destination pipeline and return load info summaries."""
    run_date = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    bucket_url = os.getenv(
        "DESTINATION__FILESYSTEM__BUCKET_URL",
        dlt.config.get("destination.filesystem.bucket_url", str) or "gs://dog-breed-explorer-raw",
    )

    results = {}

    # ── 1. Archive raw JSON to Cloud Storage, partitioned by date ─────────
    gcs_pipeline = dlt.pipeline(
        pipeline_name="dog_breeds_gcs",
        destination="filesystem",
        dataset_name=f"raw/dog_breeds/{run_date}",
    )
    gcs_info = gcs_pipeline.run(
        dog_breeds_resource(),
        loader_file_format="jsonl",
    )
    logger.info("GCS load complete: %s", gcs_info)
    results["gcs"] = str(gcs_info)

    # ── 2. Load into BigQuery bronze layer ────────────────────────────────
    bq_pipeline = dlt.pipeline(
        pipeline_name="dog_breeds_bq",
        destination=dlt.destinations.bigquery(location="europe-west1"),
        dataset_name="bronze",
    )
    bq_info = bq_pipeline.run(dog_breeds_resource())
    logger.info("BigQuery load complete: %s", bq_info)
    results["bigquery"] = str(bq_info)

    return results


# ---------------------------------------------------------------------------
# Local execution entry-point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(message)s")
    info = run_pipeline()
    print("\n=== Pipeline finished ===")
    for dest, summary in info.items():
        print(f"\n--- {dest} ---\n{summary}")
