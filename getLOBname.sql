--******************************************************************
-- |Name   : getLOBname                                            |
-- |Date   : 08 2022                                               |
-- |Author : Mohamed Houri                                         |
-- |                              			                       |
--******************************************************************

col owner for a30
col table_name for a30
col segment_type for a30
col segment_name for a30

SELECT
   a.owner 
  ,b.table_name 
  ,a.segment_type
  ,a.segment_name 
FROM
  dba_segments a
 ,dba_lobs     b
WHERE
  a.owner          = b.owner
AND a.segment_name = b.segment_name
AND a.segment_name ='&lob_seg_name'
AND a.segment_type like '%LOB%';
;