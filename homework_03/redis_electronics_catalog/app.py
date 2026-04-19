import json
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

import redis


def normalize(value: str) -> str:
    return (
        value.strip()
        .lower()
        .replace(" ", "_")
        .replace("/", "_")
        .replace("-", "_")
    )


def connect_redis() -> redis.Redis:
    return redis.Redis(
        host="localhost",
        port=6379,
        db=0,
        decode_responses=True,
    )


def file_path(filename: str) -> Path:
    return Path(__file__).parent / filename


def load_json(filename: str) -> Any:
    with open(file_path(filename), "r", encoding="utf-8") as f:
        return json.load(f)


def product_key(sku: str) -> str:
    return f"product:{sku}"


def store_meta_key(store_id: str) -> str:
    return f"store:{store_id}:meta"


def store_stock_key(store_id: str) -> str:
    return f"store:{store_id}:stock"


def category_index_key(category: str) -> str:
    return f"idx:category:{normalize(category)}"


def brand_index_key(category: str, brand: str) -> str:
    return f"idx:{normalize(category)}:brand:{normalize(brand)}"


def color_index_key(category: str, color: str) -> str:
    return f"idx:{normalize(category)}:color:{normalize(color)}"


def smartphone_screen_type_key(screen_type: str) -> str:
    return f"idx:smartphone:screen_type:{normalize(screen_type)}"


def smartphone_sim_count_key(sim_count: int) -> str:
    return f"idx:smartphone:sim_count:{sim_count}"


def smartphone_price_zset_key() -> str:
    return "idx:smartphone:price"


def smartphone_screen_size_zset_key() -> str:
    return "idx:smartphone:screen_size"


def tv_price_zset_key() -> str:
    return "idx:tv:price"


def tv_diagonal_zset_key() -> str:
    return "idx:tv:diagonal"


def popularity_zset_key() -> str:
    return "rank:products:popularity"


def geo_stores_key() -> str:
    return "geo:stores"


def cart_items_key(user_id: str) -> str:
    return f"cart:{user_id}:items"


def cart_meta_key(user_id: str) -> str:
    return f"cart:{user_id}:meta"


def audit_log_key() -> str:
    return "log:audit"


def user_views_hll_key(date_key: str) -> str:
    return f"hll:catalog:users:{date_key}"


def cache_filter_key(name: str) -> str:
    return f"cache:filter:{name}"


def stock_updates_channel() -> str:
    return "channel:stock_updates"


def cart_events_channel() -> str:
    return "channel:cart_events"


def set_system_config(r: redis.Redis) -> None:
    r.mset(
        {
            "cfg:currency": "UAH",
            "cfg:catalog_status": "active",
            "cfg:default_city": "Kyiv",
        }
    )
    r.set("app:last_seed_ts", int(time.time()))


def log_event(r: redis.Redis, payload: Dict[str, Any]) -> None:
    r.lpush(audit_log_key(), json.dumps(payload, ensure_ascii=False))


def seed_stores_geo(r: redis.Redis, geojson_data: Dict[str, Any]) -> None:
    values: List[Any] = []

    for feature in geojson_data["features"]:
        props = feature["properties"]
        coords = feature["geometry"]["coordinates"]
        lon, lat = float(coords[0]), float(coords[1])
        store_id = props["store_id"]

        r.hset(
            store_meta_key(store_id),
            mapping={
                "store_id": store_id,
                "name": props["name"],
                "store_type": props["store_type"],
                "city": props["city"],
                "address": props["address"],
                "lon": str(lon),
                "lat": str(lat),
            },
        )

        values.extend([lon, lat, store_id])

    if values:
        r.geoadd(geo_stores_key(), values)

    log_event(
        r,
        {
            "event": "seed_stores",
            "stores_loaded": len(geojson_data["features"]),
            "timestamp": int(time.time()),
        },
    )


def seed_products(r: redis.Redis, products: List[Dict[str, Any]]) -> None:
    for product in products:
        sku = product["sku"]
        total_stock = sum(product["store_stock"].values())

        mapping: Dict[str, str] = {
            "sku": sku,
            "category": product["category"],
            "brand": product["brand"],
            "model": product["model"],
            "price_uah": str(product["price_uah"]),
            "body_color": product["body_color"],
            "stock": str(total_stock),
            "available": "1" if total_stock > 0 else "0",
            "views": "0",
            "created_at": str(int(time.time())),
        }

        if product["category"] == "smartphone":
            mapping.update(
                {
                    "screen_size_inches": str(product["screen_size_inches"]),
                    "screen_type": product["screen_type"],
                    "sim_count": str(product["sim_count"]),
                }
            )
        elif product["category"] == "tv":
            mapping.update(
                {
                    "diagonal_inches": str(product["diagonal_inches"]),
                    "panel_type": product["panel_type"],
                    "resolution": product["resolution"],
                }
            )

        r.hset(product_key(sku), mapping=mapping)

        r.sadd(category_index_key(product["category"]), sku)
        r.sadd(brand_index_key(product["category"], product["brand"]), sku)
        r.sadd(color_index_key(product["category"], product["body_color"]), sku)

        if product["category"] == "smartphone":
            r.sadd(smartphone_screen_type_key(product["screen_type"]), sku)
            r.sadd(smartphone_sim_count_key(product["sim_count"]), sku)
            r.zadd(smartphone_price_zset_key(), {sku: float(product["price_uah"])})
            r.zadd(
                smartphone_screen_size_zset_key(),
                {sku: float(product["screen_size_inches"])},
            )
        else:
            r.zadd(tv_price_zset_key(), {sku: float(product["price_uah"])})
            r.zadd(tv_diagonal_zset_key(), {sku: float(product["diagonal_inches"])})

        for store_id, qty in product["store_stock"].items():
            r.hset(store_stock_key(store_id), sku, qty)

    log_event(
        r,
        {
            "event": "seed_products",
            "products_loaded": len(products),
            "timestamp": int(time.time()),
        },
    )


def seed_all(r: redis.Redis) -> None:
    products = load_json("seed_data.json")
    stores_geojson = load_json("seed_stores.geojson")

    r.flushdb()
    set_system_config(r)
    seed_stores_geo(r, stores_geojson)
    seed_products(r, products)


def parse_product(data: Dict[str, str]) -> Dict[str, Any]:
    if not data:
        return {}

    parsed: Dict[str, Any] = dict(data)

    int_fields = {"stock", "views", "sim_count"}
    float_fields = {"price_uah", "screen_size_inches", "diagonal_inches"}

    for field in int_fields:
        if field in parsed:
            parsed[field] = int(parsed[field])

    for field in float_fields:
        if field in parsed:
            parsed[field] = float(parsed[field])

    parsed["available"] = parsed.get("available") == "1"
    return parsed


def get_product(r: redis.Redis, sku: str) -> Dict[str, Any]:
    return parse_product(r.hgetall(product_key(sku)))


def get_products_by_skus(r: redis.Redis, skus: List[str]) -> List[Dict[str, Any]]:
    result = []
    for sku in skus:
        p = get_product(r, sku)
        if p:
            result.append(p)
    return result


def view_product(r: redis.Redis, sku: str, user_id: str) -> Dict[str, Any]:
    p_key = product_key(sku)

    if not r.exists(p_key):
        return {}

    r.hincrby(p_key, "views", 1)
    r.zincrby(popularity_zset_key(), 1, sku)

    today = time.strftime("%Y-%m-%d")
    r.pfadd(user_views_hll_key(today), user_id)

    log_event(
        r,
        {
            "event": "view_product",
            "sku": sku,
            "user_id": user_id,
            "timestamp": int(time.time()),
        },
    )
    return get_product(r, sku)


def get_all_smartphones_of_brand(r: redis.Redis, brand: str) -> List[Dict[str, Any]]:
    skus = sorted(r.smembers(brand_index_key("smartphone", brand)))
    return get_products_by_skus(r, skus)


def get_smartphones_by_price_and_screen(
    r: redis.Redis,
    min_price: float,
    max_price: float,
    max_screen_size: float,
) -> List[Dict[str, Any]]:
    cache_key = cache_filter_key(
        f"smartphones_{int(min_price)}_{int(max_price)}_{str(max_screen_size).replace('.', '_')}"
    )

    cached = r.get(cache_key)
    if cached:
        cached_skus = json.loads(cached)
        return get_products_by_skus(r, cached_skus)

    category_skus = set(r.smembers(category_index_key("smartphone")))
    price_skus = set(r.zrangebyscore(smartphone_price_zset_key(), min_price, max_price))
    screen_skus = set(
        r.zrangebyscore(smartphone_screen_size_zset_key(), "-inf", f"({max_screen_size}")
    )

    result_skus = sorted(category_skus & price_skus & screen_skus)

    r.setex(cache_key, 300, json.dumps(result_skus))
    return get_products_by_skus(r, result_skus)


def create_cart(r: redis.Redis, user_id: str) -> None:
    r.hset(
        cart_meta_key(user_id),
        mapping={
            "user_id": user_id,
            "status": "active",
            "created_at": str(int(time.time())),
            "last_updated": str(int(time.time())),
        },
    )
    r.expire(cart_meta_key(user_id), 60 * 60 * 24 * 7)
    r.expire(cart_items_key(user_id), 60 * 60 * 24 * 7)

    event = {
        "event": "create_cart",
        "user_id": user_id,
        "timestamp": int(time.time()),
    }
    log_event(r, event)
    r.publish(cart_events_channel(), json.dumps(event, ensure_ascii=False))


def add_to_cart(
    r: redis.Redis,
    user_id: str,
    sku: str,
    quantity: int,
    store_id: str,
) -> bool:
    if quantity <= 0:
        raise ValueError("Quantity must be positive.")

    p_key = product_key(sku)
    s_key = store_stock_key(store_id)
    c_key = cart_items_key(user_id)
    c_meta_key = cart_meta_key(user_id)

    while True:
        try:
            with r.pipeline() as pipe:
                pipe.watch(p_key, s_key)

                product_data = pipe.hgetall(p_key)
                if not product_data:
                    pipe.unwatch()
                    raise ValueError(f"Product not found: {sku}")

                global_stock = int(product_data["stock"])
                store_stock_value = pipe.hget(s_key, sku)
                store_stock = int(store_stock_value or 0)

                if global_stock < quantity or store_stock < quantity:
                    pipe.unwatch()
                    return False

                new_global_stock = global_stock - quantity
                new_available = "1" if new_global_stock > 0 else "0"

                pipe.multi()
                pipe.hincrby(c_key, sku, quantity)
                pipe.hset(c_meta_key, "last_updated", str(int(time.time())))
                pipe.hincrby(p_key, "stock", -quantity)
                pipe.hset(p_key, "available", new_available)
                pipe.hincrby(s_key, sku, -quantity)
                pipe.expire(c_key, 60 * 60 * 24 * 7)
                pipe.expire(c_meta_key, 60 * 60 * 24 * 7)
                pipe.execute()

            break
        except redis.WatchError:
            continue

    event = {
        "event": "add_to_cart",
        "user_id": user_id,
        "sku": sku,
        "quantity": quantity,
        "store_id": store_id,
        "timestamp": int(time.time()),
    }
    log_event(r, event)
    r.publish(cart_events_channel(), json.dumps(event, ensure_ascii=False))
    return True


def get_cart(r: redis.Redis, user_id: str) -> Dict[str, int]:
    raw = r.hgetall(cart_items_key(user_id))
    return {sku: int(qty) for sku, qty in raw.items()}


def update_stock(r: redis.Redis, sku: str, new_stock: int) -> None:
    if new_stock < 0:
        raise ValueError("Stock cannot be negative.")

    available = "1" if new_stock > 0 else "0"
    r.hset(
        product_key(sku),
        mapping={
            "stock": str(new_stock),
            "available": available,
        },
    )

    event = {
        "event": "update_stock",
        "sku": sku,
        "new_stock": new_stock,
        "timestamp": int(time.time()),
    }
    log_event(r, event)
    r.publish(stock_updates_channel(), json.dumps(event, ensure_ascii=False))


def get_nearest_stores_with_product(
    r: redis.Redis,
    longitude: float,
    latitude: float,
    sku: str,
    radius_km: float = 15,
) -> List[Dict[str, Any]]:
    raw = r.geosearch(
        geo_stores_key(),
        longitude=longitude,
        latitude=latitude,
        radius=radius_km,
        unit="km",
        sort="ASC",
        withdist=True,
    )

    result = []
    for item in raw:
        store_id = item[0]
        distance = float(item[1])
        qty = int(r.hget(store_stock_key(store_id), sku) or 0)

        if qty > 0:
            meta = r.hgetall(store_meta_key(store_id))
            result.append(
                {
                    "store_id": store_id,
                    "distance_km": round(distance, 3),
                    "name": meta.get("name"),
                    "city": meta.get("city"),
                    "address": meta.get("address"),
                    "stock_for_sku": qty,
                }
            )
    return result


def get_top_products(r: redis.Redis, top_n: int = 5) -> List[Dict[str, Any]]:
    top_skus = r.zrevrange(popularity_zset_key(), 0, top_n - 1)
    return get_products_by_skus(r, list(top_skus))


def get_config_values(r: redis.Redis) -> Dict[str, Optional[str]]:
    keys = ["cfg:currency", "cfg:catalog_status", "cfg:default_city"]
    values = r.mget(keys)
    return dict(zip(keys, values))


def print_section(title: str) -> None:
    print("\n" + "=" * 90)
    print(title)
    print("=" * 90)


def print_json_block(obj: Any) -> None:
    print(json.dumps(obj, ensure_ascii=False, indent=2))


def main() -> None:
    r = connect_redis()
    r.ping()

    seed_all(r)

    print_section("System configuration via MSET / MGET")
    print_json_block(get_config_values(r))
    print("Last seed timestamp via SET / GET:", r.get("app:last_seed_ts"))

    print_section("View products and populate analytics")
    view_product(r, "APPLE-IPHONE13MINI-128", "user_001")
    view_product(r, "APPLE-IPHONE13MINI-128", "user_002")
    view_product(r, "ASUS-ZENFONE10-256", "user_001")
    view_product(r, "SAMSUNG-A55-5G-256", "user_003")

    print_section("All smartphones of one manufacturer: Samsung")
    samsung_smartphones = get_all_smartphones_of_brand(r, "Samsung")
    print_json_block(samsung_smartphones)

    print_section('Smartphones priced 15-25K UAH with screen size < 6"')
    filtered_smartphones = get_smartphones_by_price_and_screen(
        r,
        min_price=15000,
        max_price=25000,
        max_screen_size=6.0,
    )
    print_json_block(filtered_smartphones)

    print_section("Create cart and add item with transaction support")
    user_id = "user_001"
    create_cart(r, user_id)
    added = add_to_cart(
        r,
        user_id=user_id,
        sku="APPLE-IPHONE13MINI-128",
        quantity=1,
        store_id="STORE_KYIV_01",
    )
    print("Added to cart:", added)
    print_json_block(get_cart(r, user_id))

    print_section("Update stock of a specific model")
    update_stock(r, "ASUS-ZENFONE10-256", 10)
    print_json_block(get_product(r, "ASUS-ZENFONE10-256"))

    print_section("Nearest stores with available Apple iPhone 13 mini")
    nearest = get_nearest_stores_with_product(
        r,
        longitude=30.5234,
        latitude=50.4501,
        sku="APPLE-IPHONE13MINI-128",
        radius_km=20,
    )
    print_json_block(nearest)

    print_section("Top products by popularity")
    print_json_block(get_top_products(r, top_n=5))

    print_section("Approximate unique catalog viewers today via HyperLogLog")
    today = time.strftime("%Y-%m-%d")
    print("Unique users today:", r.pfcount(user_views_hll_key(today)))

    print_section("Most recent audit log record")
    latest_log = r.lindex(audit_log_key(), 0)
    print(latest_log)


if __name__ == "__main__":
    main()