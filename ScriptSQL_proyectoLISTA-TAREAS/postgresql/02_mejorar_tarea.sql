-- =====================================================================
-- PASO 2 · Hacer crecer la tabla Tarea con ALTER TABLE (PostgreSQL)
-- =====================================================================

-- 2.1 Agregar columnas. Con NOT NULL + DEFAULT, las filas existentes reciben el valor por defecto.
ALTER TABLE Tarea
    ADD COLUMN descripcion     VARCHAR(300),
    ADD COLUMN completada      BOOLEAN   NOT NULL DEFAULT FALSE,   -- T-SQL: BIT NOT NULL DEFAULT 0
    ADD COLUMN prioridad       SMALLINT  NOT NULL DEFAULT 2,       -- T-SQL: TINYINT (PG no tiene TINYINT)
    ADD COLUMN fechaCreacion   TIMESTAMP NOT NULL DEFAULT now(),
    ADD COLUMN fechaLimite     DATE,
    ADD COLUMN fechaCompletada TIMESTAMP;
-- En T-SQL se escribe ADD una sola vez y las columnas separadas por coma; en PG cada una lleva ADD COLUMN.

-- 2.2 Reglas con CHECK
ALTER TABLE Tarea ADD CONSTRAINT ck_tarea_prioridad CHECK (prioridad BETWEEN 1 AND 3);
ALTER TABLE Tarea ADD CONSTRAINT ck_tarea_completada
    CHECK ((completada AND fechaCompletada IS NOT NULL) OR (NOT completada AND fechaCompletada IS NULL));

-- 2.3 Cambiar una columna existente (en PG el tipo y el NOT NULL se cambian por separado)
ALTER TABLE Tarea ALTER COLUMN nombre TYPE VARCHAR(100),          -- T-SQL: ALTER COLUMN nombre VARCHAR(100) NOT NULL
                  ALTER COLUMN nombre SET NOT NULL;

-- 2.4 Las 2 tareas originales siguen ahí
SELECT idTarea, nombre, completada, prioridad, fechaLimite FROM Tarea;

-- Estructura de la tabla: en psql escribe  \d tarea   (T-SQL: EXEC sp_help 'Tarea')
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'tarea'
ORDER BY ordinal_position;
