---------------------------------------------------------------
-- 1. Total number of records
---------------------------------------------------------------

SELECT
    COUNT(*) AS TotalRows
FROM dbo.fact_yellow_tripdata;


---------------------------------------------------------------
-- 2. Date range check
---------------------------------------------------------------

SELECT
    MIN(pickup_datetime) AS MinPickupDatetime,
    MAX(pickup_datetime) AS MaxPickupDatetime,
    MIN(dropoff_datetime) AS MinDropoffDatetime,
    MAX(dropoff_datetime) AS MaxDropoffDatetime
FROM dbo.fact_yellow_tripdata;


---------------------------------------------------------------
-- 3. Missing critical values
---------------------------------------------------------------

SELECT
    SUM(CASE WHEN pickup_datetime IS NULL THEN 1 ELSE 0 END) AS MissingPickupDatetime,
    SUM(CASE WHEN dropoff_datetime IS NULL THEN 1 ELSE 0 END) AS MissingDropoffDatetime,
    SUM(CASE WHEN passenger_count IS NULL THEN 1 ELSE 0 END) AS MissingPassengerCount,
    SUM(CASE WHEN trip_distance IS NULL THEN 1 ELSE 0 END) AS MissingTripDistance,
    SUM(CASE WHEN total_amount IS NULL THEN 1 ELSE 0 END) AS MissingTotalAmount
FROM dbo.fact_yellow_tripdata;


---------------------------------------------------------------
-- 4. Negative or zero revenue check
---------------------------------------------------------------

SELECT
    COUNT(*) AS TripsWithZeroOrNegativeRevenue
FROM dbo.fact_yellow_tripdata
WHERE total_amount <= 0
   OR total_amount IS NULL;


---------------------------------------------------------------
-- 5. Negative or zero distance check
---------------------------------------------------------------

SELECT
    COUNT(*) AS TripsWithZeroOrNegativeDistance
FROM dbo.fact_yellow_tripdata
WHERE trip_distance <= 0
   OR trip_distance IS NULL;


---------------------------------------------------------------
-- 6. Invalid passenger count check
---------------------------------------------------------------

SELECT
    passenger_count,
    COUNT(*) AS TripsCount
FROM dbo.fact_yellow_tripdata
GROUP BY passenger_count
ORDER BY passenger_count;


---------------------------------------------------------------
-- 7. Passenger count quality summary
---------------------------------------------------------------

SELECT
    SUM(CASE WHEN passenger_count BETWEEN 1 AND 6 THEN 1 ELSE 0 END) AS ValidPassengerCountRows,
    SUM(CASE WHEN passenger_count IS NULL THEN 1 ELSE 0 END) AS NullPassengerCountRows,
    SUM(CASE WHEN passenger_count < 1 THEN 1 ELSE 0 END) AS TooLowPassengerCountRows,
    SUM(CASE WHEN passenger_count > 6 THEN 1 ELSE 0 END) AS TooHighPassengerCountRows
FROM dbo.fact_yellow_tripdata;


---------------------------------------------------------------
-- 8. Trip distance distribution check
---------------------------------------------------------------

SELECT
    CASE
        WHEN trip_distance IS NULL THEN 'Unknown'
        WHEN trip_distance < 0 THEN 'Invalid negative distance'
        WHEN trip_distance >= 0  AND trip_distance < 1  THEN '0–1 miles'
        WHEN trip_distance >= 1  AND trip_distance < 3  THEN '1–3 miles'
        WHEN trip_distance >= 3  AND trip_distance < 5  THEN '3–5 miles'
        WHEN trip_distance >= 5  AND trip_distance < 10 THEN '5–10 miles'
        WHEN trip_distance >= 10 AND trip_distance < 20 THEN '10–20 miles'
        WHEN trip_distance >= 20 THEN '20+ miles'
        ELSE 'Unknown'
    END AS DistanceRange,
    COUNT(*) AS TripsCount,
    SUM(total_amount) AS TotalRevenue,
    AVG(total_amount) AS AverageRevenue
FROM dbo.fact_yellow_tripdata
GROUP BY
    CASE
        WHEN trip_distance IS NULL THEN 'Unknown'
        WHEN trip_distance < 0 THEN 'Invalid negative distance'
        WHEN trip_distance >= 0  AND trip_distance < 1  THEN '0–1 miles'
        WHEN trip_distance >= 1  AND trip_distance < 3  THEN '1–3 miles'
        WHEN trip_distance >= 3  AND trip_distance < 5  THEN '3–5 miles'
        WHEN trip_distance >= 5  AND trip_distance < 10 THEN '5–10 miles'
        WHEN trip_distance >= 10 AND trip_distance < 20 THEN '10–20 miles'
        WHEN trip_distance >= 20 THEN '20+ miles'
        ELSE 'Unknown'
    END
ORDER BY TotalRevenue DESC;


---------------------------------------------------------------
-- 9. Airport fee distribution
---------------------------------------------------------------

SELECT
    CASE
        WHEN ISNULL(airport_fee, 0) > 0 THEN 'Airport Trip'
        ELSE 'Non-Airport Trip'
    END AS AirportTripType,
    COUNT(*) AS TripsCount,
    SUM(total_amount) AS TotalRevenue,
    AVG(total_amount) AS AverageRevenuePerTrip,
    AVG(trip_distance) AS AverageTripDistance
FROM dbo.fact_yellow_tripdata
GROUP BY
    CASE
        WHEN ISNULL(airport_fee, 0) > 0 THEN 'Airport Trip'
        ELSE 'Non-Airport Trip'
    END;


---------------------------------------------------------------
-- 10. Duplicate trip ID check
---------------------------------------------------------------

SELECT
    trip_id,
    COUNT(*) AS DuplicateCount
FROM dbo.fact_yellow_tripdata
GROUP BY trip_id
HAVING COUNT(*) > 1
ORDER BY DuplicateCount DESC;


---------------------------------------------------------------
-- 11. Daily revenue validation
---------------------------------------------------------------

SELECT
    CAST(pickup_datetime AS DATE) AS TripDate,
    COUNT(*) AS TripsCount,
    SUM(total_amount) AS DailyRevenue,
    AVG(total_amount) AS AverageRevenuePerTrip,
    MIN(total_amount) AS MinTripAmount,
    MAX(total_amount) AS MaxTripAmount
FROM dbo.fact_yellow_tripdata
WHERE pickup_datetime IS NOT NULL
GROUP BY CAST(pickup_datetime AS DATE)
ORDER BY TripDate;


---------------------------------------------------------------
-- 12. Power BI fact view validation
---------------------------------------------------------------

SELECT
    COUNT(*) AS PowerBIFactRows,
    SUM(TotalAmount) AS TotalRevenue,
    AVG(TotalAmount) AS AverageRevenuePerTrip,
    AVG(TripDistance) AS AverageTripDistance
FROM bi.vw_fact_yellow_tripdata_powerbi;


---------------------------------------------------------------
-- 13. Check if Power BI dimension keys are valid
---------------------------------------------------------------

SELECT
    DistanceRangeID,
    COUNT(*) AS TripsCount
FROM bi.vw_fact_yellow_tripdata_powerbi
GROUP BY DistanceRangeID
ORDER BY DistanceRangeID;


SELECT
    PassengerCountID,
    COUNT(*) AS TripsCount
FROM bi.vw_fact_yellow_tripdata_powerbi
GROUP BY PassengerCountID
ORDER BY PassengerCountID;


SELECT
    AirportTripID,
    COUNT(*) AS TripsCount
FROM bi.vw_fact_yellow_tripdata_powerbi
GROUP BY AirportTripID
ORDER BY AirportTripID;


---------------------------------------------------------------
-- 14. Orphan check: Distance range
---------------------------------------------------------------

SELECT
    f.DistanceRangeID,
    COUNT(*) AS OrphanRows
FROM bi.vw_fact_yellow_tripdata_powerbi AS f
LEFT JOIN bi.vw_dim_distance_range_powerbi AS d
    ON f.DistanceRangeID = d.DistanceRangeID
WHERE d.DistanceRangeID IS NULL
GROUP BY f.DistanceRangeID;


---------------------------------------------------------------
-- 15. Orphan check: Passenger count
---------------------------------------------------------------

SELECT
    f.PassengerCountID,
    COUNT(*) AS OrphanRows
FROM bi.vw_fact_yellow_tripdata_powerbi AS f
LEFT JOIN bi.vw_dim_passenger_count_powerbi AS p
    ON f.PassengerCountID = p.PassengerCountID
WHERE p.PassengerCountID IS NULL
GROUP BY f.PassengerCountID;


---------------------------------------------------------------
-- 16. Orphan check: Airport trip
---------------------------------------------------------------

SELECT
    f.AirportTripID,
    COUNT(*) AS OrphanRows
FROM bi.vw_fact_yellow_tripdata_powerbi AS f
LEFT JOIN bi.vw_dim_airport_trip_powerbi AS a
    ON f.AirportTripID = a.AirportTripID
WHERE a.AirportTripID IS NULL
GROUP BY f.AirportTripID;