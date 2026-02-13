-- HSB 07.01.2026
-- 15.01.2026: Formatiert, 1.348.424 Zeilen in 183s
-- lower_sql4k
-- Setzt perf_row.lower_sql4k auf Substring aus lower_row ab erstem "select" mit Länge max. 4000.
-- Ohne die 4000-Grenze für substr gibt es Probleme (wenn auch erst später).
merge into perf_row pr
    using (
        select
                r.id                                                                                perf_row_id
            ,   r.lower_row                                                                         lower_row
            ,   dbms_lob.getlength(r.lower_row)                                                     len
            ,   least(
                    nvl(nullif(dbms_lob.instr(r.lower_row, 'select', 1, 1), 0), 999999999),
                    nvl(nullif(dbms_lob.instr(r.lower_row, 'update', 1, 1), 0), 999999999),
                    nvl(nullif(dbms_lob.instr(r.lower_row, 'delete', 1, 1), 0), 999999999),
                    nvl(nullif(dbms_lob.instr(r.lower_row, 'insert', 1, 1), 0), 999999999)
                )                                                                                   p_min
            from    perf_row                            r
            where   r.perf_file_id = :perf_file_id
        ) x
        on (pr.id = x.perf_row_id)
        when matched then update set
            pr.lower_sql4k =
                case
                    when    x.p_min < 999999999
                        and x.p_min + 6 <= x.len
                        and dbms_lob.substr(x.lower_row, 1, x.p_min + 6) in (' ', chr(9), chr(10), chr(13), '(')
                    then clob_first_4k_bytes(x.lower_row, x.p_min)
                    else null
                    end
;

    
    

-- lower_sql4k_neutralized    
-- Um SQL-Statements gruppieren zu können, unabhängig von Variablen, wird in einer Spalte lower_sql4k_neutralized eine Zuweisung der Variablen abgeschnitten. 
-- Dieses erfolgt meistens ganz am Ende, so dass die Gruppierung meistens trotzdem aussagekräftig ist.
merge into perf_row pr using (
    select
                r.id                                            id
            ,   substr(r.lower_sql4k, 1, instr(r.lower_sql4k, '/*:'))   lower_sql4k_neutralized  -- String von Start bis erstes Vorkommen von '/:*' (Variable) 
        from    perf_row r
--        where   r.perf_file_id = :perf_file_id
    ) x
    on (pr.id = x.id)
    when matched then update set
        pr.lower_sql4k_neutralized = x.lower_sql4k_neutralized
;    
    

    
    
--update perf_row set lower_sql4k = null where perf_file_id = 83;    
    
--select r.lower_sql4k from perf_row r where perf_file_id = 86 and r.lower_sql4k is not null;

--alter table perf_row rename column lower_sql to lower_sql4k;

select column_name, data_type, data_length, char_length, char_used
from user_tab_columns
where table_name = 'PERF_ROW'
  and column_name = 'LOWER_SQL4K';
  
  
select r.id,
       lengthb(dbms_lob.substr(r.lower_row, 4000, p_min)) as bytes_len
from (
  select r.*,
         least(
           nvl(nullif(dbms_lob.instr(r.lower_row,'select',1,1),0),999999999),
           nvl(nullif(dbms_lob.instr(r.lower_row,'update',1,1),0),999999999),
           nvl(nullif(dbms_lob.instr(r.lower_row,'delete',1,1),0),999999999),
           nvl(nullif(dbms_lob.instr(r.lower_row,'insert',1,1),0),999999999)
         ) p_min
  from perf_row r
  where r.perf_file_id = :perf_file_id
) r
where r.p_min < 999999999
  and lengthb(dbms_lob.substr(r.lower_row, 4000, r.p_min)) > 4000
fetch first 20 rows only;




create or replace function clob_first_4k_bytes(p_clob in clob, p_off in number)
  return varchar2
is
  v        varchar2(32767) := '';
  chunk    varchar2(32767);
  off      pls_integer := p_off;
  step     pls_integer := 500;  -- 500 Zeichen je Read (klein genug für SQL/UTF-8)
  len_c    pls_integer;
begin
  if p_clob is null or p_off is null or p_off <= 0 then
    return null;
  end if;

  len_c := dbms_lob.getlength(p_clob);

  while lengthb(v) < 4000 and off <= len_c loop
    chunk := dbms_lob.substr(p_clob, step, off);  -- max 500 Zeichen
    exit when chunk is null;

    v := v || chunk;
    off := off + step;
  end loop;

  return substrb(v, 1, 4000);
end;
/


select id,
       lengthb(clob_first_4k_bytes(lower_row, 1)) as bytes_len
from perf_row
where perf_file_id = :perf_file_id
fetch first 20 rows only;








  
