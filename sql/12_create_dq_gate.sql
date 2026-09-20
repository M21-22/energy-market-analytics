CREATE OR ALTER PROCEDURE dw.usp_ValidateStaging
AS
BEGIN
    SET NOCOUNT ON;

    /* =========================================================
       1. EMPTY DATASETS
       ========================================================= */

    IF NOT EXISTS (SELECT 1 FROM stg.ClimateMonthly)
        THROW 50001, 'DQ failed: Climate staging is empty.', 1;

    IF NOT EXISTS (SELECT 1 FROM stg.RetailMonthly)
        THROW 50002, 'DQ failed: Retail staging is empty.', 1;

    IF NOT EXISTS (SELECT 1 FROM stg.GenerationMonthly)
        THROW 50003, 'DQ failed: Generation staging is empty.', 1;


    /* =========================================================
       2. REQUIRED FIELDS
       ========================================================= */

    IF EXISTS
    (
        SELECT 1
        FROM stg.ClimateMonthly
        WHERE period IS NULL
           OR state_code IS NULL
    )
        THROW 50004, 'DQ failed: Climate contains NULL required fields.', 1;


    IF EXISTS
    (
        SELECT 1
        FROM stg.RetailMonthly
        WHERE period IS NULL
           OR state_code IS NULL
           OR sector IS NULL
    )
        THROW 50005, 'DQ failed: Retail contains NULL required fields.', 1;


    IF EXISTS
    (
        SELECT 1
        FROM stg.GenerationMonthly
        WHERE period IS NULL
           OR state_code IS NULL
           OR producer_type IS NULL
           OR energy_source IS NULL
    )
        THROW 50006, 'DQ failed: Generation contains NULL required fields.', 1;


    /* =========================================================
       3. PERIOD CONSISTENCY

       period, year and month must describe the same month.
       ========================================================= */

    IF EXISTS
    (
        SELECT 1
        FROM stg.ClimateMonthly
        WHERE year IS NULL
           OR month IS NULL
           OR year <> YEAR(period)
           OR month <> MONTH(period)
           OR month < 1
           OR month > 12
    )
        THROW 50007, 'DQ failed: Climate contains invalid period values.', 1;


    IF EXISTS
    (
        SELECT 1
        FROM stg.RetailMonthly
        WHERE year IS NULL
           OR month IS NULL
           OR year <> YEAR(period)
           OR month <> MONTH(period)
           OR month < 1
           OR month > 12
    )
        THROW 50008, 'DQ failed: Retail contains invalid period values.', 1;


    IF EXISTS
    (
        SELECT 1
        FROM stg.GenerationMonthly
        WHERE year IS NULL
           OR month IS NULL
           OR year <> YEAR(period)
           OR month <> MONTH(period)
           OR month < 1
           OR month > 12
    )
        THROW 50009, 'DQ failed: Generation contains invalid period values.', 1;


    /* =========================================================
       4. DUPLICATE GRAIN

       Climate:
       State x Month
       ========================================================= */

    IF EXISTS
    (
        SELECT 1
        FROM stg.ClimateMonthly
        GROUP BY
            state_code,
            year,
            month
        HAVING COUNT(*) > 1
    )
        THROW 50010, 'DQ failed: Duplicate Climate grain detected.', 1;


    /* =========================================================
       Retail:
       State x Month x Sector
       ========================================================= */

    IF EXISTS
    (
        SELECT 1
        FROM stg.RetailMonthly
        GROUP BY
            state_code,
            year,
            month,
            sector
        HAVING COUNT(*) > 1
    )
        THROW 50011, 'DQ failed: Duplicate Retail grain detected.', 1;


    /* =========================================================
       Generation:
       State x Month x Producer Type x Energy Source
       ========================================================= */

    IF EXISTS
    (
        SELECT 1
        FROM stg.GenerationMonthly
        GROUP BY
            state_code,
            year,
            month,
            producer_type,
            energy_source
        HAVING COUNT(*) > 1
    )
        THROW 50012, 'DQ failed: Duplicate Generation grain detected.', 1;


    /* =========================================================
       VALIDATION PASSED
       ========================================================= */

    SELECT
        'PASS' AS dq_status,
        'All staging data quality checks passed.' AS message;
END;
GO