-- =====================================================================
-- Módulo 04 · JOINs · SOLUCIONES
-- Mapa de relaciones en el README.md de esta carpeta.
-- Los JOINs se escriben IGUAL en PostgreSQL y en SQL Server.
-- =====================================================================

-- ---------------------------------------------------------------------
-- NIVEL 1 · INNER JOIN: solo filas que coinciden en ambas tablas
-- ---------------------------------------------------------------------

-- 1. Cada producto con el nombre de su categoría y de su proveedor.
--    ¿Por qué no aparece 'cable hdmi generico'?
SELECT p.codigo, p.nombre AS producto, c.nombre AS categoria, pr.nombre AS proveedor, p.precio
FROM Producto p
INNER JOIN Categoria c  ON c.idCategoria  = p.idCategoria
INNER JOIN Proveedor pr ON pr.idProveedor = p.idProveedor
ORDER BY c.nombre, p.precio DESC;
-- El cable tiene idCategoria NULL: NULL = algo nunca es verdadero, así que el INNER JOIN lo descarta.

-- 2. Cada venta con el nombre del cliente y del vendedor (solo ventas con cliente).
SELECT v.numeroDocumento, v.fechaRegistro::date AS fecha,   -- T-SQL: CAST(v.fechaRegistro AS date)
       cl.nombreCompleto AS cliente, u.nombreCompleto AS vendedor, v.total
FROM Venta v
JOIN Cliente cl ON cl.idCliente = v.idCliente
JOIN Usuario u  ON u.idUsuario  = v.idUsuario
ORDER BY v.fechaRegistro;

-- 3. "Factura" de la venta '00006': cliente, cada producto, cantidad, precio, descuento y total.
SELECT v.numeroDocumento, cl.nombreCompleto AS cliente, cl.documento,
       p.nombre AS producto, d.cantidad, d.precio, d.descuento || ' %' AS descuento, d.total
FROM Venta v
JOIN Cliente cl     ON cl.idCliente = v.idCliente
JOIN DetalleVenta d ON d.idVenta    = v.idVenta
JOIN Producto p     ON p.idProducto = d.idProducto
WHERE v.numeroDocumento = '00006';

-- ---------------------------------------------------------------------
-- NIVEL 2 · Cadenas de varias tablas y reportes
-- ---------------------------------------------------------------------

-- 4. Clientes con su ciudad y provincia.
SELECT cl.nombreCompleto, ci.nombre AS ciudad, ci.provincia
FROM Cliente cl
JOIN Ciudad ci ON ci.idCiudad = cl.idCiudad
ORDER BY ci.provincia, cl.nombreCompleto;

-- 5. Qué menús puede ver cada usuario ACTIVO (Usuario -> Rol -> MenuRol -> Menu).
SELECT u.nombreCompleto, r.nombre AS rol, m.nombre AS menu
FROM Usuario u
JOIN Rol r      ON r.idRol   = u.idRol
JOIN MenuRol mr ON mr.idRol  = r.idRol
JOIN Menu m     ON m.idMenu  = mr.idMenu
WHERE u.esActivo
ORDER BY u.idUsuario, m.idMenu;

-- 6. Total vendido (ventas PAGADAS) por provincia del cliente, de mayor a menor.
SELECT ci.provincia, COUNT(*) AS ventas, SUM(v.total) AS total
FROM Venta v
JOIN Cliente cl ON cl.idCliente = v.idCliente
JOIN Ciudad ci  ON ci.idCiudad  = cl.idCiudad
WHERE v.estado = 'PAGADA'
GROUP BY ci.provincia
ORDER BY total DESC;

-- 7. Ganancia por categoría en ventas pagadas: ingreso (total del detalle), costo
--    (costo del producto x cantidad) y ganancia. De mayor a menor ganancia.
SELECT c.nombre AS categoria,
       SUM(d.total)                         AS ingreso,
       SUM(p.costo * d.cantidad)            AS costo,
       SUM(d.total - p.costo * d.cantidad)  AS ganancia
FROM DetalleVenta d
JOIN Venta v     ON v.idVenta     = d.idVenta
JOIN Producto p  ON p.idProducto  = d.idProducto
JOIN Categoria c ON c.idCategoria = p.idCategoria
WHERE v.estado = 'PAGADA'
GROUP BY c.nombre
ORDER BY ganancia DESC;

-- 8. ¿Qué proveedor genera más ingresos? Ingresos y unidades por proveedor (ventas pagadas),
--    con la ciudad del proveedor.
SELECT pr.nombre AS proveedor, ci.nombre AS ciudad,
       SUM(d.cantidad) AS unidades, SUM(d.total) AS ingreso
FROM DetalleVenta d
JOIN Venta v      ON v.idVenta      = d.idVenta AND v.estado = 'PAGADA'
JOIN Producto p   ON p.idProducto   = d.idProducto
JOIN Proveedor pr ON pr.idProveedor = p.idProveedor
JOIN Ciudad ci    ON ci.idCiudad    = pr.idCiudad
GROUP BY pr.nombre, ci.nombre
ORDER BY ingreso DESC;

-- 9. Ranking de vendedores en noviembre 2026: nombre, rol, ventas pagadas y total.
SELECT u.nombreCompleto AS vendedor, r.nombre AS rol, COUNT(*) AS ventas, SUM(v.total) AS total
FROM Venta v
JOIN Usuario u ON u.idUsuario = v.idUsuario
JOIN Rol r     ON r.idRol     = u.idRol
WHERE v.estado = 'PAGADA'
  AND v.fechaRegistro >= '2026-11-01' AND v.fechaRegistro < '2026-12-01'
GROUP BY u.nombreCompleto, r.nombre
ORDER BY total DESC;

-- ---------------------------------------------------------------------
-- NIVEL 3 · LEFT JOIN: todas las filas de la izquierda aunque no coincidan
-- ---------------------------------------------------------------------

-- 10. TODOS los clientes con su número de compras pagadas y el total gastado
--     (0 para quien no compró). Pista: el filtro de estado va en el ON, no en el WHERE.
SELECT cl.nombreCompleto,
       COUNT(v.idVenta)          AS compras,
       COALESCE(SUM(v.total), 0) AS total_gastado      -- T-SQL: ISNULL(SUM(v.total), 0) o COALESCE
FROM Cliente cl
LEFT JOIN Venta v ON v.idCliente = cl.idCliente
                 AND v.estado = 'PAGADA'
GROUP BY cl.idCliente, cl.nombreCompleto
ORDER BY total_gastado DESC;
-- MAL: poner "WHERE v.estado = 'PAGADA'" elimina las filas con v NULL y Valeria desaparece:
-- el LEFT JOIN se convierte en un INNER JOIN sin que te des cuenta.

-- 11. Ciudades que no tienen ningún cliente.
SELECT ci.nombre, ci.provincia
FROM Ciudad ci
LEFT JOIN Cliente cl ON cl.idCiudad = ci.idCiudad
WHERE cl.idCliente IS NULL;
-- Patrón "anti-join": LEFT JOIN + WHERE <pk de la derecha> IS NULL.

-- 12. Proveedores que no tienen productos.
SELECT pr.nombre, pr.ruc
FROM Proveedor pr
LEFT JOIN Producto p ON p.idProveedor = pr.idProveedor
WHERE p.idProducto IS NULL;

-- 13. Productos que nunca se vendieron, con su categoría ('Sin categoría' si no tiene).
SELECT p.codigo, p.nombre, COALESCE(c.nombre, 'Sin categoría') AS categoria, p.stock
FROM Producto p
LEFT JOIN Categoria c    ON c.idCategoria = p.idCategoria
LEFT JOIN DetalleVenta d ON d.idProducto  = p.idProducto
WHERE d.idDetalleVenta IS NULL
ORDER BY p.idProducto;

-- 14. Todas las ventas de noviembre con el nombre del cliente; si no hay cliente
--     muestra 'Consumidor final'.
SELECT v.numeroDocumento, v.fechaRegistro::date AS fecha,
       COALESCE(cl.nombreCompleto, 'Consumidor final') AS cliente, v.total, v.estado
FROM Venta v
LEFT JOIN Cliente cl ON cl.idCliente = v.idCliente
WHERE v.fechaRegistro >= '2026-11-01' AND v.fechaRegistro < '2026-12-01'
ORDER BY v.fechaRegistro;

-- 15. Para cada categoría: cuántos productos tiene y cuántas unidades se vendieron
--     (ventas pagadas). Deben salir las 7 categorías, con 0 donde corresponda.
SELECT c.nombre AS categoria,
       COUNT(DISTINCT p.idProducto)  AS productos,
       COALESCE(SUM(d.cantidad), 0)  AS unidades_vendidas
FROM Categoria c
LEFT JOIN Producto p ON p.idCategoria = c.idCategoria
LEFT JOIN (DetalleVenta d
           JOIN Venta v ON v.idVenta = d.idVenta AND v.estado = 'PAGADA')
       ON d.idProducto = p.idProducto
GROUP BY c.idCategoria, c.nombre
ORDER BY c.idCategoria;
-- El paréntesis hace primero el INNER JOIN Detalle-Venta y luego ese bloque se une con LEFT.
-- COUNT(DISTINCT ...) evita contar un producto una vez por cada línea vendida.

-- ---------------------------------------------------------------------
-- NIVEL 4 · SELF JOIN: una tabla unida consigo misma
-- ---------------------------------------------------------------------

-- 16. Cada usuario con el nombre de su jefe. El administrador no tiene jefe: debe salir igual.
SELECT u.nombreCompleto AS usuario, r.nombre AS rol,
       COALESCE(j.nombreCompleto, '(sin jefe)') AS jefe
FROM Usuario u
JOIN Rol r          ON r.idRol      = u.idRol
LEFT JOIN Usuario j ON j.idUsuario  = u.idJefe
ORDER BY u.idUsuario;

-- 17. Total vendido por cada EQUIPO: cada supervisor con la suma de lo que vendieron
--     él y sus empleados directos (ventas pagadas).
SELECT s.nombreCompleto AS supervisor,
       COUNT(v.idVenta) AS ventas_equipo,
       SUM(v.total)     AS total_equipo
FROM Usuario s
JOIN Usuario m ON m.idUsuario = s.idUsuario OR m.idJefe = s.idUsuario   -- el supervisor y su gente
JOIN Venta v   ON v.idUsuario = m.idUsuario AND v.estado = 'PAGADA'
WHERE s.idRol = 3
GROUP BY s.nombreCompleto
ORDER BY total_equipo DESC;

-- 18. Pares de clientes que viven en la misma ciudad (cada par una sola vez).
SELECT ci.nombre AS ciudad, a.nombreCompleto AS cliente_1, b.nombreCompleto AS cliente_2
FROM Cliente a
JOIN Cliente b ON b.idCiudad = a.idCiudad AND b.idCliente > a.idCliente   -- ">" evita (A,B) y (B,A)
JOIN Ciudad ci ON ci.idCiudad = a.idCiudad
ORDER BY ci.nombre, a.nombreCompleto, b.nombreCompleto;

-- ---------------------------------------------------------------------
-- NIVEL 5 · FULL JOIN, CROSS JOIN y JOIN por rangos
-- ---------------------------------------------------------------------

-- 19. Con FULL JOIN entre Producto y Categoria muestra solo los "huérfanos":
--     productos sin categoría y categorías sin productos.
SELECT p.nombre AS producto, c.nombre AS categoria
FROM Producto p
FULL OUTER JOIN Categoria c ON c.idCategoria = p.idCategoria
WHERE p.idProducto IS NULL OR c.idCategoria IS NULL;

-- 20. Matriz vendedor x mes (julio a noviembre) con el total vendido, mostrando 0 cuando
--     un vendedor no vendió nada ese mes. Solo vendedores que tienen al menos una venta.
WITH meses AS (
    SELECT generate_series('2026-07-01'::date, '2026-11-01', interval '1 month')::date AS mes
), vendedores AS (
    SELECT DISTINCT u.idUsuario, u.nombreCompleto
    FROM Usuario u JOIN Venta v ON v.idUsuario = u.idUsuario
)
SELECT vd.nombreCompleto AS vendedor, to_char(m.mes, 'YYYY-MM') AS mes,
       COALESCE(SUM(v.total), 0) AS total
FROM vendedores vd
CROSS JOIN meses m
LEFT JOIN Venta v ON v.idUsuario = vd.idUsuario
                 AND v.estado = 'PAGADA'
                 AND date_trunc('month', v.fechaRegistro) = m.mes
GROUP BY vd.nombreCompleto, m.mes
ORDER BY vd.nombreCompleto, m.mes;
-- generate_series es de PostgreSQL. En T-SQL usarías una tabla calendario o
-- GENERATE_SERIES (SQL Server 2022) / una CTE recursiva.

-- 21. JOIN por rango (no por igualdad): clasifica los productos en rangos de precio
--     usando una tabla de rangos y cuenta cuántos hay en cada uno.
WITH rangos (rango, desde, hasta) AS (
    VALUES ('0 - 99', 0, 100), ('100 - 999', 100, 1000), ('1000 - 1999', 1000, 2000), ('2000 o más', 2000, 1000000)
)
SELECT r.rango, COUNT(p.idProducto) AS productos, STRING_AGG(p.codigo, ', ' ORDER BY p.codigo) AS codigos
FROM rangos r
LEFT JOIN Producto p ON p.precio >= r.desde AND p.precio < r.hasta
GROUP BY r.rango, r.desde
ORDER BY r.desde;
-- T-SQL: STRING_AGG(p.codigo, ', ') WITHIN GROUP (ORDER BY p.codigo)

-- ---------------------------------------------------------------------
-- NIVEL 6 · Errores típicos
-- ---------------------------------------------------------------------

-- 22. El JOIN que infla los números. Alguien quiere el total facturado por vendedor y escribe:
--       SELECT u.nombreCompleto, SUM(v.total)
--       FROM Usuario u
--       JOIN Venta v        ON v.idUsuario = u.idUsuario AND v.estado = 'PAGADA'
--       JOIN DetalleVenta d ON d.idVenta   = v.idVenta
--       GROUP BY u.nombreCompleto;
--     Los totales salen mucho más altos que en el ejercicio 7 del módulo 03. ¿Por qué? Corrígelo.
SELECT u.nombreCompleto, SUM(v.total) AS total, COUNT(*) AS ventas
FROM Usuario u
JOIN Venta v ON v.idUsuario = u.idUsuario AND v.estado = 'PAGADA'
GROUP BY u.nombreCompleto
ORDER BY total DESC;
-- Cada venta se repite una vez por cada línea de detalle, así que v.total se suma varias veces.
-- Si no necesitas columnas del detalle, no lo unas. Si las necesitas, agrega primero el detalle
-- en una subconsulta y luego une el resultado (ver módulo 05).

-- 23. RETO: la mejor venta (mayor total pagado) de cada cliente, con fecha, vendedor y
--     cuántos productos distintos tenía.
SELECT DISTINCT ON (cl.idCliente)
       cl.nombreCompleto AS cliente, v.numeroDocumento, v.fechaRegistro::date AS fecha,
       u.nombreCompleto AS vendedor, v.total,
       (SELECT COUNT(*) FROM DetalleVenta d WHERE d.idVenta = v.idVenta) AS productos
FROM Cliente cl
JOIN Venta v   ON v.idCliente = cl.idCliente AND v.estado = 'PAGADA'
JOIN Usuario u ON u.idUsuario = v.idUsuario
ORDER BY cl.idCliente, v.total DESC;
-- DISTINCT ON es exclusivo de PostgreSQL. En T-SQL (y también en PG) se resuelve con
-- ROW_NUMBER() OVER (PARTITION BY cl.idCliente ORDER BY v.total DESC) = 1 (módulo 06).
