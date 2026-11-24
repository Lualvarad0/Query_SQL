/* =====================================================================
   PASO 8 · Errores comunes en un sistema de ventas (SQL Server)

   Parte A: cosas que la base RECHAZA gracias a las reglas de las tablas.
            Cada intento va en TRY/CATCH para que el archivo siga y veas
            el número y el mensaje del error.
   Parte B: cosas que la base ACEPTA pero dan un resultado equivocado.
            En un sistema de ventas esto significa reportes con plata mal sumada.

   Corre después de los pasos 1 a 7. No cambia ningún dato.
   ===================================================================== */

USE DBVENTA;
GO
SET QUOTED_IDENTIFIER ON;   -- necesario para escribir en ProductoProveedor (índice filtrado)
GO

/* =====================================================================
   PARTE A · La base de datos te protege
   ===================================================================== */

-- A1. Vender un producto que no existe.
--     Error 547 (FOREIGN KEY FK_Detalle_Producto).
BEGIN TRY
    INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, precio, total) VALUES (1, 999, 1, 10, 10);
END TRY
BEGIN CATCH SELECT 'A1' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A2. Borrar una categoría que tiene productos.
--     Error 547. Bien: desactivarla (esActivo = 0) en vez de borrarla.
BEGIN TRY
    DELETE FROM Categoria WHERE idCategoria = 1;
END TRY
BEGIN CATCH SELECT 'A2' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A3. Vender más de lo que hay en bodega con un UPDATE directo.
--     Error 547 (CHECK CK_Producto_stock: stock >= 0). Sin esa regla el stock quedaría en negativo.
BEGIN TRY
    UPDATE Producto SET stock = stock - 1000 WHERE idProducto = 1;
END TRY
BEGIN CATCH SELECT 'A3' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A4. Precio cero o negativo.
--     Error 547 (CHECK CK_Producto_precio).
BEGIN TRY
    UPDATE Producto SET precio = 0 WHERE idProducto = 1;
END TRY
BEGIN CATCH SELECT 'A4' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A5. Dos usuarios con el mismo correo (el login no sabría a quién dejar entrar).
--     Error 2627 (UNIQUE UQ_Usuario_correo).
BEGIN TRY
    INSERT INTO Usuario (nombreCompleto, correo, idRol, clave) VALUES ('otra maria', 'maria@example.com', 2, 'x');
END TRY
BEGIN CATCH SELECT 'A5' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A6. Usuario sin rol.
--     Error 515 (NOT NULL). En el script original esto se podía.
BEGIN TRY
    INSERT INTO Usuario (nombreCompleto, correo, idRol, clave) VALUES ('sin rol', 'sinrol@example.com', NULL, 'x');
END TRY
BEGIN CATCH SELECT 'A6' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A7. Cédula con letras o con 9 dígitos.
--     Error 547 (CHECK CK_Cliente_documento del paso 6).
BEGIN TRY
    INSERT INTO Cliente (tipoDocumento, documento, nombre) VALUES ('C', '09123A567', 'Cédula mal escrita');
END TRY
BEGIN CATCH SELECT 'A7' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A8. Registrar una venta sin vendedor.
--     Error 515: idUsuario es NOT NULL desde el paso 6.
BEGIN TRY
    INSERT INTO Venta (numeroDocumento, tipoPago, total, idUsuario) VALUES ('99999', 'Efectivo', 0, NULL);
END TRY
BEGIN CATCH SELECT 'A8' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A9. Repetir un número de documento (dos facturas con el mismo número).
--     Error 2627 (UNIQUE UQ_Venta_numero).
BEGIN TRY
    INSERT INTO Venta (numeroDocumento, tipoPago, total, idUsuario) VALUES ('00001', 'Efectivo', 0, 1);
END TRY
BEGIN CATCH SELECT 'A9' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A10. Dos proveedores PRINCIPALES para el mismo producto.
--      Error 2601 (índice único filtrado UX_PP_UnPrincipal). El producto 1 ya tiene principal.
BEGIN TRY
    UPDATE ProductoProveedor SET esPrincipal = 1 WHERE idProducto = 1 AND idProveedor = 3;
END TRY
BEGIN CATCH SELECT 'A10' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A11. Borrar un cliente que tiene ventas.
--      Error 547. Las ventas son historia contable: no se pierden porque alguien borró un cliente.
BEGIN TRY
    DELETE FROM Cliente WHERE idCliente = 1;
END TRY
BEGIN CATCH SELECT 'A11' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A12. Una venta para un cliente que no existe, a través del procedimiento.
--      Error 547: la FK FK_Venta_Cliente detiene la venta, y XACT_ABORT deshace TODO
--      (no queda el número de documento gastado ni el stock descontado).
BEGIN TRY
    DECLARE @num VARCHAR(40);
    EXEC sp_RegistrarVenta 'Efectivo', N'[{"idProducto":14,"cantidad":1}]', @num OUTPUT, @idUsuario = 2, @idCliente = 99;
END TRY
BEGIN CATCH
    -- El error ocurrió DENTRO de la transacción del procedimiento: queda abierta pero
    -- "condenada" (XACT_STATE() = -1). El CATCH siempre debe deshacerla.
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    SELECT 'A12' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje;
END CATCH;
SELECT ultimo_Numero AS sigue_en_24 FROM NumeroDocumento;   -- el número no se gastó
GO

-- A13. Convertir texto que no es número.
--      Error 245. Pasa cuando una columna que debía ser INT se creó como VARCHAR y alguien
--      escribió '12abc'. Bien: el tipo correcto desde el CREATE TABLE (o TRY_CAST para revisar).
BEGIN TRY
    SELECT CAST('12abc' AS INT) AS cantidad;
END TRY
BEGIN CATCH SELECT 'A13' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
SELECT TRY_CAST('12abc' AS INT) AS con_try_cast;   -- NULL en vez de error
GO

-- A14. Borrar una tabla de la que dependen otras.
--      Error 3726: DetalleVenta y ProductoProveedor tienen FK hacia Producto.
BEGIN TRY
    DROP TABLE Producto;
END TRY
BEGIN CATCH SELECT 'A14' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

/* =====================================================================
   PARTE B · La base de datos NO te avisa
   ===================================================================== */

-- B1. Sumar la cabecera después de unirla con el detalle (el error más caro).
--     Cada venta se repite una vez por cada línea de detalle, y su total se suma varias veces.
SELECT 'B1 mal'  AS caso, SUM(v.total) AS total_vendido
FROM Venta v INNER JOIN DetalleVenta d ON d.idVenta = v.idVenta;                       -- 99530.00 (¡inflado!)
SELECT 'B1 bien' AS caso, SUM(v.total) AS total_vendido FROM Venta v;                  -- 53520.00
-- Regla: suma cada cosa en su nivel. Totales de Venta desde Venta; montos de línea desde DetalleVenta.
GO

-- B2. INNER JOIN con una relación opcional: desaparecen las ventas a consumidor final.
SELECT 'B2 mal'  AS caso, COUNT(*) AS ventas
FROM Venta v INNER JOIN Cliente c ON c.idCliente = v.idCliente;                        -- 18
SELECT 'B2 bien' AS caso, COUNT(*) AS ventas
FROM Venta v LEFT JOIN Cliente c ON c.idCliente = v.idCliente;                         -- 24
GO

-- B3. NOT IN con NULL: "clientes que nunca compraron".
--     Venta.idCliente tiene NULL (consumidor final), y NOT IN (..., NULL) nunca es verdadero.
SELECT 'B3 mal'  AS caso, COUNT(*) AS clientes
FROM Cliente WHERE idCliente NOT IN (SELECT idCliente FROM Venta);                     -- 0
SELECT 'B3 bien' AS caso, COUNT(*) AS clientes
FROM Cliente c WHERE NOT EXISTS (SELECT 1 FROM Venta v WHERE v.idCliente = c.idCliente); -- 1 (Marta Ruiz)
GO

-- B4. "= NULL" en vez de "IS NULL".
SELECT 'B4 mal'  AS caso, COUNT(*) AS ventas_consumidor_final FROM Venta WHERE idCliente = NULL;  -- 0
SELECT 'B4 bien' AS caso, COUNT(*) AS ventas_consumidor_final FROM Venta WHERE idCliente IS NULL; -- 6
GO

-- B5. Usar el precio ACTUAL del producto para calcular ventas pasadas.
--     Si mañana sube el precio de la laptop, el historial "cambia". Por eso DetalleVenta
--     guarda su propio precio: es una foto del momento de la venta.
BEGIN TRANSACTION;
    UPDATE Producto SET precio = 3000 WHERE idProducto = 1;      -- subió el precio
    SELECT 'B5' AS caso,
           SUM(d.cantidad * p.precio) AS con_precio_actual,       -- mal: ventas de hace semanas con el precio de hoy
           SUM(d.total)               AS con_precio_de_la_venta   -- bien
    FROM DetalleVenta d INNER JOIN Producto p ON p.idProducto = d.idProducto
    WHERE d.idProducto = 1;
ROLLBACK TRANSACTION;
GO

-- B6. Dinero en FLOAT.
--     FLOAT guarda aproximaciones binarias: 0.1 + 0.2 no es exactamente 0.3.
--     Para dinero siempre DECIMAL(p, s) (en PostgreSQL, NUMERIC).
SELECT 'B6' AS caso,
       CASE WHEN CAST(0.1 AS FLOAT) + CAST(0.2 AS FLOAT) = CAST(0.3 AS FLOAT)
            THEN 'igual' ELSE 'distinto' END AS con_float,                               -- distinto
       CASE WHEN CAST(0.1 AS DECIMAL(10,2)) + CAST(0.2 AS DECIMAL(10,2)) = CAST(0.3 AS DECIMAL(10,2))
            THEN 'igual' ELSE 'distinto' END AS con_decimal;                             -- igual
GO

-- B7. División entera: unidades promedio por línea de detalle.
SELECT 'B7' AS caso,
       SUM(cantidad) / COUNT(*)       AS mal,      -- entero: se pierden los decimales
       1.0 * SUM(cantidad) / COUNT(*) AS bien
FROM DetalleVenta;
GO

-- B8. UPDATE sin WHERE: querías subir 10 % un producto y subiste los 15.
BEGIN TRANSACTION;
    UPDATE Producto SET precio = precio * 1.10;          -- olvidamos: WHERE idProducto = 5
    SELECT 'B8' AS caso, @@ROWCOUNT AS productos_cambiados;                             -- 15
ROLLBACK TRANSACTION;
GO

-- B9. Filtrar la tabla derecha en el WHERE "apaga" el LEFT JOIN.
--     Queremos TODAS las categorías con lo vendido en efectivo (0 si nada).
SELECT 'B9 mal' AS caso, COUNT(DISTINCT c.idCategoria) AS categorias
FROM Categoria c
LEFT JOIN Producto p     ON p.idCategoria = c.idCategoria
LEFT JOIN DetalleVenta d ON d.idProducto  = p.idProducto
LEFT JOIN Venta v        ON v.idVenta     = d.idVenta
WHERE v.tipoPago = 'Efectivo';                                                           -- faltan categorías: 5 de 6
SELECT 'B9 bien' AS caso, COUNT(DISTINCT c.idCategoria) AS categorias
FROM Categoria c
LEFT JOIN Producto p     ON p.idCategoria = c.idCategoria
LEFT JOIN (DetalleVenta d INNER JOIN Venta v ON v.idVenta = d.idVenta AND v.tipoPago = 'Efectivo')
                         ON d.idProducto  = p.idProducto;                                -- 6
GO
