/*
Selektiert alle Select-Statements, Gruppiert nach den ersten 100 Zeichen
*/

with x as (
    select      pr.id                                           perf_row_id 
            ,   pr.lower_row                                    lower_row
            ,   dbms_lob.instr(pr.lower_row, 'select ', 1, 1)   pos_select
    from    perf_row pr
    where   pr.perf_file_id = :perf_file_id
      and   dbms_lob.getlength(pr.lower_row) > 1
),
x2 as (
    select  dbms_lob.substr(lower_row, 100, pos_select)         stmt
    from    x
    where   x.pos_select > 0
)
select      stmt                                                stmt
        ,   count(*)                                            num_rows
from    x2
group by stmt
order by count(*)
;



/*
Selektiert alle Select-Statements
*/

with x as (
    select      pr.id                                           perf_row_id 
            ,   pr.lower_row                                    lower_row
            ,   dbms_lob.instr(pr.lower_row, 'select ', 1, 1)   pos_select
    from    perf_row pr
    where   pr.perf_file_id = :perf_file_id
      and   dbms_lob.getlength(pr.lower_row) > 1
),
x2 as (
    select      x.perf_row_id                                   perf_row_id
            ,   dbms_lob.substr(lower_row, 100, pos_select)     stmt
            ,   x.lower_row                                     lower_row
    from    x
    where   x.pos_select > 0
)
select  
            x2.stmt                                             stmt
        ,   x2.lower_row                                        lower_row
from    x2
order by x2.stmt
;
