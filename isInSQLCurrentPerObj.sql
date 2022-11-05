--|-------------------------------------------------------------------|
--|Author : Mhouri                                                    |
--|Date   : september 20222                                           |
--|Scope  : this script helps identifying whether the current sql_id  |
--|         is really the one that is responsible for the time stored |
--|         into ASH. In other words, we can state whether the input  |
--|         sql_id has triggered a recursive sql id or not            |
--|-------------------------------------------------------------------|
column  is_sqlid_current    format a10
column  event 				format a70
column  current_obj#        format a30
column  cnt   format 9999
compute sum label 'Total Elapsed' of cnt on report
break   on report
select 
     h.is_sqlid_current
    ,h.event 
    ,ob.object_name
    ,count(1) cnt
from
   gv$active_session_history h
 join dba_objects ob
on ob.object_id = h.current_obj# 
 where
    sample_time between to_date('&from_date', 'mm/dd/yyyy hh24:mi:ss')
                and     to_date('&to_date', 'mm/dd/yyyy hh24:mi:ss')
and 
    sql_id = '&sql_id'			
group by 
     h.is_sqlid_current
    ,h.event 
    ,ob.object_name  
order by 4 desc   
;

