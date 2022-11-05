--|-------------------------------------------------------------------|
--|Author : Mhouri                                                    |
--|Date   : september 20222                                           |
--|Scope  : this script helps identifying whether the current sql_id  |
--|         is really the one that is responsible for the time stored |
--|         into ASH. In other words, we can state whether the input  |
--|         sql_id has triggered a recursive sql id or not            |
--|-------------------------------------------------------------------|
column  sql_current   format a15
column  cnt   format 9999
compute sum label 'Total Elapsed' of cnt on report
break   on report
select 
    sql_exec_id
   ,is_sqlid_current   sql_current
   ,count(1) cnt
from
   gv$active_session_history
 where 
   sql_id = '&sql_id'
 and
    sample_time between to_date('&datefrom', 'mm/dd/yyyy hh24:mi:ss')
				and     to_date('&dateto', 'mm/dd/yyyy hh24:mi:ss')
group by 
    sql_exec_id
   ,is_sqlid_current  
order by 3 desc   
;

