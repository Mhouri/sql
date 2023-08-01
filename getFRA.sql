archive log list

show parameter db_flashback_retention_target


col db_recovery_file_dest for a45
col space_limit_GB for 9999999
col space_used_GB for 9999999
select
   name as db_recovery_file_dest
  ,space_limit/power(1024,3) space_limit_GB
  ,space_used/power(1024,3) space_used_GB
  ,number_of_files
from
  v$recovery_file_dest;

select
  file_type
 ,percent_space_used
 ,percent_space_reclaimable
from
  v$recovery_area_usage;
                              
	