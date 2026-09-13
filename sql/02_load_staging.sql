CREATE PROCEDURE dw.usp_RefreshStaging
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE stg.ClimateMonthly;

    COPY INTO stg.ClimateMonthly
    FROM 'https://stenergyanalyticzgovlf.dfs.core.windows.net/curated/climate/climate_monthly.parquet'
    WITH
    (
        FILE_TYPE = 'PARQUET',
        CREDENTIAL = (IDENTITY = 'Managed Identity')
    );


    TRUNCATE TABLE stg.RetailMonthly;

    COPY INTO stg.RetailMonthly
    FROM 'https://stenergyanalyticzgovlf.dfs.core.windows.net/curated/eia/retail/retail_monthly.parquet'
    WITH
    (
        FILE_TYPE = 'PARQUET',
        CREDENTIAL = (IDENTITY = 'Managed Identity')
    );


    TRUNCATE TABLE stg.GenerationMonthly;

    COPY INTO stg.GenerationMonthly
    FROM 'https://stenergyanalyticzgovlf.dfs.core.windows.net/curated/eia/generation/generation_monthly.parquet'
    WITH
    (
        FILE_TYPE = 'PARQUET',
        CREDENTIAL = (IDENTITY = 'Managed Identity')
    );
END;
GO