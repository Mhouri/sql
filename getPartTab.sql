col table_name     format a20
col table_owner    format a20
col pname          format a20
col ppos           format 99999
col last_anal      format a20
col global_stats   format a12
col user_stats     format a12
compute sum label 'Total num_rows' of num_rows on report
break   on report
set verify off
select 
    table_owner
   ,table_name
   ,partition_name      pname
  -- ,partition_position  ppos  
   ,sample_size
   ,global_stats 
   ,user_stats 
  -- ,tablespace_name
   ,to_char(last_analyzed, 'dd/mm/yyyy hh24:mi:ss') last_anal
   ,num_rows
from    
  (
    select
        table_owner
       ,table_name
	   ,partition_name      
	   ,partition_position  
	   ,subpartition_count
	   ,num_rows
       ,sample_size
       ,global_stats 
       ,user_stats   
	   ,last_analyzed
	   ,tablespace_name
  from
       all_tab_partitions
where     
	table_owner = upper('&owner')
and
    table_name = upper('&table_name')
);
