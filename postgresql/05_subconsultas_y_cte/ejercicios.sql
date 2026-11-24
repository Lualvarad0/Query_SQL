-- =====================================================================
-- Módulo 05 · Subconsultas y CTE (WITH) · EJERCICIOS
-- Escribe tu consulta debajo de cada enunciado y compara con "Resultado esperado".
-- Las respuestas están en soluciones.sql de esta misma carpeta (¡inténtalo primero!).
-- =====================================================================

-- 1. Productos cuyo precio es mayor que el precio promedio de todos los productos.
--    Resultado esperado: 9 filas


-- 2. Clientes que alguna vez compraron una laptop (categoría 'Laptops'), usando IN.
--    Resultado esperado: 7 filas


-- 3. La misma pregunta, pero con EXISTS.
--    Resultado esperado: 7 filas


-- 4. Clientes que nunca han pagado con Tarjeta (incluye a quien nunca compró).
--    Resultado esperado: 1 fila


-- 5. La trampa de NOT IN con NULL. Esta consulta busca clientes sin ventas y devuelve 0 filas:
--       SELECT nombreCompleto FROM Cliente
--       WHERE idCliente NOT IN (SELECT idCliente FROM Venta);
--    ¿Por qué? Escribe una versión correcta.
--    Resultado esperado: 1 fila


-- 6. Cada producto con su precio y el precio promedio de SU categoría, y la diferencia.
--    Resultado esperado: 17 filas


-- 7. Subconsulta en el FROM: ticket promedio (venta promedio) de cada cliente, y solo los clientes
--    cuyo ticket promedio supera el ticket promedio general de todas las ventas pagadas.
--    Resultado esperado: 7 filas


-- 8. Con CTE (WITH): total gastado por cada cliente y qué porcentaje representa del total
--    facturado. Solo los 5 mejores clientes.
--    Resultado esperado: 5 filas


-- 9. Resuelve el error del ejercicio 22 de JOINs con una CTE: por vendedor, total facturado
--    (sin inflar) Y unidades vendidas (que sí necesita el detalle).
--    Resultado esperado: 5 filas


-- 10. CTE recursiva: el organigrama completo con el nivel de cada usuario y su "ruta"
--     desde el administrador (ej: codigo estudiante > jose supervisor > maria empleada).
--    Resultado esperado: 7 filas


-- 11. CTE recursiva para un calendario: ventas pagadas de cada día del 1 al 20 de noviembre,
--     incluyendo los días sin ventas (con 0).
--    Resultado esperado: 20 filas


-- 12. Productos que se venden más que el promedio: unidades vendidas por producto (pagadas)
--     mayores al promedio de unidades por producto vendido.
--    Resultado esperado: 4 filas
