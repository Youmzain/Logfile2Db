/*
Partitioniert nach SQL-Statement.
Selektiert SQL-Statements, die häufig vorkommen:     where x3.count_in_partition > 90
Paritionen werden nummeriert: pos_in_partition = 1 -> Erstes Vorkommen dieses Statements.
Zeigt nur die jeweils ersten x Statements jeder Partition:         and x3.pos_in_partition < 3
Für CUST1487694 "Pflegeinfo Stationsliste" erstellt, um festzustellen, welchen Blöcke von Statements immer wieder wiederholt werden
und wieviel Zeit dazwischen vergangen ist.




*/

with x as (
    select  
                pr.perf_file_id                                         perf_file_id
            ,   pr.row_number                                           row_number
            ,   pr.lower_row                                            lower_row
            ,   dbms_lob.instr(pr.lower_row, 'select ', 1, 1)           pos_select
            ,   dbms_lob.instr(pr.lower_row, ' from ', 1, 1)            pos_from
            ,   dbms_lob.instr(pr.lower_row, 'rows fetched', 1, 1)      pos_rows_fetched
            
    from    perf_row pr
    where      
                dbms_lob.getlength(pr.lower_row) > 1
                and     pr.perf_file_id = 221 and pr.row_number between 1328 and 178326
--                and     pr.row_number in (1472,1478)
),
x2 as (
    select  
                x.perf_file_id                                                                                              perf_file_id
            ,   x.row_number                                                                                                row_number
            ,   dbms_lob.substr(x.lower_row, 100, pos_select)                                                               stmt
            ,   x.lower_row                                                                                                 lower_row
            ,   dbms_lob.substr(x.lower_row, least(4000, dbms_lob.getlength(x.lower_row) - x.pos_select - 1), x.pos_select) stmt_long           -- Ab "Select" 4000 Zeichen als varchar2.
            ,   dbms_lob.substr(x.lower_row, 15, x.pos_rows_fetched - 15)                                                   rows_fetched        -- Substring ab 'rows fetched' - 15 zur Ermittlung der #Rows    
    from    x
    where   x.pos_select > 0 and x.pos_from > x.pos_select
),
x3 as (
    select    
            x2.perf_file_id                                                                 perf_file_id
        ,   x2.row_number                                                                   row_number   
        ,   row_number() over (partition by x2.stmt order by x2.row_number)                 pos_in_partition 
        ,   count(1) over (partition by x2.stmt)                                            count_in_partition 
        ,   x2.stmt                                                                         stmt
        ,   x2.lower_row                                                                    lower_row
        ,   x2.stmt_long                                                                    stmt_long
        ,   x2.rows_fetched                                                                 rows_fetched            
        ,   dbms_lob.instr(x2.rows_fetched, ' -- ', 1)                                      pos_before_fetched              -- Position von  ' -- ', z.B. in "; -- 1 rows fetched in 1 par", um dann "1" zu extrahieren.
        ,   length(' -- ')                                                                  len_search_start_of_fetched     
    from    x2
),
x4 as (
    select 
            x3.perf_file_id                                                                             perf_file_id
        ,   x3.row_number                                                                               row_number   
        ,   x3.pos_in_partition                                                                         pos_in_partition 
        ,   x3.count_in_partition                                                                       count_in_partition 
        ,   x3.stmt                                                                                     stmt
        ,   dbms_lob.substr(x3.rows_fetched
                , length(rows_fetched) - x3.pos_before_fetched + len_search_start_of_fetched - 1
                , x3.pos_before_fetched + len_search_start_of_fetched - 1)                              num_rows_fetched            
        ,   x3.stmt_long                                                                                stmt_long
        ,   x3.lower_row                                                                                lower_row
    from    x3
)
select 
            x4.perf_file_id                                                                             perf_file_id
        ,   x4.row_number                                                                               row_number   
        ,   x4.pos_in_partition                                                                         pos_in_partition 
        ,   x4.count_in_partition                                                                       count_in_partition 
        ,   x4.num_rows_fetched                                                                         num_rows_fetched
        ,   x4.stmt_long                                                                                stmt_long
        ,   x4.lower_row                                                                                lower_row
    from    x4
    where x4.count_in_partition > 0
        and x4.pos_in_partition < 10
        and x4.num_rows_fetched > 20
        and dbms_lob.instr(x4.lower_row, 'fetched') > 0
    order by x4.num_rows_fetched, x4.row_number, x4.count_in_partition, x4.stmt, x4.pos_in_partition

--    fetch next 1 rows only
;

/*
189; end; -- 1 
1234567890123456

*/
--o:         0 /12699,812 -12699,812 (=      0) - 2026-02-13 14:14:14,872 - (m:  70452703, mg:  74732247, g:  28804820, l:  11006, j:   47) - select t2.primitivumnummer ,t2.klasse ,t2.stammdaten ,t0.fallid ,t0.persnr  from fall t0,cw_mappe t1,cw_primitivum t2 where t0.fallid = :i1 and t1.patient (+)= t0.persnr and t2.primitivumnummer (+)= t1.primitivumnummer; begin :i1:=3041229; end; -- 1 rows fetched in 1 parts -- cpl:%f001926.txt (pflegeinfo stationsliste sub;pflegeinfo stationsliste sub)


