from __future__ import annotations

from io import BytesIO

import pandas as pd


def dataframe_to_partitioned_parquet(
    df: pd.DataFrame,
    base_path: str,
) -> list[tuple[str, bytes]]:
    """
    Convert a DataFrame into year/month Parquet partitions.

    """

    required = {"year", "month"}
    missing = required - set(df.columns)

    if missing:
        raise ValueError(
            f"Missing partition columns: {sorted(missing)}"
        )

    if df.empty:
        return []

    working_df = df.copy()

    files: list[tuple[str, bytes]] = []

    for (year, month), partition in working_df.groupby(
        ["year", "month"],
        sort=True,
    ):
        buffer = BytesIO()

        partition.to_parquet(
            buffer,
            index=False,
            engine="pyarrow",
            coerce_timestamps="ms",
            allow_truncated_timestamps=True,
        )

        blob_name = (
            f"{base_path}/"
            f"year={int(year)}/"
            f"month={int(month):02d}/"
            "data.parquet"
        )

        files.append((blob_name, buffer.getvalue()))

    return files