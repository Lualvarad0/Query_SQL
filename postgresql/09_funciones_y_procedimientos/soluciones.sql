-- =====================================================================
-- Módulo 09 · Funciones y procedimientos almacenados · SOLUCIONES
-- Las funciones y procedimientos se quedan creados en la base.
-- Las pruebas que modifican datos van dentro de BEGIN ... ROLLBACK.
-- =====================================================================

-- 1. Función fn_precio_con_iva(precio) que devuelva el precio con 15 % de IVA, redondeado.
--    Úsala para listar los 3 productos más caros con su precio final.
CREATE OR REPLACE FUNCTION fn_precio_con_iva(p_precio NUMERIC)
RETURNS NUMERIC
LANGUAGE sql IMMUTABLE
AS $$
    SELECT ROUND(p_precio * 1.15, 2);
$$;

SELECT nombre, precio, fn_precio_con_iva(precio) AS precio_final
FROM Producto ORDER BY precio DESC LIMIT 3;
-- T-SQL: CREATE OR ALTER FUNCTION dbo.fn_precio_con_iva(@precio DECIMAL(10,2))
--        RETURNS DECIMAL(10,2) AS BEGIN RETURN ROUND(@precio * 1.15, 2) END;
--        y se llama con el esquema: dbo.fn_precio_con_iva(precio)

-- 2. Función fn_total_cliente(idCliente) que devuelva cuánto ha gastado un cliente en ventas
--    pagadas (0 si nada). Úsala con todos los clientes de Guayaquil.
CREATE OR REPLACE FUNCTION fn_total_cliente(p_idCliente INT)
RETURNS NUMERIC
LANGUAGE plpgsql STABLE
AS $$
DECLARE
    v_total NUMERIC;                        -- T-SQL: DECLARE @total DECIMAL(12,2);
BEGIN
    SELECT COALESCE(SUM(total), 0) INTO v_total
    FROM Venta
    WHERE idCliente = p_idCliente AND estado = 'PAGADA';
    RETURN v_total;
END;
$$;

SELECT nombreCompleto, fn_total_cliente(idCliente) AS gastado
FROM Cliente WHERE idCiudad = 1
ORDER BY gastado DESC;

-- 3. Función que devuelve una TABLA: fn_ventas_entre(desde, hasta) con documento, fecha,
--    cliente y total de las ventas pagadas en ese rango. Pruébala con la primera semana de noviembre.
CREATE OR REPLACE FUNCTION fn_ventas_entre(p_desde DATE, p_hasta DATE)
RETURNS TABLE (numeroDocumento VARCHAR, fecha DATE, cliente VARCHAR, total NUMERIC)
LANGUAGE sql STABLE
AS $$
    SELECT v.numeroDocumento, v.fechaRegistro::date,
           COALESCE(cl.nombreCompleto, 'Consumidor final'), v.total
    FROM Venta v
    LEFT JOIN Cliente cl ON cl.idCliente = v.idCliente
    WHERE v.estado = 'PAGADA'
      AND v.fechaRegistro >= p_desde
      AND v.fechaRegistro <  p_hasta + 1
    ORDER BY v.fechaRegistro;
$$;

SELECT * FROM fn_ventas_entre('2026-11-01', '2026-11-07');
-- T-SQL: CREATE FUNCTION dbo.fn_ventas_entre(@desde DATE, @hasta DATE) RETURNS TABLE AS
--        RETURN (SELECT ...);   -- "inline table-valued function"

-- 4. Procedimiento sp_registrar_venta que haga TODO lo del ejercicio 8 del módulo 07 en una
--    llamada: recibe cliente, vendedor, tipo de pago y listas de códigos y cantidades; valida
--    el stock, crea la venta con el siguiente número, inserta el detalle, calcula totales y
--    descuenta el stock. Pruébalo vendiendo 2 'AUR-002' y 1 'ACC-004'.
CREATE OR REPLACE PROCEDURE sp_registrar_venta(
    p_idCliente  INT,
    p_idUsuario  INT,
    p_tipoPago   VARCHAR,
    p_codigos    VARCHAR[],
    p_cantidades INT[]
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_numero  INT;
    v_idVenta INT;
    v_prod    RECORD;
    i         INT;
BEGIN
    IF array_length(p_codigos, 1) IS DISTINCT FROM array_length(p_cantidades, 1) THEN
        RAISE EXCEPTION 'Hay % códigos y % cantidades', array_length(p_codigos, 1), array_length(p_cantidades, 1);
    END IF;

    UPDATE NumeroDocumento SET ultimo_Numero = ultimo_Numero + 1
    RETURNING ultimo_Numero INTO v_numero;

    INSERT INTO Venta (numeroDocumento, idCliente, idUsuario, tipoPago)
    VALUES (lpad(v_numero::text, 5, '0'), p_idCliente, p_idUsuario, p_tipoPago)
    RETURNING idVenta INTO v_idVenta;

    FOR i IN 1 .. array_length(p_codigos, 1) LOOP
        SELECT idProducto, precio, stock, nombre INTO v_prod
        FROM Producto WHERE codigo = p_codigos[i]
        FOR UPDATE;                                   -- bloquea la fila mientras vendemos

        IF NOT FOUND THEN
            RAISE EXCEPTION 'El producto % no existe', p_codigos[i];
        END IF;
        IF v_prod.stock < p_cantidades[i] THEN
            RAISE EXCEPTION 'Stock insuficiente de "%": hay %, se piden %',
                            v_prod.nombre, v_prod.stock, p_cantidades[i];
        END IF;

        INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, precio, total)
        VALUES (v_idVenta, v_prod.idProducto, p_cantidades[i], v_prod.precio, v_prod.precio * p_cantidades[i]);

        UPDATE Producto SET stock = stock - p_cantidades[i] WHERE idProducto = v_prod.idProducto;
    END LOOP;

    UPDATE Venta v
    SET subtotal = s.suma, impuesto = ROUND(s.suma * 0.15, 2), total = s.suma + ROUND(s.suma * 0.15, 2)
    FROM (SELECT SUM(total) AS suma FROM DetalleVenta WHERE idVenta = v_idVenta) s
    WHERE v.idVenta = v_idVenta;

    RAISE NOTICE 'Venta % registrada', lpad(v_numero::text, 5, '0');
END;
$$;

BEGIN;
CALL sp_registrar_venta(2, 4, 'Tarjeta', ARRAY['AUR-002', 'ACC-004'], ARRAY[2, 1]);
SELECT numeroDocumento, subtotal, impuesto, total FROM Venta WHERE numeroDocumento = '00061';
ROLLBACK;
-- @esperado: venta 00061 con subtotal 1405.00, impuesto 210.75 y total 1615.75
-- Si cualquier paso lanza una excepción, PostgreSQL deshace todo lo que hizo el procedimiento.
-- T-SQL: CREATE OR ALTER PROCEDURE dbo.sp_registrar_venta @idCliente INT, ... AS BEGIN
--          SET XACT_ABORT ON; BEGIN TRAN; ... COMMIT; END
--        y se llama con EXEC dbo.sp_registrar_venta 2, 4, 'Tarjeta', ...
--        SQL Server no tiene arreglos: se pasa una tabla (table-valued parameter) o un JSON.

-- 5. Prueba el control de errores: intenta vender 10 'mouse logitech g203' (solo hay 4).
--    Atrapa el error en un bloque DO y muestra el mensaje sin que se corte el script.
DO $$
BEGIN
    CALL sp_registrar_venta(2, 4, 'Efectivo', ARRAY['ACC-004'], ARRAY[10]);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'No se pudo vender: %', SQLERRM;
END;
$$;
SELECT ultimo_Numero FROM NumeroDocumento;
-- @esperado: el aviso "No se pudo vender: Stock insuficiente..." y ultimo_Numero sigue en 60
-- T-SQL: BEGIN TRY ... END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH

-- 6. ¿Función o procedimiento? Responde con tus palabras y luego compara:
--    Función: devuelve un valor o una tabla y se usa DENTRO de un SELECT/WHERE. Debería solo leer.
--    Procedimiento: se ejecuta con CALL (EXEC en T-SQL), hace un proceso de varios pasos que
--    modifica datos y puede manejar transacciones (COMMIT/ROLLBACK) por dentro.
SELECT 'función = calcular/consultar · procedimiento = ejecutar un proceso' AS resumen;
-- @esperado: tu explicación en un comentario
