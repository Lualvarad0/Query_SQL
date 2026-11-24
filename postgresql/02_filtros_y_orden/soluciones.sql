-- =====================================================================
-- Módulo 02 · Filtros (WHERE) y orden (ORDER BY, LIMIT) · SOLUCIONES
-- =====================================================================

-- 1. Productos que cuestan más de 1000, del más caro al más barato.
SELECT nombre, precio
FROM Producto
WHERE precio > 1000
ORDER BY precio DESC;

-- 2. Productos de las categorías 1 (Laptops) o 2 (Monitores) que tengan 20 o más en stock.
SELECT nombre, idCategoria, stock
FROM Producto
WHERE (idCategoria = 1 OR idCategoria = 2)   -- ¡los paréntesis importan! AND va antes que OR
  AND stock >= 20;

-- 3. Ventas pagadas con Tarjeta o Transferencia (usa IN).
SELECT numeroDocumento, tipoPago, total
FROM Venta
WHERE tipoPago IN ('Tarjeta', 'Transferencia');

-- 4. Ventas de octubre de 2026.
SELECT numeroDocumento, fechaRegistro, total
FROM Venta
WHERE fechaRegistro >= '2026-10-01'
  AND fechaRegistro <  '2026-11-01'
ORDER BY fechaRegistro;
-- Ojo: BETWEEN '2026-10-01' AND '2026-10-31' pierde las ventas del 31 después de las 00:00,
-- porque fechaRegistro tiene hora. El rango [inicio, fin) es la forma segura (igual en T-SQL).

-- 5. Productos cuyo nombre empieza con 'laptop'.
SELECT nombre FROM Producto WHERE nombre LIKE 'laptop%';

-- 6. Productos que contienen 'LOGITECH' sin importar mayúsculas.
SELECT nombre FROM Producto WHERE nombre ILIKE '%LOGITECH%';
-- T-SQL: nombre LIKE '%LOGITECH%' ya ignora mayúsculas con la intercalación por defecto.
-- En PostgreSQL LIKE sí las distingue; por eso existe ILIKE.

-- 7. Clientes que no tienen correo registrado.
SELECT nombreCompleto, telefono
FROM Cliente
WHERE correo IS NULL;          -- correo = NULL nunca es verdadero: siempre usa IS NULL

-- 8. Clientes que tienen correo Y teléfono.
SELECT nombreCompleto, correo, telefono
FROM Cliente
WHERE correo IS NOT NULL AND telefono IS NOT NULL;

-- 9. Ventas que no están anuladas y cuyo total supera 5000, de la más reciente a la más antigua.
SELECT numeroDocumento, fechaRegistro, total
FROM Venta
WHERE estado <> 'ANULADA'
  AND total > 5000
ORDER BY fechaRegistro DESC;

-- 10. Clientes ordenados por ciudad (idCiudad) y, dentro de cada ciudad, por nombre.
SELECT idCiudad, nombreCompleto
FROM Cliente
ORDER BY idCiudad, nombreCompleto;

-- 11. Los 5 productos más caros.
SELECT nombre, precio
FROM Producto
ORDER BY precio DESC, nombre
LIMIT 5;
-- T-SQL: SELECT TOP 5 nombre, precio FROM Producto ORDER BY precio DESC, nombre;

-- 12. "Página 2" del catálogo ordenado por nombre, de 5 en 5 (productos 6 al 10).
SELECT nombre, precio
FROM Producto
ORDER BY nombre
LIMIT 5 OFFSET 5;
-- T-SQL (y también PostgreSQL): ORDER BY nombre OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;

-- 13. Productos con stock por debajo de su stock mínimo (hay que reponer).
SELECT codigo, nombre, stock, stockMinimo
FROM Producto
WHERE stock < stockMinimo;

-- 14. Productos que NO son de la categoría 1. ¿Aparece 'cable hdmi generico'? ¿Por qué?
--     Escribe una versión que sí lo incluya.
SELECT nombre, idCategoria
FROM Producto
WHERE idCategoria IS DISTINCT FROM 1;
-- Con WHERE idCategoria <> 1 el cable NO sale: NULL <> 1 da NULL (desconocido), no verdadero.
-- Otra forma: WHERE idCategoria <> 1 OR idCategoria IS NULL
-- (IS DISTINCT FROM existe en SQL Server desde la versión 2022)
