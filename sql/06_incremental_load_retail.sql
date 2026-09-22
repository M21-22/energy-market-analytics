CREATE PROCEDURE dw.usp_LoadRetailIncremental
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @watermark INT;

    SELECT
        @watermark = ISNULL(MAX(date_key), 0)
    FROM dw.FactRetailElectricity;


    /* ---------------------------------------------------------
       1. Add new dates if Retail extends beyond DimDate
       --------------------------------------------------------- */

    INSERT INTO dw.DimDate
    (
        date_key,
        full_date,
        year,
        month,
        month_name
    )
    SELECT DISTINCT
        YEAR(r.period) * 10000
            + MONTH(r.period) * 100
            + 1,

        CAST(r.period AS DATE),

        YEAR(r.period),
        MONTH(r.period),
        DATENAME(MONTH, r.period)

    FROM stg.RetailMonthly r

    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dw.DimDate d
        WHERE d.full_date = CAST(r.period AS DATE)
    );


    /* ---------------------------------------------------------
       2. Insert only new Retail fact rows

       >= watermark allows an incomplete latest month
       to be completed safely.

       NOT EXISTS makes reruns idempotent.
       --------------------------------------------------------- */

    INSERT INTO dw.FactRetailElectricity
    (
        date_key,
        state_key,
        sector_key,
        revenue_thousand_dollars,
        sales_mwh,
        customer_count,
        avg_price_cents_per_kwh,
        data_status
    )
    SELECT
        d.date_key,
        st.state_key,
        se.sector_key,

        r.revenue_thousand_dollars,
        r.sales_mwh,
        r.customer_count,
        r.avg_price_cents_per_kwh,
        r.data_status

    FROM stg.RetailMonthly r

    JOIN dw.DimDate d
        ON d.full_date = CAST(r.period AS DATE)

    JOIN dw.DimState st
        ON st.state_code = r.state_code

    JOIN dw.DimSector se
        ON se.sector_name = r.sector

    WHERE d.date_key >= @watermark

      AND NOT EXISTS
      (
          SELECT 1
          FROM dw.FactRetailElectricity f
          WHERE f.date_key = d.date_key
            AND f.state_key = st.state_key
            AND f.sector_key = se.sector_key
      );
END;
GO