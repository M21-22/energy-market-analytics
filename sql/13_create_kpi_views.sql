/* =========================================================
   KPI / REPORTING VIEWS
   Power BI-ready datasets
   ========================================================= */


/* ---------------------------------------------------------
   1. Energy source classification

   Excludes the EIA Total row.
   --------------------------------------------------------- */

CREATE VIEW dw.vw_EnergySourceClassification
AS
SELECT
    energy_source_key,
    energy_source_name,

    CASE
        WHEN energy_source_name IN (
            'Geothermal',
            'Hydroelectric Conventional',
            'Other Biomass',
            'Solar Thermal and Photovoltaic',
            'Wind',
            'Wood and Wood Derived Fuels'
        )
            THEN 'Renewable'

        WHEN energy_source_name IN (
            'Coal',
            'Natural Gas',
            'Other Gases',
            'Petroleum'
        )
            THEN 'Fossil'

        WHEN energy_source_name = 'Nuclear'
            THEN 'Nuclear'

        WHEN energy_source_name = 'Pumped Storage'
            THEN 'Storage'

        ELSE 'Other'
    END AS energy_category

FROM dw.DimEnergySource
WHERE energy_source_name <> 'Total';
GO


/* ---------------------------------------------------------
   2. Generation mix

   Grain:
   State × Month × Energy Source

   Uses Total Electric Power Industry so generation is not
   duplicated across producer types.
   --------------------------------------------------------- */

CREATE VIEW dw.vw_GenerationMix
AS
SELECT
    d.full_date,
    d.year,
    d.month,

    s.state_code,
    s.state_name,

    e.energy_source_name,
    c.energy_category,

    f.generation_mwh

FROM dw.FactElectricityGeneration f

JOIN dw.DimDate d
    ON d.date_key = f.date_key

JOIN dw.DimState s
    ON s.state_key = f.state_key

JOIN dw.DimProducerType p
    ON p.producer_type_key = f.producer_type_key

JOIN dw.DimEnergySource e
    ON e.energy_source_key = f.energy_source_key

JOIN dw.vw_EnergySourceClassification c
    ON c.energy_source_key = e.energy_source_key

WHERE p.producer_type_name = 'Total Electric Power Industry'
  AND e.energy_source_name <> 'Total';
GO


/* ---------------------------------------------------------
   3. Generation by category

   Grain:
   State × Month × Energy Category
   --------------------------------------------------------- */

CREATE VIEW dw.vw_GenerationCategoryMonthly
AS
SELECT
    full_date,
    year,
    month,
    state_code,
    state_name,
    energy_category,

    SUM(generation_mwh) AS generation_mwh

FROM dw.vw_GenerationMix

GROUP BY
    full_date,
    year,
    month,
    state_code,
    state_name,
    energy_category;
GO


/* ---------------------------------------------------------
   4. Generation share

   Grain:
   State × Month × Energy Category
   --------------------------------------------------------- */

CREATE VIEW dw.vw_GenerationShare
AS
SELECT
    full_date,
    year,
    month,
    state_code,
    state_name,
    energy_category,
    generation_mwh,

    SUM(generation_mwh) OVER (
        PARTITION BY full_date, state_code
    ) AS classified_generation_mwh,

    CASE
        WHEN SUM(generation_mwh) OVER (
            PARTITION BY full_date, state_code
        ) <> 0
        THEN
            100.0 * generation_mwh
            /
            SUM(generation_mwh) OVER (
                PARTITION BY full_date, state_code
            )
    END AS generation_share_pct

FROM dw.vw_GenerationCategoryMonthly;
GO


/* ---------------------------------------------------------
   5. Retail KPI monthly

   Grain:
   State × Month

   Uses EIA Total sector only.
   --------------------------------------------------------- */

CREATE VIEW dw.vw_RetailKPI
AS
SELECT
    full_date,
    year,
    month,
    state_code,
    state_name,

    sales_mwh,
    revenue_thousand_dollars,
    customer_count,
    avg_price_cents_per_kwh,

    LAG(sales_mwh, 12) OVER (
        PARTITION BY state_code
        ORDER BY full_date
    ) AS sales_mwh_previous_year,

    LAG(avg_price_cents_per_kwh, 12) OVER (
        PARTITION BY state_code
        ORDER BY full_date
    ) AS avg_price_previous_year,

    CASE
        WHEN LAG(sales_mwh, 12) OVER (
            PARTITION BY state_code
            ORDER BY full_date
        ) <> 0
        THEN
            100.0 *
            (
                sales_mwh -
                LAG(sales_mwh, 12) OVER (
                    PARTITION BY state_code
                    ORDER BY full_date
                )
            )
            /
            LAG(sales_mwh, 12) OVER (
                PARTITION BY state_code
                ORDER BY full_date
            )
    END AS sales_yoy_pct,

    CASE
        WHEN LAG(avg_price_cents_per_kwh, 12) OVER (
            PARTITION BY state_code
            ORDER BY full_date
        ) <> 0
        THEN
            100.0 *
            (
                avg_price_cents_per_kwh -
                LAG(avg_price_cents_per_kwh, 12) OVER (
                    PARTITION BY state_code
                    ORDER BY full_date
                )
            )
            /
            LAG(avg_price_cents_per_kwh, 12) OVER (
                PARTITION BY state_code
                ORDER BY full_date
            )
    END AS price_yoy_pct

FROM dw.vw_RetailTotal;
GO


/* ---------------------------------------------------------
   6. Sector monthly

   Grain:
   State × Month × Sector
   --------------------------------------------------------- */

CREATE VIEW dw.vw_SectorKPI
AS
SELECT
    full_date,
    year,
    month,
    state_code,
    state_name,
    sector_name,

    sales_mwh,
    revenue_thousand_dollars,
    customer_count,
    avg_price_cents_per_kwh

FROM dw.vw_RetailDetail;
GO


/* ---------------------------------------------------------
   7. Weather and demand reporting view

   Grain:
   State × Month
   --------------------------------------------------------- */

CREATE VIEW dw.vw_WeatherDemandKPI
AS
SELECT
    full_date,
    year,
    month,
    state_code,
    state_name,

    sales_mwh,
    revenue_thousand_dollars,
    customer_count,
    avg_price_cents_per_kwh,

    avg_temperature,
    cooling_degree_days,
    heating_degree_days,
    precipitation

FROM dw.vw_DemandWeather;
GO


/* ---------------------------------------------------------
   8. Retail vs generation reporting view

   Grain:
   State × Month
   --------------------------------------------------------- */

CREATE VIEW dw.vw_RetailGenerationKPI
AS
SELECT
    full_date,
    year,
    month,
    state_code,
    state_name,

    retail_sales_mwh,
    generation_mwh,
    generation_minus_retail_mwh

FROM dw.vw_RetailGeneration;
GO