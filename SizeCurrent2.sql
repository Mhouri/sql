column  ts      format a35              heading 'TABLESPACE'
column  tst     format a9               heading 'STATUS'
column  vt      format 99999999990      heading 'TOTAL|SPACE|(GB)'
column  vo      format 99999999990      heading 'SPACE|USED|(GB)'
column  vr      format 99999999990      heading 'SPACE|REMAINED|(GB)'
column  tx      format 990              heading '%USED'

compute sum label 'Total tablespaces' of vt vo vr on report

break   on report


with got_my_max
as (select
   tablespace_name tbs,
   Bytes_G,
   maxbytes_G,
   to_max_G,
   case when maxbytes_G=0 then -1 else round((Bytes_G*100/maxbytes_G)) end  pct
from
    (
    select
          tablespace_name,
          round(sum(nvl(BYTES,0))/1024/1024/1024) Bytes_G,
          round(sum(nvl(MAXBYTES,0))/1024/1024/1024) maxbytes_G,
          round(sum(nvl(MAXBYTES-BYTES,0))/1024/1024/1024) to_max_G
  from (select 
          tablespace_name
         ,file_name,bytes
         ,case when nvl(maxbytes,0)=0 then bytes 
           else nvl(maxbytes,0) end MAXBYTES 
          from dba_data_files)
  group by tablespace_name
  )
  )
select  
    t.tablespace_name
   ||decode(t.contents,'TEMPORARY','  (TEMPORARY/'||b.file_type||')','')   ts,
   t.status                                                                tst,
   b.bytes/1024/1024/1024                                                  vt,
   b.bytes_used/1024/1024/1024                                             vo,
   b.bytes_free/1024/1024/1024                                             vr,
-- ceil(b.bytes_used*100/b.bytes)                                          tx,
   ceil(b.bytes_used*100/(b.bytes+(g.to_max_G*1024*1024*1024)))            tx,
   g.to_max_G                                                              to_max_G
from    (
        select  
           df.tablespace_name      tablespace_name,
           df.bytes                bytes,
           nvl(u.bytes_used,0)     bytes_used,
           nvl(f.bytes_free,0)     bytes_free,
          'DATAFILE'               file_type
        from   
           (select  
               tablespace_name,
               sum(bytes)       bytes
           from    
               dba_data_files
            group by 
              tablespace_name
            ) df,
            (select  
                 tablespace_name,
                 sum(bytes)      bytes_used
             from    
                 dba_segments
             group by 
                 tablespace_name
             ) u,
             (select  
                 tablespace_name,
                 sum(bytes)              bytes_free
              from    
                 dba_free_space
              group by 
                 tablespace_name
              ) f
        where   
           df.tablespace_name = u.tablespace_name (+)
        and
           df.tablespace_name = f.tablespace_name (+)
        ) b,
        dba_tablespaces         t,
        got_my_max         g
where   
   t.tablespace_name = b.tablespace_name
and g.tbs = b.tablespace_name
order   by tx desc, vo desc
;

