CREATE OR ALTER PROCEDURE dw.usp_LoadStagingIncremental
    @storage_base VARCHAR(1000),
    @climate_max_period DATE,
    @retail_max_period DATE,
    @generation_max_period DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @watermark DATE;
    DECLARE @current_period DATE;
    DECLARE @sources VARCHAR(8000);
    DECLARE @sql VARCHAR(8000);


    /* =========================================================
       1. CLIMATE

       Grain:
       State x Month
       ========================================================= */

    SELECT
        @watermark = MAX(period)
    FROM stg.ClimateMonthly;

    -- Empty staging table = bootstrap from 2010-01.
    SET @watermark =
        ISNULL(@watermark, CAST('2010-01-01' AS DATE));

    IF @watermark <= @climate_max_period
    BEGIN
        SET @current_period = @watermark;
        SET @sources = '';

        WHILE @current_period <= @climate_max_period
        BEGIN
            SET @sources =
                @sources
                + CASE
                    WHEN LEN(@sources) > 0 THEN ', '
                    ELSE ''
                  END
                + ''''
                + @storage_base
                + 'climate/year='
                + CAST(YEAR(@current_period) AS VARCHAR(4))
                + '/month='
                + RIGHT(
                    '0'
                    + CAST(
                        MONTH(@current_period) AS VARCHAR(2)
                    ),
                    2
                )
                + '/data.parquet''';

            SET @current_period =
                DATEADD(MONTH, 1, @current_period);
        END;

        -- Replace only the affected period.
        BEGIN TRY
            BEGIN TRANSACTION;

            DELETE FROM stg.ClimateMonthly
            WHERE period >= @watermark
            AND period <= @climate_max_period;

            SET @sql =
                'COPY INTO stg.ClimateMonthly
                FROM ' + @sources + '
                WITH
                (
                    FILE_TYPE = ''PARQUET'',
                    CREDENTIAL = (
                        IDENTITY = ''Managed Identity''
                    )
                );';

            EXEC(@sql);

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            THROW;
        END CATCH;
    END;


    /* =========================================================
       2. RETAIL

       Grain:
       State x Month x Sector
       ========================================================= */

    SELECT
        @watermark = MAX(period)
    FROM stg.RetailMonthly;

    SET @watermark =
        ISNULL(@watermark, CAST('2010-01-01' AS DATE));

    IF @watermark <= @retail_max_period
    BEGIN
        SET @current_period = @watermark;
        SET @sources = '';

        WHILE @current_period <= @retail_max_period
        BEGIN
            SET @sources =
                @sources
                + CASE
                    WHEN LEN(@sources) > 0 THEN ', '
                    ELSE ''
                  END
                + ''''
                + @storage_base
                + 'eia/retail/year='
                + CAST(YEAR(@current_period) AS VARCHAR(4))
                + '/month='
                + RIGHT(
                    '0'
                    + CAST(
                        MONTH(@current_period) AS VARCHAR(2)
                    ),
                    2
                )
                + '/data.parquet''';

            SET @current_period =
                DATEADD(MONTH, 1, @current_period);
        END;

        BEGIN TRY
            BEGIN TRANSACTION;

            DELETE FROM stg.RetailMonthly
            WHERE period >= @watermark
            AND period <= @retail_max_period;

            SET @sql =
                'COPY INTO stg.RetailMonthly
                FROM ' + @sources + '
                WITH
                (
                    FILE_TYPE = ''PARQUET'',
                    CREDENTIAL = (
                        IDENTITY = ''Managed Identity''
                    )
                );';

            EXEC(@sql);

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            THROW;
        END CATCH;
    END;


    /* =========================================================
       3. GENERATION

       Grain:
       State x Month x Producer Type x Energy Source
       ========================================================= */

    SELECT
        @watermark = MAX(period)
    FROM stg.GenerationMonthly;

    SET @watermark =
        ISNULL(@watermark, CAST('2010-01-01' AS DATE));

    IF @watermark <= @generation_max_period
    BEGIN
        SET @current_period = @watermark;
        SET @sources = '';

        WHILE @current_period <= @generation_max_period
        BEGIN
            SET @sources =
                @sources
                + CASE
                    WHEN LEN(@sources) > 0 THEN ', '
                    ELSE ''
                  END
                + ''''
                + @storage_base
                + 'eia/generation/year='
                + CAST(YEAR(@current_period) AS VARCHAR(4))
                + '/month='
                + RIGHT(
                    '0'
                    + CAST(
                        MONTH(@current_period) AS VARCHAR(2)
                    ),
                    2
                )
                + '/data.parquet''';

            SET @current_period =
                DATEADD(MONTH, 1, @current_period);
        END;

        BEGIN TRY
            BEGIN TRANSACTION;

            DELETE FROM stg.GenerationMonthly
            WHERE period >= @watermark
            AND period <= @generation_max_period;

            SET @sql =
                'COPY INTO stg.GenerationMonthly
                FROM ' + @sources + '
                WITH
                (
                    FILE_TYPE = ''PARQUET'',
                    CREDENTIAL = (
                        IDENTITY = ''Managed Identity''
                    )
                );';

            EXEC(@sql);

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            THROW;
        END CATCH;
    END;
END;