-- taken from : https://www.developpez.net/forums/d2131641/bases-donnees/oracle/sql/separer-champ-texte-lignes/

create table demo (text varchar2(100));

insert into demo values ('54668107$001/190');
insert into demo values ('54668108$002/190');
insert into demo values ('54668109$003/290');
insert into demo values ('54668110$004/110');
insert into demo values ('54668111$005/190');
insert into demo values ('54668112$006/190');
insert into demo values ('54668113$007/190');

commit;

select * from demo;

TEXT
----------------------
54668107$001/190
54668108$002/190
54668109$003/290
54668110$004/110
54668111$005/190
54668112$006/190
54668113$007/190

7 rows selected.

-- Expected output

TEXT
------------ -----
54668107$001 190
54668108$002 190
54668109$003 290
54668110$004 110
54668111$005 190
54668112$006 190
54668113$007 190

7 rows selected.

-- Result

col val0 for a25
col val1 for a25
col val2 for a25
select 
     text                            val0
   , regexp_substr(text,'[^/]+',1,1) val1  -- find the first / in text and substr from position 1 up to /
   , regexp_substr(text,'[^/]+',1,2) val2  -- find the first / in text and substr from the position of this / up to the end (second mach)
from demo;

VAL0                      VAL1                      VAL2
------------------------- ------------------------- --------
54668107$001/190          54668107$001              190
54668108$002/190          54668108$002              190
54668109$003/290          54668109$003              290
54668110$004/110          54668110$004              110
54668111$005/190          54668111$005              190
54668112$006/190          54668112$006              190
54668113$007/190          54668113$007              190

7 rows selected.

