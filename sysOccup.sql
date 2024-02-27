--Mhouri
col occupant_name for a50
compute sum label 'Total Size' of MB on report
break on report
select 
     occupant_name
    ,occupant_desc
    ,round(space_usage_kbytes/power(1024,1),2) MB
from  
    v$sysaux_occupants
where
   space_usage_kbytes >0
order  by space_usage_kbytes desc;
