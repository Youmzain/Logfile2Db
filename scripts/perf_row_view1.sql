
-- Gruppiert nach Statement:
WITH x1 AS (
    SELECT      
            pr.perf_file_id                                                                                 perf_file_id
        ,   pr.row_number                                                                                   row_number
        ,   pr.log_timestamp                                                                                log_timestamp
        ,   LEAD(pr.log_timestamp, 1, null) OVER(PARTITION BY pr.perf_file_id ORDER BY pr.row_number)
                - pr.log_timestamp                                                                          diff_lead_timestamp
        ,   pr.rows_fetched                                                                                 rows_fetched
        ,   pr.fetched_in_ms                                                                                fetched_in_ms
        ,   pr.fetched_in_parts                                                                             fetched_in_parts
        ,   pr.lower_row                                                                                    lower_row
        ,   dbms_lob.instr(pr.lower_row, 'select ', 1, 1)                                                   pos_select
        ,   dbms_lob.instr(pr.lower_row, 'delete ', 1, 1)                                                   pos_delete
        ,   dbms_lob.instr(pr.lower_row, ' from ', 1, 1)                                                    pos_from
        ,   dbms_lob.instr(pr.lower_row, 'update ', 1, 1)                                                   pos_update
        ,   dbms_lob.instr(pr.lower_row, ' set ', 1, 1)                                                     pos_set
        ,   dbms_lob.instr(pr.lower_row, 'insert ', 1, 1)                                                   pos_insert
        ,   dbms_lob.instr(pr.lower_row, ' into ', 1, 1)                                                    pos_into        
        FROM    perf_row                                            pr
        WHERE       pr.perf_file_id IN (362)
                AND dbms_lob.getlength(pr.lower_row) > 1
    )
, x2 AS (
    SELECT
            x1.perf_file_id				    					                                                                    perf_file_id
        ,	x1.row_number										                                                                    row_number
        ,	x1.log_timestamp				    					                                                                log_timestamp
        ,   round(  extract(day    from diff_lead_timestamp) * 86400
                +   extract(hour   from diff_lead_timestamp) * 3600
                +   extract(minute from diff_lead_timestamp) * 60
                +   extract(second from diff_lead_timestamp), 3)                                                                    diff_lead_s
        ,	x1.rows_fetched				    					                                                                    rows_fetched
        ,	x1.fetched_in_ms				    					                                                                fetched_in_ms
        ,	x1.fetched_in_parts									                                                                    fetched_in_parts
        ,   dbms_lob.substr(lower_row, 100, coalesce(
                  case when x1.pos_select > 0 and x1.pos_from > x1.pos_select then x1.pos_select end,
                  case when x1.pos_delete > 0 and x1.pos_from > x1.pos_delete then x1.pos_delete end,
                  case when x1.pos_update > 0 and x1.pos_set  > x1.pos_update then x1.pos_update end,
                  case when x1.pos_insert > 0 and x1.pos_into > x1.pos_insert then x1.pos_insert end))                              stmt        
        ,	x1.lower_row				    						                                                                lower_row
        FROM        x1
    )
SELECT
        x2.perf_file_id				    					                                                                    perf_file_id
    ,   x2.stmt                                                                                                                 stmt        
    ,   COUNT(*)                                                                                                                count_stmt
    ,   SUM(x2.diff_lead_s)                                                                                                     sum_diff_lead_s
    ,	SUM(x2.rows_fetched)                                                                                                    sum_rows_fetched
    ,	SUM(x2.fetched_in_ms)				    					                                                            sum_fetched_in_ms
    ,	SUM(x2.fetched_in_parts)									                                                            sum_fetched_in_parts
    ,	MIN(x2.row_number)										                                                                min_row_number
    ,	MAX(x2.row_number)										                                                                max_row_number
    ,	MIN(x2.log_timestamp)				    					                                                            min_log_timestamp
    ,	MAX(x2.log_timestamp)				    					                                                            max_log_timestamp
    FROM        x2
    GROUP BY x2.perf_file_id, x2.stmt
    --ORDER BY count(*) DESC
    ORDER BY SUM(x2.diff_lead_s) DESC
;



