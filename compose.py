import psycopg2
import pandas as pd
import re

# -----------------------------
# PostgreSQL connection details
# -----------------------------
DB_NAME = my_db_name
DB_USER = my_db_user
DB_PASSWORD = my_fb_password
DB_HOST = my_db_host
DB_PORT = my_db_port

# -----------------------------
# Read CSV file
# -----------------------------
df = pd.read_csv("my_relative_pathname.csv", parse_dates=True)

# -----------------------------
# Clean column names
# -----------------------------
def clean_column_name(col):
    """Replace everything except letters/numbers with underscores."""
    return re.sub(r'[^A-Za-z0-9]+', '_', col).strip('_')

# Rename columns
df.rename(columns={col: clean_column_name(col) for col in df.columns}, inplace=True)

# -----------------------------
# Map pandas dtypes to PostgreSQL types
# -----------------------------
def map_dtype(column, dtype):
    if pd.api.types.is_integer_dtype(dtype):
        return "INTEGER"
    elif pd.api.types.is_float_dtype(dtype):
        return "DOUBLE PRECISION"   # Only float rule
    elif pd.api.types.is_datetime64_any_dtype(dtype):
        return "TIMESTAMP"
    elif df[column].astype(str).str.match(r'^\d{4}-\d{2}-\d{2}$').all():
        return "DATE"
    elif df[column].astype(str).str.match(r'^\d{2}:\d{2}(:\d{2})?$').all():
        return "TIME"
    else:
        return "TEXT"

# -----------------------------
# Connect to PostgreSQL
# -----------------------------
conn = None

try:
    conn = psycopg2.connect(
        dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD,
        host=DB_HOST, port=DB_PORT
    )
    cursor = conn.cursor()
    print("Connected to the database successfully")

    # -----------------------------
    # Drop old table (if exists)
    # -----------------------------
    cursor.execute("DROP TABLE IF EXISTS trials_datasets;")
    conn.commit()

    # -----------------------------
    # Create table dynamically
    # -----------------------------
    column_definitions = ", ".join([
        f"{col} {map_dtype(col, df[col].dtype)}"
        for col in df.columns
    ])
    create_table_query = f"""
    CREATE TABLE trials_datasets (
        {column_definitions}
    );
    """
    cursor.execute(create_table_query)
    conn.commit()
    print("Table created successfully")

    # -----------------------------
    # Insert data
    # -----------------------------
    columns = ', '.join(df.columns)
    placeholders = ', '.join(['%s'] * len(df.columns))
    insert_query = f"INSERT INTO trials_datasets ({columns}) VALUES ({placeholders})"

    for _, row in df.iterrows():
        values = [row[col] if pd.notna(row[col]) else None for col in df.columns]
        cursor.execute(insert_query, values)

    conn.commit()
    print("Data inserted successfully")

except Exception as e:
    print("Error:", e)

finally:
    if conn:
        cursor.close()
        conn.close()
        print("Database connection closed")
