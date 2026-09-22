/* =========================================================
   SYNAPSE -> CURATED ADLS ACCESS

   Required SQLCMD variable:
     ADLS_ACCOUNT

   Prerequisite:
     A database master key must already exist in the SQL pool.
   ========================================================= */

CREATE MASTER KEY
ENCRYPTION BY PASSWORD = '$(MASTER_KEY_PASSWORD)';

CREATE DATABASE SCOPED CREDENTIAL WorkspaceIdentity
WITH IDENTITY = 'Managed Identity';

CREATE EXTERNAL DATA SOURCE CuratedData
WITH
(
    LOCATION = 'https://$(ADLS_ACCOUNT).dfs.core.windows.net/curated',
    CREDENTIAL = WorkspaceIdentity
);