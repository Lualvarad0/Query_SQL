-- =====================================================================
-- Módulo 05 · Subconsultas y CTE (WITH) · SOLUCIONES
-- =====================================================================

-- 1. Productos cuyo precio es mayor que el precio promedio de todos los productos.
SELECT nombre, precio
FROM Producto
WHERE precio > (SELECT AVG(precio) FROM Producto)   -- subconsulta escalar: devuelve 1 valor
ORDER BY precio DESC;

-- 2. Clientes que alguna vez compraron una laptop (categoría 'Laptops'), usando IN.
SELECT nombreCompleto
FROM Cliente
WHERE idCliente IN (
    SELECT v.idCliente
    FROM Venta v
    JOIN DetalleVenta d ON d.idVenta = v.idVenta
    JOIN Producto p     ON p.idProducto = d.idProducto
    JOIN Categoria c    ON c.idCategoria = p.idCategoria
    WHERE c.nombre = 'Laptops' AND v.estado = 'PAGADA'
)
ORDER BY nombreCompleto;

-- 3. La misma pregunta, pero con EXISTS.
SELECT cl.nombreCompleto
FROM Cliente cl
WHERE EXISTS (
    SELECT 1
    FROM Venta v
    JOIN DetalleVenta d ON d.idVenta = v.idVenta
    JOIN Producto p     ON p.idProducto = d.idProducto
    WHERE v.idCliente = cl.idCliente          -- correlacionada: depende de la fila de afuera
      AND v.estado = 'PAGADA'
      AND p.idCategoria = 1
)
ORDER BY cl.nombreCompleto;

-- 4. Clientes que nunca han pagado con Tarjeta (incluye a quien nunca compró).
SELECT cl.nombreCompleto
FROM Cliente cl
WHERE NOT EXISTS (
    SELECT 1 FROM Venta v
    WHERE v.idCliente = cl.idCliente AND v.tipoPago = 'Tarjeta' AND v.estado = 'PAGADA'
)
ORDER BY cl.nombreCompleto;

-- 5. La trampa de NOT IN con NULL. Esta consulta busca clientes sin ventas y devuelve 0 filas:
--       SELECT nombreCompleto FROM Cliente
--       WHERE idCliente NOT IN (SELECT idCliente FROM Venta);
--    ¿Por qué? Escribe una versión correcta.
SELECT nombreCompleto
FROM Cliente cl
WHERE NOT EXISTS (SELECT 1 FROM Venta v WHERE v.idCliente = cl.idCliente);
-- Venta tiene idCliente NULL (consumidor final). "x NOT IN (1, 2, NULL)" nunca es verdadero,
-- porque x <> NULL es desconocido. NOT EXISTS no tiene ese problema. Pasa igual en SQL Server.

-- 6. Cada producto con su precio y el precio promedio de SU categoría, y la diferencia.
SELECT p.nombre, p.idCategoria, p.precio,
       (SELECT ROUND(AVG(p2.precio), 2) FROM Producto p2
         WHERE p2.idCategoria = p.idCategoria)              AS promedio_categoria,
       p.precio - (SELECT AVG(p2.precio) FROM Producto p2
                    WHERE p2.idCategoria = p.idCategoria)   AS diferencia
FROM Producto p
WHERE p.idCategoria IS NOT NULL
ORDER BY p.idCategoria, p.precio DESC;

-- 7. Subconsulta en el FROM: ticket promedio (venta promedio) de cada cliente, y solo los clientes
--    cuyo ticket promedio supera el ticket promedio general de todas las ventas pagadas.
SELECT cl.nombreCompleto, t.compras, t.ticket_promedio
FROM (
    SELECT idCliente, COUNT(*) AS compras, ROUND(AVG(total), 2) AS ticket_promedio
    FROM Venta
    WHERE estado = 'PAGADA' AND idCliente IS NOT NULL
    GROUP BY idCliente
) t                                    -- en PG y T-SQL la subconsulta del FROM necesita alias
JOIN Cliente cl ON cl.idCliente = t.idCliente
WHERE t.ticket_promedio > (SELECT AVG(total) FROM Venta WHERE estado = 'PAGADA')
ORDER BY t.ticket_promedio DESC;

-- 8. Con CTE (WITH): total gastado por cada cliente y qué porcentaje representa del total
--    facturado. Solo los 5 mejores clientes.
WITH por_cliente AS (
    SELECT idCliente, SUM(total) AS gastado
    FROM Venta
    WHERE estado = 'PAGADA' AND idCliente IS NOT NULL
    GROUP BY idCliente
), global AS (
    SELECT SUM(total) AS facturado FROM Venta WHERE estado = 'PAGADA'
)
SELECT cl.nombreCompleto, pc.gastado,
       ROUND(pc.gastado / g.facturado * 100, 2) AS porcentaje
FROM por_cliente pc
JOIN Cliente cl ON cl.idCliente = pc.idCliente
CROSS JOIN global g
ORDER BY pc.gastado DESC
LIMIT 5;

-- 9. Resuelve el error del ejercicio 22 de JOINs con una CTE: por vendedor, total facturado
--    (sin inflar) Y unidades vendidas (que sí necesita el detalle).
WITH unidades AS (
    SELECT v.idUsuario, SUM(d.cantidad) AS unidades
    FROM Venta v JOIN DetalleVenta d ON d.idVenta = v.idVenta
    WHERE v.estado = 'PAGADA'
    GROUP BY v.idUsuario
), facturado AS (
    SELECT idUsuario, SUM(total) AS total
    FROM Venta WHERE estado = 'PAGADA'
    GROUP BY idUsuario
)
SELECT u.nombreCompleto, f.total, un.unidades
FROM facturado f
JOIN unidades un ON un.idUsuario = f.idUsuario
JOIN Usuario u   ON u.idUsuario  = f.idUsuario
ORDER BY f.total DESC;

-- 10. CTE recursiva: el organigrama completo con el nivel de cada usuario y su "ruta"
--     desde el administrador (ej: codigo estudiante > jose supervisor > maria empleada).
WITH RECURSIVE organigrama AS (
    SELECT idUsuario, nombreCompleto, 1 AS nivel,
           nombreCompleto::text AS ruta
    FROM Usuario
    WHERE idJefe IS NULL                         -- punto de partida: el que no tiene jefe
    UNION ALL
    SELECT u.idUsuario, u.nombreCompleto, o.nivel + 1,
           o.ruta || ' > ' || u.nombreCompleto
    FROM Usuario u
    JOIN organigrama o ON u.idJefe = o.idUsuario -- paso recursivo: los hijos de lo ya encontrado
)
SELECT nivel, nombreCompleto, ruta
FROM organigrama
ORDER BY ruta;
-- T-SQL: igual pero sin la palabra RECURSIVE (WITH organigrama AS (...)), y el texto se une con +.

-- 11. CTE recursiva para un calendario: ventas pagadas de cada día del 1 al 20 de noviembre,
--     incluyendo los días sin ventas (con 0).
WITH RECURSIVE dias AS (
    SELECT DATE '2026-11-01' AS dia
    UNION ALL
    SELECT dia + 1 FROM dias WHERE dia < DATE '2026-11-20'
)
SELECT d.dia, COUNT(v.idVenta) AS ventas, COALESCE(SUM(v.total), 0) AS total
FROM dias d
LEFT JOIN Venta v ON v.fechaRegistro::date = d.dia AND v.estado = 'PAGADA'
GROUP BY d.dia
ORDER BY d.dia;
-- En PostgreSQL también: SELECT generate_series(DATE '2026-11-01', DATE '2026-11-20', '1 day')

-- 12. Productos que se venden más que el promedio: unidades vendidas por producto (pagadas)
--     mayores al promedio de unidades por producto vendido.
WITH unidades AS (
    SELECT d.idProducto, SUM(d.cantidad) AS unidades
    FROM DetalleVenta d JOIN Venta v ON v.idVenta = d.idVenta
    WHERE v.estado = 'PAGADA'
    GROUP BY d.idProducto
)
SELECT p.nombre, u.unidades
FROM unidades u
JOIN Producto p ON p.idProducto = u.idProducto
WHERE u.unidades > (SELECT AVG(unidades) FROM unidades)
ORDER BY u.unidades DESC;
