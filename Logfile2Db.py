# Autor: Harald Schmitz-Becker
# Liest eine Datei ein und erzeugt eine Zeile im Table per_file für die Datei und eine Zeile in perf_row für jede Zeile in der Datei.
# Aufruf:
# python Logffile2Db.py -f "<Pfad>" -t CUST1412353
# Beispiel: python Logfile2Db.py -f "C:\Tickets\CUST1414766 verlangsamtes System\CUST1412353 Aufruf des DRG WP extrem langsam\DRGWP Aufruf KHVM langsam.log" -t CUST1412353
# Wenn venv nicht aktiviert werden kann:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

import argparse
import oracledb
import re
from pathlib import Path


# Parameter

parser = argparse.ArgumentParser(
    description="Importiert eine Logdatei zeilenweise in die Oracle-DB"
)

parser.add_argument(
    "-t",
    "--ticket",
    dest="customer_ticket_id",
    required=True,
    help="Customer Ticket ID (z.B. CUST1412353)",
)

parser.add_argument(
    "-f", "--file", dest="file_path", required=True, help="Pfad zur Logdatei"
)

args = parser.parse_args()


# Verbindung
conn = oracledb.connect(user="harald", password="klo+tkx", dsn="localhost/FREEPDB1")

# File

# file_path = Path(r"C:\Tickets\CUST1414766 verlangsamtes System\CUST1412353 Aufruf des DRG WP extrem langsam\DRGWP Aufruf KHVM langsam.log")
# customer_ticket_id = "CUST1412353"

file_path = Path(args.file_path)
customer_ticket_id = args.customer_ticket_id

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
        customer_ticket_id=customer_ticket_id,
        file_path=str(file_path),
        new_id=new_id,
    )

perf_file_id = int(new_id.getvalue()[0])

# Rows

fetch_time_re = re.compile(r'fetched in (\d+) ms')

def extract_fetch_time_ms(line: str) -> int | None:
    match = fetch_time_re.search(line)
    if match: 
        return int(match.group(1))
    return None
   

sql_row = """
INSERT INTO perf_row (
        perf_file_id
    ,   row_number
    ,   row_type
    ,   lower_row
    ,   fetched_in_ms
    )
    VALUES (
        :perf_file_id
    ,   :row_number
    ,   :row_type
    ,   :lower_row
    ,   :fetched_in_ms
    )
"""

rows = []
row_number = 1

with file_path.open(encoding="utf-8", errors="replace") as f:
    for line in f:

        lower_row = line.rstrip("\r\n")
        if not lower_row:
            lower_row = " "
        lower_row = lower_row.lower()

        row_type = lower_row[0] if len(lower_row) > 1 and lower_row[1] == ":" else " "
        fetched_in_ms = extract_fetch_time_ms(line)
        rows.append(
            {
                "perf_file_id": perf_file_id,
                "row_number": row_number,
                "row_type": row_type,
                "lower_row": lower_row,
                "fetched_in_ms": fetched_in_ms,
            }
        )
        row_number += 1


# Batch-Insert
with conn.cursor() as cur:

    cur.setinputsizes(
        perf_file_id=oracledb.NUMBER,
        row_number=oracledb.NUMBER,
        row_type=oracledb.STRING,
        lower_row=oracledb.CLOB,
        fetched_in_ms=oracledb.NUMBER,
    )

    cur.executemany(sql_row, rows)


# Commit

conn.commit()
conn.close()

print(f"Created Id: {perf_file_id}")
