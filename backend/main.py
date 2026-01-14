import os
from fastapi import FastAPI
import psycopg2
from contextlib import asynccontextmanager

# Global variable for connection
conn = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global conn
    try:
        conn = psycopg2.connect(
            dbname=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            host=os.getenv("DB_HOST"),
            port=os.getenv("DB_PORT"),
        )
    except Exception as e:
        print(f"Database connection failed: {e}")
    yield
    if conn:
        conn.close()

app = FastAPI(lifespan=lifespan)

@app.get("/")
def root():
    if not conn:
        return {"error": "Database not connected"}, 500
    cur = conn.cursor()
    cur.execute("SELECT NOW();")
    result = cur.fetchone()
    cur.close()
    return {"db_time": str(result[0])}

@app.get("/ready")
def ready():
    try:
        if conn is None:
            raise Exception("No connection")
        cur = conn.cursor()
        cur.execute("SELECT 1;")
        cur.close()
        return {"status": "ready"}
    except Exception:
        # Return a non-200 status code so K8s knows it's NOT ready
        from fastapi import Response
        return Response(status_code=503, content='{"status": "not ready"}')

@app.get("/health")
def health():
    # Liveness check should be simple - just "is the process alive?"
    return {"status": "ok"}