````md
# DAX Measures — Yellow Taxi Power BI Dashboard

This file contains the recommended DAX measures for the Power BI dashboard.

The measures assume that the Power BI model contains the following tables:

- `FactTrips`
- `DimDate`
- `DimDistanceRange`
- `DimPassengerCount`
- `DimAirportTrip`

If your imported table names are different, replace the table names in the formulas.

---

## Basic Measures

### Total Revenue

```DAX
Total Revenue =
SUM(FactTrips[Total Amount])