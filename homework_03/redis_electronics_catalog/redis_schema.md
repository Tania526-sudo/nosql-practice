# Redis Schema Design for Electronics Catalog

## 1. Overview

This document describes the Redis data model used in the online electronics catalog.

The solution is designed as an extended Redis-based operational catalog and demonstrates practical usage of multiple Redis data types:

- String
- Hash
- Set
- Sorted Set
- List
- GEO
- HyperLogLog
- Pub/Sub
- Transactions

The catalog contains:
- smartphones
- TVs
- stores / pickup points
- stock by store
- carts
- filtering indexes
- analytics
- logs

---

## 2. Main Redis key patterns

### 2.1. Configuration keys

These keys store basic system configuration values.

```text
cfg:currency
cfg:catalog_status
cfg:default_city
app:last_seed_ts