-- Enabling constraint using parallelism
--Mhouri
alter table table_name add constraint constraint_name primary key (col1, col2, col3)
using index
enable novalidate;

alter session force parallel ddl;
alter table table_name parallel 8;
alter table table_name modify constraint constraint_name validate;
alter table table_name noparallel;
alter session disable parallel ddl;