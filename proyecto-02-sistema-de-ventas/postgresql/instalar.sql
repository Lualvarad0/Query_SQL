-- Instala la base del sistema de ventas en PostgreSQL (pasos 1 y 2).
-- Uso: psql -d dbventa_app -f proyecto-02-sistema-de-ventas/postgresql/instalar.sql
\set ON_ERROR_STOP on
\ir 01_crear_base_y_tablas.sql
\ir 02_datos.sql
\echo 'DBVENTA (proyecto) lista.'
