-- =====================================================================
-- 03_soluciones_joins.sql
-- Soluciones de 02_ejercicios_joins.sql (PostgreSQL).
-- Cuando la sintaxis de SQL Server (T-SQL) es distinta, va debajo como comentario "T-SQL:".
-- Intenta primero resolver cada ejercicio tú solo.
--   psql -d dbventa -f postgresql/03_soluciones_joins.sql
-- =====================================================================

-- =====================================================================
-- NIVEL 1 · INNER JOIN (solo filas que coinciden en ambas tablas)
-- =====================================================================

-- 1. Productos con el nombre de su categoría.  (15 filas: el cable sin categoría NO sale)
SELECT p.nombre AS producto, c.nombre AS categoria, p.precio
FROM Producto p
INNER JOIN Categoria c ON c.idCategoria = p.idCategoria
ORDER BY c.nombre, p.precio DESC;

-- 2. Usuarios con el nombre de su rol.  (3 filas)
SELECT u.nombreCompleto, u.correo, r.nombre AS rol
FROM Usuario u
JOIN Rol r ON r.idRol = u.idRol;          -- JOIN a secas = INNER JOIN

-- 3. Detalle de la venta '00004'.  (3 filas, suma 4400.00)
SELECT v.numeroDocumento, p.nombre AS producto, d.cantidad, d.precio, d.total
FROM Venta v
JOIN DetalleVenta d ON d.idVenta = v.idVenta
JOIN Producto p     ON p.idProducto = d.idProducto
WHERE v.numeroDocumento = '00004';

-- =====================================================================
-- NIVEL 2 · Varias tablas (cadenas de JOIN y tablas puente)
-- =====================================================================

-- 4. Qué menús ve cada rol. MenuRol es la tabla puente.  (12 filas)
SELECT r.nombre AS rol, m.nombre AS menu, m.url
FROM Rol r
JOIN MenuRol mr ON mr.idRol = r.idRol
JOIN Menu m     ON m.idMenu = mr.idMenu
ORDER BY r.nombre, m.idMenu;

-- 5. Menús que ve el usuario 'maria empleada'.  (2 filas: Venta, Historial Ventas)
SELECT u.nombreCompleto, m.nombre AS menu
FROM Usuario u
JOIN MenuRol mr ON mr.idRol = u.idRol     -- se salta la tabla Rol: no hace falta su nombre
JOIN Menu m     ON m.idMenu = mr.idMenu
WHERE u.nombreCompleto = 'maria empleada';

-- 6. Cada línea vendida con documento, fecha, producto y categoría.  (22 filas)
SELECT v.numeroDocumento,
       v.fechaRegistro::date AS fecha,     -- T-SQL: CAST(v.fechaRegistro AS date)
       p.nombre AS producto,
       c.nombre AS categoria,
       d.cantidad, d.total
FROM DetalleVenta d
JOIN Venta v     ON v.idVenta = d.idVenta
JOIN Producto p  ON p.idProducto = d.idProducto
JOIN Categoria c ON c.idCategoria = p.idCategoria
ORDER BY v.fechaRegistro;

-- =====================================================================
-- NIVEL 3 · LEFT JOIN (todas las filas de la izquierda, aunque no coincidan)
-- =====================================================================

-- 7. Todas las categorías con sus productos, incluida la que no tiene.  (16 filas; Impresoras con NULL)
SELECT c.nombre AS categoria, p.nombre AS producto
FROM Categoria c
LEFT JOIN Producto p ON p.idCategoria = c.idCategoria
ORDER BY c.idCategoria;

-- 8. Productos que nunca se vendieron (anti-join).  (5 filas: ids 3, 9, 13, 15, 16)
SELECT p.idProducto, p.nombre
FROM Producto p
LEFT JOIN DetalleVenta d ON d.idProducto = p.idProducto
WHERE d.idDetalleVenta IS NULL
ORDER BY p.idProducto;
-- Alternativa equivalente (y muchas veces más clara):
--   SELECT p.idProducto, p.nombre FROM Producto p
--   WHERE NOT EXISTS (SELECT 1 FROM DetalleVenta d WHERE d.idProducto = p.idProducto);

-- 9. Cantidad de productos por categoría, incluyendo las que tienen 0.  (7 filas)
SELECT c.nombre AS categoria, COUNT(p.idProducto) AS productos
FROM Categoria c
LEFT JOIN Producto p ON p.idCategoria = c.idCategoria
GROUP BY c.idCategoria, c.nombre
ORDER BY productos DESC, c.nombre;
-- Ojo: COUNT(*) daría 1 para Impresoras (cuenta la fila con NULL). COUNT(p.idProducto) da 0.

-- 10. La trampa ON vs WHERE: unidades vendidas con TARJETA por producto, mostrando TODOS los productos.
-- MAL: el filtro en WHERE elimina las filas NULL y el LEFT JOIN se vuelve INNER JOIN.
--   SELECT p.nombre, SUM(d.cantidad)
--   FROM Producto p
--   LEFT JOIN DetalleVenta d ON d.idProducto = p.idProducto
--   LEFT JOIN Venta v        ON v.idVenta = d.idVenta
--   WHERE v.tipoPago = 'Tarjeta'
--   GROUP BY p.nombre;                    -- solo salen los vendidos con tarjeta
-- BIEN: el filtro va dentro del JOIN.  (16 filas, con 0 donde no hubo ventas con tarjeta)
SELECT p.nombre AS producto,
       COALESCE(SUM(d.cantidad), 0) AS unidades_tarjeta   -- T-SQL: también COALESCE, o ISNULL(x, 0)
FROM Producto p
LEFT JOIN (DetalleVenta d
           JOIN Venta v ON v.idVenta = d.idVenta AND v.tipoPago = 'Tarjeta')
       ON d.idProducto = p.idProducto
GROUP BY p.idProducto, p.nombre
ORDER BY unidades_tarjeta DESC, p.nombre;

-- =====================================================================
-- NIVEL 4 · JOIN + GROUP BY (reportes)
-- =====================================================================

-- 11. Total vendido por categoría.  (5 filas; Laptops primero con 14400.00. Memorias no sale: nunca se vendió)
SELECT c.nombre AS categoria, SUM(d.total) AS total_vendido, SUM(d.cantidad) AS unidades
FROM DetalleVenta d
JOIN Producto p  ON p.idProducto = d.idProducto
JOIN Categoria c ON c.idCategoria = p.idCategoria
GROUP BY c.nombre
ORDER BY total_vendido DESC;

-- 12. Top 3 productos por unidades vendidas.  (hyperx 5, samsung book pro 4, y un empate a 3 que decide el ORDER BY por nombre)
SELECT p.nombre, SUM(d.cantidad) AS unidades
FROM DetalleVenta d
JOIN Producto p ON p.idProducto = d.idProducto
GROUP BY p.idProducto, p.nombre
ORDER BY unidades DESC, p.nombre
LIMIT 3;
-- T-SQL: SELECT TOP 3 p.nombre, SUM(d.cantidad) AS unidades ... ORDER BY unidades DESC
-- (ambos aceptan también: OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY)

-- 13. Ventas por mes y tipo de pago.  (4 filas)
SELECT to_char(v.fechaRegistro, 'YYYY-MM') AS mes,   -- T-SQL: FORMAT(v.fechaRegistro, 'yyyy-MM')
       v.tipoPago,
       COUNT(*)     AS ventas,
       SUM(v.total) AS total
FROM Venta v
GROUP BY mes, v.tipoPago                             -- T-SQL no deja usar el alias "mes" en GROUP BY
ORDER BY mes, v.tipoPago;

-- 14. Menús de cada rol en una sola fila, separados por coma.  (3 filas)
SELECT r.nombre AS rol,
       STRING_AGG(m.nombre, ', ' ORDER BY m.idMenu) AS menus
FROM Rol r
JOIN MenuRol mr ON mr.idRol = r.idRol
JOIN Menu m     ON m.idMenu = mr.idMenu
GROUP BY r.nombre;
-- T-SQL (2017+): STRING_AGG(m.nombre, ', ') WITHIN GROUP (ORDER BY m.idMenu)

-- =====================================================================
-- NIVEL 5 · FULL, SELF y CROSS JOIN
-- =====================================================================

-- 15. FULL JOIN: todos los productos y todas las categorías.  (17 filas)
--     Sale el cable sin categoría Y la categoría Impresoras sin productos.
SELECT p.nombre AS producto, c.nombre AS categoria
FROM Producto p
FULL OUTER JOIN Categoria c ON c.idCategoria = p.idCategoria
WHERE p.idProducto IS NULL OR c.idCategoria IS NULL;   -- quita este WHERE para ver las 17
-- (2 filas con el WHERE)

-- 16. SELF JOIN: pares de productos de la MISMA categoría donde el segundo es más caro.
SELECT c.nombre AS categoria,
       barato.nombre AS producto, barato.precio,
       caro.nombre   AS mas_caro,  caro.precio AS precio_mas_caro
FROM Producto barato
JOIN Producto caro ON caro.idCategoria = barato.idCategoria
                  AND caro.precio > barato.precio
JOIN Categoria c   ON c.idCategoria = barato.idCategoria
ORDER BY c.nombre, barato.precio;

-- 17. CROSS JOIN: matriz de permisos rol x menú (3 x 6 = 18 filas) con Sí/No.
SELECT r.nombre AS rol, m.nombre AS menu,
       CASE WHEN mr.idMenuRol IS NULL THEN 'No' ELSE 'Sí' END AS tiene_acceso
FROM Rol r
CROSS JOIN Menu m
LEFT JOIN MenuRol mr ON mr.idRol = r.idRol AND mr.idMenu = m.idMenu
ORDER BY r.idRol, m.idMenu;

-- =====================================================================
-- NIVEL 6 · Errores típicos
-- =====================================================================

-- 18. El JOIN que multiplica filas.
-- MAL: "productos por categoría" uniendo también DetalleVenta: cada venta repite el producto.
--   SELECT c.nombre, COUNT(p.idProducto)
--   FROM Categoria c
--   JOIN Producto p     ON p.idCategoria = c.idCategoria
--   JOIN DetalleVenta d ON d.idProducto = p.idProducto
--   GROUP BY c.nombre;              -- Laptops da 5, pero solo hay 3 laptops (y 2 vendidas)
-- BIEN: cuenta productos distintos.  (5 filas: solo categorías con algo vendido)
SELECT c.nombre AS categoria,
       COUNT(DISTINCT p.idProducto) AS productos_vendidos,
       COUNT(*)                     AS lineas_de_venta
FROM Categoria c
JOIN Producto p     ON p.idCategoria = c.idCategoria
JOIN DetalleVenta d ON d.idProducto = p.idProducto
GROUP BY c.nombre
ORDER BY c.nombre;

-- RETO FINAL: venta promedio por tipo de pago y la categoría más vendida en cada tipo de pago.
-- (pista: CTE con WITH + ROW_NUMBER() OVER (PARTITION BY ...), igual en PostgreSQL y T-SQL)
WITH por_pago AS (
    SELECT v.tipoPago, c.nombre AS categoria, SUM(d.total) AS total,
           ROW_NUMBER() OVER (PARTITION BY v.tipoPago ORDER BY SUM(d.total) DESC) AS puesto
    FROM Venta v
    JOIN DetalleVenta d ON d.idVenta = v.idVenta
    JOIN Producto p     ON p.idProducto = d.idProducto
    JOIN Categoria c    ON c.idCategoria = p.idCategoria
    GROUP BY v.tipoPago, c.nombre
)
SELECT pp.tipoPago, pp.categoria AS categoria_top, pp.total AS total_categoria,
       ROUND(AVG(v.total), 2) AS venta_promedio
FROM por_pago pp
JOIN Venta v ON v.tipoPago = pp.tipoPago
WHERE pp.puesto = 1
GROUP BY pp.tipoPago, pp.categoria, pp.total;
