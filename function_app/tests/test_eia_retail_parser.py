from pathlib import Path
import sys

FUNCTION_APP_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(FUNCTION_APP_DIR))

from src.eia_retail_parser import build_retail_dataframe

ROOT = Path(__file__).resolve().parents[2]
EIA_RETAIL = (
    ROOT
    / "data"
    / "raw"
    / "eia"
    / "retail"
    / "HS861M_2010-current.xlsx"
)


def test_build_retail_dataframe():
    df = build_retail_dataframe(
        EIA_RETAIL.read_bytes(),
        min_year=2010,
    )

    assert not df.empty

    assert (
        df.duplicated(
            ["state_code", "year", "month", "sector"]
        ).sum()
        == 0
    )

    assert df["state_code"].nunique() == 51

    assert set(df["sector"]) == {
        "Residential",
        "Commercial",
        "Industrial",
        "Transportation",
        "Total",
    }

    assert df["month"].between(1, 12).all()

    assert df["period"].min().strftime("%Y-%m") == "2010-01"
    assert df["period"].max().strftime("%Y-%m") == "2026-06"