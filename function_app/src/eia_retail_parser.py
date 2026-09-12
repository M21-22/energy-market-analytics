from __future__ import annotations

from io import BytesIO

import pandas as pd


SHEET_NAME = "Monthly-States"

SECTORS = [
    "Residential",
    "Commercial",
    "Industrial",
    "Transportation",
    "Total",
]

OUTPUT_COLUMNS = [
    "period",
    "year",
    "month",
    "state_code",
    "sector",
    "revenue_thousand_dollars",
    "sales_mwh",
    "customer_count",
    "avg_price_cents_per_kwh",
    "data_status",
]


def build_retail_dataframe(
    excel_bytes: bytes,
    *,
    min_year: int = 2010,
) -> pd.DataFrame:
    """
    Convert EIA Monthly-States workbook from wide sector columns into:

        State × Month × Sector
    """

    df = pd.read_excel(
        BytesIO(excel_bytes),
        sheet_name=SHEET_NAME,
        header=None,
        skiprows=3,
        engine="openpyxl",
    )

    # The actual Monthly-States table contains 24 columns.
    df = df.iloc[:, :24].copy()

    df.columns = [
        "year",
        "month",
        "state_code",
        "data_status",
        *[f"value_{i}" for i in range(20)],
    ]

    # Removes the notes/footer row automatically.
    df["year"] = pd.to_numeric(df["year"], errors="coerce")
    df["month"] = pd.to_numeric(df["month"], errors="coerce")

    df = df.dropna(
        subset=["year", "month", "state_code"]
    ).copy()

    df["year"] = df["year"].astype(int)
    df["month"] = df["month"].astype(int)

    df = df[df["year"] >= min_year].copy()

    frames: list[pd.DataFrame] = []

    # Each sector occupies four consecutive columns:
    # Revenue, Sales, Customers, Price
    for sector_index, sector in enumerate(SECTORS):
        start = 4 + sector_index * 4

        sector_df = pd.DataFrame(
            {
                "year": df["year"],
                "month": df["month"],
                "state_code": df["state_code"]
                .astype(str)
                .str.strip(),
                "sector": sector,
                "revenue_thousand_dollars": pd.to_numeric(
                    df.iloc[:, start],
                    errors="coerce",
                ),
                "sales_mwh": pd.to_numeric(
                    df.iloc[:, start + 1],
                    errors="coerce",
                ),
                "customer_count": pd.to_numeric(
                    df.iloc[:, start + 2],
                    errors="coerce",
                ),
                "avg_price_cents_per_kwh": pd.to_numeric(
                    df.iloc[:, start + 3],
                    errors="coerce",
                ),
                "data_status": df["data_status"]
                .astype(str)
                .str.strip(),
            }
        )

        frames.append(sector_df)

    retail = pd.concat(frames, ignore_index=True)

    retail["period"] = pd.to_datetime(
        {
            "year": retail["year"],
            "month": retail["month"],
            "day": 1,
        }
    )

    retail = retail[OUTPUT_COLUMNS].sort_values(
        ["period", "state_code", "sector"],
        ignore_index=True,
    )

    _validate_retail(retail)

    return retail


def _validate_retail(df: pd.DataFrame) -> None:
    key = ["state_code", "year", "month", "sector"]

    if df.duplicated(key).any():
        duplicates = df[
            df.duplicated(key, keep=False)
        ][key]

        raise ValueError(
            "Duplicate State × Month × Sector rows found:\n"
            f"{duplicates.head()}"
        )

    if not df["month"].between(1, 12).all():
        raise ValueError("Month outside 1-12 detected")

    unknown_sectors = set(df["sector"]) - set(SECTORS)

    if unknown_sectors:
        raise ValueError(
            f"Unexpected sectors: {sorted(unknown_sectors)}"
        )


def dataframe_to_parquet_bytes(df: pd.DataFrame) -> bytes:
    buffer = BytesIO()

    df.to_parquet(
        buffer,
        index=False,
        engine="pyarrow",
    )

    return buffer.getvalue()