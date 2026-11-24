-- =====================================================================
-- PASO 1 · La versión original (PostgreSQL)
-- Equivalente del script original (antes Query.txt). Antes de correrlo:
--     createdb dbtareas
--     psql -d dbtareas -f postgresql/01_version_original.sql
-- =====================================================================

DROP TABLE IF EXISTS UsuarioCredencial, ListaCompartida, TareaEtiqueta, Etiqueta, Tarea, Lista, Usuario CASCADE;

CREATE TABLE Tarea (
    idTarea INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,   -- T-SQL: INT PRIMARY KEY IDENTITY
    nombre  VARCHAR(40)
);

INSERT INTO Tarea (nombre) VALUES
('Aprender Angular'),
('Aprender Blazor');

SELECT * FROM Tarea;
