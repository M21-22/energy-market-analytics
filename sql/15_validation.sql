/* =========================================================
   STAGING VALIDATION
   ========================================================= */

-- Row counts
SELECT 'Climate' AS dataset, COUNT(*) AS row_count
FROM stg.ClimateMonthly

UNION ALL

SELECT 'Retail', COUNT(*)
FROM stg.RetailMonthly

UNION ALL

SELECT 'Generation', COUNT(*)
FROM stg.GenerationMonthly;
GO


-- Period ranges
SELECT
    'Climate' AS dataset,
    MIN(period) AS min_period,
    MAX(period) AS max_period
FROM stg.ClimateMonthly

UNION ALL

SELECT
    'Retail',
    MIN(period),
    MAX(period)
FROM stg.RetailMonthly

UNION ALL

SELECT
    'Generation',
    MIN(period),
    MAX(period)
FROM stg.GenerationMonthly;
GO


-- Climate grain:
-- State × Month
SELECT
    state_code,
    year,
    month,
    COUNT(*) AS duplicate_count
FROM stg.ClimateMonthly
GROUP BY
    state_code,
    year,
    month
HAVING COUNT(*) > 1;
GO


-- Retail grain:
-- State × Month × Sector
SELECT
    state_code,
    year,
    month,
    sector,
    COUNT(*) AS duplicate_count
FROM stg.RetailMonthly
GROUP BY
    state_code,
    year,
    month,
    sector
HAVING COUNT(*) > 1;
GO


-- Generation grain:
-- State × Month × Producer × Energy Source
SELECT
    state_code,
    year,
    month,
    producer_type,
    energy_source,
    COUNT(*) AS duplicate_count
FROM stg.GenerationMonthly
GROUP BY
    state_code,
    year,
    month,
    producer_type,
    energy_source
HAVING COUNT(*) > 1;
GO

-- FactClimate: Date × State
SELECT date_key, state_key, COUNT(*) AS cnt
FROM dw.FactClimate
GROUP BY date_key, state_key
HAVING COUNT(*) > 1;
GO

-- FactRetail: Date × State × Sector
SELECT date_key, state_key, sector_key, COUNT(*) AS cnt
FROM dw.FactRetailElectricity
GROUP BY date_key, state_key, sector_key
HAVING COUNT(*) > 1;
GO

-- FactGeneration: Date × State × Producer Type × Energy Source
SELECT
    date_key,
    state_key,
    producer_type_key,
    energy_source_key,
    COUNT(*) AS cnt
FROM dw.FactElectricityGeneration
GROUP BY
    date_key,
    state_key,
    producer_type_key,
    energy_source_key
HAVING COUNT(*) > 1;
GO