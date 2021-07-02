col partition_name format a20
col num_distinct   format a20
col last_anal      format a20
col column_name    format a12
col user_stats     format a12
select
       partition_name
	   ,column_name
      --,num_distinct
      --,density
	  ,to_char(last_analyzed,'dd/mm/yyyy hh24:mi:ss') last_anal
      ,histogram
      ,notes
    from
        all_part_col_statistics
    where owner     = upper('&owner')
    and table_name  = upper('&table_name')
   -- and column_name = upper('&column_name')
	;