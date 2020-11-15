select
           sql_id
		 , round(elapsed_time/1e6,2) QC_time
         , px_maxdop DOP
         , px_servers_requested
         , px_servers_allocated        
         , round(cpu_time/1e6) cpu
         --, round(concurrency_wait_time/1e6,2) conc
         , round(user_io_wait_time/1e6) IO_Waits
   from gv$sql_monitor
   where sql_id = '&sql_id'
   and sql_exec_id = '&exec_id'
   and sql_text is not null;