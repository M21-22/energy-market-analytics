/* -------------------------
   DimDate
   ------------------------- */

TRUNCATE TABLE dw.DimDate;
GO

INSERT INTO dw.DimDate
(
    date_key,
    full_date,
    year,
    month,
    month_name
)
SELECT DISTINCT
    YEAR(period) * 10000
        + MONTH(period) * 100
        + 1 AS date_key,

    CAST(period AS DATE) AS full_date,
    YEAR(period) AS year,
    MONTH(period) AS month,
    DATENAME(MONTH, period) AS month_name

FROM
(
    SELECT period FROM stg.ClimateMonthly
    UNION
    SELECT period FROM stg.RetailMonthly
    UNION
    SELECT period FROM stg.GenerationMonthly
) d;
GO


/* -------------------------
   DimState
   ------------------------- */

TRUNCATE TABLE dw.DimState;
GO

WITH StateCodes AS
(
    SELECT state_code
    FROM stg.ClimateMonthly

    UNION

    SELECT state_code
    FROM stg.RetailMonthly

    UNION

    SELECT state_code
    FROM stg.GenerationMonthly
),
StateNames AS
(
    SELECT
        state_code,
        MAX(state_name) AS state_name
    FROM stg.ClimateMonthly
    GROUP BY state_code
)

INSERT INTO dw.DimState
(
    state_code,
    state_name
)
SELECT
    s.state_code,

    CASE
        WHEN s.state_code = 'DC'
            THEN 'District of Columbia'
        ELSE n.state_name
    END AS state_name

FROM StateCodes s

LEFT JOIN StateNames n
    ON s.state_code = n.state_code

WHERE s.state_code IS NOT NULL;
GO


/* -------------------------
   DimSector
   ------------------------- */

TRUNCATE TABLE dw.DimSector;
GO

INSERT INTO dw.DimSector
(
    sector_name
)
SELECT DISTINCT
    sector
FROM stg.RetailMonthly
WHERE sector IS NOT NULL;
GO


/* -------------------------
   DimEnergySource
   ------------------------- */

TRUNCATE TABLE dw.DimEnergySource;
GO

INSERT INTO dw.DimEnergySource
(
    energy_source_name
)
SELECT DISTINCT
    energy_source
FROM stg.GenerationMonthly
WHERE energy_source IS NOT NULL;
GO


/* -------------------------
   DimProducerType
   ------------------------- */

TRUNCATE TABLE dw.DimProducerType;
GO

INSERT INTO dw.DimProducerType
(
    producer_type_name
)
SELECT DISTINCT
    producer_type
FROM stg.GenerationMonthly
WHERE producer_type IS NOT NULL;
GO