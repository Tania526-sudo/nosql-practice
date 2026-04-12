import json
import time
from pathlib import Path
from typing import Any, Dict, List

import redis


def normalize(value: str) -> str:
    return value.strip().lower().replace(" ", "_").replace("/", "_")


def connect_redis() -> redis.Redis:
    return redis.Redis(
        host="localhost",
        port=6379,
        db=0,
        decode_responses=True,
    )


def load_seed_data() -> List[Dict[str, Any]]:
    data_path = Path(__file__).parent / "seed_data.json"
    with open(data_path, "r", encoding="utf-8") as f:
        return json.load(f)


def product_key(sku: str) -> str:
    return f"product:{sku}"


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


def cart_items_key(user_id: str) -> str:
    return f"cart:{user_id}:items"


def audit_log_key() -> str:
    return "log:audit"


def seed_catalog(r: redis.Redis, products: List[Dict[str, Any]]) -> None:
    r.flushdb()

    for product in products:
        sku = product["sku"]
        p_key = product_key(sku)

        flat_mapping = {
            "sku": sku,
            "category": product["category"],
            "brand": product["brand"],
            "model": product["model"],
            "price_uah": str(product["price_uah"]),
            "body_color": product["body_color"],
            "stock": str(product["stock"]),
            "available": "1" if product["stock"] > 0 else "0",
            "created_at": str(int(time.time())),
        }

        if product["category"] == "smartphone":
            flat_mapping.update(
                {
                    "screen_size_inches": str(product["screen_size_inches"]),
                    "screen_type": product["screen_type"],
                    "sim_count": str(product["sim_count"]),
                }
            )
        elif product["category"] == "tv":
            flat_mapping.update(
                {
                    "diagonal_inches": str(product["diagonal_inches"]),
                    "panel_type": product["panel_type"],
                    "resolution": product["resolution"],
                }
            )

        r.hset(p_key, mapping=flat_mapping)

        r.sadd(category_index_key(product["category"]), sku)
        r.sadd(brand_index_key(product["category"], product["brand"]), sku)
        r.sadd(color_index_key(product["category"], product["body_color"]), sku)

        if product["category"] == "smartphone":
            r.sadd(
                smartphone_screen_type_key(product["screen_type"]),
                sku,
            )
            r.sadd(
                smartphone_sim_count_key(product["sim_count"]),
                sku,
            )
            r.zadd(
                smartphone_price_zset_key(),
                {sku: float(product["price_uah"])},
            )
            r.zadd(
                smartphone_screen_size_zset_key(),
                {sku: float(product["screen_size_inches"])},
            )

        elif product["category"] == "tv":
            r.zadd(
                tv_price_zset_key(),
                {sku: float(product["price_uah"])},
            )
            r.zadd(
                tv_diagonal_zset_key(),
                {sku: float(product["diagonal_inches"])},
            )

    r.lpush(
        audit_log_key(),
        json.dumps(
            {
                "event": "seed_catalog",
                "products_loaded": len(products),
                "timestamp": int(time.time()),
            },
            ensure_ascii=False,
        ),
    )


def get_product(r: redis.Redis, sku: str) -> Dict[str, Any]:
    data = r.hgetall(product_key(sku))
    if not data:
        return {}

    parsed = dict(data)

    for field in ("price_uah", "stock", "screen_size_inches", "sim_count", "diagonal_inches"):
        if field in parsed:
            try:
                if "." in parsed[field]:
                    parsed[field] = float(parsed[field])
                else:
                    parsed[field] = int(parsed[field])
            except ValueError:
                pass

    parsed["available"] = parsed.get("available") == "1"
    return parsed


def get_products_by_skus(r: redis.Redis, skus: List[str]) -> List[Dict[str, Any]]:
    return [get_product(r, sku) for sku in skus if get_product(r, sku)]


def get_all_smartphones_of_brand(r: redis.Redis, brand: str) -> List[Dict[str, Any]]:
    skus = sorted(r.smembers(brand_index_key("smartphone", brand)))
    return get_products_by_skus(r, skus)


def get_smartphones_by_price_and_screen(
    r: redis.Redis,
    min_price: float,
    max_price: float,
    max_screen_size: float,
) -> List[Dict[str, Any]]:
    price_matches = set(
        r.zrangebyscore(smartphone_price_zset_key(), min_price, max_price)
    )
    screen_matches = set(
        r.zrangebyscore(smartphone_screen_size_zset_key(), "-inf", max_screen_size)
    )
    result_skus = sorted(price_matches.intersection(screen_matches))
    return get_products_by_skus(r, result_skus)


def create_cart(r: redis.Redis, user_id: str) -> None:
    meta_key = f"cart:{user_id}:meta"
    r.hset(
        meta_key,
        mapping={
            "user_id": user_id,
            "created_at": str(int(time.time())),
            "status": "active",
        },
    )
    r.expire(meta_key, 60 * 60 * 24 * 7)


def add_to_cart(r: redis.Redis, user_id: str, sku: str, quantity: int) -> bool:
    if quantity <= 0:
        raise ValueError("Quantity must be positive.")

    p_key = product_key(sku)
    c_key = cart_items_key(user_id)

    with r.pipeline() as pipe:
        while True:
            try:
                pipe.watch(p_key)

                product_data = pipe.hgetall(p_key)
                if not product_data:
                    pipe.unwatch()
                    raise ValueError(f"Product {sku} not found.")

                current_stock = int(product_data["stock"])
                if current_stock < quantity:
                    pipe.unwatch()
                    return False

                new_stock = current_stock - quantity
                new_available = "1" if new_stock > 0 else "0"

                pipe.multi()
                pipe.hincrby(p_key, "stock", -quantity)
                pipe.hset(p_key, "available", new_available)
                pipe.hincrby(c_key, sku, quantity)
                pipe.expire(c_key, 60 * 60 * 24 * 7)
                pipe.lpush(
                    audit_log_key(),
                    json.dumps(
                        {
                            "event": "add_to_cart",
                            "user_id": user_id,
                            "sku": sku,
                            "quantity": quantity,
                            "timestamp": int(time.time()),
                        },
                        ensure_ascii=False,
                    ),
                )
                pipe.execute()
                return True

            except redis.WatchError:
                continue


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
    r.lpush(
        audit_log_key(),
        json.dumps(
            {
                "event": "update_stock",
                "sku": sku,
                "new_stock": new_stock,
                "timestamp": int(time.time()),
            },
            ensure_ascii=False,
        ),
    )


def print_products(title: str, products: List[Dict[str, Any]]) -> None:
    print("\n" + "=" * 80)
    print(title)
    print("=" * 80)
    if not products:
        print("No matching products found.")
        return

    for p in products:
        print(json.dumps(p, ensure_ascii=False, indent=2))


def main() -> None:
    r = connect_redis()
    r.ping()

    products = load_seed_data()
    seed_catalog(r, products)

    samsung_smartphones = get_all_smartphones_of_brand(r, "Samsung")
    print_products(
        "All smartphones of one manufacturer: Samsung",
        samsung_smartphones,
    )

    filtered_smartphones = get_smartphones_by_price_and_screen(
        r,
        min_price=15000,
        max_price=25000,
        max_screen_size=6.0,
    )
    print_products(
        'Smartphones priced 15-25K UAH with screen size < 6"',
        filtered_smartphones,
    )

    user_id = "user_001"
    create_cart(r, user_id)
    added = add_to_cart(r, user_id, "APPLE-IPHONE13MINI-128", 1)
    print("\nCart created and item added:", added)
    print("Current cart:", get_cart(r, user_id))

    update_stock(r, "ASUS-ZENFONE10-256", 10)
    updated_product = get_product(r, "ASUS-ZENFONE10-256")
    print_products("Updated stock for ASUS-ZENFONE10-256", [updated_product])

    print("\nRecent audit log entry:")
    print(r.lindex(audit_log_key(), 0))


if __name__ == "__main__":
    main()