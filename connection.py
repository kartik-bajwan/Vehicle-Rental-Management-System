import os
import sys
from pathlib import Path
from contextlib import contextmanager
import pymysql
import pymysql.cursors
from pymysql.constants import CLIENT

# Ensure backend config can be imported
sys.path.append(str(Path(__file__).resolve().parent.parent))
from backend.config import DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD

def get_raw_connection(include_db: bool = True):
    """
    Creates a new PyMySQL connection.
    """
    kwargs = {
        "host": DB_HOST,
        "port": DB_PORT,
        "user": DB_USER,
        "password": DB_PASSWORD,
        "charset": "utf8mb4",
        "cursorclass": pymysql.cursors.DictCursor,
        "autocommit": False,
        "client_flag": CLIENT.MULTI_STATEMENTS
    }
    if include_db:
        kwargs["database"] = DB_NAME
    return pymysql.connect(**kwargs)

@contextmanager
def get_db_connection():
    """
    Context manager to safely yield a connection and ensure it closes or rollbacks on error.
    """
    conn = get_raw_connection(include_db=True)
    try:
        yield conn
    finally:
        conn.close()

def execute_query(query: str, params: tuple = None, fetch_one: bool = False, commit: bool = False):
    """
    Executes a SQL query and returns dictionary results.
    """
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, params or ())
            if commit:
                conn.commit()
            if cur.description is not None:
                if fetch_one:
                    return cur.fetchone()
                return cur.fetchall()
            return None

def parse_sql_script(content: str):
    """
    Parses a SQL script into individual executable statements, properly
    handling MySQL DELIMITER changes for triggers and stored procedures.
    """
    statements = []
    current_stmt = []
    delimiter = ";"

    for line in content.splitlines():
        trimmed = line.strip()
        if not trimmed or trimmed.startswith("--"):
            continue

        if trimmed.upper().startswith("DELIMITER "):
            delimiter = trimmed.split()[1]
            continue

        if trimmed.endswith(delimiter):
            stmt_part = line[:line.rfind(delimiter)]
            current_stmt.append(stmt_part)
            full_stmt = "\n".join(current_stmt).strip()
            if full_stmt:
                statements.append(full_stmt)
            current_stmt = []
        else:
            current_stmt.append(line)

    if current_stmt:
        remaining = "\n".join(current_stmt).strip()
        if remaining:
            statements.append(remaining)

    return statements

def init_database():
    """
    Initializes MySQL database, schema, views, triggers, and seed data.
    """
    base_dir = Path(__file__).resolve().parent
    schema_file = base_dir / "rental_schema.sql"
    procedures_file = base_dir / "rental_procedures.sql"
    seed_file = base_dir / "rental_seed.sql"

    # Clean up legacy airline files if present
    legacy_files = [
        base_dir / "mysql_schema.sql",
        base_dir / "mysql_procedures.sql",
        base_dir / "mysql_seed.sql",
        base_dir / "schema.sql",
        base_dir / "procedures.sql",
        base_dir / "seed.sql",
        base_dir.parent / "backend" / "routers" / "flights.py",
        base_dir.parent / "backend" / "routers" / "bookings.py",
        base_dir.parent / "backend" / "routers" / "admin.py",
    ]
    for p in legacy_files:
        if p.exists():
            try:
                p.unlink()
                print(f"-> Removed legacy airline file: {p.name}")
            except Exception:
                pass

    print(f"Connecting to MySQL at {DB_HOST}:{DB_PORT} as '{DB_USER}'...")

    # Step 1: Connect without database to create database if not exists
    conn_no_db = get_raw_connection(include_db=False)
    try:
        with conn_no_db.cursor() as cur:
            cur.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME};")
        conn_no_db.commit()
    finally:
        conn_no_db.close()

    # Step 2: Connect to database and execute scripts
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # 1. Execute Schema
            print(f"-> Executing {schema_file.name}...")
            with open(schema_file, "r", encoding="utf-8") as f:
                for stmt in parse_sql_script(f.read()):
                    cur.execute(stmt)
            conn.commit()

            # 2. Execute Procedures & Triggers
            print(f"-> Executing {procedures_file.name}...")
            with open(procedures_file, "r", encoding="utf-8") as f:
                for stmt in parse_sql_script(f.read()):
                    cur.execute(stmt)
            conn.commit()

            # 3. Execute Seed Data
            print(f"-> Executing {seed_file.name}...")
            with open(seed_file, "r", encoding="utf-8") as f:
                for stmt in parse_sql_script(f.read()):
                    cur.execute(stmt)
            conn.commit()

    print("MySQL database initialization completed successfully!")

if __name__ == "__main__":
    try:
        init_database()
    except Exception as err:
        print(f"\nFailed to initialize MySQL database: {err}")
        print("\nTroubleshooting Tips:")
        print("1. Ensure MySQL Server is running (e.g. XAMPP, MySQL Workbench, or Windows Service).")
        print("2. Check credentials in backend/config.py or .env (DB_USER, DB_PASSWORD, DB_PORT).")
        sys.exit(1)
