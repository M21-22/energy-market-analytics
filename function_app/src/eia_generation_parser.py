from __future__ import annotations

from io import BytesIO

import pandas as pd


OUTPUT_COLUMNS = [
    "period",
    "year",
    "month",
    "state_code",
    "producer_type",
    "energy_source",
    "generation_mwh",
    "data_status",
]


def build_generation_dataframe(
    excel_bytes: bytes,
    *,
    min_year: int = 2010,
) -> pd.DataFrame:
    workbook = pd.ExcelFile(
        BytesIO(excel_bytes),
        engine="openpyxl",
    )

    frames: list[pd.DataFrame] = []

    for sheet_name in workbook.sheet_names:
        if sheet_name == "EnergySource_Notes":
            continue

        df = _read_generation_sheet(
            workbook,
            sheet_name,
        )

        if df.empty:
            continue

        df["data_status"] = _status_from_sheet(
            sheet_name
        )

        frames.append(df)

    if not frames:
        raise ValueError(
            "No EIA generation data found"
        )

    generation = pd.concat(
        frames,
        ignore_index=True,
    )

    generation["year"] = pd.to_numeric(
        generation["year"],
        errors="coerce",
    )

    generation["month"] = pd.to_numeric(
        generation["month"],
        errors="coerce",
    )

    generation["generation_mwh"] = pd.to_numeric(
        generation["generation_mwh"],
        errors="coerce",
    )

    generation = generation.dropna(
        subset=[
            "year",
            "month",
            "state_code",
            "producer_type",
            "energy_source",
            "generation_mwh",
        ]
    ).copy()

    generation["year"] = (
        generation["year"].astype(int)
    )
    generation["month"] = (
        generation["month"].astype(int)
    )

    generation = generation[
        generation["year"] >= min_year
    ].copy()

    for column in [
        "state_code",
        "producer_type",
        "energy_source",
    ]:
        generation[column] = (
            generation[column]
            .astype(str)
            .str.strip()
        )

    generation = generation[
        ~generation["state_code"].str.upper().isin(
            {"US-TOTAL"}
        )
    ].copy()

    generation["period"] = pd.to_datetime(
        {
            "year": generation["year"],
            "month": generation["month"],
            "day": 1,
        }
    )

    generation = generation[
        OUTPUT_COLUMNS
    ].sort_values(
        [
            "period",
            "state_code",
            "producer_type",
            "energy_source",
        ],
        ignore_index=True,
    )

    _validate_generation(generation)

    return generation


def _read_generation_sheet(
    workbook: pd.ExcelFile,
    sheet_name: str,
) -> pd.DataFrame:

    raw = pd.read_excel(
        workbook,
        sheet_name=sheet_name,
        header=None,
    )

    header_row = _find_header_row(raw)

    if header_row is None:
        raise ValueError(
            f"Header row not found in sheet "
            f"{sheet_name!r}"
        )

    header = (
        raw.iloc[header_row]
        .astype(str)
        .str.strip()
        .str.replace("\n", " ", regex=False)
    )

    df = raw.iloc[
        header_row + 1 :
    ].copy()

    df.columns = header

    normalized_columns = {}

    for column in df.columns:
        normalized = (
            str(column)
            .strip()
            .upper()
            .replace("\n", " ")
        )

        if normalized == "YEAR":
            normalized_columns[column] = "year"

        elif normalized == "MONTH":
            normalized_columns[column] = "month"

        elif normalized == "STATE":
            normalized_columns[column] = (
                "state_code"
            )

        elif "TYPE OF PRODUCER" in normalized:
            normalized_columns[column] = (
                "producer_type"
            )

        elif "ENERGY SOURCE" in normalized:
            normalized_columns[column] = (
                "energy_source"
            )

        elif "GENERATION" in normalized:
            normalized_columns[column] = (
                "generation_mwh"
            )

    df = df.rename(
        columns=normalized_columns
    )

    required = [
        "year",
        "month",
        "state_code",
        "producer_type",
        "energy_source",
        "generation_mwh",
    ]

    missing = [
        column
        for column in required
        if column not in df.columns
    ]

    if missing:
        raise ValueError(
            f"Missing columns in "
            f"{sheet_name!r}: {missing}"
        )

    return df[required].copy()


def _find_header_row(
    df: pd.DataFrame,
) -> int | None:

    # Header occurs either immediately or after
    # introductory EIA metadata rows.
    for index in range(
        min(15, len(df))
    ):
        values = {
            str(value)
            .strip()
            .upper()
            .replace("\n", " ")
            for value in df.iloc[index]
            if pd.notna(value)
        }

        if {
            "YEAR",
            "MONTH",
            "STATE",
        }.issubset(values):
            return index

    return None


def _status_from_sheet(
    sheet_name: str,
) -> str:
    name = sheet_name.upper()

    if "PRELIMINARY" in name:
        return "Preliminary"

    if "FINAL" in name:
        return "Final"

    return "Unknown"


def _validate_generation(
    df: pd.DataFrame,
) -> None:

    key = [
        "state_code",
        "year",
        "month",
        "producer_type",
        "energy_source",
    ]

    if df.duplicated(key).any():
        duplicates = df[
            df.duplicated(
                key,
                keep=False,
            )
        ][key]

        raise ValueError(
            "Duplicate State × Month × "
            "Producer Type × Energy Source "
            "rows found:\n"
            f"{duplicates.head()}"
        )

    if not df["month"].between(
        1,
        12,
    ).all():
        raise ValueError(
            "Month outside 1-12 detected"
        )