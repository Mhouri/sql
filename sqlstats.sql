ol execs format 99999999
select
   child_number child
 --, sql_profile
 , plan_hash_value
 , round(buffer_gets/decode(nvl(executions,0),0,1,executions)) avg_gets
 , round(disk_reads/decode(nvl(executions,0),0,1,executions)) avg_pios
 , (elapsed_time/1000000)/decode(nvl(executions,0),0,1,executions) avg_etime
 , executions execs
from
 gv$sql
where
   sql_id = '&sql_id';