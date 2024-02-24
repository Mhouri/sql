-- get all necassry information about
   -- whether I am on a CDB or PDB
   -- the con_id number
   -- open mode
   -- connexion name
col name for a30
col restricted for a10
show con_name

select con_id, name, open_mode, restricted from v$containers;