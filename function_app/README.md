# Phase 4 — NOAA Azure Function

HTTP-triggered Azure Function that:

1. lists NOAA files under `raw/noaa/climate/`;
2. selects the latest version of each required statewide metric file;
3. parses NOAA nClimDiv fixed-width records;
4. keeps only NOAA state codes `001`–`050`;
5. converts NOAA missing-value sentinels to null;
6. combines temperature, CDD, HDD, and precipitation at `State × Month`;
7. removes future placeholder months with no observations;
8. writes `curated/climate/climate_monthly.parquet`.

The Function App reads/writes ADLS using its managed identity through
`DefaultAzureCredential`.

Required Function App setting:

`DATA_LAKE_ACCOUNT_NAME=stenergyanalyticzgovlf`

HTTP route:

`POST /api/process-noaa`

Optional request body:

```json
{
  "min_year": 2010
}
```

The supplied September 2026 NOAA files produce data through August 2026.

Note: NOAA statewide files cover the 50 states. District of Columbia is present
in the EIA retail dataset but has no corresponding NOAA statewide record, so
weather-vs-electricity analysis will exclude DC.
