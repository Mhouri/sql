declare

v_sql_text   clob;
ln_plans     pls_integer;

begin

  select replace(sql_fulltext, chr(00), ' ')
    into v_sql_text
    from gv$sqlarea
  where sql_id = trim('&original_sql_id')
  and rownum = 1;


  -- create sql_plan_baseline for original sql using plan from modified sql
  ln_plans := dbms_spm.load_plans_from_cursor_cache (
							sql_id          => trim('&modified_sql_id'),
							plan_hash_value => to_number(trim('&plan_hash_value')),
							sql_text        => v_sql_text );
							
  dbms_output.put_line('Plans Loaded: '||ln_plans);    

end;
/