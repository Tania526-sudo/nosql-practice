# Redis Timestamp Project / Redis Timestamp

![Python](https://img.shields.io/badge/Python-3.10%2B-blue)
![Redis](https://img.shields.io/badge/Redis-local-red)
![Docker](https://img.shields.io/badge/Docker-supported-2496ED)
![Status](https://img.shields.io/badge/status-ready-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)

A simple Python project that connects to a local Redis instance, stores the current Unix timestamp in the `dt` key, and reads it back for verification.  

---

## Project Overview

This project demonstrates a basic integration between Python and Redis.  
The application:

- connects to Redis running locally on `localhost:6379`
- checks the connection using `PING`
- generates the current Unix timestamp
- saves it into Redis under the key `dt`
- reads the value back and prints it to the console

---
