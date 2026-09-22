CREATE PROCEDURE dw.usp_LoadWarehouseIncremental
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Validate staging before touching warehouse
    EXEC dw.usp_ValidateStaging;

    -- 2. Add any new dimension members
    EXEC dw.usp_LoadDimensionsIncremental;

    -- 3. Load facts
    EXEC dw.usp_LoadRetailIncremental;
    EXEC dw.usp_LoadGenerationIncremental;
    EXEC dw.usp_LoadClimateIncremental;
END;
GO