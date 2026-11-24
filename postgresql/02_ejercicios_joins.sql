-- =====================================================================
-- 02_ejercicios_joins.sql
-- Ejercicios de JOINs sobre DBVENTA (PostgreSQL). Escribe tu consulta debajo de cada uno.
-- Entre paréntesis está cuántas filas debería devolver, para que te autocorrijas.
-- Las soluciones están en 03_soluciones_joins.sql (¡no hagas trampa!).
--
-- Mapa de relaciones:
--   Rol 1──* Usuario
--   Rol 1──* MenuRol *──1 Menu          (muchos a muchos)
--   Categoria 1──* Producto 1──* DetalleVenta *──1 Venta
-- =====================================================================

-- NIVEL 1 · INNER JOIN ------------------------------------------------

-- 1. Lista cada producto con el nombre de su categoría y su precio.         (15 filas)
--    ¿Por qué no aparece 'cable hdmi generico'?

-- 2. Lista los usuarios con el nombre de su rol.                             (3 filas)

-- 3. Muestra el detalle de la venta '00004': producto, cantidad, precio y total.   (3 filas)

-- NIVEL 2 · Varias tablas ---------------------------------------------

-- 4. ¿Qué menús ve cada rol? Muestra rol, menú y url.                        (12 filas)

-- 5. ¿Qué menús ve el usuario 'maria empleada'?                              (2 filas)

-- 6. Cada línea vendida con número de documento, fecha (sin hora), producto y categoría.  (22 filas)

-- NIVEL 3 · LEFT JOIN -------------------------------------------------

-- 7. Todas las categorías con sus productos, incluida la que no tiene productos.  (16 filas)

-- 8. Productos que nunca se vendieron.                                       (5 filas)

-- 9. Cuántos productos tiene cada categoría, mostrando 0 donde no hay.       (7 filas)
--    Pista: COUNT(*) y COUNT(columna) no dan lo mismo aquí.

-- 10. Unidades vendidas con 'Tarjeta' por producto, mostrando TODOS los productos (0 si no hubo).  (16 filas)
--     Pista: si pones el filtro de tipoPago en el WHERE, ¿qué le pasa al LEFT JOIN?

-- NIVEL 4 · JOIN + GROUP BY -------------------------------------------

-- 11. Total vendido (dinero y unidades) por categoría, de mayor a menor.    (5 filas)

-- 12. Top 3 productos por unidades vendidas.                                 (3 filas)

-- 13. Cantidad de ventas y total por mes (YYYY-MM) y tipo de pago.           (4 filas)

-- 14. Los menús de cada rol en una sola fila, separados por coma.           (3 filas)

-- NIVEL 5 · FULL, SELF y CROSS JOIN -----------------------------------

-- 15. Con un FULL JOIN entre Producto y Categoria, muestra solo los "huérfanos":
--     productos sin categoría y categorías sin productos.                    (2 filas)

-- 16. SELF JOIN: para cada producto, los productos de su misma categoría que son más caros.  (11 filas)

-- 17. CROSS JOIN: matriz de permisos con todas las combinaciones rol x menú y una
--     columna 'Sí'/'No' según si el rol tiene ese menú.                      (18 filas)

-- NIVEL 6 · Errores típicos -------------------------------------------

-- 18. Un compañero quiere "cuántos productos distintos se vendieron por categoría" y escribió:
--       SELECT c.nombre, COUNT(p.idProducto)
--       FROM Categoria c
--       JOIN Producto p     ON p.idCategoria = c.idCategoria
--       JOIN DetalleVenta d ON d.idProducto = p.idProducto
--       GROUP BY c.nombre;
--     Laptops le da 5. ¿Por qué está mal y cómo lo arreglas?                 (5 filas)

-- RETO FINAL: por cada tipo de pago, la venta promedio y la categoría que más dinero vendió.  (2 filas)
--     Pista: WITH (CTE) + ROW_NUMBER() OVER (PARTITION BY ...).
