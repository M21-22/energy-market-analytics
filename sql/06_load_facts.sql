/* -------------------------
   FactClimate
   ------------------------- */

TRUNCATE TABLE dw.FactClimate;
GO

INSERT INTO dw.FactClimate
(
    date_key,
    state_key,
    avg_temperature,
    cooling_degree_days,
    heating_degree_days,
    precipitation
)
SELECT
    d.date_key,
    s.state_key,
    c.avg_temperature,
    c.cooling_degree_days,
    c.heating_degree_days,
    c.precipitation
FROM stg.ClimateMonthly c

JOIN dw.DimDate d
    ON d.full_date = CAST(c.period AS DATE)

JOIN dw.DimState s
    ON s.state_code = c.state_code;
GO


/* -------------------------
   FactRetailElectricity
   ------------------------- */

TRUNCATE TABLE dw.FactRetailElectricity;
GO

INSERT INTO dw.FactRetailElectricity
(
    date_key,
    state_key,
    sector_key,
    revenue_thousand_dollars,
    sales_mwh,
    customer_count,
    avg_price_cents_per_kwh,
    data_status
)
SELECT
    d.date_key,
    st.state_key,
    se.sector_key,
    r.revenue_thousand_dollars,
    r.sales_mwh,
    r.customer_count,
    r.avg_price_cents_per_kwh,
    r.data_status
FROM stg.RetailMonthly r

JOIN dw.DimDate d
    ON d.full_date = CAST(r.period AS DATE)

JOIN dw.DimState st
    ON st.state_code = r.state_code

JOIN dw.DimSector se
    ON se.sector_name = r.sector;
GO


/* -------------------------
   FactElectricityGeneration
   ------------------------- */

TRUNCATE TABLE dw.FactElectricityGeneration;
GO

INSERT INTO dw.FactElectricityGeneration
(
    date_key,
    state_key,
    producer_type_key,
    energy_source_key,
    generation_mwh,
    data_status
)
SELECT
    d.date_key,
    st.state_key,
    p.producer_type_key,
    e.energy_source_key,
    g.generation_mwh,
    g.data_status
FROM stg.GenerationMonthly g

JOIN dw.DimDate d
    ON d.full_date = CAST(g.period AS DATE)

JOIN dw.DimState st
    ON st.state_code = g.state_code

JOIN dw.DimProducerType p
    ON p.producer_type_name = g.producer_type

JOIN dw.DimEnergySource e
    ON e.energy_source_name = g.energy_source;
GO