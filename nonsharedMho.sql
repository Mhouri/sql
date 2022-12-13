select
   	 sh.sql_id,
   	 xt.c1,
   	 xt.r1 raison,
   	 xt.d1
   from
     gv$sql_shared_cursor sh
     inner join xmltable (
        '/ChildNode'
        passing xmlparse(content sh.reason)
        columns
            c1 number       path 'ChildNumber',
            r1 varchar2(40) path 'reason',
            d1 varchar2(40) path 'details'
    )
    xt on ( 1 = 1 )
  where
    sh.sql_id = '&sql_id';
