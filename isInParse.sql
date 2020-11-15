column  in_exec       format a15
column  in_hard_parse format a15
column  in_parse      format a15
column  cnt   format 9999
compute sum label 'Total Elapsed' of cnt on report
break   on report
select 
    sql_exec_id
   ,in_sql_execution in_exec
   ,in_parse
   ,in_hard_parse   
  ,count(1) cnt
from
   gv$active_session_history
 where
   sql_id = '&sql_id'
group by 
    sql_exec_id
   ,in_sql_execution
   ,in_parse
   ,in_hard_parse  
order by 5 desc   
;

