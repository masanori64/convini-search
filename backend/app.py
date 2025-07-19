"""
Minimal Flask API for convini-search backend.

Assumptions
-----------
* DB connection params are provided via environment variables:
    - DB_HOST, DB_PORT (optional, default 5432)
    - DB_NAME
    - DB_USER
    - DB_PASSWORD
* `stores` テーブルに PGroonga インデックスが作成済み。
* Query parameters are optional and combined with AND.

Run with::

    (.venv) $ flask --app app run --reload
"""
from __future__ import annotations

import os
from contextlib import contextmanager
from typing import Any, Dict, Generator

import psycopg2
import psycopg2.extras
from dotenv import load_dotenv
from flask import Flask, jsonify, request

# --------------------------------------------------
# Environment
# --------------------------------------------------
load_dotenv()  # .env を読む

DB_SETTINGS = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "dbname": os.getenv("DB_NAME", "convini"),
    "user": os.getenv("DB_USER", "maasa"),
    "password": os.getenv("DB_PASSWORD", ""),
}

# --------------------------------------------------
# Connection helper
# --------------------------------------------------


@contextmanager
def get_conn() -> Generator[psycopg2.extensions.connection, None, None]:
    conn = psycopg2.connect(
        **DB_SETTINGS, cursor_factory=psycopg2.extras.RealDictCursor
    )
    try:
        yield conn
    finally:
        conn.close()


# --------------------------------------------------
# Flask app
# --------------------------------------------------
app = Flask(__name__)


@app.route("/health")
def health() -> Dict[str, str]:
    """Simple health-check."""
    return {"status": "ok"}


@app.route("/search")
def search():  # type: ignore[return-value]
    """
    /search?q=セブン&pref=東京都&city=渋谷区&brand=7-Eleven

    Returns up to 100 stores matching all provided filters.
    """
    q = request.args.get("q",     "").strip()
    brand = request.args.get("brand", "").strip()
    pref = request.args.get("pref",  "").strip()
    city = request.args.get("city",  "").strip()

    sql = """
        SELECT id,
               name,
               operator AS brand,
               pref,
               city,
               lat,
               lon
          FROM stores
         WHERE TRUE
    """
    params: list[Any] = []

    # Full-text search (PGroonga)
    if q:
        sql += " AND searchtext &@~ %s"
        params.append(q)
    if brand:
        sql += " AND operator &@~ %s"
        params.append(brand)
    if pref:
        sql += " AND pref = %s"
        params.append(pref)
    if city:
        sql += " AND city = %s"
        params.append(city)

    sql += " LIMIT 100"  # safety cap

    with get_conn() as conn:
        cur = conn.cursor()
        cur.execute(sql, params)
        rows = cur.fetchall()

    return jsonify(rows)


# --------------------------------------------------
# Local CLI run
# --------------------------------------------------
if __name__ == "__main__":
    # `python app.py` でも起動できるようにしておく
    app.run(debug=True, host="0.0.0.0", port=5000)
