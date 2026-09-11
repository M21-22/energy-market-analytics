from pathlib import Path
import sys

FUNCTION_APP_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(FUNCTION_APP_DIR))

from src.noaa_parser import build_climate_dataframe


ROOT = Path(__file__).resolve().parents[2]
NOAA = ROOT / "data" / "raw" / "noaa" / "climate"


def _read(prefix: str) -> str:
    path = next(NOAA.glob(f"{prefix}*.txt"))
    return path.read_text(encoding="utf-8")


def test_build_climate_dataframe():
    df = build_climate_dataframe(
        temperature_text=_read("climdiv-tmpcst-"),
        cdd_text=_read("climdiv-cddcst-"),
        hdd_text=_read("climdiv-hddcst-"),
        precipitation_text=_read("climdiv-pcpnst-"),
        min_year=2010,
    )

    assert not df.empty
    assert df.duplicated(["state_code", "year", "month"]).sum() == 0
    assert df["state_code"].nunique() == 50
    assert df["month"].between(1, 12).all()

    # Supplied 2026-09-04 source version contains observed data through Aug 2026.
    assert df["period"].max().strftime("%Y-%m") == "2026-08"
