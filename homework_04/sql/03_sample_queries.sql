---------------------------------------------------------------
-- 1. Daily revenue for all available dates
---------------------------------------------------------------

SELECT
    TripDate,
    COUNT(*) AS TripsCount,
    SUM(TotalAmount) AS DailyRevenue,
    AVG(TotalAmount) AS AverageRevenuePerTrip,
    AVG(TripDistance) AS AverageTripDistance
FROM bi.vw_fact_yellow_tripdata_powerbi
GROUP BY TripDate
ORDER BY TripDate;


---------------------------------------------------------------
-- 2. Daily revenue for a selected month
---------------------------------------------------------------

DECLARE @SelectedMonth CHAR(7) = '2023-01';

SELECT
    d.YearMonth,
    f.TripDate,
    COUNT(*) AS TripsCount,
    SUM(f.TotalAmount) AS DailyRevenue,
    AVG(f.TotalAmount) AS AverageRevenuePerTrip
FROM bi.vw_fact_yellow_tripdata_powerbi AS f
INNER JOIN bi.vw_dim_date_powerbi AS d
    ON f.TripDate = d.Date
WHERE d.YearMonth = @SelectedMonth
GROUP BY
    d.YearMonth,
    f.TripDate
ORDER BY f.TripDate;


---------------------------------------------------------------
-- 3. Revenue by distance range
---------------------------------------------------------------

SELECT
    dr.DistanceRange,
    dr.DistanceRangeDescription,
    COUNT(*) AS TripsCount,
    SUM(f.TotalAmount) AS TotalRevenue,
    AVG(f.TotalAmount) AS AverageRevenuePerTrip,
    AVG(f.TripDistance) AS AverageDistance
FROM bi.vw_fact_yellow_tripdata_powerbi AS f
LEFT JOIN bi.vw_dim_distance_range_powerbi AS dr
    ON f.DistanceRangeID = dr.DistanceRangeID
GROUP BY
    dr.DistanceRange,
    dr.DistanceRangeDescription,
    dr.SortOrder
ORDER BY dr.SortOrder;


---------------------------------------------------------------
-- 4. Revenue by passenger count
---------------------------------------------------------------

SELECT
    pc.PassengerCountLabel,
    COUNT(*) AS TripsCount,
    SUM(f.TotalAmount) AS TotalRevenue,
    AVG(f.TotalAmount) AS AverageRevenuePerTrip,
    AVG(f.TripDistance) AS AverageTripDistance
FROM bi.vw_fact_yellow_tripdata_powerbi AS f
LEFT JOIN bi.vw_dim_passenger_count_powerbi AS pc
    ON f.PassengerCountID = pc.PassengerCountID
GROUP BY
    pc.PassengerCountLabel,
    pc.SortOrder
ORDER BY pc.SortOrder;


---------------------------------------------------------------
-- 5. Airport vs Non-Airport revenue comparison
---------------------------------------------------------------

SELECT
    a.AirportTripType,
    COUNT(*) AS TripsCount,
    SUM(f.TotalAmount) AS TotalRevenue,
    AVG(f.TotalAmount) AS AverageRevenuePerTrip,
    AVG(f.TripDistance) AS AverageTripDistance,
    SUM(f.TipAmount) AS TotalTips
FROM bi.vw_fact_yellow_tripdata_powerbi AS f
LEFT JOIN bi.vw_dim_airport_trip_powerbi AS a
    ON f.AirportTripID = a.AirportTripID
GROUP BY a.AirportTripType
ORDER BY TotalRevenue DESC;


---------------------------------------------------------------
-- 6. Daily revenue by airport trip type
---------------------------------------------------------------

SELECT
    f.TripDate,
    a.AirportTripType,
    COUNT(*) AS TripsCount,
    SUM(f.TotalAmount) AS DailyRevenue,
    AVG(f.TotalAmount) AS AverageRevenuePerTrip
FROM bi.vw_fact_yellow_tripdata_powerbi AS f
LEFT JOIN bi.vw_dim_airport_trip_powerbi AS a
    ON f.AirportTripID = a.AirportTripID
GROUP BY
    f.TripDate,
    a.AirportTripType
ORDER BY
    f.TripDate,
    a.AirportTripType;


---------------------------------------------------------------
-- 7. Daily revenue by distance range
---------------------------------------------------------------

SELECT
    f.TripDate,
    dr.DistanceRange,
    COUNT(*) AS TripsCount,
    SUM(f.TotalAmount) AS DailyRevenue,
    AVG(f.TotalAmount) AS AverageRevenuePerTrip
FROM bi.vw_fact_yellow_tripdata_powerbi AS f
LEFT JOIN bi.vw_dim_distance_range_powerbi AS dr
    ON f.DistanceRangeID = dr.DistanceRangeID
GROUP BY
    f.TripDate,
    dr.DistanceRange,
    dr.SortOrder
ORDER BY
    f.TripDate,
    dr.SortOrder;


---------------------------------------------------------------
-- 8. Top 10 revenue days
---------------------------------------------------------------

SELECT TOP 10
    TripDate,
    COUNT(*) AS TripsCount,
    SUM(TotalAmount) AS DailyRevenue,
    AVG(TotalAmount) AS AverageRevenuePerTrip
FROM bi.vw_fact_yellow_tripdata_powerbi
GROUP BY TripDate
ORDER BY DailyRevenue DESC;


---------------------------------------------------------------
-- 9. Lowest 10 revenue days
---------------------------------------------------------------

SELECT TOP 10
    TripDate,
    COUNT(*) AS TripsCount,
    SUM(TotalAmount) AS DailyRevenue,
    AVG(TotalAmount) AS AverageRevenuePerTrip
FROM bi.vw_fact_yellow_tripdata_powerbi
GROUP BY TripDate
ORDER BY DailyRevenue ASC;


---------------------------------------------------------------
-- 10. Monthly revenue summary
---------------------------------------------------------------

SELECT
    d.Year,
    d.MonthNumber,
    d.MonthName,
    d.YearMonth,
    COUNT(*) AS TripsCount,
    SUM(f.TotalAmount) AS MonthlyRevenue,
    AVG(f.TotalAmount) AS AverageRevenuePerTrip,
    AVG(f.TripDistance) AS AverageTripDistance
FROM bi.vw_fact_yellow_tripdata_powerbi AS f
INNER JOIN bi.vw_dim_date_powerbi AS d
    ON f.TripDate = d.Date
GROUP BY
    d.Year,
    d.MonthNumber,
    d.MonthName,
    d.YearMonth
ORDER BY
    d.Year,
    d.MonthNumber;


---------------------------------------------------------------
-- 11. Revenue matrix: distance range and airport trip type
---------------------------------------------------------------

SELECT
    dr.DistanceRange,
    a.AirportTripType,
    COUNT(*) AS TripsCount,
    SUM(f.TotalAmount) AS TotalRevenue,
    AVG(f.TotalAmount) AS AverageRevenuePerTrip,
    AVG(f.TripDistance) AS AverageTripDistance
FROM bi.vw_fact_yellow_tripdata_powerbi AS f
LEFT JOIN bi.vw_dim_distance_range_powerbi AS dr
    ON f.DistanceRangeID = dr.DistanceRangeID
LEFT JOIN bi.vw_dim_airport_trip_powerbi AS a
    ON f.AirportTripID = a.AirportTripID
GROUP BY
    dr.DistanceRange,
    dr.SortOrder,
    a.AirportTripType
ORDER BY
    dr.SortOrder,
    a.AirportTripType;


---------------------------------------------------------------
-- 12. Revenue matrix: passenger count and distance range
---------------------------------------------------------------

SELECT
    pc.PassengerCountLabel,
    dr.DistanceRange,
    COUNT(*) AS TripsCount,
    SUM(f.TotalAmount) AS TotalRevenue,
    AVG(f.TotalAmount) AS AverageRevenuePerTrip
FROM bi.vw_fact_yellow_tripdata_powerbi AS f
LEFT JOIN bi.vw_dim_passenger_count_powerbi AS pc
    ON f.PassengerCountID = pc.PassengerCountID
LEFT JOIN bi.vw_dim_distance_range_powerbi AS dr
    ON f.DistanceRangeID = dr.DistanceRangeID
GROUP BY
    pc.PassengerCountLabel,
    pc.SortOrder,
    dr.DistanceRange,
    dr.SortOrder
ORDER BY
    pc.SortOrder,
    dr.SortOrder;


---------------------------------------------------------------
-- 13. Full dashboard dataset preview
---------------------------------------------------------------

SELECT TOP 100
    *
FROM bi.vw_yellow_tripdata_dashboard_dataset
ORDER BY TripDate, TripID;