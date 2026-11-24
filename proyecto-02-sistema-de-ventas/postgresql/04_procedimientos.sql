-- =====================================================================
-- PASO 4 · Funciones y procedimientos (PostgreSQL)
--
-- Equivalentes de sqlserver/04_procedimientos.sql.
-- Diferencia clave: en PostgreSQL lo que DEVUELVE filas es una FUNCTION
-- (se consulta con SELECT * FROM fn(...)); un PROCEDURE no devuelve tablas.
-- En SQL Server un solo PROCEDURE hace las dos cosas.
-- =====================================================================

-- 4.1 fn_obtener_menus: menús de un usuario  (T-SQL: EXEC sp_ObtenerMenus @idUsuario = 3)
CREATE OR REPLACE FUNCTION fn_obtener_menus(p_idUsuario INT)
RETURNS TABLE (idMenu INT, nombre VARCHAR, icono VARCHAR, url VARCHAR)
LANGUAGE sql STABLE
AS $$
    SELECT m.idMenu, m.nombre, m.icono, m.url
    FROM Usuario u
    JOIN MenuRol mr ON mr.idRol = u.idRol
    JOIN Menu m     ON m.idMenu = mr.idMenu
    WHERE u.idUsuario = p_idUsuario
    ORDER BY m.idMenu;
$$;

-- 4.2 sp_registrar_venta: la venta completa en una llamada.
--     El detalle llega como JSON: '[{"idProducto":11,"cantidad":2}, ...]'
--     INOUT devuelve el número generado (T-SQL: @numeroDocumento OUTPUT).
CREATE OR REPLACE PROCEDURE sp_registrar_venta(
    p_tipoPago            VARCHAR,
    p_detalle             JSONB,
    INOUT p_numeroDocumento VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_idVenta INT;
    v_numero  INT;
BEGIN
    -- JSON -> tabla temporal  (T-SQL: OPENJSON(@detalle) WITH (...))
    CREATE TEMP TABLE IF NOT EXISTS tmp_items (idProducto INT, cantidad INT) ON COMMIT DROP;
    DELETE FROM tmp_items;
    INSERT INTO tmp_items
    SELECT (e->>'idProducto')::int, (e->>'cantidad')::int
    FROM jsonb_array_elements(p_detalle) AS e;

    IF NOT EXISTS (SELECT 1 FROM tmp_items) THEN
        RAISE EXCEPTION 'La venta no tiene productos.';
    END IF;

    IF EXISTS (SELECT 1 FROM tmp_items i
               LEFT JOIN Producto p ON p.idProducto = i.idProducto AND p.esActivo
               WHERE p.idProducto IS NULL) THEN
        RAISE EXCEPTION 'Hay un producto que no existe o está inactivo.';
    END IF;

    IF EXISTS (SELECT 1 FROM tmp_items i JOIN Producto p ON p.idProducto = i.idProducto
               WHERE p.stock < i.cantidad) THEN
        RAISE EXCEPTION 'Stock insuficiente para uno de los productos.';
    END IF;

    UPDATE NumeroDocumento SET ultimo_Numero = ultimo_Numero + 1
    RETURNING ultimo_Numero INTO v_numero;
    p_numeroDocumento := lpad(v_numero::text, 5, '0');

    INSERT INTO Venta (numeroDocumento, tipoPago, total)
    VALUES (p_numeroDocumento, p_tipoPago, 0)
    RETURNING idVenta INTO v_idVenta;                       -- T-SQL: SCOPE_IDENTITY()

    INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, precio, total)
    SELECT v_idVenta, p.idProducto, i.cantidad, p.precio, p.precio * i.cantidad
    FROM tmp_items i JOIN Producto p ON p.idProducto = i.idProducto;

    UPDATE Producto p SET stock = p.stock - i.cantidad
    FROM tmp_items i WHERE i.idProducto = p.idProducto;

    UPDATE Venta SET total = (SELECT SUM(total) FROM DetalleVenta WHERE idVenta = v_idVenta)
    WHERE idVenta = v_idVenta;
    -- No hace falta BEGIN/COMMIT: si algo falla, PostgreSQL deshace todo el CALL.
END;
$$;

-- 4.3 fn_reporte_ventas: reporte por rango  (T-SQL: EXEC sp_ReporteVentas '2026-11-01', '2026-11-03')
CREATE OR REPLACE FUNCTION fn_reporte_ventas(p_fechaInicio DATE, p_fechaFin DATE)
RETURNS TABLE (numeroDocumento VARCHAR, tipoPago VARCHAR, fecha TEXT, totalVenta NUMERIC,
               producto VARCHAR, cantidad INT, precio NUMERIC, totalLinea NUMERIC)
LANGUAGE sql STABLE
AS $$
    SELECT v.numeroDocumento, v.tipoPago, to_char(v.fechaRegistro, 'DD/MM/YYYY'),
           v.total, p.nombre, d.cantidad, d.precio, d.total
    FROM Venta v
    JOIN DetalleVenta d ON d.idVenta    = v.idVenta
    JOIN Producto p     ON p.idProducto = d.idProducto
    WHERE v.fechaRegistro >= p_fechaInicio
      AND v.fechaRegistro <  p_fechaFin + 1
    ORDER BY v.fechaRegistro, p.nombre;
$$;

-- 4.4 fn_dashboard_ventas_por_dia: el gráfico del dashboard.
--     (Una función devuelve UN resultado; el procedimiento de SQL Server devolvía dos.)
CREATE OR REPLACE FUNCTION fn_dashboard_ventas_por_dia(p_hoy DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (dia DATE, ventas BIGINT, total NUMERIC)
LANGUAGE sql STABLE
AS $$
    SELECT fechaRegistro::date, COUNT(*), SUM(total)
    FROM Venta
    WHERE fechaRegistro::date BETWEEN p_hoy - 6 AND p_hoy
    GROUP BY 1
    ORDER BY 1;
$$;

-- ---------------------------------------------------------------------
-- Pruebas
-- ---------------------------------------------------------------------
SELECT * FROM fn_obtener_menus(3);                          -- supervisor: 4 menús
SELECT * FROM fn_dashboard_ventas_por_dia('2026-11-23');    -- 5 días con ventas
SELECT * FROM fn_reporte_ventas('2026-11-01', '2026-11-03');

BEGIN;
    CALL sp_registrar_venta('Tarjeta', '[{"idProducto":11,"cantidad":2},{"idProducto":14,"cantidad":1}]');
    SELECT numeroDocumento, total FROM Venta ORDER BY idVenta DESC LIMIT 1;   -- 00025, 1560.00
ROLLBACK;

-- Error controlado: más stock del que hay
DO $$
DECLARE v_num VARCHAR;
BEGIN
    CALL sp_registrar_venta('Efectivo', '[{"idProducto":6,"cantidad":99}]', v_num);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error: %', SQLERRM;                       -- T-SQL: BEGIN TRY ... BEGIN CATCH
END;
$$;
