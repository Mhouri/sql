col high_value for a34
col partition_name for a35
col OWNER format a20
col index_name format a30
col SUBPARTITION_NAME format a20
col sizeM for 9999999999 head "Size (M)"

set feed off

define owner=&1
define table_name=&2

clear break


select owner,segment_type,segment_name,tablespace_name,round(sum(bytes)/1024/1024,2) sizeM from dba_segments where owner=upper('&owner') and segment_name=upper('&table_name')
group by owner,segment_type,segment_name,tablespace_name;

select owner,segment_type,tablespace_name,round(sum(bytes/1024/1024),2) sizeM from dba_segments where 
(owner,segment_name) in ( select owner,segment_name from dba_lobs where owner=upper('&owner') and table_name=upper('&table_name')
		  union
		  select owner,index_name from dba_lobs where owner=upper('&owner') and table_name=upper('&table_name')
		)
group by owner,segment_type,owner,tablespace_name
/


set feed on
select 	sz.owner,
	sz.partition_name,
	part.high_value,
	sz.lob_partition_name,
	sz.segment_type,
	sz.sizeM
from
(
select owner,b.table_name,b.partition_name,b.LOB_PARTITION_NAME,segment_type,bytes/1024/1024 sizeM from dba_segments s , dba_lob_partitions b
where
(owner,segment_name) in ( select owner,segment_name from dba_lobs where owner=upper('&owner') and table_name=upper('&table_name')
                  union
                  select owner,index_name from dba_lobs where owner=upper('&owner') and table_name=upper('&table_name')
                )
and s.owner=b.table_owner
--and s.segment_name=b.table_name
and s.partition_name=b.LOB_PARTITION_NAME
) sz, dba_tab_partitions part
where 	sz.owner=part.table_owner (+) and
        sz.table_name = part.table_name and
	sz.partition_name = part.partition_name (+)	
order by 2
--/

select owner,PARTITION_NAME,segment_type,tablespace_name, round(bytes/1024/1024,2) sizeM
from dba_segments
where
(owner,segment_name) in
 ( select owner,segment_name from dba_lobs where owner=upper('&owner') and table_name=upper('&table_name')
  union
 select owner,index_name from dba_lobs where owner=upper('&owner') and table_name=upper('&table_name')
 )
order by 5
/



compute sum label "Tot: " of sizeM on   partition_name
compute sum label "G Tot: " of sizeM on report

break on report on owner on segment_type on  partition_name skip 1

prompt --subpartitions
with seg as
(
select
        s.owner,
        s.segment_type,
        s.partition_name,
        round(sum(s.bytes)/1024/1024,2) sizeM
from dba_segments s
where s.owner=upper('&owner') and s.segment_name=upper('&table_name')
group by s.owner, s.segment_type,s.partition_name, s.tablespace_name
)
,
part as
(
select  table_owner,
        table_name,
        partition_name,
        subpartition_name
from
dba_tab_subpartitions where table_owner=upper('&owner') and table_name=upper('&table_name')
)
select
        seg.owner,
        seg.segment_type,
        part.partition_name,
        part.subpartition_name,
        sizeM
from seg, part
where
seg.owner       = part.table_owner and
seg.partition_name=part.subpartition_name
order by 1,2,3,5
/

break on report

prompt --partitions
with seg as
(
select
        s.owner,
        s.segment_type,
        s.partition_name,
        round(sum(s.bytes)/1024/1024,2) sizeM
from dba_segments s
where s.owner=upper('&owner') and s.segment_name=upper('&table_name')
group by s.owner, s.segment_type,s.partition_name, s.tablespace_name
)
,
part as
(
select  table_owner,
        table_name,
        partition_name
from
dba_tab_partitions where table_owner=upper('&owner') and table_name=upper('&table_name')
)
select
        seg.owner,
        seg.segment_type,
        part.partition_name,
        sizeM
from seg, part
where
seg.owner       = part.table_owner and
seg.partition_name=part.partition_name
order by 1,2,4
/


select 	s.owner,
	s.segment_name index_name,
	ceil(sum(bytes)/1024/1024) sizeM
from dba_segments s
where (s.owner,s.segment_name) in (select owner,index_name from dba_indexes where owner=upper('&owner') and table_name=upper('&table_name'))
and s.segment_type like  'INDEX%'
group by s.owner,s.segment_name
/


prompt -- cas IOT
/*
select OWNER,SEGMENT_TYPE,segment_name,partition_name,round(bytes/1024/1024) sizeM
from 
	dba_segments where 
	owner=upper('&owner') and 
	segment_name=(
			case 
			when (select IOT_TYPE from dba_tables where owner=upper('&owner') and table_name=upper('&table_name'))='IOT' then 
				(select index_name from dba_indexes where table_name=upper('&table_name') and owner=upper('&owner') and   index_type='IOT - TOP')
			else segment_name
			end
		    )
/
*/
