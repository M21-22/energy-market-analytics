from pathlib import Path
import sys


FUNCTION_APP_DIR = (
    Path(__file__).resolve().parents[1]
)

sys.path.insert(
    0,
    str(FUNCTION_APP_DIR),
)

from src.eia_generation_parser import (
    build_generation_dataframe,
)


ROOT = Path(__file__).resolve().parents[2]

EIA_GENERATION = (
    ROOT
    / "data"
    / "raw"
    / "eia"
    / "generation"
    / "generation_monthly.xlsx"
)


def test_build_generation_dataframe():
    df = build_generation_dataframe(
        EIA_GENERATION.read_bytes(),
        min_year=2010,
    )

    assert not df.empty

    assert (
        df.duplicated(
            [
                "state_code",
                "year",
                "month",
                "producer_type",
                "energy_source",
            ]
        ).sum()
        == 0
    )

    assert df["month"].between(
        1,
        12,
    ).all()

    assert (
        df["generation_mwh"].notna().all()
    )

    assert (
        df["period"]
        .min()
        .strftime("%Y-%m")
        == "2010-01"
    )

    # Important:
    # negative generation values are valid
    # and must not be filtered out.
    assert (
        df["generation_mwh"].min()
        < 0
    )

    assert set(
        df["data_status"].unique()
    ).issubset(
        {
            "Final",
            "Preliminary",
        }
    )