-- =====================================================================
-- PASO 11 · Errores comunes: lo que NO se debe hacer (PostgreSQL)
-- Equivalente de sqlserver/11_errores_comunes.sql (allí está la explicación de cada caso).
--
-- Parte A: lo que la base RECHAZA. Cada intento va en un bloque DO con
--          EXCEPTION, así el archivo sigue y ves el error como NOTICE:
--              [SQLSTATE] mensaje
--          (T-SQL: BEGIN TRY ... BEGIN CATCH ... ERROR_NUMBER())
-- Parte B: lo que la base ACEPTA pero da un resultado equivocado.
-- Corre después de los pasos 1 a 10. No cambia ningún dato.
-- =====================================================================

-- ======================= PARTE A =====================================

-- A1. Tarea en una lista que no existe -> 23503 foreign_key_violation
DO $$ BEGIN
    INSERT INTO Tarea (idLista, nombre) VALUES (99, 'Tarea huérfana');
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A1 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A2. Borrar una lista que tiene tareas -> 23503
DO $$ BEGIN
    DELETE FROM Lista WHERE idLista = 1;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A2 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A3. Prioridad fuera de rango -> 23514 check_violation
DO $$ BEGIN
    UPDATE Tarea SET prioridad = 5 WHERE idTarea = 1;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A3 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A4. Tarea sin nombre -> 23502 not_null_violation
DO $$ BEGIN
    INSERT INTO Tarea (idLista, nombre) VALUES (1, NULL);
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A4 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A5. Etiqueta repetida -> 23505 unique_violation
DO $$ BEGIN
    INSERT INTO Etiqueta (nombre) VALUES ('urgente');
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A5 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A6. La misma etiqueta dos veces en una tarea -> 23505 (llave primaria compuesta)
DO $$ BEGIN
    INSERT INTO TareaEtiqueta (idTarea, idEtiqueta) VALUES (1, 1);
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A6 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A7. Nombre de 150 caracteres en un VARCHAR(100) -> 22001 string_data_right_truncation
DO $$ BEGIN
    INSERT INTO Tarea (idLista, nombre) VALUES (1, repeat('x', 150));
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A7 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A8. Fecha que no existe -> 22008 datetime_field_overflow
DO $$ BEGIN
    UPDATE Tarea SET fechaLimite = '2026-02-30' WHERE idTarea = 1;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A8 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A9. Subtarea colgada de una tarea de otra lista -> 23503 (FK compuesta fk_tarea_padre)
DO $$ BEGIN
    UPDATE Tarea SET idTareaPadre = 22 WHERE idTarea = 1;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A9 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A10. Una tarea subtarea de sí misma -> 23514
DO $$ BEGIN
    UPDATE Tarea SET idTareaPadre = 3 WHERE idTarea = 3;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A10 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A11. Escribir el id a mano en GENERATED ALWAYS -> 428C9
--      (si de verdad hace falta: INSERT ... OVERRIDING SYSTEM VALUE; T-SQL: SET IDENTITY_INSERT ON)
DO $$ BEGIN
    INSERT INTO Etiqueta (idEtiqueta, nombre) VALUES (100, 'inventada');
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A11 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A12. Columna NOT NULL sin DEFAULT en una tabla con filas -> 23502
DO $$ BEGIN
    ALTER TABLE Tarea ADD COLUMN responsable VARCHAR(100) NOT NULL;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A12 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A13. Borrar una tabla de la que dependen otras -> 2BP01 dependent_objects_still_exist
--      (DROP TABLE ... CASCADE la borraría junto con las FK que apuntan a ella: ¡cuidado!)
DO $$ BEGIN
    DROP TABLE Etiqueta;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A13 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A14. División entre cero (lista vacía) -> 22012 division_by_zero
DO $$ BEGIN
    PERFORM 100 * COUNT(*) FILTER (WHERE t.completada) / COUNT(t.idTarea)
    FROM Lista l LEFT JOIN Tarea t ON t.idLista = l.idLista
    GROUP BY l.idLista;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A14 -> [%] %', SQLSTATE, SQLERRM;
END $$;
-- Bien: ... / NULLIF(COUNT(t.idTarea), 0)

-- ======================= PARTE B =====================================

-- B1. "= NULL" nunca es verdadero
SELECT 'B1 mal'  AS caso, COUNT(*) AS sin_fecha FROM Tarea WHERE fechaLimite = NULL;    -- 0
SELECT 'B1 bien' AS caso, COUNT(*) AS sin_fecha FROM Tarea WHERE fechaLimite IS NULL;   -- 4

-- B2. NOT IN con NULL en la subconsulta
SELECT 'B2 mal' AS caso, COUNT(*) AS tareas
FROM Tarea WHERE idTarea NOT IN (SELECT idTareaPadre FROM Tarea);                       -- 0
SELECT 'B2 bien' AS caso, COUNT(*) AS tareas
FROM Tarea t WHERE NOT EXISTS (SELECT 1 FROM Tarea h WHERE h.idTareaPadre = t.idTarea); -- 23

-- B3. COUNT(*) en un LEFT JOIN cuenta la fila vacía
SELECT 'B3 mal' AS caso, l.nombre, COUNT(*) AS tareas
FROM Lista l LEFT JOIN Tarea t ON t.idLista = l.idLista
WHERE l.idLista = 6 GROUP BY l.nombre;                                                   -- 1
SELECT 'B3 bien' AS caso, l.nombre, COUNT(t.idTarea) AS tareas
FROM Lista l LEFT JOIN Tarea t ON t.idLista = l.idLista
WHERE l.idLista = 6 GROUP BY l.nombre;                                                   -- 0

-- B4. Filtro de la tabla derecha en el WHERE: el LEFT JOIN se vuelve INNER
SELECT 'B4 mal' AS caso, COUNT(DISTINCT l.idLista) AS listas
FROM Lista l LEFT JOIN Tarea t ON t.idLista = l.idLista
WHERE t.prioridad = 1;                                                                    -- 4
SELECT 'B4 bien' AS caso, COUNT(DISTINCT l.idLista) AS listas
FROM Lista l LEFT JOIN Tarea t ON t.idLista = l.idLista AND t.prioridad = 1;            -- 6

-- B5. Producto cartesiano
SELECT 'B5 mal' AS caso, COUNT(*) AS filas FROM Usuario u CROSS JOIN Tarea t;            -- 100
SELECT 'B5 bien' AS caso, COUNT(*) AS filas
FROM Usuario u
JOIN Lista l ON l.idUsuario = u.idUsuario
JOIN Tarea t ON t.idLista = l.idLista;                                                    -- 25

-- B6. División entera
SELECT 'B6' AS caso,
       COUNT(*) FILTER (WHERE completada) / COUNT(*)         AS mal,                      -- 0
       100.0 * COUNT(*) FILTER (WHERE completada) / COUNT(*) AS bien                      -- 48.0
FROM Tarea;

-- B7. UPDATE sin WHERE (RETURNING nos deja contar las filas cambiadas)
BEGIN;
    WITH cambiadas AS (
        UPDATE Tarea SET completada = TRUE          -- olvidamos: WHERE idTarea = 6
        RETURNING idTarea
    )
    SELECT 'B7' AS caso, COUNT(*) AS filas_cambiadas FROM cambiadas;                      -- 25
ROLLBACK;

-- B8. DELETE en cascada silencioso
BEGIN;
    SELECT COUNT(*) AS vinculos_antes FROM TareaEtiqueta;                                  -- 35
    DELETE FROM Etiqueta WHERE nombre = 'urgente';
    SELECT COUNT(*) AS vinculos_despues FROM TareaEtiqueta;                                -- 30
ROLLBACK;

-- B9. Fechas guardadas como texto se ordenan como texto
SELECT 'B9 mal' AS caso, f AS fecha_texto
FROM (VALUES ('20/11/2026'), ('05/12/2026'), ('01/01/2027')) v(f)
ORDER BY f;                                                -- 01/01/2027, 05/12/2026, 20/11/2026
