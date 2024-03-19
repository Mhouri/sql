-- cpulaod
SELECT 
    snap_begin,
    dbid,
    instance,     
    case
     when sum(case when name ='DB CPU' then round(valeur/1000000,1) else 0 end) >0 
     then sum(case when name ='DB CPU' then round(valeur/1000000,1) else 0 end)
     else 0 end "DB CPU",        
    case
    when sum(case when name ='DB time' then round(valeur/1000000,1) else 0 end) >0
    then sum(case when name ='DB time' then round(valeur/1000000,1) else 0 end)
    else 0 end "DB time",
    case
    when sum(case when name ='redo size' then round(valeur/power(1024,2),2) else 0 end) >0 
    then sum(case when name ='redo size' then round(valeur/power(1024,2),2) else 0 end)
    else 0 end "redo size(MB)", 
    case
    when sum(case when name ='session logical reads' then round(valeur,2) else 0 end)> 0 
    then sum(case when name ='session logical reads' then round(valeur,2) else 0 end)
    else 0 end "Logical reads(blocks)" ,
    case
    when sum(case when name ='db block changes' then round(valeur,2) else 0 end)>0  
    then sum(case when name ='db block changes' then round(valeur,2) else 0 end)
    else 0 end "Block changes" ,  
    case
    when sum(case when name ='physical reads' then round(valeur,2) else 0 end) > 0
    then sum(case when name ='physical reads' then round(valeur,2) else 0 end)
    else 0 end "Physical read (blocks)", 
    case
    when sum(case when name ='physical writes' then round(valeur,2) else 0 end) >0 
    then sum(case when name ='physical writes' then round(valeur,2) else 0 end) 
    else 0 end "physical writes",
    case
    when sum(case when name ='user calls' then valeur else 0 end) >0
    then sum(case when name ='user calls' then valeur else 0 end) 
    else 0 end "user calls", 
    case
    when sum(case when name ='parse count (total)' then valeur else 0 end) >0    
    then sum(case when name ='parse count (total)' then valeur else 0 end)
    else 0 end "parses", 
    case
    when sum(case when name ='parse count (hard)' then valeur else 0 end) >0
    then sum(case when name ='parse count (hard)' then valeur else 0 end) 
    else 0 end "hard parses", 
    case
   when sum(case when name ='execute count' then valeur else 0 end) > 0
    then sum(case when name ='execute count' then valeur else 0 end)
    else 0 end "execute count",
    case 
    when sum(case when name ='user commits' then valeur else 0 end) >0
    then sum(case when name ='user commits' then valeur else 0 end) 
    else 0 end "user commits",
      case
    when sum(case when name ='logons cumulative' then round(valeur *( temps*24*60*60) ) else 0 end) >0    
    then sum(case when name ='logons cumulative' then round(valeur * (temps*24*60*60) )else 0 end)
    else 0 end "logons cumulative", 
    case
    when sum(case when name ='user rollbacks' then valeur else 0 end) >0
    then sum(case when name ='user rollbacks' then valeur else 0 end) 
    else 0 end "user rollbacks" 
FROM
(
  SELECT 
       snap_begin
     , dbid
     , instance
     , name
      , temps
     , round(valeur/(temps*24*60*60), 2) valeur
  FROM
     (
           ( -- dba_hist_sysstat
            SELECT 
               sna.begin_interval_time snap_begin
              ,sna.dbid
              ,a.instance_number instance
              ,a.stat_name name
              ,(value - lag(value, 1) over(partition by stat_name,a.instance_number order by begin_interval_time)) valeur
              ,to_date(to_char(end_interval_time, 'ddmmyyyy hh24:mi:ss'), 'ddmmyyyy hh24:mi:ss')
                 - to_date(to_char(begin_interval_time, 'ddmmyyyy hh24:mi:ss'), 'ddmmyyyy hh24:mi:ss') temps  
            FROM
             dba_hist_sysstat a,
             dba_hist_snapshot sna
            WHERE
                a.snap_id  = sna.snap_id
            AND a.instance_number = sna.instance_number 
            AND a.stat_name in 
                        ('user commits'               
                        ,'user rollbacks'
                        ,'logons cumulative'
                        ,'logons current'            
                        ,'execute count'
                        ,'user calls'
                        ,'redo size'
                        ,'DB time'             
                        ,'parse count (total)'
                        ,'parse count (hard)'
                        ,'parse count (failures)'
                        ,'parse time cpu'
                        ,'parse time elapsed'
                        ,'session logical reads'
                        ,'db block changes'
                        ,'physical reads'
                        ,'physical writes'
                        )
            AND trunc(sna.begin_interval_time) >= trunc(sysdate)-30
        )
  UNION ALL
       (-- dba_hist_sys_time_model
          SELECT 
          sna.begin_interval_time snap_begin,
          sna.dbid,
          a.instance_number instance,
          a.stat_name name, 
          (value - lag(value, 1) over(partition by stat_name,a.instance_number order by begin_interval_time)) valeur,
          to_date(to_char(end_interval_time, 'ddmmyyyy hh24:mi:ss'), 'ddmmyyyy hh24:mi:ss') - to_date(to_char(begin_interval_time, 'ddmmyyyy hh24:mi:ss'), 'ddmmyyyy hh24:mi:ss') temps  
    FROM
        dba_hist_sys_time_model a,
        dba_hist_snapshot sna
    WHERE
         a.snap_id  = sna.snap_id
    AND  a.instance_number = sna.instance_number 
    --AND  a.stat_name in ('DB CPU')
    AND trunc(sna.begin_interval_time) >= trunc(sysdate)-30
        )
)
)
WHERE 
  valeur is not null
AND snap_begin >= to_date('01012022','ddmmyyyy')
GROUP BY 
   snap_begin
  ,instance
  ,dbid
ORDER BY 
  1 asc;
