CREATE SCHEMA stg;
GO

CREATE SCHEMA dw;
GO


CREATE TABLE stg.ClimateMonthly
(
    period              DATETIME2,
    year                 BIGINT,
    month                BIGINT,
    noaa_state_code      VARCHAR(3),
    state_code           VARCHAR(2),
    state_name           VARCHAR(50),
    avg_temperature      FLOAT,
    cooling_degree_days  FLOAT,
    heating_degree_days  FLOAT,
    precipitation        FLOAT
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    HEAP
);
GO


CREATE TABLE stg.RetailMonthly
(
    period                       DATETIME2,
    year                          BIGINT,
    month                         BIGINT,
    state_code                    VARCHAR(2),
    sector                        VARCHAR(30),
    revenue_thousand_dollars      FLOAT,
    sales_mwh                     FLOAT,
    customer_count                FLOAT,
    avg_price_cents_per_kwh       FLOAT,
    data_status                   VARCHAR(20)
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    HEAP
);
GO


CREATE TABLE stg.GenerationMonthly
(
    period           DATETIME2,
    year              BIGINT,
    month             BIGINT,
    state_code        VARCHAR(2),
    producer_type     VARCHAR(100),
    energy_source     VARCHAR(100),
    generation_mwh    FLOAT,
    data_status       VARCHAR(20)
)
WITH
(
    DISTRIBUTION = ROUND_ROBIN,
    HEAP
);
GO