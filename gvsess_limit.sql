column resource_name            format a32
column max_utilization          format 999,999
column current_utilization      format 999,999
column initial_allocation       format a18
column limit_value              format a11
 
spool resource_limit.lst
 
select
        resource_name,
        max_utilization,
        current_utilization,
        lpad(initial_allocation,18)     initial_allocation,
        lpad(limit_value,11)            limit_value
from
        v$resource_limit
;