CREATE PROCEDURE dw.usp_LoadClimateIncremental
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @watermark INT;

    SELECT
        @watermark = ISNULL(MAX(date_key), 0)
    FROM dw.FactClimate;


    /* Add any new dates */

    INSERT INTO dw.DimDate
    (
        date_key,
        full_date,
        year,
        month,
        month_name
    )
    SELECT DISTINCT
        YEAR(c.period) * 10000
            + MONTH(c.period) * 100
            + 1,

        CAST(c.period AS DATE),
        YEAR(c.period),
        MONTH(c.period),
        DATENAME(MONTH, c.period)

    FROM stg.ClimateMonthly c

    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dw.DimDate d
        WHERE d.full_date = CAST(c.period AS DATE)
    );


    /* Insert only missing Climate fact rows */

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
        st.state_key,

        c.avg_temperature,
        c.cooling_degree_days,
        c.heating_degree_days,
        c.precipitation

    FROM stg.ClimateMonthly c

    JOIN dw.DimDate d
        ON d.full_date = CAST(c.period AS DATE)

    JOIN dw.DimState st
        ON st.state_code = c.state_code

    WHERE d.date_key >= @watermark

      AND NOT EXISTS
      (
          SELECT 1
          FROM dw.FactClimate f
          WHERE f.date_key = d.date_key
            AND f.state_key = st.state_key
      );
END;
GO