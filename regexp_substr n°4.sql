-- https://community.oracle.com/tech/developers/discussion/4508090/how-to-convert-comma-seperated-values-from-multiple-colums#latest

-- results
with example(ITEM_NO, QTY, Price) as (
    select '77,78,361,362,366', '43,43,44,33,26', '86,43,8800,8250,5096' from dual
)
select * from example;
ITEM_NO                             QTY                                 PRICE
----------------------------------- ----------------------------------- -----------------------------------
77,78,361,362,366                   43,43,44,33,26                      86,43,8800,8250,5096


-- expected output
ITEM_NO QTY price
77 		43 	86
78 		43 	43
361 	44 	8800
362 	33 	8250
366 	26 	5096

-- premier jet comme cela

with example(ITEM_NO, QTY, Price) as (
    select '77,78,361,362,366', '43,43,44,33,26', '86,43,8800,8250,5096' from dual
)
select 
    regexp_substr(ITEM_NO, '[^,]+',1,1) item_no
   ,regexp_substr(QTY, '[^,]+',1,1)     item_no
   ,regexp_substr(Price, '[^,]+',1,1)   item_no
 from 
   example;
ITEM_NO                             ITEM_NO                             ITEM_NO
----------------------------------- ----------------------------------- ---------
77                                  43                                  86

-- par contre il faut faire cela pour tout le reste
-- du coup il faut passer à l'utilisation du level
-- le level doit être égal au nombre de virgule + 1: regexp_count(item_no, ',') + 1

-- results
with example(ITEM_NO, QTY, Price) as (
    select '77,78,361,362,366', '43,43,44,33,26', '86,43,8800,8250,5096' from dual
)
select
    level lvl,
    regexp_substr (ITEM_NO,'[^,]+', 1, level ) ITEM_NO,
    regexp_substr (QTY,'[^,]+', 1, level ) QTY,
    regexp_substr (Price,'[^,]+', 1, level ) Price
from 
  example 
connect by level <= regexp_count(ITEM_NO,',') + 1;

       LVL ITEM_NO   QTY        PRICE
---------- --------- ---------- ----------
         1 77        43         86         -- on prend la première occurence avant la virgule pour chaque element
         2 78        43         43         -- on prend la 2ème occurence avant la virgule pour chaque element
         3 361       44         8800       -- on prend la 3ème occurence avant la virgule pour chaque element
         4 362       33         8250       -- on prend la 4ème occurence avant la virgule pour chaque element
         5 366       26         5096       -- on prend la 5ème occurence avant la virgule pour chaque element
		 
-- Mais attention : ici nous avons pris le nombre de virgule contenu dans le champs item_no = 4
-- il se trouve que le nombre de virgule dans qty et dans price est aussi égal à 4
-- que se passe t-il se ce n'est pas le cas?

with example(FLAG,ITEM_NO, QTY, Price)
  as (
      select 'same number of elements','77,78,361,362,366', '43,43,44,33,26', '86,43,8800,8250,5096' from dual union all
      select 'different number of elements','1,2,3,4,5','1,2,3','1,2,3,4' from dual
     )
select  flag,
        regexp_substr(ITEM_NO,'[^,]+',1,lvl) ITEM_NO,
        regexp_substr(QTY,'[^,]+',1,lvl) QTY,
        regexp_substr(Price,'[^,]+',1,lvl) Price
from  
   example,
        lateral(
                select  level lvl
                  from  dual
                  connect by level <= greatest(
                                               regexp_count(ITEM_NO,','),
                                               regexp_count(QTY,','),
                                               regexp_count(PRICE,',')
                                              ) + 1
               )
;