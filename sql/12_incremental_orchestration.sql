CREATE PROCEDURE dw.usp_LoadWarehouseIncremental
AS
BEGIN
    SET NOCOUNT ON;

    EXEC dw.usp_LoadRetailIncremental;
    EXEC dw.usp_LoadGenerationIncremental;
    EXEC dw.usp_LoadClimateIncremental;
END;
GO