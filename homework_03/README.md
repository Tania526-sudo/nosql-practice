# Homework 3

This homework contains two professional parts based on Task 3.

## Part A. Redis electronics catalog
A Redis-based online electronics catalog with:
- 5 smartphone models
- 3 TV models
- 3 smartphones of one manufacturer
- multi-parameter filtering
- cart creation
- stock updates
- Redis HASH / SET / ZSET / LIST / GEO / PubSub / HyperLogLog / transactions

## Part B. ECB XML parsing in MS SQL Server
A T-SQL solution that:
- loads ECB XML data into `@XML_SRC`
- parses XML using namespaces
- normalizes the data into:
  - `dbo.tblCurrency`
  - `dbo.tblCurrencyRate`

## Repository structure

```text
homework_03/
├── README.md
├── redis_electronics_catalog/
│   ├── README.md
│   ├── requirements.txt
│   ├── seed_products.json
│   ├── seed_stores.geojson
│   └── app.py
└── sql_xml_ecb/
    ├── README.md
    └── parse_ecb_xml.sql
```

## Submission notes

This solution is intentionally extended and professional:
- Redis is used not only as a key-value store, but as a multi-structure operational data platform
- the catalog supports filtering, cart logic, stock mutation, spatial lookup, and lightweight analytics
- the SQL part demonstrates normalized XML ingestion into relational tables