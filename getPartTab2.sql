col table_name     format a30
col pname          format a30
col ppos           format 99999
col las_anal       format a20
compute sum label 'Total num_rows' of num_rows on report
break   on report
set verify off
select 
    table_name
   ,partition_name      pname
   ,partition_position  ppos
   ,subpartition_count
   ,num_rows
   ,tablespace_name
  ,to_date((regexp_replace( extract(dbms_xmlgen.getxmltype(
			 'select high_value from dba_tab_partitions 
			  where table_owner='''||&owner||''' 
			  and table_name='''||&table_name||''' 
			  and partition_name='''||partition_name||''''
			 ),'/ROWSET/ROW/HIGH_VALUE/text()').getstringval()
			 ,'[^;]*apos; *([^;]*) *[^;]apos;.*','\1'))
			,'yyyy-mm-dd hh24:mi:ss') high_value
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
    table_owner = upper('&owner')
and
    table_name = upper('&table_name')
);

          
          