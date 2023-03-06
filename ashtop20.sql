--|-----------------------------------------------------------|
--|Scope  : display awr top events and sql    				  |
--|Usage  : @aashtop20 "16032021 08:00:00" "16032021 09:00:00"|
--|-----------------------------------------------------------|

set feed off

define from_mmddyy="&1"
define to_mmddyy="&2"

clear break

select decode(event,null, 'on cpu', event) event, count(1)
from gv$active_session_history
where
    sample_time between to_date('&from_mmddyy', 'ddmmyyyy hh24:mi:ss')
                and     to_date('&to_mmddyy', 'ddmmyyyy hh24:mi:ss') 			
group by event
order by 2 desc
fetch first 20 rows only;

select sql_id, count(1)
from gv$active_session_history
where
    sample_time between to_date('&from_mmddyy', 'ddmmyyyy hh24:mi:ss')
                and     to_date('&to_mmddyy', 'ddmmyyyy hh24:mi:ss') 			
group by sql_id
order by 2 desc
fetch first 20 rows only;

undefine from_mmddyy
undefine to_mmddyy