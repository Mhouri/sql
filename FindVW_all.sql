/* ------------------------------------------------------------------------------------|
|Author : Mohamed Houri                                                                |
|Date   : 03/07/2017                                                                   |
|Scope  : gives all sql_id in memory and from AWR history using all VW_ transformation |
|																					   |
---------------------------------------------------------------------------------------|*/
-- 
col sql_id           format a15
col plan_hash_value  format 999999999999
col object_name      format a25

break on report
select
    *
from 
( select  
      sql_id
	 ,plan_hash_value
	 ,object_name
	 ,cardinality
  from
     gv$sql_plan
  where
    object_name like '%VW%'
  union
  select  
      sql_id
	 ,plan_hash_value
	 ,object_name
	 ,cardinality
  from
     dba_hist_sql_plan
  where
    object_name like '%VW%'
)
order by sql_id;