-- =====================================================================
-- Módulo 03 · Funciones de agregación, GROUP BY y HAVING · EJERCICIOS
-- Regla de oro: cada columna del SELECT que no esté dentro de una función
-- de agregación (COUNT, SUM, ...) debe ir en el GROUP BY.
-- Escribe tu consulta debajo de cada enunciado y compara con "Resultado esperado".
-- Las respuestas están en soluciones.sql de esta misma carpeta (¡inténtalo primero!).
-- =====================================================================

-- 1. ¿Cuántos productos hay en el catálogo?
--    Resultado esperado: 1 fila


-- 2. Precio mínimo, máximo y promedio (2 decimales) de los productos.
--    Resultado esperado: 1 fila


-- 3. ¿Cuántos clientes hay y cuántos tienen correo? (en una sola consulta)
--    Resultado esperado: 1 fila


-- 4. Total facturado, IVA cobrado y número de ventas, solo de ventas PAGADAS.
--    Resultado esperado: 1 fila


-- 5. Número de ventas pagadas y monto total por tipo de pago.
--    Resultado esperado: 3 filas


-- 6. Ventas pagadas por mes (formato YYYY-MM): cantidad y total.
--    Resultado esperado: 5 filas


-- 7. Por cada vendedor (idUsuario): ventas pagadas, total y ticket promedio.
--    Resultado esperado: 5 filas


-- 8. Clientes (idCliente) con más de 5 compras pagadas.
--    Resultado esperado: 4 filas


-- 9. Categorías (idCategoria) cuyo precio promedio supera 900.
--    Resultado esperado: 3 filas


-- 10. ¿Cuántas ventas hay en cada estado y cuánto dinero representan?
--    Resultado esperado: 2 filas


-- 11. Unidades vendidas por producto (idProducto) en ventas de cualquier estado,
--     solo los que vendieron 10 unidades o más.
--    Resultado esperado: 10 filas


-- 12. Por mes, el total pagado con Tarjeta y con Efectivo en columnas separadas
--     (solo ventas pagadas).
--    Resultado esperado: 5 filas


-- 13. Ventas pagadas por día de la semana: cantidad y promedio. Ordena de lunes a domingo.
--    Resultado esperado: 7 filas
