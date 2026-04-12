# Redis Electronics Catalog

## Overview
This project implements an online electronics catalog in Redis and covers key topics from Lecture 3:
- SET / GET
- HASH
- LIST
- unordered sets
- sorted sets
- transactions / pipelines

## Business scope
The catalog contains:
- 5 smartphone models
- 3 TV models
- 3 smartphones from one manufacturer

It supports:
- filtering all smartphones of one manufacturer
- filtering smartphones with price in 15-25K UAH and screen size < 6 inches
- cart creation
- stock update

## Redis data model

### Product storage
Each product is stored as a HASH:

- `product:{sku}`

### Filtering indexes
Sets and sorted sets are used for fast filtering:

- `idx:category:{category}`
- `idx:smartphone:brand:{brand}`
- `idx:smartphone:color:{color}`
- `idx:smartphone:screen_type:{screen_type}`
- `idx:smartphone:sim_count:{sim_count}`
- `idx:smartphone:price`
- `idx:smartphone:screen_size`
- `idx:tv:price`
- `idx:tv:diagonal`

### Cart
Cart is stored as a HASH:

- `cart:{user_id}:items`

### Audit log
Operational events are stored as a LIST:

- `log:audit`

## Run locally

### 1. Start Redis
```bash
docker run -d --name redis-local -p 6379:6379 redis:7-alpine