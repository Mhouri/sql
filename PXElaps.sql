/* -----------------------------------------------------------------------------|
|Author : Mohamed Houri                                                         |
|Date   : 03/07/2017                                                            |
|Scope  : gives time consumed by all PX slaves during a parallel query          |        
|							                                                    |
--------------------------------------------------------------------------------|*/
compute sum label 'Total Slaves time' of elapsed on report
break   on report
select
          sql_id
		 ,sql_exec_id
		 ,sid		 
         , process_name 		 
         , round(elapsed_time/1e6,2) elapsed
       --  , round(cpu_time/1e6) cpu
         --, round(concurrency_wait_time/1e6,2) conc
       --  , round(user_io_wait_time/1e6) IO_Waits
   from gv$sql_monitor
   where sql_id = '&sql_id'   
   and sql_exec_id = '&exec_id'
   and sql_text is  null
   order by round(elapsed_time/1e6,2);