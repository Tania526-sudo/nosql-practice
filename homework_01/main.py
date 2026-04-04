import time
import redis


def main():
    try:
        r = redis.Redis(
            host="localhost",
            port=6379,
            db=0,
            decode_responses=True
        )

        r.ping()

        dt = int(time.time())
        r.set("dt", dt)
        saved_dt = r.get("dt")

        print(f"Current Unix timestamp dt: {dt}")
        print(f"Value read from Redis: {saved_dt}")

    except redis.ConnectionError:
        print("Connection error: Redis is not running on localhost:6379")
    except Exception as e:
        print(f"Unexpected error: {e}")


if __name__ == "__main__":
    main()