import oracledb
from pathlib import Path

# Verbindung
conn = oracledb.connect(
    user="harald",
    password="klo+tkx",
    dsn="localhost/FREEPDB1"
)

# File

file_path = Path(r"C:\Tickets\CUST1414766 verlangsamtes System\CUST1412353 Aufruf des DRG WP extrem langsam\DRGWP Aufruf KHVM langsam.log")
customer_ticket_id = "CUST1412353"

sql_file = """
INSERT INTO perf_file (
        customer_ticket_id
    ,   file_path
    )
    VALUES (
        :customer_ticket_id
    ,   :file_path
    )
    RETURNING id INTO :new_id
"""

new_id = conn.cursor().var(oracledb.NUMBER)

with conn.cursor() as cur:
    cur.execute(
        sql_file,
        customer_ticket_id = customer_ticket_id,
        file_path = str(file_path),
        new_id = new_id
    )

perf_file_id = int(new_id.getvalue()[0])

# Rows

sql_row = """
INSERT INTO perf_row (
        perf_file_id
    ,   row_number
    ,   file_row
    )
    VALUES (
        :perf_file_id
    ,   :row_number
    ,   :file_row
    )
"""

rows = []
row_number = 1

with file_path.open(encoding="utf-8", errors="replace") as f:
    for line in f:
        file_row = line.rstrip("\n")
        if not file_row:
            file_row = " "
        rows.append({
            "perf_file_id": perf_file_id,
            "row_number": row_number,
            "file_row": file_row
        })
        row_number += 1


# Batch-Insert → schnell!
with conn.cursor() as cur:
    cur.executemany(sql_row, rows)


# Commit

conn.commit()
conn.close()
