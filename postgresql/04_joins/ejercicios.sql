-- =====================================================================
-- Módulo 04 · JOINs · EJERCICIOS
-- Mapa de relaciones en el README.md de esta carpeta.
-- Los JOINs se escriben IGUAL en PostgreSQL y en SQL Server.
-- Escribe tu consulta debajo de cada enunciado y compara con "Resultado esperado".
-- Las respuestas están en soluciones.sql de esta misma carpeta (¡inténtalo primero!).
-- =====================================================================

-- ---------------------------------------------------------------------
-- NIVEL 1 · INNER JOIN: solo filas que coinciden en ambas tablas
-- ---------------------------------------------------------------------
-- 1. Cada producto con el nombre de su categoría y de su proveedor.
--    ¿Por qué no aparece 'cable hdmi generico'?
--    Resultado esperado: 17 filas


-- 2. Cada venta con el nombre del cliente y del vendedor (solo ventas con cliente).
--    Resultado esperado: 57 filas


-- 3. "Factura" de la venta '00006': cliente, cada producto, cantidad, precio, descuento y total.
--    Resultado esperado: 4 filas


-- ---------------------------------------------------------------------
-- NIVEL 2 · Cadenas de varias tablas y reportes
-- ---------------------------------------------------------------------
-- 4. Clientes con su ciudad y provincia.
--    Resultado esperado: 15 filas


-- 5. Qué menús puede ver cada usuario ACTIVO (Usuario -> Rol -> MenuRol -> Menu).
--    Resultado esperado: 20 filas


-- 6. Total vendido (ventas PAGADAS) por provincia del cliente, de mayor a menor.
--    Resultado esperado: 7 filas


-- 7. Ganancia por categoría en ventas pagadas: ingreso (total del detalle), costo
--    (costo del producto x cantidad) y ganancia. De mayor a menor ganancia.
--    Resultado esperado: 6 filas


-- 8. ¿Qué proveedor genera más ingresos? Ingresos y unidades por proveedor (ventas pagadas),
--    con la ciudad del proveedor.
--    Resultado esperado: 4 filas


-- 9. Ranking de vendedores en noviembre 2026: nombre, rol, ventas pagadas y total.
--    Resultado esperado: 5 filas


-- ---------------------------------------------------------------------
-- NIVEL 3 · LEFT JOIN: todas las filas de la izquierda aunque no coincidan
-- ---------------------------------------------------------------------
-- 10. TODOS los clientes con su número de compras pagadas y el total gastado
--     (0 para quien no compró). Pista: el filtro de estado va en el ON, no en el WHERE.
--    Resultado esperado: 15 filas


-- 11. Ciudades que no tienen ningún cliente.
--    Resultado esperado: 1 fila


-- 12. Proveedores que no tienen productos.
--    Resultado esperado: 1 fila


-- 13. Productos que nunca se vendieron, con su categoría ('Sin categoría' si no tiene).
--    Resultado esperado: 4 filas


-- 14. Todas las ventas de noviembre con el nombre del cliente; si no hay cliente
--     muestra 'Consumidor final'.
--    Resultado esperado: 7 filas


-- 15. Para cada categoría: cuántos productos tiene y cuántas unidades se vendieron
--     (ventas pagadas). Deben salir las 7 categorías, con 0 donde corresponda.
--    Resultado esperado: 7 filas


-- ---------------------------------------------------------------------
-- NIVEL 4 · SELF JOIN: una tabla unida consigo misma
-- ---------------------------------------------------------------------
-- 16. Cada usuario con el nombre de su jefe. El administrador no tiene jefe: debe salir igual.
--    Resultado esperado: 7 filas


-- 17. Total vendido por cada EQUIPO: cada supervisor con la suma de lo que vendieron
--     él y sus empleados directos (ventas pagadas).
--    Resultado esperado: 2 filas


-- 18. Pares de clientes que viven en la misma ciudad (cada par una sola vez).
--    Resultado esperado: 17 filas


-- ---------------------------------------------------------------------
-- NIVEL 5 · FULL JOIN, CROSS JOIN y JOIN por rangos
-- ---------------------------------------------------------------------
-- 19. Con FULL JOIN entre Producto y Categoria muestra solo los "huérfanos":
--     productos sin categoría y categorías sin productos.
--    Resultado esperado: 2 filas


-- 20. Matriz vendedor x mes (julio a noviembre) con el total vendido, mostrando 0 cuando
--     un vendedor no vendió nada ese mes. Solo vendedores que tienen al menos una venta.
--    Resultado esperado: 25 filas


-- 21. JOIN por rango (no por igualdad): clasifica los productos en rangos de precio
--     usando una tabla de rangos y cuenta cuántos hay en cada uno.
--    Resultado esperado: 4 filas


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
--    Resultado esperado: 5 filas


-- 23. RETO: la mejor venta (mayor total pagado) de cada cliente, con fecha, vendedor y
--     cuántos productos distintos tenía.
--    Resultado esperado: 14 filas
