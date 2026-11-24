-- =====================================================================
-- Módulo 01 · SELECT básico · SOLUCIONES
-- =====================================================================

-- 1. Muestra todas las columnas y filas de la tabla Categoria.
SELECT * FROM Categoria;
-- En consultas de verdad evita SELECT *: pide solo las columnas que usas.

-- 2. Muestra el código, nombre y precio de todos los productos.
SELECT codigo, nombre, precio
FROM Producto;

-- 3. Repite la anterior pero con los encabezados "producto" y "precio de venta".
SELECT nombre AS producto,
       precio AS "precio de venta"   -- con espacios: comillas dobles. T-SQL: [precio de venta]
FROM Producto;

-- 4. Para cada producto calcula la ganancia por unidad (precio - costo) y el margen
--    en porcentaje con 1 decimal.
SELECT nombre,
       precio - costo                          AS ganancia_unidad,
       ROUND((precio - costo) / precio * 100, 1) AS margen_pct
FROM Producto;

-- 5. Muestra el precio de cada producto con IVA (15 %), redondeado a 2 decimales.
SELECT nombre, precio, ROUND(precio * 1.15, 2) AS precio_con_iva
FROM Producto;

-- 6. ¿Qué tipos de pago existen en las ventas? Sin repetir.
SELECT DISTINCT tipoPago
FROM Venta;

-- 7. Lista las provincias donde hay ciudades registradas, sin repetir y en orden alfabético.
SELECT DISTINCT provincia
FROM Ciudad
ORDER BY provincia;

-- 8. Clasifica cada producto: 'Premium' si cuesta 1500 o más, 'Medio' desde 500,
--    y 'Económico' el resto.
SELECT nombre, precio,
       CASE
           WHEN precio >= 1500 THEN 'Premium'
           WHEN precio >= 500  THEN 'Medio'
           ELSE 'Económico'
       END AS gama
FROM Producto;

-- 9. Muestra cada cliente como texto "Nombre <correo>". Si no tiene correo,
--    muestra "Nombre <sin correo>".
SELECT nombreCompleto || ' <' || COALESCE(correo, 'sin correo') || '>' AS contacto
FROM Cliente;
-- Sin COALESCE, 'texto' || NULL da NULL y perderías el nombre.
-- T-SQL: nombreCompleto + ' <' + ISNULL(correo, 'sin correo') + '>'
--        (o CONCAT(...), que en ambos motores trata NULL como texto vacío)

-- 10. Muestra el nombre de cada usuario en MAYÚSCULAS y la cantidad de letras de su nombre.
SELECT UPPER(nombreCompleto) AS nombre, LENGTH(nombreCompleto) AS letras
FROM Usuario;
-- T-SQL: LEN(nombreCompleto)
