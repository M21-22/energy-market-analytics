from io import BytesIO

import pandas as pd

from src.partitioned_parquet import dataframe_to_partitioned_parquet

def test_dataframe_is_partitioned_by_year_and_month():
    df = pd.DataFrame(
        {
            "year": [2025, 2025, 2026],
            "month": [12, 12, 1],
            "value": [10, 20, 30],
        }
    )

    files = dataframe_to_partitioned_parquet(
        df,
        "test/data",
    )

    assert len(files) == 2

    paths = [path for path, _ in files]

    assert paths == [
        "test/data/year=2025/month=12/data.parquet",
        "test/data/year=2026/month=01/data.parquet",
    ]


def test_partition_contains_only_its_rows():
    df = pd.DataFrame(
        {
            "year": [2025, 2025, 2026],
            "month": [12, 12, 1],
            "value": [10, 20, 30],
        }
    )

    files = dataframe_to_partitioned_parquet(
        df,
        "test/data",
    )

    _, parquet_bytes = files[0]

    result = pd.read_parquet(BytesIO(parquet_bytes))

    assert len(result) == 2
    assert set(result["value"]) == {10, 20}
    assert set(result["year"]) == {2025}
    assert set(result["month"]) == {12}


def test_missing_partition_columns_raises_error():
    df = pd.DataFrame(
        {
            "period": ["2025-01-01"],
            "value": [10],
        }
    )

    try:
        dataframe_to_partitioned_parquet(
            df,
            "test/data",
        )
        assert False, "Expected ValueError"
    except ValueError as exc:
        assert "Missing partition columns" in str(exc)


