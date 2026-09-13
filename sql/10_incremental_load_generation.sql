CREATE PROCEDURE dw.usp_LoadGenerationIncremental
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @watermark INT;

    SELECT
        @watermark = ISNULL(MAX(date_key), 0)
    FROM dw.FactElectricityGeneration;


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
        YEAR(g.period) * 10000
            + MONTH(g.period) * 100
            + 1,

        CAST(g.period AS DATE),
        YEAR(g.period),
        MONTH(g.period),
        DATENAME(MONTH, g.period)

    FROM stg.GenerationMonthly g

    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dw.DimDate d
        WHERE d.full_date = CAST(g.period AS DATE)
    );


    /* Insert only missing Generation fact rows */

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
        ON e.energy_source_name = g.energy_source

    WHERE d.date_key >= @watermark

      AND NOT EXISTS
      (
          SELECT 1
          FROM dw.FactElectricityGeneration f
          WHERE f.date_key = d.date_key
            AND f.state_key = st.state_key
            AND f.producer_type_key = p.producer_type_key
            AND f.energy_source_key = e.energy_source_key
      );
END;
GO