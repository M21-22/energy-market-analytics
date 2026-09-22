CREATE PROCEDURE dw.usp_LoadDimensionsIncremental
AS
BEGIN
    SET NOCOUNT ON;

    /* DimDate */
    INSERT INTO dw.DimDate (date_key, full_date, year, month, month_name)
    SELECT
        YEAR(d.period) * 10000 + MONTH(d.period) * 100 + 1,
        CAST(d.period AS DATE),
        YEAR(d.period),
        MONTH(d.period),
        DATENAME(MONTH, d.period)
    FROM
    (
        SELECT period FROM stg.ClimateMonthly
        UNION
        SELECT period FROM stg.RetailMonthly
        UNION
        SELECT period FROM stg.GenerationMonthly
    ) d
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dw.DimDate x
        WHERE x.date_key = YEAR(d.period) * 10000 + MONTH(d.period) * 100 + 1
    );

    /* DimState */
    ;WITH StateCodes AS
    (
        SELECT state_code FROM stg.ClimateMonthly
        UNION
        SELECT state_code FROM stg.RetailMonthly
        UNION
        SELECT state_code FROM stg.GenerationMonthly
    ),
    StateNames AS
    (
        SELECT state_code, MAX(state_name) AS state_name
        FROM stg.ClimateMonthly
        GROUP BY state_code
    )
    INSERT INTO dw.DimState (state_code, state_name)
    SELECT
        s.state_code,
        CASE WHEN s.state_code = 'DC'
             THEN 'District of Columbia'
             ELSE n.state_name
        END
    FROM StateCodes s
    LEFT JOIN StateNames n ON n.state_code = s.state_code
    WHERE s.state_code IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM dw.DimState x
          WHERE x.state_code = s.state_code
      );

    /* DimSector */
    INSERT INTO dw.DimSector (sector_name)
    SELECT DISTINCT r.sector
    FROM stg.RetailMonthly r
    WHERE r.sector IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1 FROM dw.DimSector x
          WHERE x.sector_name = r.sector
      );

    /* DimEnergySource */
    INSERT INTO dw.DimEnergySource (energy_source_name)
    SELECT DISTINCT g.energy_source
    FROM stg.GenerationMonthly g
    WHERE g.energy_source IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1 FROM dw.DimEnergySource x
          WHERE x.energy_source_name = g.energy_source
      );

    /* DimProducerType */
    INSERT INTO dw.DimProducerType (producer_type_name)
    SELECT DISTINCT g.producer_type
    FROM stg.GenerationMonthly g
    WHERE g.producer_type IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1 FROM dw.DimProducerType x
          WHERE x.producer_type_name = g.producer_type
      );
END;
