from __future__ import annotations

from functools import reduce
from io import BytesIO
from typing import Iterable

import pandas as pd


# NOAA nClimDiv statewide codes used by the *st files.
# These are NOAA state codes, not FIPS codes.
NOAA_STATE_MAP = {
    "001": ("AL", "Alabama"),
    "002": ("AZ", "Arizona"),
    "003": ("AR", "Arkansas"),
    "004": ("CA", "California"),
    "005": ("CO", "Colorado"),
    "006": ("CT", "Connecticut"),
    "007": ("DE", "Delaware"),
    "008": ("FL", "Florida"),
    "009": ("GA", "Georgia"),
    "010": ("ID", "Idaho"),
    "011": ("IL", "Illinois"),
    "012": ("IN", "Indiana"),
    "013": ("IA", "Iowa"),
    "014": ("KS", "Kansas"),
    "015": ("KY", "Kentucky"),
    "016": ("LA", "Louisiana"),
    "017": ("ME", "Maine"),
    "018": ("MD", "Maryland"),
    "019": ("MA", "Massachusetts"),
    "020": ("MI", "Michigan"),
    "021": ("MN", "Minnesota"),
    "022": ("MS", "Mississippi"),
    "023": ("MO", "Missouri"),
    "024": ("MT", "Montana"),
    "025": ("NE", "Nebraska"),
    "026": ("NV", "Nevada"),
    "027": ("NH", "New Hampshire"),
    "028": ("NJ", "New Jersey"),
    "029": ("NM", "New Mexico"),
    "030": ("NY", "New York"),
    "031": ("NC", "North Carolina"),
    "032": ("ND", "North Dakota"),
    "033": ("OH", "Ohio"),
    "034": ("OK", "Oklahoma"),
    "035": ("OR", "Oregon"),
    "036": ("PA", "Pennsylvania"),
    "037": ("RI", "Rhode Island"),
    "038": ("SC", "South Carolina"),
    "039": ("SD", "South Dakota"),
    "040": ("TN", "Tennessee"),
    "041": ("TX", "Texas"),
    "042": ("UT", "Utah"),
    "043": ("VT", "Vermont"),
    "044": ("VA", "Virginia"),
    "045": ("WA", "Washington"),
    "046": ("WV", "West Virginia"),
    "047": ("WI", "Wisconsin"),
    "048": ("WY", "Wyoming"),
    "049": ("HI", "Hawaii"),
    "050": ("AK", "Alaska"),
}

# Element codes observed in the supplied NOAA statewide files.
EXPECTED_ELEMENT_CODES = {
    "precipitation": "001",
    "avg_temperature": "002",
    "heating_degree_days": "025",
    "cooling_degree_days": "026",
}

# NOAA missing-value sentinels in the supplied files.
MISSING_SENTINELS = {
    "precipitation": {-9.99},
    "avg_temperature": {-99.90},
    "heating_degree_days": {-9999.0},
    "cooling_degree_days": {-9999.0},
}


def _is_missing(metric: str, value: float) -> bool:
    return value in MISSING_SENTINELS[metric]


def parse_statewide_file(
    text: str,
    metric: str,
    *,
    min_year: int = 2010,
) -> pd.DataFrame:
    """
    Parse one NOAA nClimDiv statewide (*st) fixed-width text file.

    Record identifier:
        characters 1-3  : NOAA state/location code
        characters 4-6  : element code
        characters 7-10 : year
        remainder       : 12 monthly values

    Only NOAA state codes 001-050 are retained. Regional/national rows
    that also occur in statewide files are intentionally excluded.
    """
    if metric not in EXPECTED_ELEMENT_CODES:
        raise ValueError(f"Unsupported metric: {metric}")

    expected_element = EXPECTED_ELEMENT_CODES[metric]
    rows: list[dict] = []

    for line_number, raw_line in enumerate(text.splitlines(), start=1):
        if not raw_line.strip():
            continue

        if len(raw_line) < 10:
            raise ValueError(f"Line {line_number}: record is shorter than 10 characters")

        state_code = raw_line[0:3]
        element_code = raw_line[3:6]

        try:
            year = int(raw_line[6:10])
        except ValueError as exc:
            raise ValueError(f"Line {line_number}: invalid year") from exc

        if element_code != expected_element:
            raise ValueError(
                f"Line {line_number}: expected element {expected_element} "
                f"for {metric}, found {element_code}"
            )

        # Statewide files also include regional/national aggregate codes.
        # Keep only the 50 state rows.
        if state_code not in NOAA_STATE_MAP:
            continue

        if year < min_year:
            continue

        values = raw_line[10:].split()
        if len(values) != 12:
            raise ValueError(
                f"Line {line_number}: expected 12 monthly values, found {len(values)}"
            )

        state_abbr, state_name = NOAA_STATE_MAP[state_code]

        for month, raw_value in enumerate(values, start=1):
            try:
                value = float(raw_value)
            except ValueError as exc:
                raise ValueError(
                    f"Line {line_number}, month {month}: invalid numeric value {raw_value!r}"
                ) from exc

            rows.append(
                {
                    "noaa_state_code": state_code,
                    "state_code": state_abbr,
                    "state_name": state_name,
                    "year": year,
                    "month": month,
                    metric: None if _is_missing(metric, value) else value,
                }
            )

    return pd.DataFrame(rows)


def build_climate_dataframe(
    temperature_text: str,
    cdd_text: str,
    hdd_text: str,
    precipitation_text: str,
    *,
    min_year: int = 2010,
) -> pd.DataFrame:
    """Parse and combine the four NOAA statewide metrics into State × Month rows."""
    frames = [
        parse_statewide_file(
            temperature_text, "avg_temperature", min_year=min_year
        ),
        parse_statewide_file(
            cdd_text, "cooling_degree_days", min_year=min_year
        ),
        parse_statewide_file(
            hdd_text, "heating_degree_days", min_year=min_year
        ),
        parse_statewide_file(
            precipitation_text, "precipitation", min_year=min_year
        ),
    ]

    key_columns = [
        "noaa_state_code",
        "state_code",
        "state_name",
        "year",
        "month",
    ]

    climate = reduce(
        lambda left, right: left.merge(right, on=key_columns, how="outer"),
        frames,
    )

    # Future months in NOAA files are represented by metric-specific sentinels.
    # After converting sentinels to nulls, remove rows with no actual observations.
    metric_columns = [
        "avg_temperature",
        "cooling_degree_days",
        "heating_degree_days",
        "precipitation",
    ]
    climate = climate.dropna(subset=metric_columns, how="all")

    climate["period"] = pd.to_datetime(
        {
            "year": climate["year"],
            "month": climate["month"],
            "day": 1,
        }
    )

    climate = climate[
        [
            "period",
            "year",
            "month",
            "noaa_state_code",
            "state_code",
            "state_name",
            "avg_temperature",
            "cooling_degree_days",
            "heating_degree_days",
            "precipitation",
        ]
    ].sort_values(["period", "state_code"], ignore_index=True)

    _validate_climate(climate)
    return climate


def _validate_climate(df: pd.DataFrame) -> None:
    key = ["state_code", "year", "month"]

    if df.duplicated(key).any():
        duplicates = df[df.duplicated(key, keep=False)][key]
        raise ValueError(f"Duplicate State × Month rows found:\n{duplicates.head()}")

    if not df["month"].between(1, 12).all():
        raise ValueError("Month outside 1-12 detected")

    unknown_states = set(df["state_code"]) - {
        state_abbr for state_abbr, _ in NOAA_STATE_MAP.values()
    }
    if unknown_states:
        raise ValueError(f"Unexpected states: {sorted(unknown_states)}")


def dataframe_to_parquet_bytes(df: pd.DataFrame) -> bytes:
    buffer = BytesIO()
    df.to_parquet(buffer, index=False, engine="pyarrow")
    return buffer.getvalue()
