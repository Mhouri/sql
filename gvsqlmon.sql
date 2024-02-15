-- gives an immediate picture on a given sql_id 
-- monitored into RTSM

col exec_start for a25
col status for a20
SELECT
     p.sql_id
	,p.sql_exec_id
	,to_char(p.sql_exec_start,'dd/mm/yyyy hh24:mi:ss') exec_start
    ,p.sql_plan_hash_value   
    ,round(p.elapsed_time/1e6) elaps
	,round(p.cpu_time/1e6) cpu_time
	,p.status
 FROM   
    gv$sql_monitor p
where
    p.sql_id = '&sql_id'
;

          
          