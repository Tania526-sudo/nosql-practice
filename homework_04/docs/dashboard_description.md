# Dashboard Description — Yellow Taxi Daily Revenue Analysis

## Purpose of the Dashboard

The purpose of this Power BI dashboard is to analyze Yellow Taxi trip revenue using the prepared relational data model from the RDBMS ETL process.

The dashboard focuses on daily revenue analysis for a selected month and provides interactive filtering by distance range, passenger count, and airport trip status.

This allows users to understand how taxi revenue changes over time and how different trip characteristics influence the final revenue.

## Business Context

Taxi trip data contains many useful indicators for operational and financial analysis:

- pickup and drop-off time;
- trip distance;
- passenger count;
- fare amount;
- tips;
- tolls;
- airport fees;
- total trip amount.

For this homework, the most important metric is total revenue.  
The main dashboard chart shows daily revenue for a selected month.

Additional filters allow the user to compare different trip groups and better understand which categories contribute most to revenue.

## Analytical Model

The model is designed as a star schema.

The central table is the fact table with taxi trips.  
Dimension tables describe analytical categories such as date, distance ranges, passenger count, and airport trip status.

This design is suitable for Power BI because it provides:

- simple relationships;
- fast filtering;
- clean aggregation logic;
- reusable DAX measures;
- clear separation between facts and dimensions.

##  Main Fact Table

The fact table contains trip-level records.

Recommended columns:

| Column | Description |
|---|---|
| Trip ID | Unique trip identifier |
| Pickup Datetime | Start time of the trip |
| Dropoff Datetime | End time of the trip |
| Trip Date | Date used for daily aggregation |
| Passenger Count | Number of passengers |
| Trip Distance | Trip distance |
| Fare Amount | Base fare |
| Tip Amount | Tip value |
| Tolls Amount | Toll payments |
| Airport Fee | Airport-related fee |
| Total Amount | Total trip revenue |
| Distance Range ID | Link to distance range dimension |
| Airport Trip ID | Link to airport trip dimension |

## Dimension Tables

### Date Dimension

The date dimension is used to filter data by year, month, and day.

Recommended fields:

- Date;
- Year;
- Month Number;
- Month Name;
- Year-Month;
- Day of Month;
- Day of Week;
- Weekday Name.

### Distance Range Dimension

The distance range dimension groups trips into meaningful categories:

| Range | Meaning |
|---|---|
| 0–1 miles | Very short trips |
| 1–3 miles | Short trips |
| 3–5 miles | Medium trips |
| 5–10 miles | Long trips |
| 10–20 miles | Very long trips |
| 20+ miles | Extra long trips |

This dimension is used as a filter and for revenue comparison.

### Passenger Count Dimension

The passenger count dimension allows filtering by the number of passengers in a trip.

Typical categories:

- 1 passenger;
- 2 passengers;
- 3 passengers;
- 4 passengers;
- 5 passengers;
- 6 passengers;
- Unknown or invalid passenger count.

### Airport Trip Dimension

The airport trip dimension separates trips into:

- Airport trip;
- Non-airport trip;
- Unknown.

This filter is useful because airport trips usually have different distance, fare, and revenue patterns.

## Dashboard Layout

The recommended dashboard layout contains the following blocks.

### Header

Title:

```text
Yellow Taxi Daily Revenue Dashboard