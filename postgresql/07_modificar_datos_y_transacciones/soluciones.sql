-- =====================================================================
-- Módulo 07 · INSERT, UPDATE, DELETE y transacciones · SOLUCIONES
-- Cada ejercicio corre dentro de BEGIN ... ROLLBACK, así la base vuelve a
-- quedar como estaba y los demás módulos siguen dando los mismos resultados.
-- Cuando practiques de verdad, cambia ROLLBACK por COMMIT para guardar.
-- =====================================================================

-- 1. Registra un cliente nuevo de Loja y muestra el id que le asignó la base.
BEGIN;
INSERT INTO Cliente (documento, nombreCompleto, correo, telefono, idCiudad, fechaRegistro)
VALUES ('1105556667', 'Jorge Ochoa', 'jorge.o@example.com', '0987770000', 6, CURRENT_DATE)
RETURNING idCliente, nombreCompleto;
ROLLBACK;
-- @esperado: 1 fila con idCliente 16 (o mayor si ya lo corriste: un ROLLBACK no devuelve los números de la secuencia)
-- T-SQL: INSERT INTO Cliente (...) OUTPUT inserted.idCliente VALUES (...);  o  SELECT SCOPE_IDENTITY();

-- 2. Agrega dos ciudades en una sola sentencia y luego cuenta cuántas ciudades hay.
BEGIN;
INSERT INTO Ciudad (nombre, provincia) VALUES
('Riobamba', 'Chimborazo'),
('Ibarra',   'Imbabura');
SELECT COUNT(*) AS ciudades FROM Ciudad;
ROLLBACK;
-- @esperado: 10 ciudades

-- 3. INSERT ... SELECT: crea una tabla temporal con los clientes "VIP" (más de 15000 en compras
--    pagadas) y muéstrala.
BEGIN;
CREATE TEMP TABLE ClienteVip (idCliente INT, nombre VARCHAR(100), gastado NUMERIC(12,2));
INSERT INTO ClienteVip (idCliente, nombre, gastado)
SELECT cl.idCliente, cl.nombreCompleto, SUM(v.total)
FROM Cliente cl
JOIN Venta v ON v.idCliente = cl.idCliente AND v.estado = 'PAGADA'
GROUP BY cl.idCliente, cl.nombreCompleto
HAVING SUM(v.total) > 15000;
SELECT * FROM ClienteVip ORDER BY gastado DESC;
ROLLBACK;
-- @esperado: 5 clientes, encabezados por Carlos Mendoza con 25949.75
-- T-SQL: CREATE TABLE #ClienteVip (...)  -- las tablas temporales empiezan con #

-- 4. Sube 5 % el precio de todos los Monitores (por nombre de categoría, no por id)
--    y muestra cómo quedaron.
BEGIN;
UPDATE Producto p
SET precio = ROUND(p.precio * 1.05, 2)
FROM Categoria c
WHERE c.idCategoria = p.idCategoria
  AND c.nombre = 'Monitores';
SELECT nombre, precio FROM Producto WHERE idCategoria = 2 ORDER BY nombre;
ROLLBACK;
-- @esperado: 3 monitores con precios 1102.50, 1417.50 y 1470.00
-- T-SQL: UPDATE p SET precio = ROUND(p.precio * 1.05, 2)
--        FROM Producto p JOIN Categoria c ON c.idCategoria = p.idCategoria
--        WHERE c.nombre = 'Monitores';

-- 5. Desactiva (esActivo = FALSE) los productos del proveedor 'Austro Digital'.
--    ¿Cuántas filas se modificaron?
BEGIN;
UPDATE Producto
SET esActivo = FALSE
WHERE idProveedor = (SELECT idProveedor FROM Proveedor WHERE nombre = 'Austro Digital')
RETURNING codigo, nombre, esActivo;
ROLLBACK;
-- @esperado: 4 filas (UPDATE 4)

-- 6. Intenta borrar las ventas ANULADAS. ¿Qué error da? Bórralas bien (con su detalle)
--    dentro de la transacción.
BEGIN;
-- DELETE FROM Venta WHERE estado = 'ANULADA';
--   ERROR: update or delete on table "venta" violates foreign key constraint ... on table "detalleventa"
--   La llave foránea protege el detalle: primero hay que borrar a los "hijos".
DELETE FROM DetalleVenta
WHERE idVenta IN (SELECT idVenta FROM Venta WHERE estado = 'ANULADA');
DELETE FROM Venta WHERE estado = 'ANULADA';
SELECT COUNT(*) AS ventas_restantes FROM Venta;
ROLLBACK;
-- @esperado: 57 ventas restantes
-- En la vida real casi nunca se borran ventas: se marcan como ANULADA (borrado lógico), como ya hace esta base.

-- 7. "UPSERT": registra al cliente con documento '0912345678' con el teléfono '0990000000'.
--    Si ya existe, solo actualiza el teléfono.
BEGIN;
INSERT INTO Cliente (documento, nombreCompleto, telefono, idCiudad, fechaRegistro)
VALUES ('0912345678', 'Carlos Mendoza', '0990000000', 1, CURRENT_DATE)
ON CONFLICT (documento) DO UPDATE
    SET telefono = EXCLUDED.telefono            -- EXCLUDED = la fila que intentaste insertar
RETURNING idCliente, nombreCompleto, telefono;
ROLLBACK;
-- @esperado: 1 fila: idCliente 1 con el teléfono nuevo (no se creó otro cliente)
-- T-SQL: MERGE Cliente AS t USING (SELECT '0912345678' AS documento, ...) AS s
--        ON t.documento = s.documento
--        WHEN MATCHED THEN UPDATE SET telefono = s.telefono
--        WHEN NOT MATCHED THEN INSERT (...) VALUES (...);

-- 8. Transacción completa: registra la venta '00061' a 'Lucía Andrade' (vendedora maria) con
--    2 'auricular hyperx gamer' y 1 'mouse logitech g203', calcula totales, descuenta stock
--    y actualiza NumeroDocumento. Si algo falla, nada debe quedar a medias.
BEGIN;
WITH nueva AS (
    INSERT INTO Venta (numeroDocumento, idCliente, idUsuario, tipoPago)
    VALUES ('00061', 2, 4, 'Tarjeta')
    RETURNING idVenta
)
INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, precio, total)
SELECT n.idVenta, p.idProducto, x.cantidad, p.precio, p.precio * x.cantidad
FROM nueva n
CROSS JOIN (VALUES ('AUR-002', 2), ('ACC-004', 1)) AS x(codigo, cantidad)
JOIN Producto p ON p.codigo = x.codigo;

UPDATE Venta v
SET subtotal = s.suma, impuesto = ROUND(s.suma * 0.15, 2), total = s.suma + ROUND(s.suma * 0.15, 2)
FROM (SELECT idVenta, SUM(total) AS suma FROM DetalleVenta GROUP BY idVenta) s
WHERE s.idVenta = v.idVenta AND v.numeroDocumento = '00061';

UPDATE Producto p
SET stock = p.stock - d.cantidad
FROM DetalleVenta d JOIN Venta v ON v.idVenta = d.idVenta
WHERE d.idProducto = p.idProducto AND v.numeroDocumento = '00061';

UPDATE NumeroDocumento SET ultimo_Numero = ultimo_Numero + 1;

SELECT v.numeroDocumento, v.subtotal, v.impuesto, v.total,
       (SELECT stock FROM Producto WHERE codigo = 'ACC-004') AS stock_mouse
FROM Venta v WHERE v.numeroDocumento = '00061';
ROLLBACK;   -- con COMMIT quedaría guardada
-- @esperado: subtotal 1405.00, impuesto 210.75, total 1615.75 y stock_mouse 3
-- Fíjate cuántos pasos manuales son: en los módulos 09 y 10 esto se automatiza.

-- 9. SAVEPOINT: dentro de una transacción, sube el precio del 'teclado logitech', guarda un punto,
--    bórralo por error, vuelve al punto y comprueba que el producto sigue existiendo.
BEGIN;
UPDATE Producto SET precio = 1050 WHERE codigo = 'TEC-003';
SAVEPOINT antes_de_borrar;
DELETE FROM Producto WHERE codigo = 'TEC-003';     -- se puede: nunca se vendió
ROLLBACK TO SAVEPOINT antes_de_borrar;
SELECT codigo, nombre, precio FROM Producto WHERE codigo = 'TEC-003';
ROLLBACK;
-- @esperado: 1 fila con precio 1050.00 (el borrado se deshizo, la subida de precio no)
-- T-SQL: SAVE TRANSACTION antes_de_borrar; ... ROLLBACK TRANSACTION antes_de_borrar;
