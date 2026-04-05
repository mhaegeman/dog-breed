"""
Cloud Function (Gen2) entry-point for the Dog Breed Explorer pipeline.

Triggered by Cloud Scheduler via HTTP POST at 02:00 UTC daily.
"""

from __future__ import annotations

import logging

import functions_framework

logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(message)s")
logger = logging.getLogger(__name__)


@functions_framework.http
def handler(request):
    """HTTP handler invoked by Cloud Scheduler."""
    from pipeline import run_pipeline

    logger.info("Pipeline triggered — starting ingestion")
    try:
        results = run_pipeline()
        return {"status": "ok", "results": results}, 200
    except Exception:
        logger.exception("Pipeline failed")
        return {"status": "error"}, 500
