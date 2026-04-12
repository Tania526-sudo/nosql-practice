SET NOCOUNT ON;

/* ------------------------------------------------------------------
   STEP 1. SOURCE XML VARIABLE
   ------------------------------------------------------------------ */

DECLARE @XML_SRC XML;

/*
Option A:
Paste the XML text directly into the variable:

SET @XML_SRC = N'<?xml version="1.0" encoding="UTF-8"?>
... full ECB XML here ...';

Option B:
Load from a local file using OPENROWSET.
Adjust the path to your downloaded XML file.
*/

SELECT @XML_SRC = TRY_CAST(BulkColumn AS XML)
FROM OPENROWSET(
    BULK 'C:\Temp\eurofxref-hist-90d.xml',
    SINGLE_BLOB
) AS X;

IF @XML_SRC IS NULL
BEGIN
    THROW 50001, 'XML source was not loaded into @XML_SRC.', 1;
END;

/* ------------------------------------------------------------------
   STEP 2. DROP OLD TABLES IF THEY EXIST
   ------------------------------------------------------------------ */

IF OBJECT_ID('dbo.tblCurrencyRate', 'U') IS NOT NULL
    DROP TABLE dbo.tblCurrencyRate;

IF OBJECT_ID('dbo.tblCurrency', 'U') IS NOT NULL
    DROP TABLE dbo.tblCurrency;

/* ------------------------------------------------------------------
   STEP 3. CREATE NORMALIZED TABLES
   ------------------------------------------------------------------ */

CREATE TABLE dbo.tblCurrency
(
    CurrencyCode CHAR(3) NOT NULL PRIMARY KEY,
    CurrencyName NVARCHAR(100) NULL,
    IsBaseCurrency BIT NOT NULL
        CONSTRAINT DF_tblCurrency_IsBaseCurrency DEFAULT (0),
    SourceSystem NVARCHAR(50) NOT NULL
        CONSTRAINT DF_tblCurrency_SourceSystem DEFAULT ('ECB')
);

CREATE TABLE dbo.tblCurrencyRate
(
    CurrencyRateID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CurrencyCode CHAR(3) NOT NULL,
    RateDate DATE NOT NULL,
    BaseCurrencyCode CHAR(3) NOT NULL
        CONSTRAINT DF_tblCurrencyRate_Base DEFAULT ('EUR'),
    Rate DECIMAL(18,8) NOT NULL,
    CreatedAt DATETIME2 NOT NULL
        CONSTRAINT DF_tblCurrencyRate_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT FK_tblCurrencyRate_tblCurrency
        FOREIGN KEY (CurrencyCode) REFERENCES dbo.tblCurrency (CurrencyCode),
    CONSTRAINT UQ_tblCurrencyRate_CurrencyCode_RateDate
        UNIQUE (CurrencyCode, RateDate)
);

/* ------------------------------------------------------------------
   STEP 4. PARSE XML INTO CTE
   Typical ECB structure:
   /gesmes:Envelope/ecb:Cube/ecb:Cube[@time]/ecb:Cube[@currency, @rate]
   ------------------------------------------------------------------ */

;WITH XMLNAMESPACES
(
    'http://www.gesmes.org/xml/2002-08-01' AS gesmes,
    'http://www.ecb.int/vocabulary/2002-08-01/eurofxref' AS ecb
),
ParsedRates AS
(
    SELECT
        T.X.value('@time', 'date') AS RateDate,
        R.X.value('@currency', 'char(3)') AS CurrencyCode,
        R.X.value('@rate', 'decimal(18,8)') AS Rate
    FROM @XML_SRC.nodes('/gesmes:Envelope/ecb:Cube/ecb:Cube') AS T(X)
    CROSS APPLY T.X.nodes('ecb:Cube') AS R(X)
)
INSERT INTO dbo.tblCurrency (CurrencyCode, CurrencyName, IsBaseCurrency, SourceSystem)
SELECT DISTINCT
    P.CurrencyCode,
    NULL AS CurrencyName,
    0 AS IsBaseCurrency,
    'ECB' AS SourceSystem
FROM ParsedRates AS P;

/* Add EUR as base currency */
IF NOT EXISTS
(
    SELECT 1
    FROM dbo.tblCurrency
    WHERE CurrencyCode = 'EUR'
)
BEGIN
    INSERT INTO dbo.tblCurrency (CurrencyCode, CurrencyName, IsBaseCurrency, SourceSystem)
    VALUES ('EUR', 'Euro', 1, 'ECB');
END;

/* ------------------------------------------------------------------
   STEP 5. INSERT EXCHANGE RATES
   ------------------------------------------------------------------ */

;WITH XMLNAMESPACES
(
    'http://www.gesmes.org/xml/2002-08-01' AS gesmes,
    'http://www.ecb.int/vocabulary/2002-08-01/eurofxref' AS ecb
),
ParsedRates AS
(
    SELECT
        T.X.value('@time', 'date') AS RateDate,
        R.X.value('@currency', 'char(3)') AS CurrencyCode,
        R.X.value('@rate', 'decimal(18,8)') AS Rate
    FROM @XML_SRC.nodes('/gesmes:Envelope/ecb:Cube/ecb:Cube') AS T(X)
    CROSS APPLY T.X.nodes('ecb:Cube') AS R(X)
)
INSERT INTO dbo.tblCurrencyRate
(
    CurrencyCode,
    RateDate,
    BaseCurrencyCode,
    Rate
)
SELECT
    P.CurrencyCode,
    P.RateDate,
    'EUR' AS BaseCurrencyCode,
    P.Rate
FROM ParsedRates AS P;

/* ------------------------------------------------------------------
   STEP 6. VALIDATION QUERIES
   ------------------------------------------------------------------ */

SELECT *
FROM dbo.tblCurrency
ORDER BY CurrencyCode;

SELECT *
FROM dbo.tblCurrencyRate
ORDER BY RateDate DESC, CurrencyCode;

/* ------------------------------------------------------------------
   STEP 7. EXAMPLE ANALYTICAL QUERY
   ------------------------------------------------------------------ */

SELECT
    R.CurrencyCode,
    MIN(R.Rate) AS MinRate,
    MAX(R.Rate) AS MaxRate,
    AVG(R.Rate) AS AvgRate
FROM dbo.tblCurrencyRate AS R
GROUP BY R.CurrencyCode
ORDER BY R.CurrencyCode;