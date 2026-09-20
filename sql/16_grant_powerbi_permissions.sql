-- Run in the Dedicated SQL Pool database.

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = 'powerbi_reader'
)
BEGIN
    CREATE USER powerbi_reader
    FOR LOGIN powerbi_reader;
END;

GRANT SELECT ON OBJECT::dw.DimDate
TO powerbi_reader;

GRANT SELECT ON OBJECT::dw.DimState
TO powerbi_reader;

GRANT SELECT ON OBJECT::dw.vw_RetailKPI
TO powerbi_reader;

GRANT SELECT ON OBJECT::dw.vw_SectorKPI
TO powerbi_reader;

GRANT SELECT ON OBJECT::dw.vw_GenerationMix
TO powerbi_reader;

GRANT SELECT ON OBJECT::dw.vw_GenerationShare
TO powerbi_reader;

GRANT SELECT ON OBJECT::dw.vw_WeatherDemandKPI
TO powerbi_reader;

GRANT SELECT ON OBJECT::dw.vw_RetailGenerationKPI
TO powerbi_reader;