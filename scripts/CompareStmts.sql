
/*
Selektiert alle Select-Statements, Gruppiert nach den ersten 100 Zeichen
*/

with x as (
    select      pr.perf_file_id                                 perf_file_id
            ,   pr.id                                           perf_row_id 
            ,   pr.row_number                                   row_number
            ,   pr.lower_row                                    lower_row
            ,   dbms_lob.instr(pr.lower_row, 'select ', 1, 1)   pos_select
            ,   dbms_lob.instr(pr.lower_row, 'delete ', 1, 1)   pos_delete
            ,   dbms_lob.instr(pr.lower_row, ' from ', 1, 1)    pos_from
            ,   dbms_lob.instr(pr.lower_row, 'update ', 1, 1)   pos_update
            ,   dbms_lob.instr(pr.lower_row, ' set ', 1, 1)     pos_set
            ,   dbms_lob.instr(pr.lower_row, 'insert ', 1, 1)   pos_insert
            ,   dbms_lob.instr(pr.lower_row, ' into ', 1, 1)    pos_into
    from    perf_row pr
    where       pr.perf_file_id in (:perf_file_id1, :perf_file_id2)
            and dbms_lob.getlength(pr.lower_row) > 1
),          
x2 as (
    select      
                x.perf_file_id                                                                              perf_file_id
            ,   x.perf_row_id                                                                               perf_row_id 
            ,   x.row_number                                                                                row_number
            ,   x.lower_row                                                                                 lower_row
            ,   dbms_lob.substr(lower_row, 100, coalesce(
                      case when x.pos_select > 0 and x.pos_from > x.pos_select then x.pos_select end,
                      case when x.pos_delete > 0 and x.pos_from > x.pos_delete then x.pos_delete end,
                      case when x.pos_update > 0 and x.pos_set > x.pos_update  then x.pos_update end,
                      case when x.pos_insert > 0 and x.pos_into > x.pos_insert then x.pos_insert end))      stmt        
        from    x
    where       (x.pos_select > 0 and x.pos_from    > x.pos_select)
            or  (x.pos_delete > 0 and x.pos_from    > x.pos_delete)
            or  (x.pos_update > 0 and x.pos_set     > x.pos_update)
            or  (x.pos_insert > 0 and x.pos_into    > x.pos_insert)
),
x3 as (
    select      
            x2.perf_file_id                                     perf_file_id
        ,   min(x2.perf_row_id)                                 min_perf_row_id 
        ,   min(x2.row_number)                                  min_row_number
        ,   stmt                                                stmt
        ,   count(*)                                            num_rows
        ,   sum(count(*)) over()                                overall
    from    x2
    group by stmt, perf_file_id
)
select 
            x3.perf_file_id                                     perf_file_id
--        ,   x3.min_perf_row_id                                  min_perf_row_id 
        ,   x3.min_row_number                                   min_row_number
        ,   x3.stmt                                             stmt
        ,   x3.num_rows                                         num_rows
        ,   x3.overall                                          overall
        ,   pr.lower_row                                        lower_row
    from    x3
    join    perf_row    pr  on pr.id = x3.min_perf_row_id
    -- Stmts, die NUR in :perf_file_id1 vorkommen:
    -- where       x3.perf_file_id = :perf_file_id1 and not exists (select 1 from x3 x3_2 where x3_2.perf_file_id = :perf_file_id2 and x3_2.stmt = x3.stmt) 
    order by stmt, perf_file_id, num_rows
;


