column  cnt   format 9999999
compute sum label 'Total Elapsed' of cnt on report

break   on report

select 
   sql_plan_line_id
  ,count(1) cnt
from
   gv$active_session_history
 where
    sample_time between to_date('&datefrom', 'mm/dd/yyyy hh24:mi:ss')
				and     to_date('&dateto', 'mm/dd/yyyy hh24:mi:ss')
and sql_id = '&sql_id'
group by sql_plan_line_id
order by 2 desc;