-- =====================================================================
-- PASO 8 · Trigger y procedimiento (PostgreSQL)
-- Equivalente de sqlserver/08_trigger_y_procedimiento.sql
-- =====================================================================

-- 8.1 Trigger BEFORE: corrige la fila ANTES de guardarla, así el CHECK
--     ck_tarea_completada se puede quedar (en SQL Server hubo que quitarlo,
--     porque allá no existe BEFORE).
CREATE OR REPLACE FUNCTION trg_tarea_fecha_completada()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.completada THEN
        NEW.fechaCompletada := COALESCE(NEW.fechaCompletada, now());
    ELSE
        NEW.fechaCompletada := NULL;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_tarea_fecha_completada ON Tarea;
CREATE TRIGGER tr_tarea_fecha_completada
BEFORE INSERT OR UPDATE OF completada ON Tarea
FOR EACH ROW
EXECUTE FUNCTION trg_tarea_fecha_completada();

BEGIN;
    UPDATE Tarea SET completada = TRUE WHERE idTarea IN (6, 10);     -- sin mandar la fecha
    SELECT idTarea, completada, fechaCompletada IS NOT NULL AS tiene_fecha FROM Tarea WHERE idTarea IN (6, 10);
    UPDATE Tarea SET completada = FALSE WHERE idTarea = 6;
    SELECT idTarea, completada, fechaCompletada FROM Tarea WHERE idTarea = 6;
ROLLBACK;

-- 8.2 Crear una tarea con etiquetas (las nuevas se crean).
--     Es una FUNCTION porque devuelve el id (T-SQL: PROCEDURE con parámetro OUTPUT).
CREATE OR REPLACE FUNCTION fn_crear_tarea(
    p_idLista     INT,
    p_nombre      VARCHAR,
    p_prioridad   SMALLINT DEFAULT 2,
    p_fechaLimite DATE     DEFAULT NULL,
    p_etiquetas   TEXT     DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_idTarea INT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Lista WHERE idLista = p_idLista) THEN
        RAISE EXCEPTION 'La lista no existe.';
    END IF;

    INSERT INTO Tarea (idLista, nombre, prioridad, fechaLimite)
    VALUES (p_idLista, p_nombre, p_prioridad, p_fechaLimite)
    RETURNING idTarea INTO v_idTarea;

    -- texto -> filas  (T-SQL: STRING_SPLIT)
    INSERT INTO Etiqueta (nombre)
    SELECT DISTINCT lower(trim(x))
    FROM unnest(string_to_array(COALESCE(p_etiquetas, ''), ',')) AS x
    WHERE trim(x) <> ''
    ON CONFLICT (nombre) DO NOTHING;                        -- las que ya existen se ignoran

    INSERT INTO TareaEtiqueta (idTarea, idEtiqueta)
    SELECT DISTINCT v_idTarea, e.idEtiqueta
    FROM unnest(string_to_array(COALESCE(p_etiquetas, ''), ',')) AS x
    JOIN Etiqueta e ON e.nombre = lower(trim(x));

    RETURN v_idTarea;
END;
$$;

BEGIN;
    SELECT fn_crear_tarea(1, 'Estudiar triggers', 1::smallint, '2026-11-29', 'estudio, SQL ,urgente,') AS idNueva;

    -- en otra sentencia: una consulta no "ve" las filas que inserta una función llamada dentro de ella
    SELECT t.idTarea, t.nombre, STRING_AGG(e.nombre, ', ') AS etiquetas
    FROM Tarea t
    JOIN TareaEtiqueta te ON te.idTarea = t.idTarea
    JOIN Etiqueta e       ON e.idEtiqueta = te.idEtiqueta
    WHERE t.nombre = 'Estudiar triggers'
    GROUP BY t.idTarea;                       -- 3 etiquetas; 'sql' se creó nueva
ROLLBACK;
