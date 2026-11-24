-- =====================================================================
-- PASO 7 · Reportes y estadísticas (PostgreSQL)
-- Equivalente de sqlserver/07_reportes.sql. "Hoy" = 2026-11-23.
-- =====================================================================

-- 7.1 Progreso de cada lista (incluye listas vacías).
SELECT l.nombre AS lista,
       COUNT(t.idTarea)                            AS total,
       COUNT(*) FILTER (WHERE t.completada)        AS completadas,   -- T-SQL: SUM(CASE WHEN ... THEN 1 ELSE 0 END)
       COALESCE(ROUND(100.0 * COUNT(*) FILTER (WHERE t.completada) / NULLIF(COUNT(t.idTarea), 0), 1), 0) AS porcentaje
FROM Lista l
LEFT JOIN Tarea t ON t.idLista = l.idLista
GROUP BY l.idLista
ORDER BY porcentaje DESC;
-- NULLIF(x, 0) convierte 0 en NULL para no dividir entre cero (existe igual en T-SQL).

-- 7.2 Resumen por usuario (incluye usuarios sin listas).
SELECT u.nombre,
       COUNT(DISTINCT l.idLista) AS listas,
       COUNT(t.idTarea)          AS tareas,
       COUNT(*) FILTER (WHERE NOT t.completada)                                   AS pendientes,
       COUNT(*) FILTER (WHERE NOT t.completada AND t.fechaLimite < DATE '2026-11-23') AS vencidas
FROM Usuario u
LEFT JOIN Lista l ON l.idUsuario = u.idUsuario
LEFT JOIN Tarea t ON t.idLista   = l.idLista
GROUP BY u.idUsuario
ORDER BY u.idUsuario;

-- 7.3 Etiquetas más usadas.
SELECT e.nombre, COUNT(te.idTarea) AS tareas
FROM Etiqueta e
LEFT JOIN TareaEtiqueta te ON te.idEtiqueta = e.idEtiqueta
GROUP BY e.nombre
ORDER BY tareas DESC, e.nombre;

-- 7.4 Días promedio para completar, por lista.
SELECT l.nombre AS lista, COUNT(*) AS completadas,
       ROUND(AVG(t.fechaCompletada::date - t.fechaCreacion::date), 1) AS dias_promedio
FROM Tarea t
JOIN Lista l ON l.idLista = t.idLista
WHERE t.completada
GROUP BY l.nombre
ORDER BY dias_promedio;

-- 7.5 Completadas tarde.
SELECT nombre, fechaLimite, fechaCompletada::date AS completada_el,
       fechaCompletada::date - fechaLimite AS dias_tarde
FROM Tarea
WHERE completada AND fechaCompletada::date > fechaLimite;

-- 7.6 Completadas por semana ISO.
SELECT EXTRACT(WEEK FROM fechaCompletada) AS semana,       -- T-SQL: DATEPART(ISO_WEEK, ...)
       MIN(fechaCompletada::date) AS desde, COUNT(*) AS completadas
FROM Tarea
WHERE completada
GROUP BY semana
ORDER BY semana;

-- 7.7 La pendiente más urgente de cada lista.
SELECT DISTINCT ON (t.idLista)                             -- solo PG; en T-SQL: ROW_NUMBER() como en sqlserver/
       l.nombre AS lista, t.nombre AS tarea, t.prioridad, t.fechaLimite
FROM Tarea t
JOIN Lista l ON l.idLista = t.idLista
WHERE NOT t.completada
ORDER BY t.idLista, t.prioridad, t.fechaLimite NULLS LAST;

-- 7.8 Pares de etiquetas que aparecen juntas.
SELECT e1.nombre AS etiqueta_1, e2.nombre AS etiqueta_2, COUNT(*) AS veces
FROM TareaEtiqueta a
JOIN TareaEtiqueta b ON b.idTarea = a.idTarea AND b.idEtiqueta > a.idEtiqueta
JOIN Etiqueta e1     ON e1.idEtiqueta = a.idEtiqueta
JOIN Etiqueta e2     ON e2.idEtiqueta = b.idEtiqueta
GROUP BY e1.nombre, e2.nombre
ORDER BY veces DESC;
