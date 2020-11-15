col table_name     format a20
col pname          format a10
col ppos           format 99999
col last_anal      format a20
compute sum label 'Total num_rows' of num_rows on report
break   on report
select 
    table_name
   ,partition_name      pname
   ,partition_position  ppos
  -- ,subpartition_count
   ,num_rows
   ,tablespace_name
   ,to_char(last_analyzed, 'dd/mm/yyyy hh24:mi:ss') last_anal
from    
  (
    select
		table_name
	   ,partition_name      
	   ,partition_position  
	   ,subpartition_count
	   ,num_rows
	   ,last_analyzed
	   ,tablespace_name
  from
       all_tab_partitions
where 
    table_owner = upper('c##mhouri')
and
    table_name = upper('t_acs_part')
);

          
          