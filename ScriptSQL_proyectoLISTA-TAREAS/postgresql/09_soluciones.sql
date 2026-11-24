-- =====================================================================
-- PASO 9 · Soluciones de ../ejercicios.sql (PostgreSQL)
-- La versión SQL Server está en ../sqlserver/09_soluciones.sql
-- "Hoy" = 2026-11-23. Corre después de los pasos 1 a 5.
-- =====================================================================

-- 1. Todas las tareas con el nombre de su lista y del dueño de la lista.
SELECT t.idTarea, t.nombre AS tarea, l.nombre AS lista, u.nombre AS usuario
FROM Tarea t
JOIN Lista l   ON l.idLista   = t.idLista
JOIN Usuario u ON u.idUsuario = l.idUsuario
ORDER BY t.idTarea;

-- 2. Tareas pendientes de prioridad alta (1), de la que vence antes a la que vence después.
SELECT nombre, fechaLimite
FROM Tarea
WHERE NOT completada AND prioridad = 1
ORDER BY fechaLimite;

-- 3. Cuántas tareas tiene cada lista, incluidas las listas vacías.
SELECT l.nombre AS lista, COUNT(t.idTarea) AS tareas
FROM Lista l
LEFT JOIN Tarea t ON t.idLista = l.idLista
GROUP BY l.nombre
ORDER BY tareas DESC, l.nombre;

-- 4. Usuarios que no tienen ninguna lista.
SELECT u.nombre, u.correo
FROM Usuario u
LEFT JOIN Lista l ON l.idUsuario = u.idUsuario
WHERE l.idLista IS NULL;

-- 5. Tareas pendientes que no tienen fecha límite.
SELECT nombre FROM Tarea WHERE NOT completada AND fechaLimite IS NULL;

-- 6. Etiquetas que no se usan en ninguna tarea.
SELECT e.nombre
FROM Etiqueta e
WHERE NOT EXISTS (SELECT 1 FROM TareaEtiqueta te WHERE te.idEtiqueta = e.idEtiqueta);

-- 7. Tareas que tienen a la vez la etiqueta 'trabajo' Y la etiqueta 'urgente'.
SELECT t.nombre
FROM Tarea t
JOIN TareaEtiqueta te ON te.idTarea = t.idTarea
JOIN Etiqueta e       ON e.idEtiqueta = te.idEtiqueta
WHERE e.nombre IN ('trabajo', 'urgente')
GROUP BY t.idTarea, t.nombre
HAVING COUNT(*) = 2;
-- Con WHERE e.nombre = 'trabajo' AND e.nombre = 'urgente' no sale nada: una fila tiene UNA etiqueta.

-- 8. Tareas vencidas (pendientes con fecha límite antes de hoy) y cuántos días de retraso llevan.
SELECT t.nombre, l.nombre AS lista, t.fechaLimite, DATE '2026-11-23' - t.fechaLimite AS dias_retraso
FROM Tarea t
JOIN Lista l ON l.idLista = t.idLista
WHERE NOT t.completada AND t.fechaLimite < DATE '2026-11-23'
ORDER BY dias_retraso DESC;

-- 9. Cuántas tareas completó cada usuario en noviembre 2026 (solo usuarios con alguna).
SELECT u.nombre, COUNT(*) AS completadas_noviembre
FROM Tarea t
JOIN Lista l   ON l.idLista   = t.idLista
JOIN Usuario u ON u.idUsuario = l.idUsuario
WHERE t.completada
  AND t.fechaCompletada >= '2026-11-01' AND t.fechaCompletada < '2026-12-01'
GROUP BY u.nombre
ORDER BY completadas_noviembre DESC;

-- 10. Listas que tienen tareas y TODAS están completadas.
SELECT l.nombre
FROM Lista l
JOIN Tarea t ON t.idLista = l.idLista
GROUP BY l.nombre
HAVING COUNT(*) = COUNT(*) FILTER (WHERE t.completada);   -- T-SQL: SUM(CASE WHEN t.completada = 1 THEN 1 ELSE 0 END)

-- 11. Promedio de etiquetas por tarea (con 2 decimales).
SELECT ROUND(AVG(n), 2) AS promedio_etiquetas
FROM (SELECT t.idTarea, COUNT(te.idEtiqueta) AS n
      FROM Tarea t LEFT JOIN TareaEtiqueta te ON te.idTarea = t.idTarea
      GROUP BY t.idTarea) x;

-- 12. La tarea pendiente más antigua (por fecha de creación) de cada usuario.
SELECT usuario, tarea, creada
FROM (
    SELECT u.nombre AS usuario, t.nombre AS tarea, t.fechaCreacion::date AS creada,
           ROW_NUMBER() OVER (PARTITION BY u.idUsuario ORDER BY t.fechaCreacion, t.idTarea) AS n
    FROM Tarea t
    JOIN Lista l   ON l.idLista   = t.idLista
    JOIN Usuario u ON u.idUsuario = l.idUsuario
    WHERE NOT t.completada
) x
WHERE n = 1
ORDER BY usuario;

-- 13. Cuántas tareas se crearon cada mes (formato YYYY-MM).
SELECT to_char(fechaCreacion, 'YYYY-MM') AS mes, COUNT(*) AS creadas
FROM Tarea
GROUP BY mes
ORDER BY mes;

-- 14. Ranking de usuarios por tareas completadas (incluye a quien tiene 0), con RANK.
SELECT u.nombre,
       COUNT(t.idTarea) FILTER (WHERE t.completada) AS completadas,
       RANK() OVER (ORDER BY COUNT(t.idTarea) FILTER (WHERE t.completada) DESC) AS puesto
FROM Usuario u
LEFT JOIN Lista l ON l.idUsuario = u.idUsuario
LEFT JOIN Tarea t ON t.idLista   = l.idLista
GROUP BY u.idUsuario, u.nombre
ORDER BY puesto, u.nombre;

-- 15. RETO · Carga de la próxima semana: por cada usuario, cuántas tareas pendientes vencen entre
--     hoy y dentro de 7 días, y cuáles son. Deben salir los 4 usuarios.
SELECT u.nombre,
       COUNT(t.idTarea) AS tareas_semana,
       COALESCE(STRING_AGG(t.nombre, '; ' ORDER BY t.fechaLimite), '-') AS cuales
FROM Usuario u
LEFT JOIN Lista l ON l.idUsuario = u.idUsuario
LEFT JOIN Tarea t ON t.idLista = l.idLista
                 AND NOT t.completada
                 AND t.fechaLimite BETWEEN DATE '2026-11-23' AND DATE '2026-11-23' + 7
GROUP BY u.idUsuario, u.nombre
ORDER BY tareas_semana DESC, u.nombre;
