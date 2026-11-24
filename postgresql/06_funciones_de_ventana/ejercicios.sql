-- =====================================================================
-- Módulo 06 · Funciones de ventana (OVER) · EJERCICIOS
-- A diferencia de GROUP BY, una función de ventana NO junta las filas:
-- cada fila se queda y gana una columna calculada sobre su "ventana".
-- Todo este módulo se escribe igual en SQL Server (salvo detalles marcados).
-- Escribe tu consulta debajo de cada enunciado y compara con "Resultado esperado".
-- Las respuestas están en soluciones.sql de esta misma carpeta (¡inténtalo primero!).
-- =====================================================================

-- 1. Numera los productos de cada categoría del más caro al más barato.
--    Resultado esperado: 17 filas


-- 2. Los 2 productos más caros de cada categoría.
--    Resultado esperado: 12 filas


-- 3. Ranking de productos por unidades vendidas (pagadas) con ROW_NUMBER, RANK y DENSE_RANK.
--    Mira qué pasa con los empates.
--    Resultado esperado: 14 filas


-- 4. Ventas pagadas de noviembre con el total acumulado día a día.
--    Resultado esperado: 7 filas


-- 5. Total pagado por mes y la variación contra el mes anterior (en dinero y en %).
--    Resultado esperado: 5 filas


-- 6. Qué porcentaje de las ventas (ingreso del detalle, pagadas) aporta cada categoría.
--    Resultado esperado: 6 filas


-- 7. Para cada compra pagada de los clientes, cuántos días pasaron desde su compra anterior.
--    Resultado esperado: 54 filas


-- 8. Promedio móvil de 3 meses del total pagado mensual (el mes y los 2 anteriores).
--    Resultado esperado: 5 filas


-- 9. Divide a los clientes que compraron en 4 grupos (cuartiles) según lo que gastaron.
--    Resultado esperado: 14 filas


-- 10. La primera y la última compra pagada de cada cliente (fecha y documento) en una sola fila.
--    Resultado esperado: 14 filas


-- 11. La mejor venta de cada cliente (resuelve el reto 23 de JOINs sin DISTINCT ON).
--    Resultado esperado: 14 filas
