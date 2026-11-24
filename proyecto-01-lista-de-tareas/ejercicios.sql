-- =====================================================================
-- EJERCICIOS · Lista de Tareas (DBAngular)
-- Funcionan con la base de sqlserver/ o de postgresql/ (después de los pasos 1 a 5).
-- "Hoy" = 2026-11-23. Escribe tu consulta debajo de cada enunciado.
-- Soluciones: sqlserver/09_soluciones.sql y postgresql/09_soluciones.sql
-- Niveles: 1 a 6 JOINs y NULL · 7 a 11 agrupaciones · 12 a 15 funciones de ventana y retos.
-- =====================================================================

-- 1. Todas las tareas con el nombre de su lista y del dueño de la lista.
--    Resultado esperado: 25 filas



-- 2. Tareas pendientes de prioridad alta (1), de la que vence antes a la que vence después.
--    Resultado esperado: 5 filas



-- 3. Cuántas tareas tiene cada lista, incluidas las listas vacías.
--    Resultado esperado: 6 filas



-- 4. Usuarios que no tienen ninguna lista.
--    Resultado esperado: 1 fila



-- 5. Tareas pendientes que no tienen fecha límite.
--    Resultado esperado: 2 filas



-- 6. Etiquetas que no se usan en ninguna tarea.
--    Resultado esperado: 1 fila



-- 7. Tareas que tienen a la vez la etiqueta 'trabajo' Y la etiqueta 'urgente'.
--    Resultado esperado: 2 filas



-- 8. Tareas vencidas (pendientes con fecha límite antes de hoy) y cuántos días de retraso llevan.
--    Resultado esperado: 3 filas



-- 9. Cuántas tareas completó cada usuario en noviembre 2026 (solo usuarios con alguna).
--    Resultado esperado: 3 filas



-- 10. Listas que tienen tareas y TODAS están completadas.
--    Resultado esperado: 1 fila



-- 11. Promedio de etiquetas por tarea (con 2 decimales).
--    Resultado esperado: 1 fila



-- 12. La tarea pendiente más antigua (por fecha de creación) de cada usuario.
--    Resultado esperado: 2 filas



-- 13. Cuántas tareas se crearon cada mes (formato YYYY-MM).
--    Resultado esperado: 2 filas



-- 14. Ranking de usuarios por tareas completadas (incluye a quien tiene 0), con RANK.
--    Resultado esperado: 4 filas



-- 15. RETO · Carga de la próxima semana: por cada usuario, cuántas tareas pendientes vencen entre
--     hoy y dentro de 7 días, y cuáles son. Deben salir los 4 usuarios.
--    Resultado esperado: 4 filas
