-- Instala (o reinstala desde cero) la base de práctica.
-- Uso:  psql -d dbventa -f postgresql/00_base_de_datos/instalar.sql
\set ON_ERROR_STOP on
\ir 01_esquema.sql
\ir 02_datos.sql
\echo 'Base DBVENTA lista.'
