/* =========================================================
   ADF MANAGED IDENTITY PERMISSIONS

   Required SQLCMD variable:
     ADF_NAME
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
   Execute warehouse procedures.
   Underlying SELECT / DELETE / INSERT operations are performed
   through the procedures rather than granted directly to ADF.
   --------------------------------------------------------- */

GRANT EXECUTE ON SCHEMA::dw
TO [$(ADF_NAME)];

GRANT SELECT ON SCHEMA::dw
TO [$(ADF_NAME)];

GRANT INSERT ON SCHEMA::dw
TO [$(ADF_NAME)];

/* ---------------------------------------------------------
   COPY INTO executed by the staging procedure.
   --------------------------------------------------------- */

GRANT INSERT ON SCHEMA::stg
TO [$(ADF_NAME)];

GRANT SELECT ON SCHEMA::stg
TO [$(ADF_NAME)];

GRANT DELETE ON SCHEMA::stg
TO [$(ADF_NAME)];

GRANT ADMINISTER DATABASE BULK OPERATIONS
TO [$(ADF_NAME)];
GO