/* --------------------------------------------------------------
Author : Mohamed Houri
Date   : 24/08/2015
If you want to know what object are read
in ASH then use the following script
Particularly :
   -- if current_obj = 0 then this means you are reading from 
                       undo block(useful to check read consistency)
					   
   -- if current_obj = -1 then this means you are working on cpu                      					   
----------------------------------------------------------------------- */
select
     decode(current_obj#
            ,0
            ,'undo block'
            ,-1
            ,'cpu'
            ,current_obj#) cur_obj
   , count(1)
from 
     gv$active_session_history
where 
   sample_time between to_date('&date_from', 'ddmmyyyy hh24:mi:ss')
                  and  to_date('&date_from', 'ddmmyyyy hh24:mi:ss')
and event = 'db file sequential read'
and sql_id = '&sql_id'
group by current_obj# 
order by 2 asc;