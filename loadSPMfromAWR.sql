/* --|-------------------------------------------------------------------------|
   --| Author 		: Mohamed Houri                                          --|
   --| Date   		: 08/06/2022                                             --|
   --| inspired by  : Carlos Sierra create_spb_from_awr.sq script            --|
   --| Scope        : Create a SPM baseline from a historical execution plan --|
   --| Usage        : @loadSPMfromAWR                                        --|
   --| Remarks      : the begin and end snap must be different               --|
   --|              : the plan hash value must be present in the end snap    --|
   --|              : for example if you are in the following case           --|
   --|                                                                       --|
   --|				SQL> @loadSPMAWR                                         --|
   --|				Enter sql_id: b64jvr5722ujx                              --|
   --|				                                                         --|
   --|				PLAN_HASH_VALUE AVG_ET_SECS EXECUTIONS_TOTAL             --|
   --|				--------------- ----------- ----------------             --|
   --|					1362763525   17.825681                1              --|
   --|					1518369540                                           --|
   --|				                                                         --|
   --|				Enter Plan Hash Value: 1362763525                        --|
   --|				                                                         --|
   --|				BEGIN_SNAP_ID END_SNAP_ID                                --|
   --|				------------- -----------                                --|
   --|						692         692                                  --|
   --|				                                                         --|
   --|				Enter begin snap: 691 spot this                          --|
   --|				Enter end   snap: 692                                    --|
   --|				                                                         --|
   --|				PL/SQL procedure successfully completed.                 --|
   --|				                                                         --|
   --|						RS                                               --|
   --|				----------                                               --|
   --|						1                                                --|
     --|-----------------------------------------------------------------------| */

acc sql_id prompt 'Enter sql_id: ';

with p as 
  (SELECT 
     plan_hash_value
   FROM 
     dba_hist_sql_plan
   WHERE 
       sql_id = trim('&&sql_id.')
   AND other_xml IS NOT NULL )
,a as 
  (SELECT 
      plan_hash_value
	 ,SUM(elapsed_time_total)/SUM(executions_total) avg_et_secs
	 ,MAX(executions_total) executions_total
   FROM 
      dba_hist_sqlstat
   WHERE 
      sql_id = TRIM('&&sql_id.')
   AND executions_total > 0
   GROUP BY
       plan_hash_value
  )
SELECT 
   p.plan_hash_value
  ,ROUND(a.avg_et_secs/1e6, 6) avg_et_secs
  ,a.executions_total
FROM 
    p,a
WHERE 
  p.plan_hash_value = a.plan_hash_value(+)
ORDER BY
   avg_et_secs NULLS LAST;

acc plan_hash_value prompt 'Enter Plan Hash Value: ';

COL dbid new_v dbid NOPRI;
SELECT dbid FROM v$database;

col begin_snap_id new_v begin_snap_id;
col end_snap_id   new_v end_snap_id;

SELECT 
     MIN(p.snap_id) begin_snap_id
    ,MAX(p.snap_id) end_snap_id
FROM 
   dba_hist_sqlstat p
  ,dba_hist_snapshot s
 WHERE 
       p.dbid = &&dbid
   AND p.sql_id = '&&sql_id.'
   AND p.plan_hash_value = to_number('&&plan_hash_value.')
   AND s.snap_id = p.snap_id
   AND s.dbid = p.dbid
   AND s.instance_number = p.instance_number;

acc begin_snap_id prompt 'Enter begin snap: ';
acc end_snap_id prompt   'Enter end   snap: ';

var rs number;

begin
  :rs := dbms_spm.load_plans_from_awr(begin_snap   => &&begin_snap_id.
                                     ,end_snap     => &&end_snap_id.
                                     ,basic_filter => q'# sql_id = TRIM('&&sql_id.') and plan_hash_value = TO_NUMBER('&&plan_hash_value.') #');
end;
/

print rs;
                                                                         