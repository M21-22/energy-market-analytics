from __future__ import annotations

import json
import logging
import os

import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

from src.noaa_parser import build_climate_dataframe
from src.eia_retail_parser import build_retail_dataframe
from src.eia_generation_parser import build_generation_dataframe
from src.partitioned_parquet import dataframe_to_partitioned_parquet

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

RAW_CONTAINER = "raw"
CURATED_CONTAINER = "curated"
NOAA_PREFIX = "noaa/climate/"
CURATED_OUTPUT = "climate"

EIA_RETAIL_PREFIX = "eia/retail/"
EIA_RETAIL_FILENAME = "HS861M_2010-current.xlsx"
EIA_RETAIL_OUTPUT = "eia/retail"

EIA_GENERATION_PREFIX = "eia/generation/"
EIA_GENERATION_FILENAME = "generation_monthly.xlsx"
EIA_GENERATION_OUTPUT = "eia/generation"


FILE_PREFIXES = {
    "temperature": "climdiv-tmpcst-",
    "cdd": "climdiv-cddcst-",
    "hdd": "climdiv-hddcst-",
    "precipitation": "climdiv-pcpnst-",
}


def _blob_service() -> BlobServiceClient:
    account_name = os.environ["DATA_LAKE_ACCOUNT_NAME"]
    account_url = f"https://{account_name}.blob.core.windows.net"

    # Uses the Function App's managed identity.
    credential = DefaultAzureCredential()
    return BlobServiceClient(account_url=account_url, credential=credential)


def _find_latest_blob(container_client, filename_prefix: str) -> str:
    matches = [
        blob.name
        for blob in container_client.list_blobs(name_starts_with=NOAA_PREFIX)
        if blob.name.split("/")[-1].startswith(filename_prefix)
    ]

    if not matches:
        raise FileNotFoundError(
            f"No blob found under {NOAA_PREFIX!r} with prefix {filename_prefix!r}"
        )

    # Filenames include YYYYMMDD, so lexicographic ordering selects the latest version.
    return max(matches)


def _download_text(container_client, blob_name: str) -> str:
    data = container_client.download_blob(blob_name).readall()
    return data.decode("utf-8")


def _find_blob(
    container_client,
    prefix: str,
    filename: str,
) -> str:
    matches = [
        blob.name
        for blob in container_client.list_blobs(
            name_starts_with=prefix
        )
        if blob.name.split("/")[-1] == filename
    ]

    if not matches:
        raise FileNotFoundError(
            f"File {filename!r} not found under {prefix!r}"
        )

    return matches[0]


def _download_bytes(
    container_client,
    blob_name: str,
) -> bytes:
    return container_client.download_blob(
        blob_name
    ).readall()

@app.route(route="process-noaa", methods=["POST"])
def process_noaa(req: func.HttpRequest) -> func.HttpResponse:
    try:
        body = req.get_json() if req.get_body() else {}
    except ValueError:
        body = {}

    min_year = int(body.get("min_year", 2010))

    try:
        service = _blob_service()
        raw = service.get_container_client(RAW_CONTAINER)
        curated = service.get_container_client(CURATED_CONTAINER)

        selected = {
            name: _find_latest_blob(raw, prefix)
            for name, prefix in FILE_PREFIXES.items()
        }

        climate = build_climate_dataframe(
            temperature_text=_download_text(raw, selected["temperature"]),
            cdd_text=_download_text(raw, selected["cdd"]),
            hdd_text=_download_text(raw, selected["hdd"]),
            precipitation_text=_download_text(raw, selected["precipitation"]),
            min_year=min_year,
        )

        partitions = dataframe_to_partitioned_parquet(
            climate,
            CURATED_OUTPUT,
        )

        for blob_name, parquet_bytes in partitions:
            curated.upload_blob(
                name=blob_name,
                data=parquet_bytes,
                overwrite=True,
            )

        result = {
            "status": "success",
            "rows_written": len(climate),
            "min_period": climate["period"].min().strftime("%Y-%m"),
            "max_period": climate["period"].max().strftime("%Y-%m"),
            "partitions_written": len(partitions),
        }

        logging.info("NOAA processing completed: %s", result)

        return func.HttpResponse(
            json.dumps(result),
            mimetype="application/json",
            status_code=200,
        )

    except Exception as exc:
        logging.exception("NOAA processing failed")

        return func.HttpResponse(
            json.dumps(
                {
                    "status": "failed",
                    "error": str(exc),
                }
            ),
            mimetype="application/json",
            status_code=500,
        )

@app.route(route="process-eia-retail", methods=["POST"],
)
def process_eia_retail(
    req: func.HttpRequest,
) -> func.HttpResponse:

    try:
        body = req.get_json() if req.get_body() else {}
    except ValueError:
        body = {}

    min_year = int(body.get("min_year", 2010))

    try:
        service = _blob_service()

        raw = service.get_container_client(RAW_CONTAINER)

        curated = service.get_container_client(CURATED_CONTAINER)

        source_blob = _find_blob(raw, EIA_RETAIL_PREFIX, EIA_RETAIL_FILENAME)

        retail = build_retail_dataframe(_download_bytes(raw, source_blob), min_year=min_year)

        partitions = dataframe_to_partitioned_parquet(
            retail,
            EIA_RETAIL_OUTPUT,
        )

        for blob_name, parquet_bytes in partitions:
            curated.upload_blob(
                name=blob_name,
                data=parquet_bytes,
                overwrite=True,
            )

        result = {
            "status": "success",
            "rows_written": len(retail),
            "min_period": retail["period"].min().strftime("%Y-%m"),
            "max_period": retail["period"].max().strftime("%Y-%m"),
            "partitions_written": len(partitions),
        }

        logging.info(
            "EIA Retail processing completed: %s",
            result,
        )

        return func.HttpResponse(
            json.dumps(result),
            mimetype="application/json",
            status_code=200,
        )

    except Exception as exc:
        logging.exception(
            "EIA Retail processing failed"
        )

        return func.HttpResponse(
            json.dumps(
                {
                    "status": "failed",
                    "error": str(exc),
                }
            ),
            mimetype="application/json",
            status_code=500,
        )
    
@app.route(
    route="process-eia-generation",
    methods=["POST"],
)
def process_eia_generation(
    req: func.HttpRequest,
) -> func.HttpResponse:

    try:
        body = req.get_json() if req.get_body() else {}
    except ValueError:
        body = {}

    min_year = int(body.get("min_year", 2010))

    try:
        service = _blob_service()

        raw = service.get_container_client(RAW_CONTAINER)

        curated = service.get_container_client(CURATED_CONTAINER)

        source_blob = _find_blob(raw, EIA_GENERATION_PREFIX, EIA_GENERATION_FILENAME)

        generation = build_generation_dataframe(_download_bytes(raw, source_blob), min_year=min_year)

        partitions = dataframe_to_partitioned_parquet(
            generation,
            EIA_GENERATION_OUTPUT,
        )

        for blob_name, parquet_bytes in partitions:
            curated.upload_blob(
                name=blob_name,
                data=parquet_bytes,
                overwrite=True,
            )

        result = {
            "status": "success",
            "rows_written": len(generation),
            "min_period": (generation["period"].min().strftime("%Y-%m")),
            "max_period": (generation["period"].max().strftime("%Y-%m")),
            "partitions_written": len(partitions),
        }

        logging.info(
            "EIA Generation processing "
            "completed: %s",
            result,
        )

        return func.HttpResponse(
            json.dumps(result),
            mimetype="application/json",
            status_code=200,
        )

    except Exception as exc:
        logging.exception(
            "EIA Generation processing failed"
        )

        return func.HttpResponse(
            json.dumps(
                {
                    "status": "failed",
                    "error": str(exc),
                }
            ),
            mimetype="application/json",
            status_code=500,
        )