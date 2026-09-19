/* =========================================================
   ADF MANAGED IDENTITY PERMISSIONS

   Required SQLCMD variable:
     ADF_NAME
   ========================================================= */

/* =========================================================
   ADF MANAGED IDENTITY DATABASE ACCESS
   ========================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = '$(ADF_NAME)'
)
BEGIN
    CREATE USER [$(ADF_NAME)]
    FROM EXTERNAL PROVIDER;
END;
GO

/* ---------------------------------------------------------
   1. Execute warehouse procedures
   --------------------------------------------------------- */

GRANT EXECUTE ON SCHEMA::dw
TO [$(ADF_NAME)];


/* ---------------------------------------------------------
   2. Read staging data
   Required by incremental warehouse procedures
   --------------------------------------------------------- */

GRANT SELECT ON SCHEMA::stg
TO [$(ADF_NAME)];


/* ---------------------------------------------------------
   3. Refresh staging
   DELETE requires DELETE
   COPY INTO requires INSERT
   --------------------------------------------------------- */

GRANT DELETE ON SCHEMA::stg
TO [$(ADF_NAME)];

GRANT INSERT ON SCHEMA::stg
TO [$(ADF_NAME)];


/* ---------------------------------------------------------
   4. Read warehouse dimensions/facts
   Required for watermarks, NOT EXISTS checks and joins
   --------------------------------------------------------- */

GRANT SELECT ON SCHEMA::dw
TO [$(ADF_NAME)];


/* ---------------------------------------------------------
   5. Insert incremental warehouse rows
   --------------------------------------------------------- */

GRANT INSERT ON SCHEMA::dw
TO [$(ADF_NAME)];


/* ---------------------------------------------------------
   6. Required by COPY INTO
   --------------------------------------------------------- */

GRANT ADMINISTER DATABASE BULK OPERATIONS
TO [$(ADF_NAME)];
GO