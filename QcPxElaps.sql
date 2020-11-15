compute sum label 'Query time' of wall_clock_time on report
break   on report
with px as (select max(px_maxdop) px_maxdop
            from gv$sql_monitor
			where sql_id ='&sql_id'
			and   sql_exec_id = '&sql_exec_id')
select
          sql_id	          		 
         ,round(elapsed_time/1e6,2) wall_clock_time
		 ,px_maxdop
from gv$sql_monitor
where sql_id = '&sql_id'   
and sql_exec_id = '&exec_id'
and sql_text is  null
union all
select
          sql_id	          		 
         ,round(elapsed_time/1e6,2) wall_clock_time
		 ,null
from gv$sql_monitor,px
where sql_id = '&sql_id'   
and sql_exec_id = '&exec_id'
and sql_text is  null
order by round(elapsed_time/1e6,2)
