/* =====================================================================
   PASO 7 · Reportes y estadísticas (SQL Server)
   Consultas más avanzadas: agregaciones, LEFT JOIN, CTE y ventanas.
   "Hoy" = 2026-11-23.
   ===================================================================== */

USE DBAngular;
GO

-- 7.1 Progreso de cada lista: total, completadas y porcentaje (incluye listas vacías).
SELECT l.nombre AS lista,
       COUNT(t.idTarea) AS total,
       SUM(CASE WHEN t.completada = 1 THEN 1 ELSE 0 END) AS completadas,
       CASE WHEN COUNT(t.idTarea) = 0 THEN 0
            ELSE CAST(100.0 * SUM(CASE WHEN t.completada = 1 THEN 1 ELSE 0 END) / COUNT(t.idTarea) AS DECIMAL(5,1))
       END AS porcentaje
FROM Lista l
LEFT JOIN Tarea t ON t.idLista = l.idLista
GROUP BY l.idLista, l.nombre
ORDER BY porcentaje DESC;
GO

-- 7.2 Resumen por usuario: listas, tareas, pendientes y vencidas (incluye usuarios sin listas).
DECLARE @hoy DATE = '2026-11-23';

SELECT u.nombre,
       COUNT(DISTINCT l.idLista) AS listas,
       COUNT(t.idTarea)          AS tareas,
       SUM(CASE WHEN t.completada = 0 THEN 1 ELSE 0 END) AS pendientes,
       SUM(CASE WHEN t.completada = 0 AND t.fechaLimite < @hoy THEN 1 ELSE 0 END) AS vencidas
FROM Usuario u
LEFT JOIN Lista l ON l.idUsuario = u.idUsuario
LEFT JOIN Tarea t ON t.idLista   = l.idLista
GROUP BY u.idUsuario, u.nombre
ORDER BY u.idUsuario;
GO

-- 7.3 Etiquetas más usadas (incluye las que no se usan).
SELECT e.nombre, COUNT(te.idTarea) AS tareas
FROM Etiqueta e
LEFT JOIN TareaEtiqueta te ON te.idEtiqueta = e.idEtiqueta
GROUP BY e.nombre
ORDER BY tareas DESC, e.nombre;
GO

-- 7.4 ¿Cuántos días se tarda en promedio en completar una tarea, por lista?
SELECT l.nombre AS lista,
       COUNT(*) AS completadas,
       AVG(DATEDIFF(DAY, t.fechaCreacion, t.fechaCompletada) * 1.0) AS dias_promedio
FROM Tarea t
INNER JOIN Lista l ON l.idLista = t.idLista
WHERE t.completada = 1
GROUP BY l.nombre
ORDER BY dias_promedio;
GO

-- 7.5 Tareas completadas TARDE (después de su fecha límite) y por cuántos días.
SELECT t.nombre, t.fechaLimite, CAST(t.fechaCompletada AS DATE) AS completada_el,
       DATEDIFF(DAY, t.fechaLimite, t.fechaCompletada) AS dias_tarde
FROM Tarea t
WHERE t.completada = 1
  AND CAST(t.fechaCompletada AS DATE) > t.fechaLimite;
GO

-- 7.6 Tareas completadas por semana (semana ISO) en octubre y noviembre.
SELECT DATEPART(ISO_WEEK, fechaCompletada) AS semana,
       MIN(CAST(fechaCompletada AS DATE))  AS desde,
       COUNT(*)                            AS completadas
FROM Tarea
WHERE completada = 1
GROUP BY DATEPART(ISO_WEEK, fechaCompletada)
ORDER BY semana;
GO

-- 7.7 La tarea pendiente más urgente de cada lista (ROW_NUMBER por lista).
WITH ordenadas AS (
    SELECT l.nombre AS lista, t.nombre AS tarea, t.prioridad, t.fechaLimite,
           ROW_NUMBER() OVER (PARTITION BY t.idLista
                              ORDER BY t.prioridad,
                                       CASE WHEN t.fechaLimite IS NULL THEN 1 ELSE 0 END,
                                       t.fechaLimite) AS n
    FROM Tarea t
    INNER JOIN Lista l ON l.idLista = t.idLista
    WHERE t.completada = 0
)
SELECT lista, tarea, prioridad, fechaLimite
FROM ordenadas
WHERE n = 1
ORDER BY prioridad, fechaLimite;
GO

-- 7.8 Pares de etiquetas que aparecen juntas en la misma tarea.
SELECT e1.nombre AS etiqueta_1, e2.nombre AS etiqueta_2, COUNT(*) AS veces
FROM TareaEtiqueta a
INNER JOIN TareaEtiqueta b ON b.idTarea = a.idTarea AND b.idEtiqueta > a.idEtiqueta
INNER JOIN Etiqueta e1     ON e1.idEtiqueta = a.idEtiqueta
INNER JOIN Etiqueta e2     ON e2.idEtiqueta = b.idEtiqueta
GROUP BY e1.nombre, e2.nombre
ORDER BY veces DESC;
GO
