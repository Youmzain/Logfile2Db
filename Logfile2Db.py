import oracledb
from pathlib import Path

# Verbindung
conn = oracledb.connect(
    user="harald",
    password="klo+tkx",
    dsn="localhost/FREEPDB1"
)

file_path = Path(r"C:\Tickets\CUST1414766 verlangsamtes System\CUST1412353 Aufruf des DRG WP extrem langsam\DRGWP Aufruf KHVM langsam.log")
customer_ticket_id = "CUST1412353"

sql = """
INSERT INTO perf_log (file_row, row_number, file_path, customer_ticket_id)
VALUES (:file_row, :row_number, :file_path, :customer_ticket_id)
"""

rows = []
row_number = 1
with file_path.open(encoding="utf-8", errors="replace") as f:
    for line in f:
        text = line.rstrip("\n")
        # if not text:
        #    continue   # leere Zeilen ignorieren

        rows.append({
            "file_row": text,
            "row_number": row_number,
            "file_path": str(file_path),
            "customer_ticket_id": customer_ticket_id
        })
        row_number += 1


# Batch-Insert → schnell!
with conn.cursor() as cur:
    cur.executemany(sql, rows)

conn.commit()
conn.close()
