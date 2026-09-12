CREATE DATABASE SCOPED CREDENTIAL WorkspaceIdentity
WITH IDENTITY = 'Managed Identity';
GO

CREATE EXTERNAL DATA SOURCE CuratedData
WITH
(
    LOCATION = 'https://stenergyanalyticzgovlf.dfs.core.windows.net/curated',
    CREDENTIAL = WorkspaceIdentity
);
GO