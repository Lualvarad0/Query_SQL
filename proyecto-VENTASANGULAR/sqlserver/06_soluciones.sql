/* =====================================================================
   PASO 6 · Soluciones de ../ejercicios.sql (SQL Server)
   La versión PostgreSQL está en ../postgresql/06_soluciones.sql
   Las líneas marcadas "PG:" muestran qué cambia en PostgreSQL.
   ===================================================================== */

USE DBVENTA;
GO

-- 1. Lista los productos con el nombre de su categoría, del más caro al más barato.
SELECT p.nombre, c.nombre AS categoria, p.precio
FROM Producto p
INNER JOIN Categoria c ON c.idCategoria = p.idCategoria
ORDER BY p.precio DESC, p.nombre;

-- 2. ¿Cuántos productos hay en cada categoría?
SELECT c.nombre AS categoria, COUNT(p.idProducto) AS productos
FROM Categoria c
LEFT JOIN Producto p ON p.idCategoria = c.idCategoria
GROUP BY c.nombre
ORDER BY productos DESC, c.nombre;

-- 3. ¿Cuánto dinero hay en inventario (stock x precio) por categoría?
SELECT c.nombre AS categoria, SUM(p.stock * p.precio) AS valor_inventario
FROM Producto p
INNER JOIN Categoria c ON c.idCategoria = p.idCategoria
GROUP BY c.nombre
ORDER BY valor_inventario DESC;

-- 4. Los menús de cada rol en una sola fila, separados por coma.
SELECT r.nombre AS rol, STRING_AGG(m.nombre, ', ') WITHIN GROUP (ORDER BY m.idMenu) AS menus  -- PG: STRING_AGG(m.nombre, ', ' ORDER BY m.idMenu)
FROM Rol r
INNER JOIN MenuRol mr ON mr.idRol = r.idRol
INNER JOIN Menu m     ON m.idMenu = mr.idMenu
GROUP BY r.nombre
ORDER BY r.nombre;

-- 5. ¿Qué usuarios pueden entrar a la pantalla 'Reportes'?
SELECT u.nombreCompleto, r.nombre AS rol
FROM Usuario u
INNER JOIN Rol r      ON r.idRol  = u.idRol
INNER JOIN MenuRol mr ON mr.idRol = r.idRol
INNER JOIN Menu m     ON m.idMenu = mr.idMenu
WHERE m.nombre = 'Reportes'
ORDER BY u.nombreCompleto;

-- 6. Total vendido por día en noviembre (solo los días con ventas).
SELECT CAST(fechaRegistro AS DATE) AS dia, COUNT(*) AS ventas, SUM(total) AS total   -- PG: fechaRegistro::date
FROM Venta
GROUP BY CAST(fechaRegistro AS DATE)        -- PG permite GROUP BY dia
ORDER BY dia;

-- 7. Total por tipo de pago y qué porcentaje del total representa.
SELECT tipoPago, COUNT(*) AS ventas, SUM(total) AS total,
       CAST(SUM(total) * 100.0 / (SELECT SUM(total) FROM Venta) AS DECIMAL(5,1)) AS porcentaje
FROM Venta
GROUP BY tipoPago;

-- 8. Los 5 productos con más unidades vendidas.
SELECT TOP 5 p.nombre, SUM(d.cantidad) AS unidades, SUM(d.total) AS ingresos   -- PG: ... LIMIT 5
FROM DetalleVenta d
INNER JOIN Producto p ON p.idProducto = d.idProducto
GROUP BY p.nombre
ORDER BY unidades DESC, ingresos DESC;

-- 9. Productos que nunca se vendieron.
SELECT p.nombre, p.stock
FROM Producto p
LEFT JOIN DetalleVenta d ON d.idProducto = p.idProducto
WHERE d.idDetalleVenta IS NULL;

-- 10. Ingresos por categoría, incluyendo las que no vendieron nada (con 0).
SELECT c.nombre AS categoria, ISNULL(SUM(d.total), 0) AS ingresos      -- COALESCE también funciona
FROM Categoria c
LEFT JOIN Producto p     ON p.idCategoria = c.idCategoria
LEFT JOIN DetalleVenta d ON d.idProducto  = p.idProducto
GROUP BY c.nombre
ORDER BY ingresos DESC;

-- 11. Ticket promedio, venta más alta y venta más baja.
SELECT CAST(AVG(total) AS DECIMAL(10,2)) AS ticket_promedio, MAX(total) AS mas_alta, MIN(total) AS mas_baja
FROM Venta;

-- 12. Ventas cuyo total supera el ticket promedio.
SELECT numeroDocumento, total
FROM Venta
WHERE total > (SELECT AVG(total) FROM Venta)
ORDER BY total DESC;

-- 13. Ventas por semana del año (número de semana ISO).
SELECT DATEPART(ISO_WEEK, fechaRegistro) AS semana, COUNT(*) AS ventas, SUM(total) AS total  -- PG: EXTRACT(WEEK FROM f)
FROM Venta
GROUP BY DATEPART(ISO_WEEK, fechaRegistro)
ORDER BY semana;

-- 14. En cada venta con más de un producto: qué porcentaje del total aporta cada línea.
SELECT v.numeroDocumento, p.nombre, d.total,
       CAST(d.total * 100.0 / SUM(d.total) OVER (PARTITION BY d.idVenta) AS DECIMAL(5,1)) AS pct_de_la_venta
FROM DetalleVenta d
INNER JOIN Venta v    ON v.idVenta    = d.idVenta
INNER JOIN Producto p ON p.idProducto = d.idProducto
WHERE d.idVenta IN (SELECT idVenta FROM DetalleVenta GROUP BY idVenta HAVING COUNT(*) > 1)
ORDER BY v.numeroDocumento, d.total DESC;

-- 15. "Comprados juntos": pares de productos que aparecieron en la misma venta y cuántas veces.
SELECT a.nombre AS producto_1, b.nombre AS producto_2, COUNT(*) AS veces
FROM DetalleVenta d1
INNER JOIN DetalleVenta d2 ON d2.idVenta = d1.idVenta AND d2.idProducto > d1.idProducto
INNER JOIN Producto a      ON a.idProducto = d1.idProducto
INNER JOIN Producto b      ON b.idProducto = d2.idProducto
GROUP BY a.nombre, b.nombre
ORDER BY veces DESC, producto_1, producto_2;

-- 16. ¿Cuánto stock tenía cada producto antes de las ventas? (stock actual + unidades vendidas)
SELECT p.nombre, p.stock AS stock_actual,
       ISNULL(SUM(d.cantidad), 0)           AS vendido,
       p.stock + ISNULL(SUM(d.cantidad), 0) AS stock_inicial
FROM Producto p
LEFT JOIN DetalleVenta d ON d.idProducto = p.idProducto
GROUP BY p.idProducto, p.nombre, p.stock
ORDER BY p.idProducto;
GO
