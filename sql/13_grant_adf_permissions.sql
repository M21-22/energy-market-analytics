/* =========================================================
   ADF MANAGED IDENTITY PERMISSIONS
   Principal:
   adf-energyanalytics-dev-zgovlf
   ========================================================= */

/* =========================================================
   ADF MANAGED IDENTITY DATABASE ACCESS
   ========================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = 'adf-energyanalytics-dev-zgovlf'
)
BEGIN
    CREATE USER [adf-energyanalytics-dev-zgovlf]
    FROM EXTERNAL PROVIDER;
END;
GO

/* ---------------------------------------------------------
   1. Execute warehouse procedures
   --------------------------------------------------------- */

GRANT EXECUTE ON SCHEMA::dw
TO [adf-energyanalytics-dev-zgovlf];
GO


/* ---------------------------------------------------------
   2. Read staging data
   Required by incremental warehouse procedures
   --------------------------------------------------------- */

GRANT SELECT ON SCHEMA::stg
TO [adf-energyanalytics-dev-zgovlf];
GO


/* ---------------------------------------------------------
   3. Refresh staging
   DELETE requires DELETE
   COPY INTO requires INSERT
   --------------------------------------------------------- */

GRANT DELETE ON SCHEMA::stg
TO [adf-energyanalytics-dev-zgovlf];
GO

GRANT INSERT ON SCHEMA::stg
TO [adf-energyanalytics-dev-zgovlf];
GO


/* ---------------------------------------------------------
   4. Read warehouse dimensions/facts
   Required for watermarks, NOT EXISTS checks and joins
   --------------------------------------------------------- */

GRANT SELECT ON SCHEMA::dw
TO [adf-energyanalytics-dev-zgovlf];
GO


/* ---------------------------------------------------------
   5. Insert incremental warehouse rows
   --------------------------------------------------------- */

GRANT INSERT ON SCHEMA::dw
TO [adf-energyanalytics-dev-zgovlf];
GO


/* ---------------------------------------------------------
   6. Required by COPY INTO
   --------------------------------------------------------- */

GRANT ADMINISTER DATABASE BULK OPERATIONS
TO [adf-energyanalytics-dev-zgovlf];
GO