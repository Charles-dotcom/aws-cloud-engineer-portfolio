"""Small HTTP API used by the ECS service and the local Compose stack.

Liveness does not touch the database. Readiness does. Database errors are
logged as a class name and returned as a generic status so a client never
sees a connection string.
"""

from __future__ import annotations

import logging
import os
import socket
from datetime import datetime, timezone

from flask import Flask, jsonify
import psycopg2

app = Flask(__name__)
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("portfolio-api")

REQUIRED_DB_ENV = ("DB_HOST", "DB_NAME", "DB_USERNAME", "DB_PASSWORD")


def database_configured() -> bool:
    if os.getenv("DATABASE_URL"):
        return True
    return all(os.getenv(name) for name in REQUIRED_DB_ENV)


def connect():
    url = os.getenv("DATABASE_URL")
    if url:
        return psycopg2.connect(url)

    missing = [name for name in REQUIRED_DB_ENV if not os.getenv(name)]
    if missing:
        raise RuntimeError("database configuration is incomplete")

    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=int(os.environ.get("DB_PORT", "5432")),
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USERNAME"],
        password=os.environ["DB_PASSWORD"],
        sslmode=os.environ.get("DB_SSLMODE", "require"),
    )


@app.get("/")
def index():
    return jsonify(
        service="portfolio-api",
        author="Charles Mphahlele",
        environment=os.getenv("ENVIRONMENT", "local"),
        version=os.getenv("APP_VERSION", "1.0.0"),
        hostname=socket.gethostname(),
        time=datetime.now(timezone.utc).isoformat(),
    )


@app.get("/health")
def health():
    return jsonify(status="healthy")


@app.get("/ready")
def ready():
    if not database_configured():
        return jsonify(status="not_ready"), 503
    try:
        connection = connect()
        connection.close()
    except Exception as exc:
        log.error("database readiness check failed: %s", type(exc).__name__)
        return jsonify(status="not_ready"), 503
    return jsonify(status="ready")


@app.get("/users")
def users():
    if not database_configured():
        return jsonify(status="not_ready"), 503
    try:
        connection = connect()
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT id, name, email FROM users ORDER BY id")
                rows = [
                    {"id": row[0], "name": row[1], "email": row[2]}
                    for row in cursor.fetchall()
                ]
        finally:
            connection.close()
    except Exception as exc:
        log.error("user query failed: %s", type(exc).__name__)
        return jsonify(status="not_ready"), 503
    return jsonify(rows)
