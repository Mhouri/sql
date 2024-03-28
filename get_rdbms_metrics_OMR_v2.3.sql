with db_role_hist as 
(
SELECT 
    -- First we find last role change before p_date
      t.target_name
    , 1 as priority
    , a.change_date
    , t.target_type
    , a.message
    , CASE
        WHEN REGEXP_LIKE ( a.message,'Standby.*Primary','i' ) THEN 'PRIMARY'
        WHEN REGEXP_LIKE ( a.message,'Primary.*Standby','i' ) THEN 'PHYSICAL STANDBY'
        WHEN REGEXP_LIKE ( a.message,'Snapshot Standby','i' ) THEN 'SNAPSHOT STANDBY'
        WHEN REGEXP_LIKE ( a.message,'Primary','i' ) THEN 'PRIMARY'
		WHEN REGEXP_LIKE ( a.message,'Standby','i' ) THEN 'PHYSICAL STANDBY'
        ELSE 'PRIMARY'
      END AS db_status
--      , a.*
--      , t.*
FROM
      sysman.em_target_change_log a
    , sysman.MGMT$target t
WHERE
    1 = 1
    AND a.target_guid = t.target_guid
    AND a.change_code = 6
    and t.target_type like '%database%'
order by 
    a.change_date asc
)
, prim_target_name as 
(
select 
      target_name
    , nvl(change_date, sysdate) as begin_interval
    , nvl(lead(change_date) over (partition by target_name order by change_date), sysdate) as end_interval
    , CASE
		WHEN (db_status is null) and (lead(db_status ignore nulls) OVER (partition by target_name ORDER BY change_date) = 'PHYSICAL STANDBY') THEN 'PRIMARY'
     	WHEN (db_status is null) and (lead(db_status ignore nulls) OVER (partition by target_name ORDER BY change_date) = 'PRIMARY') THEN 'PHYSICAL STANDBY'
		WHEN (db_status is null) and (lead(db_status ignore nulls) OVER (partition by target_name ORDER BY change_date) = 'PRIMARY') THEN 
              last_value(db_status) ignore nulls OVER (partition by target_name ORDER BY change_date)
        ELSE db_status
      END AS active_role
from 
      db_role_hist 
WHERE 
    1=1
)
--select * from prim_target_name where 1=1 /* and target_name like 'dbaas%' */ order by begin_interval,target_name, active_role desc;
, target_lob as
(
select
      bus.target_name
    , bus.target_guid
    , bus.property_value as target_lob
--    , bus.*
from
    sysman.MGMT$TARGET_PROPERTIES bus 
where
    1=1
    and bus.property_name = 'orcl_gtp_line_of_bus'
)
-- select * from prim_target_name natural join target_lob where 1=1 /*and target_name like 'dbaas%'*/ order by active_role, begin_interval;
, target_lcs as
(
select
      lcs.target_name
    , lcs.target_guid
    , lcs.property_value as target_lcs
from
    sysman.MGMT$TARGET_PROPERTIES lcs
where
    1=1
    and lcs.property_name = 'orcl_gtp_lifecycle_status'
)
, rac_db_instances as
(
select
    *
from
    sysman.mgmt$target_associations
where
    1=1
--    and source_target_name = 'ALLDTMD_PRM'
    and source_target_type = 'rac_database'
    and assoc_def_name = 'cluster_contains'
    and assoc_target_type = 'oracle_database'
order by
    source_target_name
    , assoc_target_name
)
, rac_db_gi as
(
select
    *
from
    sysman.mgmt$target_associations
where
    1=1
--    and source_target_name = 'ALLDTMD_PRM'
    and source_target_type = 'rac_database'
    and assoc_def_name = 'runs_on_cluster'
    and assoc_target_type = 'cluster'
order by
    source_target_name
    , assoc_target_name
)
, rac_db_frame as
(
select
    *
from
    sysman.mgmt$target_associations
where
    1=1
--    and source_target_name = 'ALLDTMD_PRM'
    and source_target_type = 'rac_database'
    and assoc_def_name = 'deployed_on'
    and assoc_target_type = 'oracle_dbmachine'
order by
    source_target_name
    , assoc_target_name
)
, db_gi_frame as 
(
select
      gi.source_target_name as rac_db_name
    , gi.source_target_type as db_tgt_type
    , nvl(gi.assoc_target_name,'noGI') as gi_tgt_name
    , nvl(gi.assoc_target_type,'noGI') as gi_tgt_type
    , nvl(f.assoc_target_name,'noFrame') as frame_tgt_name
    , nvl(f.assoc_target_type,'noFrame') as frame_tgt_type
from
    rac_db_gi gi
    left outer join rac_db_frame f on gi.source_target_name = f.source_target_name
where
    1=1
    -- and i.source_target_name = 'ALLDTMD_PRM'
order by 
    rac_db_name
)
, inst_rac_gi_frame as
(
select
      i.source_target_name as rac_db_name
    , i.source_target_type as db_tgt_type
    , i.assoc_target_name as db_inst_name
    , i.assoc_target_type as inst_tgt_type
    , nvl(gi.assoc_target_name,'noGI') as gi_tgt_name
    , nvl(gi.assoc_target_type,'noGI') as gi_tgt_type
    , nvl(f.assoc_target_name,'noFrame') as frame_tgt_name
    , nvl(f.assoc_target_type,'noFrame') as frame_tgt_type
from
    rac_db_instances i 
    left outer join rac_db_gi gi on i.source_target_name = gi.source_target_name
    left outer join rac_db_frame f on i.source_target_name = f.source_target_name
where
    1=1
    -- and i.source_target_name = 'ALLDTMD_PRM'
order by 
    rac_db_name
)
, si_db_instances as 
(
select
      source_target_name as target_name
    , source_target_type as target_type
    , assoc_target_name as host_name
from
    sysman.mgmt$target_associations
where
    1=1
--    and source_target_name = 'RB1'
    and source_target_type = 'oracle_database'
    and assoc_target_type = 'host'
    and association_type = 'hosted_by'
)
, host_frame as
(
select 
      member_target_name as host_name
    , aggregate_target_name as frame_name
    , aggregate_target_type as frame_type
from
    sysman.mgmt$target_flat_members
where
    1=1
    and member_target_type = 'host'
    and aggregate_target_type IN ('oracle_exadata_cloud_service', 'oracle_dbmachine','oracle_si_supercluster')
--    and member_target_name='exa1dc02-frapvm04.orpea.net'
)
, host_gi as
(
select 
      member_target_name as host_name
    , aggregate_target_name as gi_name
    , aggregate_target_type
from
    sysman.mgmt$target_flat_members
where
    1=1
    and member_target_type = 'host'
    and aggregate_target_type IN ('cluster')
--    and member_target_name='exa1dc02-frapvm04.orpea.net'
)
, si_db_gi as 
(
select 
    i.*
    , h.gi_name
    , hf.frame_name
    , hf.frame_type
from
    si_db_instances i
    join host_gi h on i.host_name = h.host_name
    left outer join host_frame hf on h.host_name = hf.host_name
)
-- select * from inst_rac_gi_frame;
-- select * from si_db_gi;
, db_metrics as 
(
select /*+ materialize */
      d.target_name
    , d.target_guid
    , d.target_type
--    , to_char(d.rollup_timestamp,'YYYY-MM-DD HH24:MI') as snap_time
    , d.rollup_timestamp as snap_time
    , p.active_role
--    , tlob.target_lob as target_lob
--    , tlcs.target_lcs as target_lcs
-- DB Time`
    , ROUND(MAX(CASE WHEN metric_column = 'dbTimePs' THEN d.maximum END), 2) as db_max_tot_dbTime_ps
    , ROUND(MAX(CASE WHEN metric_column = 'dbTimePs' THEN d.average END), 2) as db_avg_tot_dbTime_ps
-- CPU
    , ROUND(MAX(CASE WHEN metric_column = 'dbCpuPs' THEN d.average END), 2) as db_avg_tot_core_ps
    , ROUND(MAX(CASE WHEN metric_column = 'dbCpuPs' THEN d.maximum END), 2) as db_max_tot_core_ps
-- memory
    , ROUND(MAX(CASE WHEN metric_column = 'total_pga_allocated' THEN d.average END), 2)*1024*1024 as pga_avg_allocated_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'total_pga_allocated' THEN d.maximum END), 2)*1024*1024 as pga_max_allocated_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'memory_usage' THEN d.average END), 2)*1024*1024 as memory_avg_usage_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'memory_usage' THEN d.maximum END), 2)*1024*1024 as memory_max_usage_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'streams_pool' THEN d.average END), 2)*1024*1024 as streams_pool_avg_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'streams_pool' THEN d.maximum END), 2)*1024*1024 as streams_pool_max_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'sga_total' THEN d.average END), 2)*1024*1024 as sga_total_pool_avg_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'sga_total' THEN d.maximum END), 2)*1024*1024 as sga_total_pool_max_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'other_sga_memory' THEN d.average END), 2)*1024*1024 as other_sga_memory_avg_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'other_sga_memory' THEN d.maximum END), 2)*1024*1024 as other_sga_memory_max_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'pga_total' THEN d.average END), 2)*1024*1024 as pga_total_avg_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'pga_total' THEN d.maximum END), 2)*1024*1024 as pga_total_max_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'large_pool' THEN d.average END), 2)*1024*1024 as large_pool_avg_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'large_pool' THEN d.maximum END), 2)*1024*1024 as large_pool_max_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'fixed_sga' THEN d.average END), 2)*1024*1024 as fixed_sga_avg_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'fixed_sga' THEN d.maximum END), 2)*1024*1024 as fixed_sga_max_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'java_pool' THEN d.average END), 2)*1024*1024 as java_pool_avg_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'java_pool' THEN d.maximum END), 2)*1024*1024 as java_pool_max_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'shared_pool' THEN d.average END), 2)*1024*1024 as shared_pool_avg_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'shared_pool' THEN d.maximum END), 2)*1024*1024 as shared_pool_max_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'buffer_cache' THEN d.average END), 2)*1024*1024 as buffer_cache_avg_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'buffer_cache' THEN d.maximum END), 2)*1024*1024 as buffer_cache_max_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'log_buffer' THEN d.average END), 2)*1024*1024 as log_buffer_avg_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'log_buffer' THEN d.maximum END), 2)*1024*1024 as log_buffer_max_bytes
-- top activity
    , ROUND(MAX(CASE WHEN metric_column = 'avg_active_sessions' THEN d.average END), 2) as aas_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'avg_active_sessions' THEN d.maximum END), 2) as aas_max_ps
    , ROUND(MAX(CASE WHEN metric_column = 'user_cpu_time_cnt' THEN d.average END), 2) as user_avg_cpu_cnt
    , ROUND(MAX(CASE WHEN metric_column = 'user_cpu_time_cnt' THEN d.maximum END), 2) as user_max_cpu_cnt
    , ROUND(MAX(CASE WHEN metric_column = 'userio_wait_cnt' THEN d.average END), 2) as userio_avg_wait_cnt
    , ROUND(MAX(CASE WHEN metric_column = 'userio_wait_cnt' THEN d.maximum END), 2) as userio_max_wait_cnt
    , ROUND(MAX(CASE WHEN metric_column = 'other_wait_cnt' THEN d.average END), 2) as other_avg_wait_cnt
    , ROUND(MAX(CASE WHEN metric_column = 'other_wait_cnt' THEN d.maximum END), 2) as other_max_wait_cnt    
-- top activity by wait class
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Administrative' THEN d.maximum END), 2) as admin_max_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Administrative' THEN d.average END), 2) as admin_avg_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Application' THEN d.maximum END), 2) as application_max_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Application' THEN d.average END), 2) as application_avg_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Cluster' THEN d.maximum END), 2) as cluster_max_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Cluster' THEN d.average END), 2) as cluster_avg_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Commit' THEN d.maximum END), 2) as commit_max_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Commit' THEN d.average END), 2) as commit_avg_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Concurrency' THEN d.maximum END), 2) as concurrency_max_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Concurrency' THEN d.average END), 2) as concurrency_avg_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Configuration' THEN d.maximum END), 2) as configuration_max_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Configuration' THEN d.average END), 2) as configuration_avg_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Idle' THEN d.maximum END), 2) as Idle_max_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Idle' THEN d.average END), 2) as Idle_avg_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Network' THEN d.maximum END), 2) as network_max_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Network' THEN d.average END), 2) as network_avg_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Other' THEN d.maximum END), 2) as other_max_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Other' THEN d.average END), 2) as other_avg_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Queueing' THEN d.maximum END), 2) as queueing_max_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Queueing' THEN d.average END), 2) as queueing_avg_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Scheduler' THEN d.maximum END), 2) as scheduler_max_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'Scheduler' THEN d.average END), 2) as scheduler_avg_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'System I/O' THEN d.maximum END), 2) as systemIO_max_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'System I/O' THEN d.average END), 2) as systemIO_avg_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'User I/O' THEN d.maximum END), 2) as userIO_max_waitclass_pct
    , ROUND(MAX(CASE WHEN metric_column = 'dbtime_waitclass_pct' and key_value = 'User I/O' THEN d.average END), 2) as userIO_avg_waitclass_pct
-- sessions
    , ROUND(MAX(CASE WHEN metric_column = 'session_usage' THEN d.maximum END), 2) as sess_max_pct
    , ROUND(MAX(CASE WHEN metric_column = 'session_usage' THEN d.average END), 2) as sess_avg_pct
-- executions_ps
    , ROUND(MAX(CASE WHEN metric_column = 'executions_ps' THEN d.average END), 2) execs_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'executions_ps' THEN d.maximum END), 2) execs_max_ps   
-- iorequests_ps
    , ROUND(MAX(CASE WHEN metric_column = 'iorequests_ps' THEN d.average END), 2) iops_avg_ioreq_ps
    , ROUND(MAX(CASE WHEN metric_column = 'iorequests_ps' THEN d.maximum END), 2) iops_max_ioreq_ps
-- iobytes_ps
    , ROUND(MAX(CASE WHEN metric_column = 'iombs_ps' THEN d.average END)*1024*1024, 2) io_bytes_avg_ioreq_ps
    , ROUND(MAX(CASE WHEN metric_column = 'iombs_ps' THEN d.maximum END)*1024*1024, 2) io_bytes_max_ioreq_ps
-- iotypes
    , ROUND(MAX(CASE WHEN metric_column = 'physreads_ps' THEN d.average END), 2) physreads_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'physreads_ps' THEN d.maximum END), 2) physreads_max_ps
    , ROUND(MAX(CASE WHEN metric_column = 'physreadsdir_ps' THEN d.average END), 2) physreadsdir_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'physreadsdir_ps' THEN d.maximum END), 2) physreadsdir_max_ps
    , ROUND(MAX(CASE WHEN metric_column = 'physreadslob_ps' THEN d.average END), 2) physreadslob_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'physreadslob_ps' THEN d.maximum END), 2) physreadslob_max_ps
    , ROUND(MAX(CASE WHEN metric_column = 'physwrites_ps' THEN d.average END), 2) physwrites_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'physwrites_ps' THEN d.maximum END), 2) physwrites_max_ps
    , ROUND(MAX(CASE WHEN metric_column = 'physwritesdir_ps' THEN d.average END), 2) physwritesdir_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'physwritesdir_ps' THEN d.maximum END), 2) physwritesdir_max_ps
    , ROUND(MAX(CASE WHEN metric_column = 'physwriteslob_ps' THEN d.average END), 2) physwriteslob_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'physwriteslob_ps' THEN d.maximum END), 2) physwriteslob_max_ps
-- latency
    , ROUND(MAX(CASE WHEN metric_column = 'avg_sync_singleblk_read_latency' THEN d.average END), 4) sb_read_avg_latency_ms
    , ROUND(MAX(CASE WHEN metric_column = 'avg_sync_singleblk_read_latency' THEN d.maximum END), 4) sb_read_max_latency_ms
    , ROUND(MAX(CASE WHEN metric_column = 'userio' THEN d.maximum END), 4) userio_max_latency_ms
    , ROUND(MAX(CASE WHEN metric_column = 'userio' THEN d.maximum END), 4) userio_avg_latency_ms
-- idx_vs_table
    , ROUND(MAX(CASE WHEN metric_column = 'indxscanstotal_ps' THEN d.average END), 4) indxscanstotal_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'indxscanstotal_ps' THEN d.maximum END), 4) indxscanstotal_max_ps
    , ROUND(MAX(CASE WHEN metric_column = 'tabscanstotal_ps' THEN d.average END), 4) tabscanstotal_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'tabscanstotal_ps' THEN d.maximum END), 4) tabscanstotal_max_ps
-- logons_ps
    , ROUND(MAX(CASE WHEN metric_column = 'logons_ps' THEN d.average END), 2) logons_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'logons_ps' THEN d.maximum END), 2) logons_max_ps   
-- redosize_ps
    , ROUND(MAX(CASE WHEN metric_column = 'redosize_ps' THEN d.average END)*1024, 2) redosize_bytes_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'redosize_ps' THEN d.maximum END)*1024, 2) redosize_bytes_max_ps
-- commit
    , ROUND(MAX(CASE WHEN metric_column = 'commits_ps' THEN d.average END), 2) commits_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'commits_ps' THEN d.maximum END), 2) commits_max_ps
-- backup
    , ROUND(MAX(CASE WHEN metric_column = 'rmanCpuTimeBackupRestorePs' THEN d.maximum END), 2) as rmanCpuTime_max_ps
    , ROUND(MAX(CASE WHEN metric_column = 'rmanCpuTimeBackupRestorePs' THEN d.average END), 2) as rmanCpuTime_avg_ps
-- usercalls_ps
    , ROUND(MAX(CASE WHEN metric_column = 'usercalls_ps' THEN d.average END), 2) usercalls_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'usercalls_ps' THEN d.maximum END), 2) usercalls_max_ps
-- parsess
    , ROUND(MAX(CASE WHEN metric_column = 'parses_ps' THEN d.maximum END), 2) parses_max_ps
    , ROUND(MAX(CASE WHEN metric_column = 'parses_ps' THEN d.average END), 2) parses_avg_ps
    , ROUND(MAX(CASE WHEN metric_column = 'hardparses_ps' THEN d.maximum END), 2) hard_parses_max_ps
    , ROUND(MAX(CASE WHEN metric_column = 'hardparses_ps' THEN d.average END), 2) hard_parses_avg_ps
-- database size
    , ROUND(MAX(CASE WHEN metric_column = 'ALLOCATED_GB' THEN d.average END)*1024*1024*1024, 2) allocated_avg_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'ALLOCATED_GB' THEN d.maximum END)*1024*1024*1024, 2) allocated_max_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'USED_GB' THEN d.average END)*1024*1024*1024, 2) used_avg_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'USED_GB' THEN d.maximum END)*1024*1024*1024, 2) used_max_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'archTotal' THEN d.maximum END)*1024, 2) archTotal_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'archAvail' THEN d.maximum END)*1024, 2) archAvail_bytes
    , ROUND(MAX(CASE WHEN metric_column = 'archUsed' THEN d.maximum END)*1024, 2) archUsed_bytes    
from 
--    sysman.MGMT$metric_daily d 
    sysman.mgmt$metric_hourly d
    join prim_target_name p on d.target_name = p.target_name 
where 
        1=1
    and d.rollup_timestamp between p.begin_interval and p.end_interval
--    and p.active_role = 'PRIMARY'
    and d.target_type like '%database%'
--    and to_char(rollup_timestamp,'YYYY-MM-DD')='2024-01-07'
group by 
      d.target_name
    , d.target_guid
    , d.target_type
--    , to_char(d.rollup_timestamp,'YYYY-MM-DD HH24:MI')
    , d.rollup_timestamp
    , p.active_role
order by 
      target_name
    , target_guid
    , snap_time
    , p.active_role
)
-- select * from db_metrics where snap_time = '2022-03-01' order by target_guid;
select
      nvl(ii.database_name,d.target_name) database_name
    , case
        when d.target_type = 'rac_database' then gif.gi_tgt_name
        when d.target_type = 'oracle_database' then sig.gi_name
        else 'toto'
      end as gi_tgt_name
    , case
        when d.target_type = 'rac_database' then gif.gi_tgt_type
        when d.target_type = 'oracle_database' then igif.gi_tgt_type
        else 'toto'
      end as gi_tgt_type
    , case
        when d.target_type = 'rac_database' then gif.frame_tgt_name
        when d.target_type = 'oracle_database' then sig.frame_name
        else 'toto'
      end as frame_tgt_name
    , case
        when d.target_type = 'rac_database' then gif.frame_tgt_type
        when d.target_type = 'oracle_database' then sig.frame_type
        else 'toto'
      end as frame_tgt_type
    , d.target_name
    , d.target_guid
    , d.target_type
    , nvl(sig.host_name,'noHost') as host_name
    , to_char(d.snap_time,'YYYY-MM-DD HH24:MI') snap_time
    , d.active_role
    , nvl(tlob.target_lob,'noLOB') as target_lob
    , nvl(tlcs.target_lcs,'noLCS') as target_lcs
-- DB Time
    , d.db_max_tot_dbTime_ps
    , d.db_avg_tot_dbTime_ps
-- CPU
    , d.db_max_tot_core_ps
    , d.db_avg_tot_core_ps
-- memory
    , pga_avg_allocated_bytes
    , pga_max_allocated_bytes
    , memory_avg_usage_bytes
    , memory_max_usage_bytes
    , streams_pool_avg_bytes
    , streams_pool_max_bytes
    , sga_total_pool_avg_bytes
    , sga_total_pool_max_bytes
    , other_sga_memory_avg_bytes
    , other_sga_memory_max_bytes
    , pga_total_avg_bytes
    , pga_total_max_bytes
    , large_pool_avg_bytes
    , large_pool_max_bytes
    , fixed_sga_avg_bytes
    , fixed_sga_max_bytes
    , java_pool_avg_bytes
    , java_pool_max_bytes
    , shared_pool_avg_bytes
    , shared_pool_max_bytes
    , buffer_cache_avg_bytes
    , buffer_cache_max_bytes
    , log_buffer_avg_bytes
    , log_buffer_max_bytes
-- top activity
    , d.aas_avg_ps
    , d.aas_max_ps
    , d.user_avg_cpu_cnt
    , d.user_max_cpu_cnt
    , d.userio_avg_wait_cnt
    , d.userio_max_wait_cnt
    , d.other_avg_wait_cnt
    , d.other_max_wait_cnt
-- top activity by wait class
    , d.db_max_tot_dbTime_ps * d.admin_max_waitclass_pct admin_max_waitclass_ps
    , d.db_avg_tot_dbTime_ps * admin_avg_waitclass_pct admin_avg_waitclass_ps
    , d.db_max_tot_dbTime_ps * application_max_waitclass_pct application_max_waitclass_ps
    , d.db_avg_tot_dbTime_ps * application_avg_waitclass_pct application_avg_waitclass_ps
    , d.db_max_tot_dbTime_ps * cluster_max_waitclass_pct cluster_max_waitclass_ps
    , d.db_avg_tot_dbTime_ps * cluster_avg_waitclass_pct cluster_avg_waitclass_ps
    , d.db_max_tot_dbTime_ps * commit_max_waitclass_pct commit_max_waitclass_ps
    , d.db_avg_tot_dbTime_ps * commit_avg_waitclass_pct commit_avg_waitclass_ps
    , d.db_max_tot_dbTime_ps * concurrency_max_waitclass_pct concurrency_max_waitclass_ps
    , d.db_avg_tot_dbTime_ps * concurrency_avg_waitclass_pct concurrency_avg_waitclass_ps
    , d.db_max_tot_dbTime_ps * configuration_max_waitclass_pct configuration_max_waitclass_ps
    , d.db_avg_tot_dbTime_ps * configuration_avg_waitclass_pct configuration_avg_waitclass_ps
    , d.db_max_tot_dbTime_ps * Idle_max_waitclass_pct Idle_max_waitclass_ps
    , d.db_avg_tot_dbTime_ps * Idle_avg_waitclass_pct Idle_avg_waitclass_ps
    , d.db_max_tot_dbTime_ps * network_max_waitclass_pct network_max_waitclass_ps
    , d.db_avg_tot_dbTime_ps * network_avg_waitclass_pct network_avg_waitclass_ps
    , d.db_max_tot_dbTime_ps * other_max_waitclass_pct other_max_waitclass_ps
    , d.db_avg_tot_dbTime_ps * other_avg_waitclass_pct other_avg_waitclass_ps
    , d.db_max_tot_dbTime_ps * queueing_max_waitclass_pct queueing_max_waitclass_ps
    , d.db_avg_tot_dbTime_ps * queueing_avg_waitclass_pct queueing_avg_waitclass_ps
    , d.db_max_tot_dbTime_ps * scheduler_max_waitclass_pct scheduler_max_waitclass_ps
    , d.db_avg_tot_dbTime_ps * scheduler_avg_waitclass_pct scheduler_avg_waitclass_ps
    , d.db_max_tot_dbTime_ps * systemIO_max_waitclass_pct systemIO_max_waitclass_ps
    , d.db_avg_tot_dbTime_ps * systemIO_avg_waitclass_pct systemIO_avg_waitclass_ps
    , d.db_max_tot_dbTime_ps * userIO_max_waitclass_pct userIO_max_waitclass_ps
    , d.db_avg_tot_dbTime_ps * userIO_avg_waitclass_pct userIO_avg_waitclass_ps
-- executions_ps
    , d.execs_avg_ps
    , d.execs_max_ps   
-- iorequests_ps
    , d.iops_avg_ioreq_ps
    , d.iops_max_ioreq_ps   
-- iombs_ps
    , d.io_bytes_avg_ioreq_ps
    , d.io_bytes_max_ioreq_ps
-- iotypes
    , d.physreads_avg_ps
    , d.physreads_max_ps
    , d.physreadsdir_avg_ps
    , d.physreadsdir_max_ps
    , d.physreadslob_avg_ps
    , d.physreadslob_max_ps
    , d.physwrites_avg_ps
    , d.physwrites_max_ps
    , d.physwritesdir_avg_ps
    , d.physwritesdir_max_ps
    , d.physwriteslob_avg_ps
    , d.physwriteslob_max_ps
-- latency
    , d.sb_read_avg_latency_ms
    , d.sb_read_max_latency_ms
    , d.userio_max_latency_ms
    , d.userio_avg_latency_ms
-- idx_vs_table
    , d.indxscanstotal_avg_ps
    , d.indxscanstotal_max_ps
    , d.tabscanstotal_avg_ps
    , d.tabscanstotal_max_ps
-- logons_ps
    , d.logons_avg_ps
    , d.logons_max_ps   
-- redosize_ps
    , d.redosize_bytes_avg_ps
    , d.redosize_bytes_avg_ps*24*60*60 as redosize_bytes_avg_pd
    , d.redosize_bytes_max_ps
-- commit
    , commits_avg_ps
    , commits_max_ps
-- usercalls_ps
    , d.usercalls_avg_ps
    , d.usercalls_max_ps   
-- parses
    , d.parses_avg_ps
    , d.parses_max_ps
    , d.hard_parses_avg_ps
    , d.hard_parses_max_ps
-- RMAN
    , rmanCpuTime_max_ps
    , rmanCpuTime_avg_ps
--sessions
    , sess_max_pct
    , sess_avg_pct
-- database size
    , d.allocated_avg_bytes
    , d.allocated_max_bytes
    , d.used_avg_bytes
    , d.used_max_bytes
    , d.archTotal_bytes
    , d.archAvail_bytes
    , d.archUsed_bytes  
from
	db_metrics d 
    left outer join sysman.MGMT$DB_DBNINSTANCEINFO ii on d.target_guid = ii.target_guid 
    left outer join target_lob tlob on d.target_guid = tlob.target_guid 
    left outer join target_lcs tlcs on d.target_guid = tlcs.target_guid
    left outer join si_db_gi sig on d.target_name = sig.target_name
    left outer join db_gi_frame gif on d.target_name = gif.rac_db_name and d.target_type = gif.db_tgt_type
    left outer join inst_rac_gi_frame igif on d.target_name = igif.db_inst_name and d.target_type = igif.inst_tgt_type
where
    1=1
--    and ii.database_name is null
--    and active_role = 'PRIMARY'
--    and d.snap_time = '2022-03-01'
--    and d.target_name like 'MP1%'
--    and d.target_name not in ('EMDB')
order by 
      nvl(ii.database_name,d.target_name)
    , ii.target_name
	, d.target_name
    , d.snap_time
    , d.active_role
    , tlob.target_lob
    , tlcs.target_lcs
;
