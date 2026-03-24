
/*
Selektiert alle Select-Statements, Gruppiert nach den ersten 100 Zeichen
*/

with x as (
    select      pr.id                                           perf_row_id 
            ,   pr.lower_row                                    lower_row
            ,   dbms_lob.instr(pr.lower_row, 'select ', 1, 1)   pos_select
            ,   dbms_lob.instr(pr.lower_row, ' from ', 1, 1)    pos_from
    from    perf_row pr
    where       pr.perf_file_id = :perf_file_id
            and dbms_lob.getlength(pr.lower_row) > 1
            and pr.row_number between 1328 and 178326
),
x2 as (
    select  dbms_lob.substr(lower_row, 100, pos_select)         stmt
    from    x
    where   x.pos_select > 0 and x.pos_from > x.pos_select
)
select      stmt                                                stmt
        ,   count(*)                                            num_rows
        ,   sum(count(*)) over()                                overall
from    x2
group by stmt
order by count(*)
;


/*
Selektiert alle Update-Statements, Gruppiert nach den ersten 100 Zeichen
*/

with x as (
    select      pr.id                                           perf_row_id 
            ,   pr.lower_row                                    lower_row
            ,   dbms_lob.instr(pr.lower_row, 'update ', 1, 1)   pos_update
            ,   dbms_lob.instr(pr.lower_row, ' set ', 1, 1)     pos_set
    from    perf_row pr
    where       pr.perf_file_id = :perf_file_id
            and dbms_lob.getlength(pr.lower_row) > 1
            and pr.row_number between 1328 and 178326
),
x2 as (
    select  dbms_lob.substr(lower_row, 100, pos_update)         stmt
    from    x
    where   x.pos_update > 0 and x.pos_set > x.pos_update
)
select      stmt                                                stmt
        ,   count(*)                                            num_rows
        ,   sum(count(*)) over()                                overall
from    x2
group by stmt
order by count(*)
;

/*
Selektiert alle Insert-Statements, Gruppiert nach den ersten 100 Zeichen
*/

with x as (
    select      pr.id                                           perf_row_id 
            ,   pr.lower_row                                    lower_row
            ,   dbms_lob.instr(pr.lower_row, 'insert ', 1, 1)   pos_insert
            ,   dbms_lob.instr(pr.lower_row, ' into ', 1, 1)    pos_into
    from    perf_row pr
    where       pr.perf_file_id = :perf_file_id
            and dbms_lob.getlength(pr.lower_row) > 1
            and pr.row_number between 1328 and 178326
),
x2 as (
    select  dbms_lob.substr(lower_row, 100, pos_insert)         stmt
    from    x
    where   x.pos_insert > 0 and x.pos_into > x.pos_insert
)
select      stmt                                                stmt
        ,   count(*)                                            num_rows
        ,   sum(count(*)) over()                                overall
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
