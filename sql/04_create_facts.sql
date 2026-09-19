/* =========================================================
   FACT TABLES
   ========================================================= */


/* -------------------------
   FactClimate
   Grain: State × Month
   ------------------------- */

CREATE TABLE dw.FactClimate
(
    date_key             INT NOT NULL,
    state_key            INT NOT NULL,

    avg_temperature      FLOAT NULL,
    cooling_degree_days  FLOAT NULL,
    heating_degree_days  FLOAT NULL,
    precipitation        FLOAT NULL
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    CLUSTERED COLUMNSTORE INDEX
);
GO


/* -------------------------
   FactRetailElectricity
   Grain: State × Month × Sector
   ------------------------- */

CREATE TABLE dw.FactRetailElectricity
(
    date_key                    INT NOT NULL,
    state_key                   INT NOT NULL,
    sector_key                  INT NOT NULL,

    revenue_thousand_dollars    FLOAT NULL,
    sales_mwh                   FLOAT NULL,
    customer_count              FLOAT NULL,
    avg_price_cents_per_kwh     FLOAT NULL,
    data_status                 VARCHAR(20) NULL
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    CLUSTERED COLUMNSTORE INDEX
);
GO


/* -------------------------
   FactElectricityGeneration
   Grain:
   State × Month × Producer Type × Energy Source
   ------------------------- */

CREATE TABLE dw.FactElectricityGeneration
(
    date_key            INT NOT NULL,
    state_key           INT NOT NULL,
    producer_type_key   INT NOT NULL,
    energy_source_key   INT NOT NULL,

    generation_mwh      FLOAT NULL,
    data_status         VARCHAR(20) NULL
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    CLUSTERED COLUMNSTORE INDEX
);
GO