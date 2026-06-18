# Autor: Harald Schmitz-Becker
# Liest eine Datei ein und erzeugt eine Zeile im Table perf_file
# und eine Zeile in perf_row für jede Zeile in der Datei.
#
# Aufruf:
# python Logfile2Db.py -f "<Pfad>" -t CUST1412353
#
# Beispiel:
# python Logfile2Db.py -f "C:\Tickets\CUST1414766 verlangsamtes System\CUST1412353 Aufruf des DRG WP extrem langsam\DRGWP Aufruf KHVM langsam.log" -t CUST1412353
#
# Wenn venv nicht aktiviert werden kann:
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

import argparse
import re
import os
from pathlib import Path

import oracledb


# Regex-Konstanten

ROWS_FETCHED_RE = re.compile(r" (\d+) rows fetched")
FETCHED_IN_MS_RE = re.compile(r"fetched in (\d+) ms")
FETCHED_IN_PARTS_RE = re.compile(r"fetched in (\d+) parts")


# DB-Konstanten

# setx LOGDB_USER "harald"
# setx LOGDB_PASSWORD "..."
# setx LOGDB_DSN "localhost/FREEPDB1"

DB_USER = os.environ["LOGDB_USER"]
DB_PASSWORD = os.environ["LOGDB_PASSWORD"]
DB_DSN = os.environ["LOGDB_DSN"]

# SQL-Konstanten

SQL_FILE = """
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

SQL_ROW = """
INSERT INTO perf_row (
        perf_file_id
    ,   row_number
    ,   row_type
    ,   lower_row
    ,   rows_fetched
    ,   fetched_in_ms
    ,   fetched_in_parts
    )
    VALUES (
        :perf_file_id
    ,   :row_number
    ,   :row_type
    ,   :lower_row
    ,   :rows_fetched
    ,   :fetched_in_ms
    ,   :fetched_in_parts
    )
"""


def parse_args() -> argparse.Namespace:
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
        "-f",
        "--file",
        dest="file_path",
        required=True,
        help="Pfad zur Logdatei",
    )

    return parser.parse_args()


def extract_int(line: str, pattern: re.Pattern[str]) -> int | None:
    match = pattern.search(line)
    return int(match.group(1)) if match else None


def get_row_type(lower_row: str) -> str:
    if len(lower_row) > 1 and lower_row[1] == ":":
        return lower_row[0]

    return " "


def insert_perf_file(
    conn: oracledb.Connection,
    customer_ticket_id: str,
    file_path: Path,
) -> int:
    new_id = conn.cursor().var(oracledb.NUMBER)

    with conn.cursor() as cur:
        cur.execute(
            SQL_FILE,
            customer_ticket_id=customer_ticket_id,
            file_path=str(file_path),
            new_id=new_id,
        )

    return int(new_id.getvalue()[0])


def build_rows(file_path: Path, perf_file_id: int) -> list[dict]:
    rows = []

    with file_path.open(encoding="utf-8", errors="replace") as f:
        for row_number, line in enumerate(f, start=1):
            lower_row = line.rstrip("\r\n")

            if not lower_row:
                lower_row = " "

            lower_row = lower_row.lower()

            rows.append(
                {
                    "perf_file_id": perf_file_id,
                    "row_number": row_number,
                    "row_type": get_row_type(lower_row),
                    "lower_row": lower_row,
                    "rows_fetched": extract_int(lower_row, ROWS_FETCHED_RE),
                    "fetched_in_ms": extract_int(lower_row, FETCHED_IN_MS_RE),
                    "fetched_in_parts": extract_int(lower_row, FETCHED_IN_PARTS_RE),
                }
            )

    return rows


def insert_perf_rows(conn: oracledb.Connection, rows: list[dict]) -> None:
    with conn.cursor() as cur:
        cur.setinputsizes(
            perf_file_id=oracledb.NUMBER,
            row_number=oracledb.NUMBER,
            row_type=oracledb.STRING,
            lower_row=oracledb.CLOB,
            rows_fetched=oracledb.NUMBER,
            fetched_in_ms=oracledb.NUMBER,
            fetched_in_parts=oracledb.NUMBER,
        )

        cur.executemany(SQL_ROW, rows)


def main() -> None:
    args = parse_args()

    file_path = Path(args.file_path)
    customer_ticket_id = args.customer_ticket_id

    with oracledb.connect(
        user=DB_USER,
        password=DB_PASSWORD,
        dsn=DB_DSN,
    ) as conn:
        perf_file_id = insert_perf_file(
            conn=conn,
            customer_ticket_id=customer_ticket_id,
            file_path=file_path,
        )

        rows = build_rows(
            file_path=file_path,
            perf_file_id=perf_file_id,
        )

        insert_perf_rows(conn, rows)

        conn.commit()

    print(f"Created Id: {perf_file_id}")


if __name__ == "__main__":
    main()