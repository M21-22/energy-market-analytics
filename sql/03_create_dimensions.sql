CREATE TABLE dw.DimDate
(
    date_key    INT NOT NULL,
    full_date   DATE NOT NULL,
    year        SMALLINT NOT NULL,
    month       TINYINT NOT NULL,
    month_name  VARCHAR(20) NOT NULL,

    CONSTRAINT PK_DimDate
        PRIMARY KEY NONCLUSTERED (date_key) NOT ENFORCED
)
WITH
(
    DISTRIBUTION = REPLICATE,
    HEAP
);
GO


CREATE TABLE dw.DimState
(
    state_key   INT IDENTITY(1,1) NOT NULL,
    state_code  VARCHAR(2) NOT NULL,
    state_name  VARCHAR(100) NULL,

    CONSTRAINT PK_DimState
        PRIMARY KEY NONCLUSTERED (state_key) NOT ENFORCED
)
WITH
(
    DISTRIBUTION = REPLICATE,
    HEAP
);
GO


CREATE TABLE dw.DimSector
(
    sector_key  INT IDENTITY(1,1) NOT NULL,
    sector_name VARCHAR(50) NOT NULL,

    CONSTRAINT PK_DimSector
        PRIMARY KEY NONCLUSTERED (sector_key) NOT ENFORCED
)
WITH
(
    DISTRIBUTION = REPLICATE,
    HEAP
);
GO


CREATE TABLE dw.DimEnergySource
(
    energy_source_key  INT IDENTITY(1,1) NOT NULL,
    energy_source_name VARCHAR(100) NOT NULL,

    CONSTRAINT PK_DimEnergySource
        PRIMARY KEY NONCLUSTERED (energy_source_key) NOT ENFORCED
)
WITH
(
    DISTRIBUTION = REPLICATE,
    HEAP
);
GO


CREATE TABLE dw.DimProducerType
(
    producer_type_key  INT IDENTITY(1,1) NOT NULL,
    producer_type_name VARCHAR(150) NOT NULL,

    CONSTRAINT PK_DimProducerType
        PRIMARY KEY NONCLUSTERED (producer_type_key) NOT ENFORCED
)
WITH
(
    DISTRIBUTION = REPLICATE,
    HEAP
);
GO