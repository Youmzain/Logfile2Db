with s as (
    select 
                dbms_lob.instr(r.lower_row, ':') + 1 pos1
            ,   dbms_lob.instr(r.lower_row, '/') - 1 pos2
            ,   dbms_lob.substr(r.lower_row, dbms_lob.instr(r.lower_row, '/') - dbms_lob.instr(r.lower_row, ':') - 1, dbms_lob.instr(r.lower_row, ':') + 1) s
            ,   to_number(dbms_lob.substr(r.lower_row, dbms_lob.instr(r.lower_row, '/') - dbms_lob.instr(r.lower_row, ':') - 1, dbms_lob.instr(r.lower_row, ':') + 1) default null on conversion error) n
            ,   r.*
        from perf_row r
        where r.perf_file_id = 86
            and r.lower_sql4k is not null
)
select *
    from s
    where s.n > 0
    order by s.n desc
;        
