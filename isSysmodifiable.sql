-- script used to check whether you have to stop/restart the database when you change
-- a particular parameter value or not

   -- IMMEDIATE : no need to restart the instance
   -- FALSE     : you need to restart the instance
   -- DEFERRED  : session has to be reconnected to see the new value: but no need to stop/restart the instance
col name for a35

select
    name
   ,issys_modifiable
   --,ispdb_modifiable
from
   gv$parameter
 where
    name = '&parameter_name'
union 
  select 
   n.ksppinm  as name
 , c.ksppstdf as issys_modifiable
from 
   sys.x$ksppi n
  ,sys.x$ksppcv c
where n.indx=c.indx
and lower(n.ksppinm) = lower('&parameter_name');