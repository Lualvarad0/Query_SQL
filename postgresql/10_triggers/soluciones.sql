-- =====================================================================
-- Módulo 10 · Triggers (disparadores) · SOLUCIONES
-- Lee primero el README.md de esta carpeta: explica cuándo SÍ y cuándo NO usar un trigger.
-- Los triggers se quedan creados. Las pruebas van dentro de BEGIN ... ROLLBACK.
-- Para quitarlos todos: vuelve a correr 00_base_de_datos/instalar.sql
-- En PostgreSQL un trigger son 2 piezas: una FUNCIÓN que RETURNS trigger y el TRIGGER que la llama.
-- =====================================================================

-- 1. AUDITORÍA. Cada vez que cambie el precio de un producto, guarda en AuditoriaPrecio el
--    producto, el precio anterior, el nuevo, quién lo cambió y cuándo. Prueba subiendo el
--    precio de 'teclado logitech' dos veces.
CREATE TABLE IF NOT EXISTS AuditoriaPrecio (
    idAuditoria    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    idProducto     INT NOT NULL REFERENCES Producto(idProducto),
    precioAnterior NUMERIC(10,2) NOT NULL,
    precioNuevo    NUMERIC(10,2) NOT NULL,
    usuarioBD      TEXT NOT NULL DEFAULT current_user,
    fecha          TIMESTAMP NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION trg_auditar_precio()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    -- OLD = la fila antes del cambio, NEW = la fila después
    IF NEW.precio IS DISTINCT FROM OLD.precio THEN
        INSERT INTO AuditoriaPrecio (idProducto, precioAnterior, precioNuevo)
        VALUES (NEW.idProducto, OLD.precio, NEW.precio);
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_producto_auditar_precio ON Producto;
CREATE TRIGGER tr_producto_auditar_precio
AFTER UPDATE OF precio ON Producto          -- solo cuando el UPDATE toca la columna precio
FOR EACH ROW
EXECUTE FUNCTION trg_auditar_precio();

BEGIN;
UPDATE Producto SET precio = 1050 WHERE codigo = 'TEC-003';
UPDATE Producto SET precio = 1100 WHERE codigo = 'TEC-003';
UPDATE Producto SET stock = 12   WHERE codigo = 'TEC-003';   -- no toca el precio: no audita
SELECT p.nombre, a.precioAnterior, a.precioNuevo, a.usuarioBD
FROM AuditoriaPrecio a JOIN Producto p ON p.idProducto = a.idProducto
ORDER BY a.idAuditoria;
ROLLBACK;
-- @esperado: 2 filas: 1000.00 -> 1050.00 y 1050.00 -> 1100.00
-- Es el uso más clásico y más recomendable de un trigger: nadie puede "olvidarse" de auditar,
-- sin importar si el cambio viene de la app, de un script o de alguien en pgAdmin.

-- 2. COMPLETAR DATOS (BEFORE). Al insertar en DetalleVenta, si no mandan el precio, cópialo del
--    producto, y calcula siempre el total de la línea con el descuento. Así nadie puede guardar
--    un total mal calculado.
CREATE OR REPLACE FUNCTION trg_detalle_calcular()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.precio IS NULL THEN
        SELECT precio INTO NEW.precio FROM Producto WHERE idProducto = NEW.idProducto;
    END IF;
    NEW.total := ROUND(NEW.precio * NEW.cantidad * (1 - NEW.descuento / 100), 2);
    RETURN NEW;                        -- en un BEFORE, lo que devuelves es lo que se guarda
END;
$$;

DROP TRIGGER IF EXISTS tr_detalle_calcular ON DetalleVenta;
CREATE TRIGGER tr_detalle_calcular
BEFORE INSERT OR UPDATE ON DetalleVenta
FOR EACH ROW
EXECUTE FUNCTION trg_detalle_calcular();

BEGIN;
INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, descuento, precio, total)
VALUES (60, 11, 2, 10, NULL, 0)                 -- sin precio y con un total "inventado"
RETURNING idProducto, cantidad, precio, descuento, total;
ROLLBACK;
-- @esperado: precio 680.00 y total 1224.00 (680 x 2 - 10 %)
-- Los BEFORE corren antes de revisar NOT NULL y CHECK: por eso precio NULL no da error aquí.

-- 3. INVENTARIO (AFTER). Al vender (insertar en DetalleVenta) descuenta el stock del producto y
--    registra el movimiento en MovimientoInventario. Si no hay stock suficiente, rechaza la venta.
CREATE TABLE IF NOT EXISTS MovimientoInventario (
    idMovimiento INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    idProducto   INT NOT NULL REFERENCES Producto(idProducto),
    tipo         VARCHAR(10) NOT NULL CHECK (tipo IN ('SALIDA', 'ENTRADA')),
    cantidad     INT NOT NULL,
    stockFinal   INT NOT NULL,
    referencia   VARCHAR(40),
    fecha        TIMESTAMP NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION trg_detalle_descontar_stock()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock INT;
BEGIN
    UPDATE Producto
    SET stock = stock - NEW.cantidad
    WHERE idProducto = NEW.idProducto AND stock >= NEW.cantidad
    RETURNING stock INTO v_stock;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Stock insuficiente para el producto % (se piden %)', NEW.idProducto, NEW.cantidad;
    END IF;

    INSERT INTO MovimientoInventario (idProducto, tipo, cantidad, stockFinal, referencia)
    SELECT NEW.idProducto, 'SALIDA', NEW.cantidad, v_stock, 'Venta ' || numeroDocumento
    FROM Venta WHERE idVenta = NEW.idVenta;

    RETURN NULL;                       -- en un AFTER el valor devuelto se ignora
END;
$$;

DROP TRIGGER IF EXISTS tr_detalle_descontar_stock ON DetalleVenta;
CREATE TRIGGER tr_detalle_descontar_stock
AFTER INSERT ON DetalleVenta
FOR EACH ROW
EXECUTE FUNCTION trg_detalle_descontar_stock();

BEGIN;
INSERT INTO DetalleVenta (idVenta, idProducto, cantidad) VALUES (60, 17, 3);   -- 3 mouse (hay 4)
SELECT codigo, stock FROM Producto WHERE idProducto = 17;
SELECT tipo, cantidad, stockFinal, referencia FROM MovimientoInventario;
-- INSERT INTO DetalleVenta (idVenta, idProducto, cantidad) VALUES (60, 17, 3);
--   ERROR: Stock insuficiente para el producto 17 (se piden 3)   <- ya solo queda 1
ROLLBACK;
-- @esperado: stock del mouse en 1 y 1 movimiento SALIDA "Venta 00060"
-- Fíjate que el INSERT ya no manda precio ni total: los completa el trigger del ejercicio 2.

-- 4. TOTALES DERIVADOS. Mantén subtotal, impuesto y total de Venta siempre sincronizados con su
--    detalle: recalcula cuando se inserta, cambia o borra una línea. Usa un trigger por sentencia
--    (FOR EACH STATEMENT) con tablas de transición para no recalcular fila por fila.
-- PostgreSQL no deja usar tablas de transición con varios eventos a la vez: un trigger por evento.
DROP TRIGGER IF EXISTS tr_venta_recalcular_ins ON DetalleVenta;
DROP TRIGGER IF EXISTS tr_venta_recalcular_upd ON DetalleVenta;
DROP TRIGGER IF EXISTS tr_venta_recalcular_del ON DetalleVenta;
CREATE OR REPLACE FUNCTION trg_venta_recalcular_ins() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    UPDATE Venta v
    SET subtotal = s.suma, impuesto = ROUND(s.suma * 0.15, 2), total = s.suma + ROUND(s.suma * 0.15, 2)
    FROM (SELECT d.idVenta, SUM(d.total) AS suma FROM DetalleVenta d
          WHERE d.idVenta IN (SELECT idVenta FROM nuevas) GROUP BY d.idVenta) s
    WHERE v.idVenta = s.idVenta;
    RETURN NULL;
END; $$;
CREATE OR REPLACE FUNCTION trg_venta_recalcular_del() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    UPDATE Venta v
    SET subtotal = s.suma, impuesto = ROUND(s.suma * 0.15, 2), total = s.suma + ROUND(s.suma * 0.15, 2)
    FROM (SELECT x.idVenta, COALESCE((SELECT SUM(d.total) FROM DetalleVenta d WHERE d.idVenta = x.idVenta), 0) AS suma
          FROM (SELECT DISTINCT idVenta FROM viejas) x) s
    WHERE v.idVenta = s.idVenta;
    RETURN NULL;
END; $$;

CREATE TRIGGER tr_venta_recalcular_ins
AFTER INSERT ON DetalleVenta
REFERENCING NEW TABLE AS nuevas
FOR EACH STATEMENT EXECUTE FUNCTION trg_venta_recalcular_ins();

CREATE TRIGGER tr_venta_recalcular_upd
AFTER UPDATE ON DetalleVenta
REFERENCING NEW TABLE AS nuevas
FOR EACH STATEMENT EXECUTE FUNCTION trg_venta_recalcular_ins();

CREATE TRIGGER tr_venta_recalcular_del
AFTER DELETE ON DetalleVenta
REFERENCING OLD TABLE AS viejas
FOR EACH STATEMENT EXECUTE FUNCTION trg_venta_recalcular_del();

BEGIN;
SELECT numeroDocumento, subtotal, total FROM Venta WHERE idVenta = 60;          -- antes
INSERT INTO DetalleVenta (idVenta, idProducto, cantidad) VALUES (60, 14, 2), (60, 18, 1);
SELECT numeroDocumento, subtotal, total FROM Venta WHERE idVenta = 60;          -- después
DELETE FROM DetalleVenta WHERE idVenta = 60 AND idProducto IN (14, 18);
SELECT numeroDocumento, subtotal, total FROM Venta WHERE idVenta = 60;          -- vuelve al inicio
ROLLBACK;
-- @esperado: el subtotal sube 418.00 (2 x 200 + 18) al insertar y vuelve al valor original al borrar
-- Este es el estilo de SQL Server: allá TODOS los triggers son por sentencia y leen las tablas
-- especiales "inserted" y "deleted" (aquí: REFERENCING NEW TABLE / OLD TABLE).

-- 5. PROTEGER DATOS. Impide modificar o borrar el detalle de una venta ANULADA (BEFORE que
--    lanza error). Pruébalo con la venta '00009', que está anulada.
CREATE OR REPLACE FUNCTION trg_detalle_bloquear_anuladas()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado VARCHAR;
BEGIN
    SELECT estado INTO v_estado FROM Venta WHERE idVenta = OLD.idVenta;
    IF v_estado = 'ANULADA' THEN
        RAISE EXCEPTION 'La venta % está anulada: su detalle no se puede modificar', OLD.idVenta;
    END IF;
    IF TG_OP = 'DELETE' THEN           -- TG_OP dice qué operación disparó el trigger
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_detalle_bloquear_anuladas ON DetalleVenta;
CREATE TRIGGER tr_detalle_bloquear_anuladas
BEFORE UPDATE OR DELETE ON DetalleVenta
FOR EACH ROW
EXECUTE FUNCTION trg_detalle_bloquear_anuladas();

DO $$
BEGIN
    DELETE FROM DetalleVenta WHERE idVenta = 9;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Bloqueado: %', SQLERRM;
END;
$$;
SELECT COUNT(*) AS lineas_venta_9 FROM DetalleVenta WHERE idVenta = 9;
-- @esperado: aviso "Bloqueado: La venta 9 está anulada..." y las líneas siguen ahí

-- 6. Lista los triggers que creaste y en qué tabla y momento se disparan.
SELECT event_object_table AS tabla, trigger_name, action_timing AS momento,
       string_agg(event_manipulation, ', ') AS eventos
FROM information_schema.triggers
GROUP BY event_object_table, trigger_name, action_timing
ORDER BY tabla, trigger_name;
-- @esperado: 7 triggers (1 en producto, 6 en detalleventa)
-- T-SQL: SELECT name, OBJECT_NAME(parent_id) FROM sys.triggers;

-- 7. Prueba final: con los triggers activos, una venta completa son solo 2 INSERT.
--    Compáralo con los 4 pasos manuales del ejercicio 8 del módulo 07.
BEGIN;
INSERT INTO Venta (numeroDocumento, idCliente, idUsuario, tipoPago) VALUES ('00061', 2, 4, 'Tarjeta');
INSERT INTO DetalleVenta (idVenta, idProducto, cantidad)
SELECT v.idVenta, p.idProducto, x.cantidad
FROM Venta v
CROSS JOIN (VALUES ('AUR-002', 2), ('ACC-004', 1)) x(codigo, cantidad)
JOIN Producto p ON p.codigo = x.codigo
WHERE v.numeroDocumento = '00061';
SELECT v.numeroDocumento, v.subtotal, v.impuesto, v.total,
       (SELECT stock FROM Producto WHERE codigo = 'ACC-004') AS stock_mouse,
       (SELECT COUNT(*) FROM MovimientoInventario) AS movimientos
FROM Venta v WHERE v.numeroDocumento = '00061';
ROLLBACK;
-- @esperado: total 1615.75, stock_mouse 3 y 2 movimientos: lo mismo que antes, sin pasos manuales
