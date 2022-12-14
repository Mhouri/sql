col task_name for a50
compute sum label 'Total Size' of MB on report
break on report
select 
     task_name, count(1) cnt
from  
    dba_advisor_objects
group by
   task_name
order by 2 desc;