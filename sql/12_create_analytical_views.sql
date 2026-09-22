/* ---------------------------------------------------------
   1. Retail detail
   Excludes Total sector to avoid double-counting
   --------------------------------------------------------- */

CREATE VIEW dw.vw_RetailDetail
AS
SELECT
    d.full_date,
    d.year,
    d.month,

    s.state_code,
    s.state_name,

    sec.sector_name,

    f.revenue_thousand_dollars,
    f.sales_mwh,
    f.customer_count,
    f.avg_price_cents_per_kwh,
    f.data_status

FROM dw.FactRetailElectricity f

JOIN dw.DimDate d
    ON d.date_key = f.date_key

JOIN dw.DimState s
    ON s.state_key = f.state_key

JOIN dw.DimSector sec
    ON sec.sector_key = f.sector_key

WHERE sec.sector_name <> 'Total';
GO


/* ---------------------------------------------------------
   2. Retail total
   Uses only source Total sector
   --------------------------------------------------------- */

CREATE VIEW dw.vw_RetailTotal
AS
SELECT
    d.full_date,
    d.year,
    d.month,

    s.state_code,
    s.state_name,

    f.revenue_thousand_dollars,
    f.sales_mwh,
    f.customer_count,
    f.avg_price_cents_per_kwh,
    f.data_status

FROM dw.FactRetailElectricity f

JOIN dw.DimDate d
    ON d.date_key = f.date_key

JOIN dw.DimState s
    ON s.state_key = f.state_key

JOIN dw.DimSector sec
    ON sec.sector_key = f.sector_key

WHERE sec.sector_name = 'Total';
GO


/* ---------------------------------------------------------
   3. Generation detail
   Excludes Total producer/source rows
   --------------------------------------------------------- */

CREATE VIEW dw.vw_GenerationDetail
AS
SELECT
    d.full_date,
    d.year,
    d.month,

    s.state_code,
    s.state_name,

    p.producer_type_name,
    e.energy_source_name,

    f.generation_mwh,
    f.data_status

FROM dw.FactElectricityGeneration f

JOIN dw.DimDate d
    ON d.date_key = f.date_key

JOIN dw.DimState s
    ON s.state_key = f.state_key

JOIN dw.DimProducerType p
    ON p.producer_type_key = f.producer_type_key

JOIN dw.DimEnergySource e
    ON e.energy_source_key = f.energy_source_key

WHERE p.producer_type_name <> 'Total Electric Power Industry'
  AND e.energy_source_name <> 'Total';
GO


/* ---------------------------------------------------------
   4. Generation state-month total
   Uses EIA's Total producer + Total energy source
   --------------------------------------------------------- */

CREATE VIEW dw.vw_GenerationTotal
AS
SELECT
    d.full_date,
    d.year,
    d.month,

    s.state_code,
    s.state_name,

    f.generation_mwh,
    f.data_status

FROM dw.FactElectricityGeneration f

JOIN dw.DimDate d
    ON d.date_key = f.date_key

JOIN dw.DimState s
    ON s.state_key = f.state_key

JOIN dw.DimProducerType p
    ON p.producer_type_key = f.producer_type_key

JOIN dw.DimEnergySource e
    ON e.energy_source_key = f.energy_source_key

WHERE p.producer_type_name = 'Total Electric Power Industry'
  AND e.energy_source_name = 'Total';
GO


/* ---------------------------------------------------------
   5. Climate state-month
   --------------------------------------------------------- */

CREATE VIEW dw.vw_ClimateMonthly
AS
SELECT
    d.full_date,
    d.year,
    d.month,

    s.state_code,
    s.state_name,

    f.avg_temperature,
    f.cooling_degree_days,
    f.heating_degree_days,
    f.precipitation

FROM dw.FactClimate f

JOIN dw.DimDate d
    ON d.date_key = f.date_key

JOIN dw.DimState s
    ON s.state_key = f.state_key;
GO


/* ---------------------------------------------------------
   6. Demand + Weather
   Grain: State × Month
   --------------------------------------------------------- */

CREATE VIEW dw.vw_DemandWeather
AS
SELECT
    r.full_date,
    r.year,
    r.month,

    r.state_code,
    r.state_name,

    r.sales_mwh,
    r.revenue_thousand_dollars,
    r.customer_count,
    r.avg_price_cents_per_kwh,

    c.avg_temperature,
    c.cooling_degree_days,
    c.heating_degree_days,
    c.precipitation

FROM dw.vw_RetailTotal r

LEFT JOIN dw.vw_ClimateMonthly c
    ON c.full_date = r.full_date
   AND c.state_code = r.state_code;
GO


/* ---------------------------------------------------------
   7. Retail + Generation
   Grain: State × Month
   --------------------------------------------------------- */

CREATE VIEW dw.vw_RetailGeneration
AS
SELECT
    r.full_date,
    r.year,
    r.month,

    r.state_code,
    r.state_name,

    r.sales_mwh AS retail_sales_mwh,
    g.generation_mwh,

    g.generation_mwh - r.sales_mwh
        AS generation_minus_retail_mwh

FROM dw.vw_RetailTotal r

LEFT JOIN dw.vw_GenerationTotal g
    ON g.full_date = r.full_date
   AND g.state_code = r.state_code;
GO