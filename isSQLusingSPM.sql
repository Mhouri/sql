--https://orastory.wordpress.com/2014/02/05/awr-was-a-baselined-plan-used/
with subq_mysql as
    (select sql_id
     ,      (select dbms_sqltune.sqltext_to_signature(ht.sql_text)
             from dual) sig
     from   dba_hist_sqltext       ht
     where  sql_id = '&sql_id')
    ,    subq_baselines as
    (select b.signature
     ,      b.plan_name
    ,      b.accepted
    ,      b.created
    ,      o.plan_id
    from   subq_mysql             ms
    ,      dba_sql_plan_baselines b
    ,      sys.sqlobj$            o
    where  b.signature   = ms.sig
    and    o.signature   = b.signature
    and    o.name        = b.plan_name)
   ,    subq_awr_plans as
   (select  sn.snap_id
    ,       to_char(sn.end_interval_time,'DD-MON-YYYY HH24:MI') dt
    ,       hs.sql_id
    ,       hs.plan_hash_value
    ,       t.phv2
    ,       ms.sig
    from    subq_mysql        ms
    ,       dba_hist_sqlstat  hs
    ,       dba_hist_snapshot sn
    ,       dba_hist_sql_plan hp
    ,       xmltable('for $i in /other_xml/info
                      where $i/@type eq "plan_hash_2"
                      return $i'
                     passing xmltype(hp.other_xml)
                     columns phv2 number path '/') t
    where   hs.sql_id          = ms.sql_id
    and     sn.snap_id         = hs.snap_id
    and     sn.instance_number = hs.instance_number
    and     hp.sql_id          = hs.sql_id
    and     hp.plan_hash_value = hs.plan_hash_value
    and     hp.other_xml      is not null)
   select awr.*
   ,       nvl((select max('Y')
                from   subq_baselines b
               where  b.signature = awr.sig
                and    b.accepted  = 'YES'),'N') does_baseline_exist
   ,      nvl2(b.plan_id,'Y','N') is_baselined_plan
   ,      to_char(b.created,'DD-MON-YYYY HH24:MI')  when_baseline_created
   from   subq_awr_plans awr
   ,      subq_baselines b
   where  b.signature (+) = awr.sig
   and    b.plan_id   (+) = awr.phv2
  order by awr.snap_id;
