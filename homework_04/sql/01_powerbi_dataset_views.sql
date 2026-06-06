---------------------------------------------------------------
-- 0. Create BI schema
---------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'bi'
)
BEGIN
    EXEC('CREATE SCHEMA bi');
END;
GO

---------------------------------------------------------------
-- 1. Fact View for Power BI
---------------------------------------------------------------

CREATE OR ALTER VIEW bi.vw_fact_yellow_tripdata_powerbi AS
SELECT
    -- Primary trip identifier
    CAST(f.trip_id AS BIGINT) AS TripID,

    -- Date and time
    CAST(f.pickup_datetime AS DATETIME2) AS PickupDatetime,
    CAST(f.dropoff_datetime AS DATETIME2) AS DropoffDatetime,
    CAST(f.pickup_datetime AS DATE) AS TripDate,

    -- Time attributes
    DATEPART(HOUR, f.pickup_datetime) AS PickupHour,
    DATEPART(WEEKDAY, f.pickup_datetime) AS PickupWeekdayNumber,

    -- Passenger information
    CAST(f.passenger_count AS INT) AS PassengerCount,

    -- Distance
    CAST(f.trip_distance AS DECIMAL(18, 3)) AS TripDistance,

    -- Financial measures
    CAST(f.fare_amount AS DECIMAL(18, 2)) AS FareAmount,
    CAST(ISNULL(f.tip_amount, 0) AS DECIMAL(18, 2)) AS TipAmount,
    CAST(ISNULL(f.tolls_amount, 0) AS DECIMAL(18, 2)) AS TollsAmount,
    CAST(ISNULL(f.airport_fee, 0) AS DECIMAL(18, 2)) AS AirportFee,
    CAST(f.total_amount AS DECIMAL(18, 2)) AS TotalAmount,

    -- Distance range key
    CASE
        WHEN f.trip_distance IS NULL THEN -1
        WHEN f.trip_distance < 0 THEN -1
        WHEN f.trip_distance >= 0  AND f.trip_distance < 1  THEN 1
        WHEN f.trip_distance >= 1  AND f.trip_distance < 3  THEN 2
        WHEN f.trip_distance >= 3  AND f.trip_distance < 5  THEN 3
        WHEN f.trip_distance >= 5  AND f.trip_distance < 10 THEN 4
        WHEN f.trip_distance >= 10 AND f.trip_distance < 20 THEN 5
        WHEN f.trip_distance >= 20 THEN 6
        ELSE -1
    END AS DistanceRangeID,

    -- Passenger count key
    CASE
        WHEN f.passenger_count IS NULL THEN -1
        WHEN f.passenger_count BETWEEN 1 AND 6 THEN CAST(f.passenger_count AS INT)
        ELSE -1
    END AS PassengerCountID,

    -- Airport trip key
    CASE
        WHEN ISNULL(f.airport_fee, 0) > 0 THEN 1
        ELSE 0
    END AS AirportTripID,

    -- Data quality flags
    CASE
        WHEN f.total_amount > 0 THEN 1
        ELSE 0
    END AS IsPositiveRevenue,

    CASE
        WHEN f.trip_distance > 0 THEN 1
        ELSE 0
    END AS IsPositiveDistance,

    CASE
        WHEN f.passenger_count BETWEEN 1 AND 6 THEN 1
        ELSE 0
    END AS IsValidPassengerCount

FROM dbo.fact_yellow_tripdata AS f
WHERE
    f.pickup_datetime IS NOT NULL
    AND f.total_amount IS NOT NULL;
GO

---------------------------------------------------------------
-- 2. Date Dimension View
---------------------------------------------------------------

CREATE OR ALTER VIEW bi.vw_dim_date_powerbi AS
SELECT DISTINCT
    CAST(f.pickup_datetime AS DATE) AS Date,

    YEAR(f.pickup_datetime) AS Year,
    MONTH(f.pickup_datetime) AS MonthNumber,

    DATENAME(MONTH, f.pickup_datetime) AS MonthName,

    CONCAT(
        YEAR(f.pickup_datetime),
        '-',
        RIGHT('0' + CAST(MONTH(f.pickup_datetime) AS VARCHAR(2)), 2)
    ) AS YearMonth,

    DAY(f.pickup_datetime) AS DayOfMonth,

    DATEPART(WEEKDAY, f.pickup_datetime) AS WeekdayNumber,
    DATENAME(WEEKDAY, f.pickup_datetime) AS WeekdayName,

    CASE
        WHEN DATEPART(WEEKDAY, f.pickup_datetime) IN (1, 7) THEN 1
        ELSE 0
    END AS IsWeekend

FROM dbo.fact_yellow_tripdata AS f
WHERE f.pickup_datetime IS NOT NULL;
GO

---------------------------------------------------------------
-- 3. Distance Range Dimension View
---------------------------------------------------------------

CREATE OR ALTER VIEW bi.vw_dim_distance_range_powerbi AS
SELECT *
FROM (
    VALUES
        (-1, 'Unknown / Invalid', 'Unknown or invalid distance', 0),
        (1,  '0–1 miles',        'Very short trips',             1),
        (2,  '1–3 miles',        'Short trips',                  2),
        (3,  '3–5 miles',        'Medium trips',                 3),
        (4,  '5–10 miles',       'Long trips',                   4),
        (5,  '10–20 miles',      'Very long trips',              5),
        (6,  '20+ miles',        'Extra long trips',             6)
) AS d(
    DistanceRangeID,
    DistanceRange,
    DistanceRangeDescription,
    SortOrder
);
GO

---------------------------------------------------------------
-- 4. Passenger Count Dimension View
---------------------------------------------------------------

CREATE OR ALTER VIEW bi.vw_dim_passenger_count_powerbi AS
SELECT *
FROM (
    VALUES
        (-1, 'Unknown / Invalid passenger count', 0),
        (1,  '1 passenger', 1),
        (2,  '2 passengers', 2),
        (3,  '3 passengers', 3),
        (4,  '4 passengers', 4),
        (5,  '5 passengers', 5),
        (6,  '6 passengers', 6)
) AS p(
    PassengerCountID,
    PassengerCountLabel,
    SortOrder
);
GO

---------------------------------------------------------------
-- 5. Airport Trip Dimension View
---------------------------------------------------------------

CREATE OR ALTER VIEW bi.vw_dim_airport_trip_powerbi AS
SELECT *
FROM (
    VALUES
        (0, 'Non-Airport Trip', 'Trip without airport fee'),
        (1, 'Airport Trip',     'Trip with airport fee')
) AS a(
    AirportTripID,
    AirportTripType,
    AirportTripDescription
);
GO

---------------------------------------------------------------
-- 6. Denormalized Reporting View
---------------------------------------------------------------

CREATE OR ALTER VIEW bi.vw_yellow_tripdata_dashboard_dataset AS
SELECT
    f.TripID,
    f.PickupDatetime,
    f.DropoffDatetime,
    f.TripDate,
    f.PickupHour,
    f.PassengerCount,
    f.TripDistance,
    f.FareAmount,
    f.TipAmount,
    f.TollsAmount,
    f.AirportFee,
    f.TotalAmount,

    d.Date,
    d.Year,
    d.MonthNumber,
    d.MonthName,
    d.YearMonth,
    d.DayOfMonth,
    d.WeekdayName,
    d.IsWeekend,

    dr.DistanceRange,
    dr.DistanceRangeDescription,

    pc.PassengerCountLabel,

    at.AirportTripType,
    at.AirportTripDescription,

    f.IsPositiveRevenue,
    f.IsPositiveDistance,
    f.IsValidPassengerCount

FROM bi.vw_fact_yellow_tripdata_powerbi AS f

LEFT JOIN bi.vw_dim_date_powerbi AS d
    ON f.TripDate = d.Date

LEFT JOIN bi.vw_dim_distance_range_powerbi AS dr
    ON f.DistanceRangeID = dr.DistanceRangeID

LEFT JOIN bi.vw_dim_passenger_count_powerbi AS pc
    ON f.PassengerCountID = pc.PassengerCountID

LEFT JOIN bi.vw_dim_airport_trip_powerbi AS at
    ON f.AirportTripID = at.AirportTripID;
GO