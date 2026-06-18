SELECT 
        pr.perf_file_id
    ,   pr.row_number
    ,   pr.rows_fetched
    ,   pr.fetched_in_ms
    ,   pr.fetched_in_parts
    ,   pr.log_time_stamp
    ,   pr.lower_row
    FROM perf_row pr