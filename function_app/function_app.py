from __future__ import annotations

import json
import logging
import os

import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

from src.noaa_parser import build_climate_dataframe, dataframe_to_parquet_bytes


app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

RAW_CONTAINER = "raw"
CURATED_CONTAINER = "curated"
NOAA_PREFIX = "noaa/climate/"
CURATED_OUTPUT = "climate/climate_monthly.parquet"

FILE_PREFIXES = {
    "temperature": "climdiv-tmpcst-",
    "cdd": "climdiv-cddcst-",
    "hdd": "climdiv-hddcst-",
    "precipitation": "climdiv-pcpnst-",
}


def _blob_service() -> BlobServiceClient:
    account_name = os.environ["DATA_LAKE_ACCOUNT_NAME"]
    account_url = f"https://{account_name}.blob.core.windows.net"

    # Locally this can use Azure CLI credentials.
    # In Azure it uses the Function App's managed identity.
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

        parquet = dataframe_to_parquet_bytes(climate)

        curated.upload_blob(
            name=CURATED_OUTPUT,
            data=parquet,
            overwrite=True,
        )

        result = {
            "status": "success",
            "rows_written": len(climate),
            "min_period": climate["period"].min().strftime("%Y-%m"),
            "max_period": climate["period"].max().strftime("%Y-%m"),
            "output": f"{CURATED_CONTAINER}/{CURATED_OUTPUT}",
            "source_files": selected,
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
