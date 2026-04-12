# Redis Electronics Catalog

## Overview

This project implements a Redis-based online electronics catalog and covers key Redis topics from Lecture 3:

- Key-value usage with `SET` and `GET`
- `MSET` and `MGET`
- temporary caching with `SETEX`
- `HASH` for structured product entities
- `LIST` for audit events
- unordered `SET` indexes for categorical filters
- `SORTED SET` indexes for range filters
- `GEO` for store locations
- `HyperLogLog` for approximate unique users
- transaction support for cart operations
- `PUBLISH` for stock and cart event notifications

## Business scope

The dataset contains:
- 5 smartphone models
- 3 TV models
- 3 smartphones of one manufacturer (Samsung)

The system supports:
- output all smartphones of one manufacturer
- output smartphones in the price range 15–25K UAH with screen size < 6 inches
- cart creation
- stock update for a concrete model
- nearest stores lookup using geospatial coordinates

## Redis data model

### 1. Product storage using HASH
Each product is stored as a HASH:

- `product:{sku}`

Example:
- `product:APPLE-IPHONE13MINI-128`
- `product:SAMSUNG-A55-5G-256`

### 2. Set-based filtering indexes
Used for exact categorical filtering:

- `idx:category:smartphone`
- `idx:category:tv`
- `idx:smartphone:brand:samsung`
- `idx:smartphone:screen_type:amoled`
- `idx:smartphone:sim_count:2`
- `idx:smartphone:color:black`

### 3. Sorted set indexes
Used for range-based filters:

- `idx:smartphone:price`
- `idx:smartphone:screen_size`
- `idx:tv:price`
- `idx:tv:diagonal`

### 4. Cart using HASH
- `cart:{user_id}:items`
- `cart:{user_id}:meta`

### 5. Audit log using LIST
- `log:audit`

### 6. Geo layer
Stores and pickup points are loaded into:

- `geo:stores`

Store metadata:
- `store:{store_id}:meta`

Store stock:
- `store:{store_id}:stock`

### 7. Analytics
Popularity ranking:
- `rank:products:popularity`

Approximate unique viewers:
- `hll:catalog:users:{date}`

### 8. Cache
Filter cache:
- `cache:filter:{...}`

## How to run

### 1. Start Redis locally

```bash
docker run -d --name redis-local -p 6379:6379 redis:7-alpine
```

If the container already exists:

```bash
docker start redis-local
```

### 2. Install dependencies

```bash
python -m venv venv
.\venv\Scripts\python.exe -m pip install -r homework_03/redis_electronics_catalog/requirements.txt
```

### 3. Run the application

```bash
.\venv\Scripts\python.exe homework_03/redis_electronics_catalog/app.py
```

## Professional notes

This solution is intentionally broader than a minimal homework solution. It demonstrates how Redis can be used as:

- a primary operational catalog store
- a filtering index engine
- a lightweight transactional system
- a geospatial lookup layer
- a cache
- a compact analytics backend

The geodata layer uses Redis GEO internally and GeoJSON as an exchange format for stores and pickup points.