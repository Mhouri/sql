-----  ./ashPerAction2.sql ------------------------
column  cnt   format 9999999
compute sum label 'Total Elapsed' of cnt on report

break   on report

select 
   sql_id, sql_plan_hash_value, count(1) cnt
from
   gv$active_session_history
 where
    sample_time between to_date('&datefrom', 'mm/dd/yyyy hh24:mi:ss')
				and     to_date('&dateto', 'mm/dd/yyyy hh24:mi:ss')
and action = '&ACTION'
group by sql_id, sql_plan_hash_value
order by 2 desc
;