-- =====================================================================
-- Módulo 06 · Funciones de ventana (OVER) · SOLUCIONES
-- A diferencia de GROUP BY, una función de ventana NO junta las filas:
-- cada fila se queda y gana una columna calculada sobre su "ventana".
-- Todo este módulo se escribe igual en SQL Server (salvo detalles marcados).
-- =====================================================================

-- 1. Numera los productos de cada categoría del más caro al más barato.
SELECT c.nombre AS categoria, p.nombre, p.precio,
       ROW_NUMBER() OVER (PARTITION BY p.idCategoria ORDER BY p.precio DESC, p.nombre) AS puesto
FROM Producto p
JOIN Categoria c ON c.idCategoria = p.idCategoria
ORDER BY c.nombre, puesto;

-- 2. Los 2 productos más caros de cada categoría.
SELECT categoria, nombre, precio
FROM (
    SELECT c.nombre AS categoria, p.nombre, p.precio,
           ROW_NUMBER() OVER (PARTITION BY p.idCategoria ORDER BY p.precio DESC, p.nombre) AS puesto
    FROM Producto p
    JOIN Categoria c ON c.idCategoria = p.idCategoria
) t
WHERE puesto <= 2                       -- no se puede filtrar una ventana en el WHERE directo
ORDER BY categoria, precio DESC;

-- 3. Ranking de productos por unidades vendidas (pagadas) con ROW_NUMBER, RANK y DENSE_RANK.
--    Mira qué pasa con los empates.
SELECT p.nombre, SUM(d.cantidad) AS unidades,
       ROW_NUMBER() OVER (ORDER BY SUM(d.cantidad) DESC) AS row_number,
       RANK()       OVER (ORDER BY SUM(d.cantidad) DESC) AS rank,
       DENSE_RANK() OVER (ORDER BY SUM(d.cantidad) DESC) AS dense_rank
FROM DetalleVenta d
JOIN Venta v    ON v.idVenta = d.idVenta AND v.estado = 'PAGADA'
JOIN Producto p ON p.idProducto = d.idProducto
GROUP BY p.nombre
ORDER BY unidades DESC, p.nombre;
-- RANK salta números después de un empate (1,2,2,4); DENSE_RANK no (1,2,2,3).

-- 4. Ventas pagadas de noviembre con el total acumulado día a día.
SELECT numeroDocumento, fechaRegistro, total,
       SUM(total) OVER (ORDER BY fechaRegistro) AS acumulado
FROM Venta
WHERE estado = 'PAGADA'
  AND fechaRegistro >= '2026-11-01' AND fechaRegistro < '2026-12-01'
ORDER BY fechaRegistro;

-- 5. Total pagado por mes y la variación contra el mes anterior (en dinero y en %).
WITH mensual AS (
    SELECT date_trunc('month', fechaRegistro)::date AS mes, SUM(total) AS total
    FROM Venta WHERE estado = 'PAGADA'
    GROUP BY 1
)
SELECT to_char(mes, 'YYYY-MM') AS mes, total,
       LAG(total) OVER (ORDER BY mes)          AS mes_anterior,
       total - LAG(total) OVER (ORDER BY mes)  AS variacion,
       ROUND((total - LAG(total) OVER (ORDER BY mes)) / LAG(total) OVER (ORDER BY mes) * 100, 1) AS variacion_pct
FROM mensual
ORDER BY mes;
-- T-SQL: DATEFROMPARTS(YEAR(fechaRegistro), MONTH(fechaRegistro), 1) en lugar de date_trunc.

-- 6. Qué porcentaje de las ventas (ingreso del detalle, pagadas) aporta cada categoría.
SELECT c.nombre AS categoria, SUM(d.total) AS ingreso,
       ROUND(SUM(d.total) / SUM(SUM(d.total)) OVER () * 100, 2) AS porcentaje
FROM DetalleVenta d
JOIN Venta v     ON v.idVenta = d.idVenta AND v.estado = 'PAGADA'
JOIN Producto p  ON p.idProducto = d.idProducto
JOIN Categoria c ON c.idCategoria = p.idCategoria
GROUP BY c.nombre
ORDER BY ingreso DESC;
-- OVER () vacío = la ventana es todo el resultado. SUM(SUM(...)) suma los totales de los grupos.

-- 7. Para cada compra pagada de los clientes, cuántos días pasaron desde su compra anterior.
SELECT cl.nombreCompleto, v.numeroDocumento, v.fechaRegistro::date AS fecha,
       v.fechaRegistro::date
         - LAG(v.fechaRegistro::date) OVER (PARTITION BY v.idCliente ORDER BY v.fechaRegistro) AS dias_desde_anterior
FROM Venta v
JOIN Cliente cl ON cl.idCliente = v.idCliente
WHERE v.estado = 'PAGADA'
ORDER BY cl.nombreCompleto, v.fechaRegistro;
-- T-SQL: DATEDIFF(day, LAG(v.fechaRegistro) OVER (...), v.fechaRegistro)

-- 8. Promedio móvil de 3 meses del total pagado mensual (el mes y los 2 anteriores).
WITH mensual AS (
    SELECT date_trunc('month', fechaRegistro)::date AS mes, SUM(total) AS total
    FROM Venta WHERE estado = 'PAGADA'
    GROUP BY 1
)
SELECT to_char(mes, 'YYYY-MM') AS mes, total,
       ROUND(AVG(total) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS promedio_movil_3m
FROM mensual
ORDER BY mes;

-- 9. Divide a los clientes que compraron en 4 grupos (cuartiles) según lo que gastaron.
SELECT cl.nombreCompleto, SUM(v.total) AS gastado,
       NTILE(4) OVER (ORDER BY SUM(v.total) DESC) AS cuartil      -- 1 = los que más gastan
FROM Venta v
JOIN Cliente cl ON cl.idCliente = v.idCliente
WHERE v.estado = 'PAGADA'
GROUP BY cl.nombreCompleto
ORDER BY gastado DESC;

-- 10. La primera y la última compra pagada de cada cliente (fecha y documento) en una sola fila.
SELECT DISTINCT cl.nombreCompleto,
       FIRST_VALUE(v.numeroDocumento) OVER w AS primera_compra,
       LAST_VALUE(v.numeroDocumento)  OVER w AS ultima_compra,
       COUNT(*) OVER (PARTITION BY v.idCliente) AS compras
FROM Venta v
JOIN Cliente cl ON cl.idCliente = v.idCliente
WHERE v.estado = 'PAGADA'
WINDOW w AS (PARTITION BY v.idCliente ORDER BY v.fechaRegistro
             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
ORDER BY cl.nombreCompleto;
-- Sin el "ROWS BETWEEN ... UNBOUNDED FOLLOWING", LAST_VALUE devuelve la fila actual (trampa clásica).
-- La cláusula WINDOW w AS (...) existe en PostgreSQL y en SQL Server 2022+.

-- 11. La mejor venta de cada cliente (resuelve el reto 23 de JOINs sin DISTINCT ON).
SELECT cliente, numeroDocumento, total
FROM (
    SELECT cl.nombreCompleto AS cliente, v.numeroDocumento, v.total,
           ROW_NUMBER() OVER (PARTITION BY v.idCliente ORDER BY v.total DESC) AS rn
    FROM Venta v
    JOIN Cliente cl ON cl.idCliente = v.idCliente
    WHERE v.estado = 'PAGADA'
) t
WHERE rn = 1
ORDER BY total DESC;
