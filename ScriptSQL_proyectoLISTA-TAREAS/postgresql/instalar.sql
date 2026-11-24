-- Construye la base de la lista de tareas en PostgreSQL (pasos 1 a 5).
-- Uso: psql -d dbangular -f ScriptSQL_proyectoLISTA-TAREAS/postgresql/instalar.sql
\set ON_ERROR_STOP on
\ir 01_version_original.sql
\ir 02_mejorar_tarea.sql
\ir 03_usuarios_y_listas.sql
\ir 04_etiquetas.sql
\ir 05_datos.sql
\echo 'DBAngular lista.'
