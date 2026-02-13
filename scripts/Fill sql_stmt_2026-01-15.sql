select *
    from perf_row r
    where 
        --r.perf_file_id = 121
        --and dbms_lob.instr(r.lower_row, 'open from worklist') > 0
        r.lower_sql4k is not null
    order by r.row_number
;    

select *
    from perf_row r
    where r.perf_file_id = 121
        and dbms_lob.instr(r.lower_row, 'select') > 0
    order by r.row_number

;    


-- Ohne die 4000-Grenze für substr gibt es Probleme (wenn auch erst später).
with x1 as (
        select
                r.id                                                                                                                                                       perf_row_id
            ,   r.lower_row                                                                                                                                                lower_row
            ,   dbms_lob.getlength(r.lower_row)                                                                                                                            len
            ,   nvl(nullif(dbms_lob.instr(r.lower_row, 'select '    , 1                                                   , 1), 0), 999999999)                             pos_select
            ,   nvl(nullif(dbms_lob.instr(r.lower_row, ' from '     , dbms_lob.instr(r.lower_row, 'select ', 1, 1)       , 1), 0), 999999999)         pos_from_select
            ,   nvl(nullif(dbms_lob.instr(r.lower_row, 'update '    , 1, 1), 0), 999999999)                                                                                pos_update
            ,   nvl(nullif(dbms_lob.instr(r.lower_row, ' set '      , nvl(nullif(dbms_lob.instr(r.lower_row, 'update '    , 1), 0), 999999999), 1), 0), 999999999)         pos_set
            ,   nvl(nullif(dbms_lob.instr(r.lower_row, 'delete '    , 1, 1), 0), 999999999)                                                                                pos_delete
            ,   nvl(nullif(dbms_lob.instr(r.lower_row, ' from '     , nvl(nullif(dbms_lob.instr(r.lower_row, 'delete '    , 1), 0), 999999999), 1), 0), 999999999)         pos_from_delete
            ,   nvl(nullif(dbms_lob.instr(r.lower_row, 'insert into', 1, 1), 0), 999999999)                                                                                pos_insert
            from    perf_row                            r
            where   r.perf_file_id = :perf_file_id
        ),
    x2 as (
        select 
                x1.perf_row_id                                                      perf_row_id
            ,   x1.lower_row                                                        lower_row
            ,   x1.len                                                              len
            ,   x1.pos_select                                                       pos_select 
            ,   x1.pos_from_select                                                  pos_from_select
            ,   x1.pos_update                                                       pos_update
            ,   x1.pos_set                                                          pos_set
            ,   x1.pos_delete                                                       pos_delete
            ,   x1.pos_from_delete                                                  pos_from_delete
            ,   x1.pos_insert                                                       pos_insert          
            ,   least(x1.pos_select, x1.pos_update, x1.pos_delete, x1.pos_insert)   p_min
            from    x1                           
        )
    select x2.*
--            ,   dbms_lob.substr(x2.lower_row, 1, x2.p_min + 6)                
--            ,   case
--                    when    x2.p_min < 999999999
----                        and x2.p_min + 6 <= x2.len
--                        and dbms_lob.substr(x2.lower_row, 1, x2.p_min + 6) in (' ', chr(9), chr(10), chr(13), '(')
--                    then clob_first_4k_bytes(x2.lower_row, x2.p_min)
--                    else null
--                    end
        from x2
        where   x2.p_min < 999999999
            and x2.p_min + 6 <= x2.len
            and dbms_lob.substr(x2.lower_row, 1, x2.p_min + 6) in (' ', chr(9), chr(10), chr(13), '(')
            and dbms_lob.substr(x2.lower_row, 1, x2.p_min - 1) in (' ', chr(9), chr(10), chr(13), '(')
            and (x2.pos_select = 999999999 or (dbms_lob.instr(x2.lower_row, 'from', x2.pos_select, 1) >  0)
    
--        on (pr.id = x2.perf_row_id)
--        when matched then update set
--            pr.lower_sql4k =
--                case
--                    when    x2.p_min < 999999999
--                        and x2.p_min + 6 <= x2.len
--                        and dbms_lob.substr(x2.lower_row, 1, x2.p_min + 6) in (' ', chr(9), chr(10), chr(13), '(')
--                    then clob_first_4k_bytes(x2.lower_row, x2.p_min)
--                    else null
--                    end
        order by x2.perf_row_id
;


c:*        0 /             159,875 (=       ) - 2026-01-14 13:26:40,156 - (m:  80625980, mg:  84753444, g:  31640058, l:  12136, j:   66) - destroyprocedure: name=logging_selectfile; mdichild=[log.mod (0x000002a6e9ca8f24)]

