-- =====================================================================
-- PASO 6 · Relacionar más: clientes, vendedores y proveedores (PostgreSQL)
-- Equivalente de sqlserver/06_relaciones.sql (allí está la explicación larga).
--   6.1 Cliente 1──* Venta        opcional (NULL = consumidor final)
--   6.2 Usuario 1──* Venta        obligatorio (el vendedor)
--   6.3 Usuario 1──* Usuario      auto-relación (jefe)
--   6.4 Producto *──* Proveedor   con datos propios + un solo proveedor principal
--   6.5 sp_registrar_venta con vendedor y cliente
--   6.6 Consultas
-- Corre después de los pasos 1 a 5.
-- =====================================================================

-- 6.1 Clientes
CREATE TABLE Cliente (
    idCliente      INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_cliente PRIMARY KEY,
    tipoDocumento  CHAR(1)      NOT NULL CONSTRAINT ck_cliente_tipo CHECK (tipoDocumento IN ('C', 'R', 'P')),
    documento      VARCHAR(13)  NOT NULL CONSTRAINT uq_cliente_documento UNIQUE,
    nombre         VARCHAR(100) NOT NULL,
    correo         VARCHAR(60),
    telefono       VARCHAR(15),
    fechaRegistro  TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT ck_cliente_documento CHECK (
        (tipoDocumento = 'C' AND documento ~ '^[0-9]{10}$') OR      -- ~ es "cumple la expresión regular"
        (tipoDocumento = 'R' AND documento ~ '^[0-9]{13}$') OR      -- T-SQL: LEN(...) = 13 AND NOT LIKE '%[^0-9]%'
        (tipoDocumento = 'P' AND length(documento) BETWEEN 6 AND 13)
    ),
    CONSTRAINT ck_cliente_correo CHECK (correo IS NULL OR correo LIKE '%_@_%._%')
);

INSERT INTO Cliente (tipoDocumento, documento, nombre, correo, telefono) VALUES
('C', '0912345678',    'Carlos Pérez',          'carlos@example.com',  '0991234567'),
('C', '1712345678',    'Ana Gómez',             NULL,                  '0987654321'),
('R', '1790012345001', 'Comercial Andina S.A.', 'compras@example.com', NULL),
('C', '0102030405',    'Luis Castro',           'luis@example.com',    NULL),
('R', '0992233445001', 'Tech Store Cía. Ltda.', 'tech@example.com',    '042345678'),
('P', 'AB123456',      'Marta Ruiz',            NULL,                  NULL);   -- nunca ha comprado

ALTER TABLE Venta ADD COLUMN idCliente INT CONSTRAINT fk_venta_cliente REFERENCES Cliente(idCliente);

UPDATE Venta
SET idCliente = CASE WHEN idVenta % 4 = 0 THEN NULL ELSE (idVenta - 1) % 5 + 1 END;

-- 6.2 Vendedor: 1) columna NULL, 2) llenarla, 3) NOT NULL + FK
ALTER TABLE Venta ADD COLUMN idUsuario INT;                                           -- 1)
UPDATE Venta SET idUsuario = CASE idVenta % 3 WHEN 0 THEN 3 WHEN 1 THEN 2 ELSE 1 END; -- 2)
ALTER TABLE Venta ALTER COLUMN idUsuario SET NOT NULL;                                -- 3) T-SQL: ALTER COLUMN idUsuario INT NOT NULL
ALTER TABLE Venta ADD CONSTRAINT fk_venta_usuario FOREIGN KEY (idUsuario) REFERENCES Usuario(idUsuario);

-- 6.3 Jefe (auto-relación)
ALTER TABLE Usuario ADD COLUMN idJefe INT CONSTRAINT fk_usuario_jefe REFERENCES Usuario(idUsuario);
ALTER TABLE Usuario ADD CONSTRAINT ck_usuario_no_es_su_propio_jefe CHECK (idJefe IS NULL OR idJefe <> idUsuario);
UPDATE Usuario SET idJefe = 1 WHERE idUsuario = 3;
UPDATE Usuario SET idJefe = 3 WHERE idUsuario = 2;

CREATE INDEX ix_venta_cliente ON Venta(idCliente);
CREATE INDEX ix_venta_usuario ON Venta(idUsuario);

-- 6.4 Proveedores (muchos a muchos con datos propios)
CREATE TABLE Proveedor (
    idProveedor INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_proveedor PRIMARY KEY,
    nombre      VARCHAR(80) NOT NULL,
    ruc         CHAR(13)    NOT NULL CONSTRAINT uq_proveedor_ruc UNIQUE
                CONSTRAINT ck_proveedor_ruc CHECK (ruc ~ '^[0-9]{13}$'),
    esActivo    BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE ProductoProveedor (
    idProducto   INT NOT NULL CONSTRAINT fk_pp_producto  REFERENCES Producto(idProducto),
    idProveedor  INT NOT NULL CONSTRAINT fk_pp_proveedor REFERENCES Proveedor(idProveedor),
    costo        NUMERIC(10,2) NOT NULL CONSTRAINT ck_pp_costo CHECK (costo > 0),
    diasEntrega  SMALLINT      NOT NULL CONSTRAINT ck_pp_dias  CHECK (diasEntrega BETWEEN 1 AND 60),
    esPrincipal  BOOLEAN       NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_productoproveedor PRIMARY KEY (idProducto, idProveedor)
);

-- Un solo proveedor principal por producto: índice único PARCIAL (T-SQL: índice filtrado)
CREATE UNIQUE INDEX ux_pp_un_principal ON ProductoProveedor(idProducto) WHERE esPrincipal;

INSERT INTO Proveedor (nombre, ruc) VALUES
('Distribuidora Samsung Ecuador', '1790000000001'),
('Lenovo Partner Quito',          '1790000000002'),
('Gamer Import',                  '0990000000001'),
('Accesorios del Pacífico',       '0990000000002');

INSERT INTO ProductoProveedor (idProducto, idProveedor, costo, diasEntrega, esPrincipal) VALUES
(1, 1, 2100, 5, TRUE),  (1, 3, 2150, 10, FALSE),
(2, 2, 1850, 3, TRUE),
(3, 2, 1780, 7, TRUE),  (3, 3, 1750, 15, FALSE),
(4, 3,  820, 4, TRUE),
(5, 1, 1150, 5, TRUE),  (5, 3, 1100, 12, FALSE),
(6, 3, 1080, 6, TRUE),
(7, 3,  600, 4, TRUE),
(8, 3,  780, 4, TRUE),
(9, 4,  790, 8, TRUE),  (9, 3,  760, 10, FALSE),
(10, 4, 620, 6, TRUE),
(11, 3, 500, 4, TRUE),  (11, 4, 520, 3, FALSE),
(12, 3, 730, 5, TRUE),
(14, 4, 120, 2, TRUE),
(15, 4, 110, 2, TRUE);

-- 6.5 sp_registrar_venta con vendedor y cliente.
-- En PostgreSQL, cambiar los parámetros crea OTRO procedimiento con el mismo nombre
-- (sobrecarga). Por eso primero se borra la versión del paso 4.
DROP PROCEDURE IF EXISTS sp_registrar_venta(VARCHAR, JSONB, VARCHAR);

CREATE OR REPLACE PROCEDURE sp_registrar_venta(
    p_tipoPago              VARCHAR,
    p_detalle               JSONB,
    p_idUsuario             INT,                 -- NUEVO: quién vende
    p_idCliente             INT DEFAULT NULL,    -- NUEVO: a quién (NULL = consumidor final)
    INOUT p_numeroDocumento VARCHAR DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_idVenta INT;
    v_numero  INT;
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS tmp_items (idProducto INT, cantidad INT) ON COMMIT DROP;
    DELETE FROM tmp_items;
    INSERT INTO tmp_items
    SELECT (e->>'idProducto')::int, (e->>'cantidad')::int
    FROM jsonb_array_elements(p_detalle) AS e;

    IF NOT EXISTS (SELECT 1 FROM tmp_items) THEN
        RAISE EXCEPTION 'La venta no tiene productos.';
    END IF;
    IF EXISTS (SELECT 1 FROM tmp_items WHERE cantidad IS NULL OR cantidad <= 0) THEN
        RAISE EXCEPTION 'Las cantidades deben ser mayores que cero.';
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

    INSERT INTO Venta (numeroDocumento, tipoPago, total, idUsuario, idCliente)
    VALUES (p_numeroDocumento, p_tipoPago, 0, p_idUsuario, p_idCliente)
    RETURNING idVenta INTO v_idVenta;

    INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, precio, total)
    SELECT v_idVenta, p.idProducto, i.cantidad, p.precio, p.precio * i.cantidad
    FROM tmp_items i JOIN Producto p ON p.idProducto = i.idProducto;

    UPDATE Producto p SET stock = p.stock - i.cantidad
    FROM tmp_items i WHERE i.idProducto = p.idProducto;

    UPDATE Venta SET total = (SELECT SUM(total) FROM DetalleVenta WHERE idVenta = v_idVenta)
    WHERE idVenta = v_idVenta;
END;
$$;

BEGIN;
    CALL sp_registrar_venta('Tarjeta', '[{"idProducto":11,"cantidad":1}]', 2, 6);   -- devuelve '00025'
    SELECT v.numeroDocumento, v.total, u.nombreCompleto AS vendedor, c.nombre AS cliente
    FROM Venta v
    JOIN Usuario u      ON u.idUsuario = v.idUsuario
    LEFT JOIN Cliente c ON c.idCliente = v.idCliente
    WHERE v.numeroDocumento = '00025';
ROLLBACK;

-- 6.6.1 Historial con cliente y vendedor (LEFT JOIN: si no, se pierden las ventas a consumidor final)
SELECT v.numeroDocumento,
       COALESCE(c.nombre, 'Consumidor final') AS cliente,       -- T-SQL: ISNULL
       u.nombreCompleto AS vendedor,
       v.total
FROM Venta v
JOIN Usuario u      ON u.idUsuario = v.idUsuario
LEFT JOIN Cliente c ON c.idCliente = v.idCliente
ORDER BY v.idVenta;

-- 6.6.2 Cuánto compró cada cliente (incluye a quien no compró nada)
SELECT c.nombre, COUNT(v.idVenta) AS compras, COALESCE(SUM(v.total), 0) AS total
FROM Cliente c
LEFT JOIN Venta v ON v.idCliente = c.idCliente
GROUP BY c.idCliente, c.nombre
ORDER BY total DESC;

-- 6.6.3 Organigrama (auto-JOIN)
SELECT u.nombreCompleto AS usuario, r.nombre AS rol, COALESCE(j.nombreCompleto, '(sin jefe)') AS jefe
FROM Usuario u
JOIN Rol r          ON r.idRol = u.idRol
LEFT JOIN Usuario j ON j.idUsuario = u.idJefe;

-- 6.6.4 Lo que vendió cada usuario más quienes le reportan directamente (un nivel)
SELECT j.nombreCompleto AS usuario, SUM(v.total) AS total_equipo
FROM Usuario j
JOIN Usuario u ON u.idUsuario = j.idUsuario OR u.idJefe = j.idUsuario
JOIN Venta v   ON v.idUsuario = u.idUsuario
GROUP BY j.idUsuario, j.nombreCompleto;

-- 6.6.5 Proveedor principal y margen de cada producto
SELECT p.nombre AS producto, pr.nombre AS proveedor, pp.costo, p.precio,
       p.precio - pp.costo AS margen,
       ROUND(100.0 * (p.precio - pp.costo) / p.precio, 1) AS margen_pct
FROM Producto p
JOIN ProductoProveedor pp ON pp.idProducto = p.idProducto AND pp.esPrincipal
JOIN Proveedor pr         ON pr.idProveedor = pp.idProveedor
ORDER BY margen_pct;

-- 6.6.6 Productos sin proveedor
SELECT p.idProducto, p.nombre
FROM Producto p
WHERE NOT EXISTS (SELECT 1 FROM ProductoProveedor pp WHERE pp.idProducto = p.idProducto);
