/* =====================================================================
   SOLUCIONES de ../ejercicios.sql (SQL Server)
   La versión PostgreSQL está en ../postgresql/12_soluciones.sql
   "Hoy" = 2026-11-23. Del 1 al 15: después de los pasos 1 a 5. Del 16 al 19: después del paso 9.
   ===================================================================== */

USE DBTareas;
GO

DECLARE @hoy DATE = '2026-11-23';   -- las variables viven hasta el siguiente GO: este archivo no usa GO

-- 1. Todas las tareas con el nombre de su lista y del dueño de la lista.
SELECT t.idTarea, t.nombre AS tarea, l.nombre AS lista, u.nombre AS usuario
FROM Tarea t
INNER JOIN Lista l   ON l.idLista   = t.idLista
INNER JOIN Usuario u ON u.idUsuario = l.idUsuario
ORDER BY t.idTarea;

-- 2. Tareas pendientes de prioridad alta (1), de la que vence antes a la que vence después.
SELECT nombre, fechaLimite
FROM Tarea
WHERE completada = 0 AND prioridad = 1
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
SELECT nombre FROM Tarea WHERE completada = 0 AND fechaLimite IS NULL;

-- 6. Etiquetas que no se usan en ninguna tarea.
SELECT e.nombre
FROM Etiqueta e
WHERE NOT EXISTS (SELECT 1 FROM TareaEtiqueta te WHERE te.idEtiqueta = e.idEtiqueta);

-- 7. Tareas que tienen a la vez la etiqueta 'trabajo' Y la etiqueta 'urgente'.
SELECT t.nombre
FROM Tarea t
INNER JOIN TareaEtiqueta te ON te.idTarea = t.idTarea
INNER JOIN Etiqueta e       ON e.idEtiqueta = te.idEtiqueta
WHERE e.nombre IN ('trabajo', 'urgente')
GROUP BY t.idTarea, t.nombre
HAVING COUNT(*) = 2;
-- Con WHERE e.nombre = 'trabajo' AND e.nombre = 'urgente' no sale nada: una fila tiene UNA etiqueta.

-- 8. Tareas vencidas (pendientes con fecha límite antes de hoy) y cuántos días de retraso llevan.
SELECT t.nombre, l.nombre AS lista, t.fechaLimite, DATEDIFF(DAY, t.fechaLimite, @hoy) AS dias_retraso   -- PG: fecha - fecha
FROM Tarea t
INNER JOIN Lista l ON l.idLista = t.idLista
WHERE t.completada = 0 AND t.fechaLimite < @hoy
ORDER BY dias_retraso DESC;

-- 9. Cuántas tareas completó cada usuario en noviembre 2026 (solo usuarios con alguna).
SELECT u.nombre, COUNT(*) AS completadas_noviembre
FROM Tarea t
INNER JOIN Lista l   ON l.idLista   = t.idLista
INNER JOIN Usuario u ON u.idUsuario = l.idUsuario
WHERE t.completada = 1
  AND t.fechaCompletada >= '2026-11-01' AND t.fechaCompletada < '2026-12-01'
GROUP BY u.nombre
ORDER BY completadas_noviembre DESC;

-- 10. Listas que tienen tareas y TODAS están completadas.
SELECT l.nombre
FROM Lista l
INNER JOIN Tarea t ON t.idLista = l.idLista
GROUP BY l.nombre
HAVING COUNT(*) = SUM(CASE WHEN t.completada = 1 THEN 1 ELSE 0 END);   -- PG: COUNT(*) FILTER (WHERE t.completada)

-- 11. Promedio de etiquetas por tarea (con 2 decimales).
SELECT CAST(AVG(n * 1.0) AS DECIMAL(5,2)) AS promedio_etiquetas   -- * 1.0: AVG de enteros en T-SQL da entero
FROM (SELECT t.idTarea, COUNT(te.idEtiqueta) AS n
      FROM Tarea t LEFT JOIN TareaEtiqueta te ON te.idTarea = t.idTarea
      GROUP BY t.idTarea) x;

-- 12. La tarea pendiente más antigua (por fecha de creación) de cada usuario.
SELECT usuario, tarea, creada
FROM (
    SELECT u.nombre AS usuario, t.nombre AS tarea, CAST(t.fechaCreacion AS DATE) AS creada,
           ROW_NUMBER() OVER (PARTITION BY u.idUsuario ORDER BY t.fechaCreacion, t.idTarea) AS n
    FROM Tarea t
    INNER JOIN Lista l   ON l.idLista   = t.idLista
    INNER JOIN Usuario u ON u.idUsuario = l.idUsuario
    WHERE t.completada = 0
) x
WHERE n = 1
ORDER BY usuario;

-- 13. Cuántas tareas se crearon cada mes (formato YYYY-MM).
SELECT FORMAT(fechaCreacion, 'yyyy-MM') AS mes, COUNT(*) AS creadas   -- PG: to_char(f, 'YYYY-MM')
FROM Tarea
GROUP BY FORMAT(fechaCreacion, 'yyyy-MM')
ORDER BY mes;

-- 14. Ranking de usuarios por tareas completadas (incluye a quien tiene 0), con RANK.
SELECT u.nombre,
       SUM(CASE WHEN t.completada = 1 THEN 1 ELSE 0 END) AS completadas,
       RANK() OVER (ORDER BY SUM(CASE WHEN t.completada = 1 THEN 1 ELSE 0 END) DESC) AS puesto
FROM Usuario u
LEFT JOIN Lista l ON l.idUsuario = u.idUsuario
LEFT JOIN Tarea t ON t.idLista   = l.idLista
GROUP BY u.idUsuario, u.nombre
ORDER BY puesto, u.nombre;

-- 15. RETO · Carga de la próxima semana: por cada usuario, cuántas tareas pendientes vencen entre
--     hoy y dentro de 7 días, y cuáles son. Deben salir los 4 usuarios.
SELECT u.nombre,
       COUNT(t.idTarea) AS tareas_semana,
       ISNULL(STRING_AGG(t.nombre, '; ') WITHIN GROUP (ORDER BY t.fechaLimite), '-') AS cuales
FROM Usuario u
LEFT JOIN Lista l ON l.idUsuario = u.idUsuario
LEFT JOIN Tarea t ON t.idLista = l.idLista
                 AND t.completada = 0
                 AND t.fechaLimite BETWEEN @hoy AND DATEADD(DAY, 7, @hoy)
GROUP BY u.idUsuario, u.nombre
ORDER BY tareas_semana DESC, u.nombre;
GO

/* =====================================================================
   Ejercicios 16 a 19 (necesitan el paso 9)
   ===================================================================== */

-- 16. Tareas con subtareas: cuántas, cuántas hechas y si se puede cerrar.
SELECT p.idTarea, p.nombre AS tarea,
       COUNT(h.idTarea) AS subtareas,
       SUM(CASE WHEN h.completada = 1 THEN 1 ELSE 0 END) AS hechas,
       CASE WHEN SUM(CASE WHEN h.completada = 1 THEN 0 ELSE 1 END) = 0
            THEN 'LISTA PARA CERRAR'
            ELSE 'FALTAN ' + CAST(SUM(CASE WHEN h.completada = 1 THEN 0 ELSE 1 END) AS VARCHAR(5))
       END AS estado
FROM Tarea p
INNER JOIN Tarea h ON h.idTareaPadre = p.idTarea
GROUP BY p.idTarea, p.nombre;
GO

-- 17. Listas que ve cada usuario, con su acceso.
SELECT u.nombre AS usuario, l.nombre AS lista, 'DUEÑO' AS acceso
FROM Usuario u INNER JOIN Lista l ON l.idUsuario = u.idUsuario
UNION ALL
SELECT u.nombre, l.nombre, lc.permiso
FROM ListaCompartida lc
INNER JOIN Usuario u ON u.idUsuario = lc.idUsuario
INNER JOIN Lista l   ON l.idLista   = lc.idLista
ORDER BY usuario, lista;
GO

-- 18. COUNT(*) cuenta la fila que agrega el LEFT JOIN aunque venga llena de NULL.
--     Se cuenta una columna de la tabla de la derecha: COUNT ignora los NULL.
SELECT l.nombre, COUNT(t.idTarea) AS tareas
FROM Lista l LEFT JOIN Tarea t ON t.idLista = l.idLista
GROUP BY l.idLista, l.nombre;
GO

-- 19. idTareaPadre tiene NULLs: "x NOT IN (..., NULL)" nunca es verdadero.
--     NOT EXISTS no tiene ese problema (otra opción: filtrar WHERE idTareaPadre IS NOT NULL).
SELECT t.idTarea, t.nombre
FROM Tarea t
WHERE NOT EXISTS (SELECT 1 FROM Tarea h WHERE h.idTareaPadre = t.idTarea);
GO
