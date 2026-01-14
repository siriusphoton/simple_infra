import os
from fastapi import FastAPI
import psycopg2
import time

# Global variable for connection
conn = None

def get_db_connection(retries=5, delay=2):
    for attempt in range(retries):
        try:
            return psycopg2.connect(
                dbname=os.getenv("DB_NAME"),
                user=os.getenv("DB_USER"),
                password=os.getenv("DB_PASSWORD"),
                host=os.getenv("DB_HOST"),
                port=os.getenv("DB_PORT"),
            )
        except Exception as e:
            print(f"DB connection attempt {attempt+1} failed: {e}")
            time.sleep(delay)
    return None

app = FastAPI()

@app.get("/")
def root():
    conn = get_db_connection()
    if not conn:
        return {"error": "Database unavailable"}, 503
    cur = conn.cursor()
    cur.execute("SELECT NOW();")
    result = cur.fetchone()
    cur.close()
    conn.close()
    return {"db_time": str(result[0])}


@app.get("/ready")
def ready():
    conn = get_db_connection()
    if not conn:
        from fastapi import Response
        return Response(status_code=503, content='{"status": "not ready"}')
    conn.close()
    return {"status": "ready"}


@app.get("/health")
def health():
    # Liveness check should be simple - just "is the process alive?"
    return {"status": "ok"}