-- Voila comment ca fonctionne
-- quand on créé un objet et on le supprime le max(obj#) de sys.obj$ ne bouge pas 
-- mais la sequence qui a créé cet objet  augmente si bien que lorsqu'on créé un nouvel objet sans le dropper
-- il va prendre la valeur de la sequence 
	
-- create tables
 DECLARE
   v_stmtc        varchar2(100);
   v_stmtd        varchar2(100);
   nbr_obj        number;
   next_obj       number;
   nbr_obj_reuse  number;
 BEGIN
   v_stmtc := 'create table t_';
   for j in 1..1000 loop
   v_stmtc := 'create table t_'||j||'(id number)';
   v_stmtd := 'drop table t_'||j;
  -- dbms_output.put_line (v_stmtc);
  -- dbms_output.put_line (v_stmtd);
   execute immediate v_stmtc;
   v_stmtc := null;
   execute immediate v_stmtd;
   v_stmtd := null;
   end loop;
   select max(obj#) into nbr_obj from sys.obj$; 
   select dataobj#  into next_obj from sys.obj$ where name='_NEXT_OBJECT';
   select count(*) into nbr_obj_reuse from sys.objnum_reuse;
   dbms_output.put_line('nbr_obj from sys.obj$          => '||nbr_obj);
   dbms_output.put_line('next_obj_seq from _next_object => '||next_obj);
   dbms_output.put_line('nbr of obj to be reused        => '||nbr_obj_reuse);
 END;
 /
 
nbr_obj from sys.obj$          => 156468 --> bouge pas
next_obj_seq from _next_object => 156502 --> + 10
nbr of obj to be reused        => 36089  --> + 10

PL/SQL procedure successfully completed.

SQL> /
nbr_obj from sys.obj$          => 156468 --> bouge pas
next_obj_seq from _next_object => 156512 --> + 10
nbr of obj  to be reused       => 36099  --> + 10

PL/SQL procedure successfully completed.

SQL> /
nbr_obj from sys.obj$          => 156468 --> bouge pas
next_obj_seq from _next_object => 156522 --> + 10
nbr of obj  to be reused       => 36109  --> + 10

PL/SQL procedure successfully completed.
   
 -- create job
 DECLARE
   v_job_name     varchar2(100);
   v_stmtd        varchar2(100);
   nbr_obj        number;
   next_obj       number;
   nbr_obj_reuse  number;
 BEGIN
  for j in 1..10 loop
	v_job_name := 'test_job_'||j;
	dbms_scheduler.create_job(
							job_name => v_job_name,
							job_type => 'stored_procedure',
							job_action => 'job_test',
							start_date => SYSTIMESTAMP,
							enabled => true,
							repeat_interval => 'FREQ=MINUTELY;INTERVAL=5',
							auto_drop => false,
							comments => 'Inserts new records' 
							);
	dbms_scheduler.drop_job(job_name => v_job_name);
	v_job_name := null;				   
  end loop;		
   select max(obj#) into nbr_obj from sys.obj$; 
   select dataobj#  into next_obj from sys.obj$ where name='_NEXT_OBJECT';
   select count(*)  into nbr_obj_reuse from sys.objnum_reuse;
   
   dbms_output.put_line('nbr_obj from sys.obj$          => '||nbr_obj);
   dbms_output.put_line('next_obj_seq from _next_object => '||next_obj);
   dbms_output.put_line('nbr of obj to be reused        => '||nbr_obj_reuse);
   
END;
/

nbr_obj from sys.obj$          => 156468  --> bouge pas
next_obj_seq from _next_object => 156532 --> + 10
nbr of obj to be reused        => 36109

PL/SQL procedure successfully completed.

SQL> /
nbr_obj from sys.obj$          => 156468  --> bouge pas
next_obj_seq from _next_object => 156542  --> + 10
nbr of obj to be reused        => 36109 --> bouge pas ??? pas de recyclage pour les jobs?

PL/SQL procedure successfully completed.

SQL> /
nbr_obj from sys.obj$          => 156468  --> bouge pas
next_obj_seq from _next_object => 156552 --> + 10
nbr of obj to be reused        => 36109

PL/SQL procedure successfully completed.

-- en lancant create table par 10000

nbr_obj from sys.obj$          => 156468
next_obj_seq from _next_object => 157552
nbr of obj to be reused        => 37109

PL/SQL procedure successfully completed.

SQL> /
nbr_obj from sys.obj$          => 156468
next_obj_seq from _next_object => 158552 --> +1000
nbr of obj to be reused        => 38109 --> +1000

PL/SQL procedure successfully completed.

SQL> /
nbr_obj from sys.obj$          => 156468
next_obj_seq from _next_object => 159552 --> +1000
nbr of obj to be reused        => 39109 --> +1000

PL/SQL procedure successfully completed.