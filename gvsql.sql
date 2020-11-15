col object_status format a10
col end_of_fetch_count format 999
SELECT
     p.sql_id
	,p.child_number
    --,p.plan_hash_value
	,p.is_bind_sensitive bsens
	,p.is_bind_aware baware 
    --,p.first_load_time	
	--,p.last_load_time
    ,p.executions
	,p.end_of_fetch_count end_fetch
	,p.invalidations
	,p.object_status
 FROM   
    gv$sql p
where
    p.sql_id = '&sql_id'
and    
  p.is_shareable ='Y';

          
          