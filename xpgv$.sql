SELECT 
    RPAD('Inst: '||v.inst_id, 9)||' '||RPAD('Child: '||v.child_number, 11) inst_child
   ,t.plan_table_output
FROM 
  gv$sql v,
  TABLE(DBMS_XPLAN.DISPLAY('gv$sql_plan_statistics_all'
                           , NULL
						   , 'ADVANCED ALLSTATS LAST'
						   , 'inst_id = '||v.inst_id||' 
						     AND sql_id = '''||v.sql_id||''' AND child_number = '||v.child_number
					     )
	 ) t
 WHERE 
     v.sql_id = '&&sql_id.'
 AND v.loaded_versions > 0;


SELECT 
   t.plan_table_output
FROM 
  gv$sql v,
  TABLE(DBMS_XPLAN.DISPLAY('gv$sql_plan_statistics_all'
                           , NULL
						   , 'ADVANCED ALLSTATS LAST'
						   , 'inst_id = '||v.inst_id||' 
						     AND sql_id = '''||v.sql_id||''' AND child_number = '||v.child_number
					     )
	 ) t
 WHERE 
     v.sql_id = '&&sql_id.'
 AND v.loaded_versions > 0;