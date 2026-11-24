-- =====================================================================
-- PASO 8 · Errores comunes en un sistema de ventas (PostgreSQL)
-- Equivalente de sqlserver/08_errores_comunes.sql (allí está la explicación de cada caso).
-- Parte A: lo que la base RECHAZA (cada intento en un bloque DO con EXCEPTION).
-- Parte B: lo que la base ACEPTA pero da un resultado equivocado.
-- Corre después de los pasos 1 a 7. No cambia ningún dato.
-- =====================================================================

-- ======================= PARTE A =====================================

-- A1. Vender un producto que no existe -> 23503
DO $$ BEGIN
    INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, precio, total) VALUES (1, 999, 1, 10, 10);
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A1 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A2. Borrar una categoría con productos -> 23503
DO $$ BEGIN
    DELETE FROM Categoria WHERE idCategoria = 1;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A2 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A3. Stock negativo -> 23514
DO $$ BEGIN
    UPDATE Producto SET stock = stock - 1000 WHERE idProducto = 1;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A3 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A4. Precio cero -> 23514
DO $$ BEGIN
    UPDATE Producto SET precio = 0 WHERE idProducto = 1;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A4 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A5. Correo repetido -> 23505
DO $$ BEGIN
    INSERT INTO Usuario (nombreCompleto, correo, idRol, clave) VALUES ('otra maria', 'maria@example.com', 2, 'x');
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A5 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A6. Usuario sin rol -> 23502
DO $$ BEGIN
    INSERT INTO Usuario (nombreCompleto, correo, idRol, clave) VALUES ('sin rol', 'sinrol@example.com', NULL, 'x');
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A6 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A7. Cédula con letras -> 23514
DO $$ BEGIN
    INSERT INTO Cliente (tipoDocumento, documento, nombre) VALUES ('C', '09123A567', 'Cédula mal escrita');
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A7 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A8. Venta sin vendedor -> 23502
DO $$ BEGIN
    INSERT INTO Venta (numeroDocumento, tipoPago, total, idUsuario) VALUES ('99999', 'Efectivo', 0, NULL);
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A8 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A9. Número de documento repetido -> 23505
DO $$ BEGIN
    INSERT INTO Venta (numeroDocumento, tipoPago, total, idUsuario) VALUES ('00001', 'Efectivo', 0, 1);
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A9 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A10. Dos proveedores principales para el mismo producto -> 23505 (índice único parcial)
DO $$ BEGIN
    UPDATE ProductoProveedor SET esPrincipal = TRUE WHERE idProducto = 1 AND idProveedor = 3;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A10 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A11. Borrar un cliente con ventas -> 23503
DO $$ BEGIN
    DELETE FROM Cliente WHERE idCliente = 1;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A11 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- A12. Venta a un cliente que no existe, por el procedimiento -> 23503.
--      PostgreSQL deshace todo lo que hizo el CALL: el número de documento no se gasta.
DO $$
DECLARE v_num VARCHAR;                     -- dentro de PL/pgSQL el parámetro INOUT necesita una variable
BEGIN
    CALL sp_registrar_venta('Efectivo', '[{"idProducto":14,"cantidad":1}]', 2, 99, v_num);
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A12 -> [%] %', SQLSTATE, SQLERRM;
END $$;
SELECT ultimo_Numero AS sigue_en_24 FROM NumeroDocumento;

-- A13. Texto que no es número -> 22P02
DO $$ BEGIN
    PERFORM '12abc'::INT;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A13 -> [%] %', SQLSTATE, SQLERRM;
END $$;
-- PostgreSQL no tiene TRY_CAST: se revisa antes con una expresión regular
SELECT x AS texto, CASE WHEN x ~ '^[0-9]+$' THEN x::INT END AS con_validacion   -- NULL para '12abc'
FROM (VALUES ('12abc'), ('45')) AS v(x);

-- A14. Borrar una tabla de la que dependen otras -> 2BP01
DO $$ BEGIN
    DROP TABLE Producto;
EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'A14 -> [%] %', SQLSTATE, SQLERRM;
END $$;

-- ======================= PARTE B =====================================

-- B1. Sumar la cabecera unida con el detalle (se repite una vez por línea)
SELECT 'B1 mal'  AS caso, SUM(v.total) AS total_vendido
FROM Venta v JOIN DetalleVenta d ON d.idVenta = v.idVenta;                             -- 99530.00 (¡inflado!)
SELECT 'B1 bien' AS caso, SUM(v.total) AS total_vendido FROM Venta v;                  -- 53520.00

-- B2. INNER JOIN con una relación opcional
SELECT 'B2 mal'  AS caso, COUNT(*) AS ventas FROM Venta v JOIN Cliente c ON c.idCliente = v.idCliente;       -- 18
SELECT 'B2 bien' AS caso, COUNT(*) AS ventas FROM Venta v LEFT JOIN Cliente c ON c.idCliente = v.idCliente;  -- 24

-- B3. NOT IN con NULL
SELECT 'B3 mal'  AS caso, COUNT(*) AS clientes
FROM Cliente WHERE idCliente NOT IN (SELECT idCliente FROM Venta);                     -- 0
SELECT 'B3 bien' AS caso, COUNT(*) AS clientes
FROM Cliente c WHERE NOT EXISTS (SELECT 1 FROM Venta v WHERE v.idCliente = c.idCliente); -- 1

-- B4. "= NULL"
SELECT 'B4 mal'  AS caso, COUNT(*) AS ventas_consumidor_final FROM Venta WHERE idCliente = NULL;   -- 0
SELECT 'B4 bien' AS caso, COUNT(*) AS ventas_consumidor_final FROM Venta WHERE idCliente IS NULL;  -- 6

-- B5. Precio actual vs precio guardado en la venta
BEGIN;
    UPDATE Producto SET precio = 3000 WHERE idProducto = 1;
    SELECT 'B5' AS caso,
           SUM(d.cantidad * p.precio) AS con_precio_actual,        -- mal
           SUM(d.total)               AS con_precio_de_la_venta    -- bien
    FROM DetalleVenta d JOIN Producto p ON p.idProducto = d.idProducto
    WHERE d.idProducto = 1;
ROLLBACK;

-- B6. Dinero en FLOAT (en PostgreSQL: double precision / real)
SELECT 'B6' AS caso,
       CASE WHEN 0.1::FLOAT + 0.2::FLOAT = 0.3::FLOAT THEN 'igual' ELSE 'distinto' END AS con_float,    -- distinto
       CASE WHEN 0.1::NUMERIC + 0.2::NUMERIC = 0.3::NUMERIC THEN 'igual' ELSE 'distinto' END AS con_numeric; -- igual

-- B7. División entera
SELECT 'B7' AS caso,
       SUM(cantidad) / COUNT(*)       AS mal,
       1.0 * SUM(cantidad) / COUNT(*) AS bien
FROM DetalleVenta;

-- B8. UPDATE sin WHERE
BEGIN;
    WITH cambiados AS (
        UPDATE Producto SET precio = precio * 1.10          -- olvidamos: WHERE idProducto = 5
        RETURNING idProducto
    )
    SELECT 'B8' AS caso, COUNT(*) AS productos_cambiados FROM cambiados;              -- 15
ROLLBACK;

-- B9. Filtro de la tabla derecha en el WHERE
SELECT 'B9 mal' AS caso, COUNT(DISTINCT c.idCategoria) AS categorias
FROM Categoria c
LEFT JOIN Producto p     ON p.idCategoria = c.idCategoria
LEFT JOIN DetalleVenta d ON d.idProducto  = p.idProducto
LEFT JOIN Venta v        ON v.idVenta     = d.idVenta
WHERE v.tipoPago = 'Efectivo';                                                           -- 5 de 6
SELECT 'B9 bien' AS caso, COUNT(DISTINCT c.idCategoria) AS categorias
FROM Categoria c
LEFT JOIN Producto p     ON p.idCategoria = c.idCategoria
LEFT JOIN (DetalleVenta d JOIN Venta v ON v.idVenta = d.idVenta AND v.tipoPago = 'Efectivo')
                         ON d.idProducto  = p.idProducto;                                -- 6
