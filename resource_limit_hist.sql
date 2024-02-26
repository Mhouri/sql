-- jonathan Lewis
-- https://jonathanlewis.wordpress.com/?s=resource_limit

column resource_name            format a32
column max_utilization          format 999,999
column current_utilization      format 999,999
column initial_allocation       format a18
column limit_value              format a11
column end_interval_time        format a26

select  * 
from    (
        select 
                ss.end_interval_time,
                res.resource_name, res.max_utilization, res.current_utilization 
        from 
                dba_hist_resource_limit res,
                dba_hist_snapshot       ss
        where 
                ss.end_interval_time between to_date('&from_date','ddmmyyyy hh24:mi:ss')
                                     and     to_date('&to_date','ddmmyyyy hh24:mi:ss')
        and     res.snap_id = ss.snap_id
        and     res.resource_name in ('sessions','processes','transactions')
        )       piv
        pivot   (
                        avg(max_utilization)     as max,
                        avg(current_utilization) as cur
                for     resource_name in (
                                'sessions'      as sess,
                                'processes'     as proc,
                                'transactions'  as trns
                        )
                )
order by
        end_interval_time
/