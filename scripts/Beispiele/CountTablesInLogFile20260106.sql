-- :perf_file_id z.B. 21
WITH candidates AS (
    SELECT pr.id, pr.file_row
    FROM perf_row pr
    WHERE pr.perf_file_id = 82
      AND dbms_lob.instr(pr.file_row, ' from ', 1, 1) > 0
),

pos AS (
    SELECT
        id,
        file_row,
        dbms_lob.instr(file_row, ' from ', 1, 1) AS p_from,
        dbms_lob.getlength(file_row)             AS len,
        LEAST(
            NVL(NULLIF(dbms_lob.instr(file_row, ' where ',  1, 1), 0), dbms_lob.getlength(file_row) + 1),
            NVL(NULLIF(dbms_lob.instr(file_row, ' group ',  1, 1), 0), dbms_lob.getlength(file_row) + 1),
            NVL(NULLIF(dbms_lob.instr(file_row, ' order ',  1, 1), 0), dbms_lob.getlength(file_row) + 1),
            NVL(NULLIF(dbms_lob.instr(file_row, ' having ', 1, 1), 0), dbms_lob.getlength(file_row) + 1),
            dbms_lob.getlength(file_row) + 1
        ) AS p_end
    FROM candidates
),

from_clause AS (
    SELECT
        id,
        CAST(
            dbms_lob.substr(
                file_row,
                LEAST(4000, p_end - (p_from + 6)),
                p_from + 6
            ) AS VARCHAR2(4000)
        ) AS fc
    FROM pos
    WHERE p_from > 0
      AND p_end  > p_from + 6
),

normalized AS (
    SELECT
        id,
        TRIM(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(fc, ' left join ', ','),
                  ' right join ', ','),
                ' full join ', ','),
              ' inner join ', ','),
            ' join ', ',')
        ) AS list0
    FROM from_clause
),

split_pos AS (
    SELECT
        id,
        list0,
        level AS lvl,
        CASE
            WHEN level = 1 THEN 1
            ELSE INSTR(list0, ',', 1, level - 1) + 1
        END AS start_pos,
        CASE
            WHEN INSTR(list0, ',', 1, level) = 0 THEN LENGTH(list0) + 1
            ELSE INSTR(list0, ',', 1, level)
        END AS end_pos
    FROM normalized
    CONNECT BY level <= (LENGTH(list0) - LENGTH(REPLACE(list0, ',', '')) + 1)
       AND PRIOR id = id
       AND PRIOR SYS_GUID() IS NOT NULL
),

split AS (
    SELECT
        id,
        TRIM(SUBSTR(list0, start_pos, end_pos - start_pos)) AS part
    FROM split_pos
),

no_on AS (
    SELECT
        id,
        TRIM(
            CASE
                WHEN INSTR(part, ' on ') > 0 THEN SUBSTR(part, 1, INSTR(part, ' on ') - 1)
                ELSE part
            END
        ) AS part2
    FROM split
),

table_token AS (
    SELECT
        id,
        RTRIM(
            SUBSTR(
                part2,
                1,
                CASE
                    WHEN INSTR(part2, ' ') = 0 THEN LENGTH(part2)
                    ELSE INSTR(part2, ' ') - 1
                END
            ),
            ','
        ) AS table_name
    FROM no_on
)

SELECT
    table_name,
    COUNT(*) AS occurrences
FROM table_token
WHERE TRIM(table_name) IS NOT NULL
GROUP BY table_name
ORDER BY occurrences DESC;
