-- =====================================================================
-- EJERCICIOS · Sistema de ventas (DBVENTA)
-- Funcionan con la base de sqlserver/ o de postgresql/. Del 1 al 16: pasos 1 y 2.
-- Del 17 al 22: después del paso 6 (clientes, vendedores y proveedores).
-- Escribe tu consulta debajo de cada enunciado y compara con el resultado esperado.
-- Soluciones: sqlserver/09_soluciones.sql y postgresql/09_soluciones.sql
-- Niveles: 1 a 5 JOINs básicos · 6 a 13 agrupaciones y subconsultas · 14 a 16 avanzados
--          17 a 21 relaciones del paso 6 · 22 "arregla la consulta" (errores del paso 8).
-- =====================================================================

-- 1. Lista los productos con el nombre de su categoría, del más caro al más barato.
--    Resultado esperado: 15 filas



-- 2. ¿Cuántos productos hay en cada categoría?
--    Resultado esperado: 6 filas



-- 3. ¿Cuánto dinero hay en inventario (stock x precio) por categoría?
--    Resultado esperado: 6 filas



-- 4. Los menús de cada rol en una sola fila, separados por coma.
--    Resultado esperado: 3 filas



-- 5. ¿Qué usuarios pueden entrar a la pantalla 'Reportes'?
--    Resultado esperado: 2 filas



-- 6. Total vendido por día en noviembre (solo los días con ventas).
--    Resultado esperado: 18 filas



-- 7. Total por tipo de pago y qué porcentaje del total representa.
--    Resultado esperado: 2 filas



-- 8. Los 5 productos con más unidades vendidas.
--    Resultado esperado: 5 filas



-- 9. Productos que nunca se vendieron.
--    Resultado esperado: 3 filas



-- 10. Ingresos por categoría, incluyendo las que no vendieron nada (con 0).
--    Resultado esperado: 6 filas



-- 11. Ticket promedio, venta más alta y venta más baja.
--    Resultado esperado: 1 fila



-- 12. Ventas cuyo total supera el ticket promedio.
--    Resultado esperado: 10 filas



-- 13. Ventas por semana del año (número de semana ISO).
--    Resultado esperado: 5 filas



-- 14. En cada venta con más de un producto: qué porcentaje del total aporta cada línea.
--    Resultado esperado: 23 filas



-- 15. "Comprados juntos": pares de productos que aparecieron en la misma venta y cuántas veces.
--    Resultado esperado: 16 filas



-- 16. ¿Cuánto stock tenía cada producto antes de las ventas? (stock actual + unidades vendidas)
--    Resultado esperado: 15 filas



-- =====================================================================
-- Ejercicios del paso 6 en adelante
-- =====================================================================

-- 17. Cuánto compró cada cliente (número de compras y total), incluidos los que nunca
--     compraron, que deben salir con 0. Del que más compró al que menos.
--    Resultado esperado: 6 filas



-- 18. Clientes que nunca compraron. Hazlo con NOT EXISTS y luego prueba con NOT IN:
--     ¿por qué NOT IN devuelve 0 filas?
--    Resultado esperado: 1 fila



-- 19. Por cada vendedor: su rol, cuántas ventas hizo, el total vendido y el nombre de su
--     jefe ('(sin jefe)' si no tiene).
--    Resultado esperado: 3 filas



-- 20. Cadena de mando de cada usuario con una CTE recursiva, por ejemplo:
--     'maria empleada > jose supervisor > codigo estudiante'
--    Resultado esperado: 3 filas



-- 21. Productos con más de un proveedor: el costo del proveedor principal, el costo más
--     bajo que se consigue y cuánto se ahorraría por unidad comprando al más barato.
--    Resultado esperado: 5 filas



-- 22. ARREGLA LA CONSULTA. Debería dar el total de las ventas que incluyen al menos un
--     teclado (categoría 3). Da 23960.00, pero lo real es 19310.00. ¿Por qué? Corrígela.
--
--     SELECT SUM(v.total) AS total
--     FROM Venta v
--     INNER JOIN DetalleVenta d ON d.idVenta = v.idVenta
--     INNER JOIN Producto p     ON p.idProducto = d.idProducto
--     WHERE p.idCategoria = 3;
--
--    Resultado esperado: 1 fila (19310.00)
