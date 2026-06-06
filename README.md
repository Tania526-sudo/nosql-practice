# nosql-practice

<p align="center">
  <img src="https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?style=for-the-badge&logo=powerbi&logoColor=black" />
  <img src="https://img.shields.io/badge/MS%20SQL%20Server-RDBMS-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white" />
  <img src="https://img.shields.io/badge/T--SQL-Data%20Preparation-0078D4?style=for-the-badge&logo=microsoft&logoColor=white" />
  <img src="https://img.shields.io/badge/DAX-Measures-742774?style=for-the-badge&logo=powerbi&logoColor=white" />
  <img src="https://img.shields.io/badge/BI-Star%20Schema-00A36C?style=for-the-badge" />
</p>
---

The main analytical goal is to visualize **daily taxi revenue for a selected month** and allow users to explore the results using business filters:

* trip distance range;
* passenger count;
* airport trip indicator.

---

##  Key Features

| Feature                 | Description                                                                                  |
| ----------------------- | -------------------------------------------------------------------------------------------- |
|  Daily Revenue Chart  | Shows total taxi revenue by day for a selected month                                         |
|  Interactive Filters | Allows filtering by month, distance range, passenger count, and airport trip type            |
|  DAX Measures         | Calculates revenue, trips, average revenue, distance, airport share, and tip metrics         |
|  SQL Views           | Prepares clean Power BI-ready fact and dimension views                                       |
|  Data Quality Checks   | Validates missing values, invalid distances, passenger count, revenue, and duplicate records |
|  Star Schema           | Uses a BI-friendly fact and dimension model                                                  |
|  Screenshots         | Includes model, filters, daily revenue chart, and final dashboard view                       |

---

### Fact Table

The fact table stores trip-level measures:

| Column Group         | Examples                                                              |
| -------------------- | --------------------------------------------------------------------- |
| Trip identifiers     | `TripID`                                                              |
| Date and time        | `PickupDatetime`, `DropoffDatetime`, `TripDate`                       |
| Trip characteristics | `PassengerCount`, `TripDistance`                                      |
| Financial measures   | `FareAmount`, `TipAmount`, `TollsAmount`, `AirportFee`, `TotalAmount` |
| Analytical keys      | `DistanceRangeID`, `PassengerCountID`, `AirportTripID`                |

### Dimension Tables

| Dimension           | Purpose                                 |
| ------------------- | --------------------------------------- |
| `DimDate`           | Filters by date, month, year, weekday   |
| `DimDistanceRange`  | Groups trips into distance categories   |
| `DimPassengerCount` | Allows passenger count filtering        |
| `DimAirportTrip`    | Separates airport and non-airport trips |

---

Recommended relationship settings:

| Setting                | Value                         |
| ---------------------- | ----------------------------- |
| Cardinality            | One-to-many                   |
| Cross-filter direction | Single                        |
| Filter flow            | Dimension tables → Fact table |

---

##  Power BI Dashboard Layout

The final dashboard contains several analytical blocks.

### KPI Cards

Recommended KPI cards:

| KPI                      | Meaning                            |
| ------------------------ | ---------------------------------- |
| Total Revenue            | Sum of total taxi revenue          |
| Total Trips              | Number of taxi trips               |
| Average Revenue per Trip | Revenue divided by number of trips |
| Average Trip Distance    | Average distance per trip          |
| Airport Trips Share      | Share of trips with airport fee    |

Fields:

| Role   | Field                |
| ------ | -------------------- |
| X-axis | `DimDate[Date]`      |
| Y-axis | `[Total Revenue]`    |
| Filter | `DimDate[YearMonth]` |

###  Required Filters

The dashboard includes the required filters:

| Filter          | Field                                    |
| --------------- | ---------------------------------------- |
| Month           | `DimDate[YearMonth]`                     |
| Distance Range  | `DimDistanceRange[DistanceRange]`        |
| Passenger Count | `DimPassengerCount[PassengerCountLabel]` |
| Airport Trip    | `DimAirportTrip[AirportTripType]`        |

### Additional Visuals

Recommended additional visuals:

| Visual                                     | Purpose                                            |
| ------------------------------------------ | -------------------------------------------------- |
| Revenue by Distance Range                  | Compares revenue across trip distance groups       |
| Trips by Passenger Count                   | Shows how trips are distributed by passenger count |
| Airport vs Non-Airport Revenue             | Compares revenue structure by airport trip status  |
| Average Revenue per Trip by Distance Range | Shows profitability of trip categories             |

---

##  DAX Measures

Main measures:

```DAX
Total Revenue =
SUM(FactTrips[TotalAmount])
```

```DAX
Total Trips =
COUNTROWS(FactTrips)
```

```DAX
Average Revenue per Trip =
DIVIDE(
    [Total Revenue],
    [Total Trips],
    0
)
```

```DAX
Average Trip Distance =
AVERAGE(FactTrips[TripDistance])
```

```DAX
Airport Trips Share =
DIVIDE(
    [Airport Trips],
    [Total Trips],
    0
)
```
---

## Completion Checklist

| Requirement                     | Status |
| ------------------------------- | ----   |
| SQL views prepared              |   +    |
| Data quality checks added       |   +    |
| Sample analytical queries added |   +    |
| DAX measures documented         |   +    |
| Power BI dashboard file added   |   +    |
| Daily revenue chart created     |   +    |
| Distance range filter added     |   +    |
| Passenger count filter added    |   +    |
| Airport trip filter added       |   +    |
| Data model screenshot added     |   +    |
| Filters screenshot added        |   +    |
| Dashboard screenshot added      |   +    |
| Final report screenshot added   |   +    |

---

## Expected Analytical Insights

The dashboard can help identify:

* days with the highest and lowest taxi revenue;
* distance ranges that generate the most revenue;
* difference between airport and non-airport trips;
* passenger count distribution;
* average revenue per trip;
* revenue patterns during the selected month.

---

## Technologies

<p align="center">
  <img src="https://img.shields.io/badge/SQL%20Server-Relational%20Database-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white" />
  <img src="https://img.shields.io/badge/T--SQL-Views%20%26%20Checks-0078D4?style=for-the-badge&logo=microsoft&logoColor=white" />
  <img src="https://img.shields.io/badge/Power%20BI-Interactive%20Dashboard-F2C811?style=for-the-badge&logo=powerbi&logoColor=black" />
  <img src="https://img.shields.io/badge/DAX-Business%20Measures-742774?style=for-the-badge" />
  <img src="https://img.shields.io/badge/BI%20Modeling-Star%20Schema-00A36C?style=for-the-badge" />
</p>

---

## Final Result

This homework demonstrates a complete BI workflow based on relational database modeling and Power BI reporting.

It shows how prepared RDBMS data can be transformed into an interactive analytical dashboard for business decision-making.
