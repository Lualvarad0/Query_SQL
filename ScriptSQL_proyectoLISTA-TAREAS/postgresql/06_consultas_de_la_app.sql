-- =====================================================================
-- PASO 6 · Las consultas de la app de tareas (PostgreSQL)
-- Equivalente de sqlserver/06_consultas_de_la_app.sql. "Hoy" = 2026-11-23.
-- =====================================================================

-- 6.1 Listas del usuario 1 con sus pendientes.
SELECT l.idLista, l.nombre, l.color, COUNT(t.idTarea) AS pendientes
FROM Lista l
LEFT JOIN Tarea t ON t.idLista = l.idLista AND NOT t.completada     -- T-SQL: AND t.completada = 0
WHERE l.idUsuario = 1
GROUP BY l.idLista
ORDER BY l.nombre;

-- 6.2 Tareas de la lista 2: pendientes primero, por prioridad y fecha (sin fecha al final).
SELECT idTarea, nombre, prioridad, fechaLimite, completada
FROM Tarea
WHERE idLista = 2
ORDER BY completada, prioridad, fechaLimite NULLS LAST;   -- T-SQL no tiene NULLS LAST: se usa un CASE

-- 6.3 Tareas de la lista 1 con sus etiquetas en una columna.
SELECT t.idTarea, t.nombre, STRING_AGG(e.nombre, ', ' ORDER BY e.nombre) AS etiquetas
FROM Tarea t
LEFT JOIN TareaEtiqueta te ON te.idTarea = t.idTarea
LEFT JOIN Etiqueta e       ON e.idEtiqueta = te.idEtiqueta
WHERE t.idLista = 1
GROUP BY t.idTarea
ORDER BY t.idTarea;

-- 6.4 Nueva tarea con dos etiquetas, en un solo comando (CTE con INSERT ... RETURNING).
BEGIN;
    WITH nueva AS (
        INSERT INTO Tarea (idLista, nombre, prioridad, fechaLimite)
        VALUES (1, 'Estudiar funciones de ventana', 2, '2026-11-30')
        RETURNING idTarea
    )
    INSERT INTO TareaEtiqueta (idTarea, idEtiqueta)
    SELECT n.idTarea, e.idEtiqueta FROM nueva n, Etiqueta e WHERE e.nombre IN ('estudio', 'lectura')
    RETURNING idTarea, idEtiqueta;
ROLLBACK;

-- 6.5 Editar.
BEGIN;
    UPDATE Tarea SET nombre = 'Repasar TypeScript y RxJS', prioridad = 1, fechaLimite = '2026-11-26'
    WHERE idTarea = 6
    RETURNING idTarea, nombre, prioridad, fechaLimite;
ROLLBACK;

-- 6.6 Marcar y desmarcar como completada (en el PASO 8 la fecha la pone un trigger).
BEGIN;
    UPDATE Tarea SET completada = TRUE, fechaCompletada = now() WHERE idTarea = 10
    RETURNING idTarea, completada, fechaCompletada IS NOT NULL AS tiene_fecha;
    UPDATE Tarea SET completada = FALSE, fechaCompletada = NULL WHERE idTarea = 10;
ROLLBACK;

-- 6.7 Eliminar: ON DELETE CASCADE borra sus etiquetas.
BEGIN;
    DELETE FROM Tarea WHERE idTarea = 3;
    SELECT COUNT(*) AS etiquetas_que_quedan FROM TareaEtiqueta WHERE idTarea = 3;
ROLLBACK;

-- 6.8 Buscador sin importar mayúsculas.
SELECT t.idTarea, t.nombre, l.nombre AS lista
FROM Tarea t
JOIN Lista l ON l.idLista = t.idLista
WHERE l.idUsuario = 1
  AND (t.nombre ILIKE '%sql%' OR t.descripcion ILIKE '%sql%');   -- T-SQL: LIKE (ya ignora mayúsculas)

-- 6.9 Vencidas, para hoy y próximos 7 días del usuario 1.
SELECT t.nombre, t.fechaLimite,
       CASE WHEN t.fechaLimite <  DATE '2026-11-23' THEN 'Vencida'
            WHEN t.fechaLimite =  DATE '2026-11-23' THEN 'Para hoy'
            ELSE 'Próximos 7 días' END AS estado,
       t.fechaLimite - DATE '2026-11-23' AS dias             -- T-SQL: DATEDIFF(DAY, @hoy, fechaLimite)
FROM Tarea t
JOIN Lista l ON l.idLista = t.idLista
WHERE l.idUsuario = 1
  AND NOT t.completada
  AND t.fechaLimite <= DATE '2026-11-23' + 7                 -- T-SQL: DATEADD(DAY, 7, @hoy)
ORDER BY t.fechaLimite;

-- 6.10 Tareas 'urgente' pendientes de todos los usuarios.
SELECT u.nombre AS usuario, l.nombre AS lista, t.nombre AS tarea, t.fechaLimite
FROM Etiqueta e
JOIN TareaEtiqueta te ON te.idEtiqueta = e.idEtiqueta
JOIN Tarea t          ON t.idTarea     = te.idTarea
JOIN Lista l          ON l.idLista     = t.idLista
JOIN Usuario u        ON u.idUsuario   = l.idUsuario
WHERE e.nombre = 'urgente' AND NOT t.completada
ORDER BY t.fechaLimite;
