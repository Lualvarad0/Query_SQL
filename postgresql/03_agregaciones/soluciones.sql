-- =====================================================================
-- Módulo 03 · Funciones de agregación, GROUP BY y HAVING · SOLUCIONES
-- Regla de oro: cada columna del SELECT que no esté dentro de una función
-- de agregación (COUNT, SUM, ...) debe ir en el GROUP BY.
-- =====================================================================

-- 1. ¿Cuántos productos hay en el catálogo?
SELECT COUNT(*) AS productos FROM Producto;

-- 2. Precio mínimo, máximo y promedio (2 decimales) de los productos.
SELECT MIN(precio) AS minimo, MAX(precio) AS maximo, ROUND(AVG(precio), 2) AS promedio
FROM Producto;

-- 3. ¿Cuántos clientes hay y cuántos tienen correo? (en una sola consulta)
SELECT COUNT(*) AS clientes, COUNT(correo) AS con_correo
FROM Cliente;
-- COUNT(*) cuenta filas; COUNT(columna) cuenta solo los valores que no son NULL.

-- 4. Total facturado, IVA cobrado y número de ventas, solo de ventas PAGADAS.
SELECT COUNT(*) AS ventas, SUM(subtotal) AS subtotal, SUM(impuesto) AS iva, SUM(total) AS total
FROM Venta
WHERE estado = 'PAGADA';

-- 5. Número de ventas pagadas y monto total por tipo de pago.
SELECT tipoPago, COUNT(*) AS ventas, SUM(total) AS total
FROM Venta
WHERE estado = 'PAGADA'
GROUP BY tipoPago
ORDER BY total DESC;

-- 6. Ventas pagadas por mes (formato YYYY-MM): cantidad y total.
SELECT to_char(fechaRegistro, 'YYYY-MM') AS mes, COUNT(*) AS ventas, SUM(total) AS total
FROM Venta
WHERE estado = 'PAGADA'
GROUP BY mes
ORDER BY mes;
-- T-SQL: FORMAT(fechaRegistro, 'yyyy-MM') y repetir la expresión en el GROUP BY
--        (SQL Server no permite usar el alias "mes" en GROUP BY).
-- Alternativa en PG: date_trunc('month', fechaRegistro)

-- 7. Por cada vendedor (idUsuario): ventas pagadas, total y ticket promedio.
SELECT idUsuario, COUNT(*) AS ventas, SUM(total) AS total, ROUND(AVG(total), 2) AS ticket_promedio
FROM Venta
WHERE estado = 'PAGADA'
GROUP BY idUsuario
ORDER BY total DESC;

-- 8. Clientes (idCliente) con más de 5 compras pagadas.
SELECT idCliente, COUNT(*) AS compras
FROM Venta
WHERE estado = 'PAGADA' AND idCliente IS NOT NULL
GROUP BY idCliente
HAVING COUNT(*) > 5
ORDER BY compras DESC;
-- WHERE filtra filas ANTES de agrupar; HAVING filtra grupos DESPUÉS de agrupar.

-- 9. Categorías (idCategoria) cuyo precio promedio supera 900.
SELECT idCategoria, ROUND(AVG(precio), 2) AS precio_promedio, COUNT(*) AS productos
FROM Producto
WHERE idCategoria IS NOT NULL
GROUP BY idCategoria
HAVING AVG(precio) > 900;

-- 10. ¿Cuántas ventas hay en cada estado y cuánto dinero representan?
SELECT estado, COUNT(*) AS ventas, SUM(total) AS total
FROM Venta
GROUP BY estado;

-- 11. Unidades vendidas por producto (idProducto) en ventas de cualquier estado,
--     solo los que vendieron 10 unidades o más.
SELECT idProducto, SUM(cantidad) AS unidades
FROM DetalleVenta
GROUP BY idProducto
HAVING SUM(cantidad) >= 10
ORDER BY unidades DESC;

-- 12. Por mes, el total pagado con Tarjeta y con Efectivo en columnas separadas
--     (solo ventas pagadas).
SELECT to_char(fechaRegistro, 'YYYY-MM') AS mes,
       SUM(total) FILTER (WHERE tipoPago = 'Tarjeta')  AS tarjeta,
       SUM(total) FILTER (WHERE tipoPago = 'Efectivo') AS efectivo
FROM Venta
WHERE estado = 'PAGADA'
GROUP BY mes
ORDER BY mes;
-- T-SQL no tiene FILTER: SUM(CASE WHEN tipoPago = 'Tarjeta' THEN total END) AS tarjeta
-- (esa forma con CASE también funciona en PostgreSQL)

-- 13. Ventas pagadas por día de la semana: cantidad y promedio. Ordena de lunes a domingo.
SELECT EXTRACT(ISODOW FROM fechaRegistro) AS dia_num,       -- 1 = lunes ... 7 = domingo
       to_char(fechaRegistro, 'TMDay')    AS dia,
       COUNT(*) AS ventas, ROUND(AVG(total), 2) AS promedio
FROM Venta
WHERE estado = 'PAGADA'
GROUP BY dia_num, dia
ORDER BY dia_num;
-- T-SQL: DATEPART(weekday, fechaRegistro) y DATENAME(weekday, fechaRegistro)
