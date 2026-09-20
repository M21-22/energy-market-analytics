CREATE OR ALTER PROCEDURE dw.usp_LoadWarehouseIncremental
AS
BEGIN
    SET NOCOUNT ON;

    -- Block warehouse loading if staging data fails validation.
    EXEC dw.usp_ValidateStaging;

    EXEC dw.usp_LoadRetailIncremental;
    EXEC dw.usp_LoadGenerationIncremental;
    EXEC dw.usp_LoadClimateIncremental;
END;
GO