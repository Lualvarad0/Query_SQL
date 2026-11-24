/* =====================================================================
   PASO 6 · Relacionar más: clientes, vendedores y proveedores (SQL Server)

   Hasta el paso 5 la venta no sabe A QUIÉN se vendió ni QUIÉN vendió, y
   los productos no tienen proveedor. Aquí agregamos:
     6.1 Cliente 1──* Venta          uno a muchos OPCIONAL (NULL = consumidor final)
     6.2 Usuario 1──* Venta          uno a muchos OBLIGATORIO (el vendedor)
     6.3 Usuario 1──* Usuario        auto-relación (cada usuario tiene un jefe)
     6.4 Producto *──* Proveedor     muchos a muchos con datos propios (costo, días de entrega)
         + "solo un proveedor principal por producto" con un índice único filtrado
     6.5 sp_RegistrarVenta actualizado para guardar vendedor y cliente
     6.6 Consultas que usan las relaciones nuevas

   En cada tabla nueva fíjate en las reglas (CHECK, UNIQUE, NOT NULL, FK):
   son la primera línea de seguridad de los datos.
   Corre después de los pasos 1 a 5.
   ===================================================================== */

USE DBVENTA;
GO

-- El índice filtrado de 6.4 exige QUOTED_IDENTIFIER ON. SSMS lo trae activado;
-- sqlcmd no, por eso lo dejamos explícito.
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   6.1 Clientes
   tipoDocumento: C = cédula (10 dígitos), R = RUC (13 dígitos), P = pasaporte.
   Las reglas del documento van en CHECK: la base no deja guardar una
   cédula de 9 dígitos o con letras, venga de la app o de un script.
   --------------------------------------------------------------------- */
CREATE TABLE Cliente (
    idCliente      INT IDENTITY(1,1) CONSTRAINT PK_Cliente PRIMARY KEY,
    tipoDocumento  CHAR(1)      NOT NULL CONSTRAINT CK_Cliente_tipo CHECK (tipoDocumento IN ('C', 'R', 'P')),
    documento      VARCHAR(13)  NOT NULL CONSTRAINT UQ_Cliente_documento UNIQUE,
    nombre         VARCHAR(100) NOT NULL,
    correo         VARCHAR(60)  NULL,
    telefono       VARCHAR(15)  NULL,
    fechaRegistro  DATETIME     NOT NULL CONSTRAINT DF_Cliente_fecha DEFAULT GETDATE(),
    CONSTRAINT CK_Cliente_documento CHECK (
        (tipoDocumento = 'C' AND LEN(documento) = 10 AND documento NOT LIKE '%[^0-9]%') OR
        (tipoDocumento = 'R' AND LEN(documento) = 13 AND documento NOT LIKE '%[^0-9]%') OR
        (tipoDocumento = 'P' AND LEN(documento) BETWEEN 6 AND 13)
    ),
    CONSTRAINT CK_Cliente_correo CHECK (correo IS NULL OR correo LIKE '%_@_%._%')
);
GO
-- documento NOT LIKE '%[^0-9]%' se lee: "no tiene ningún carácter que no sea un dígito".

INSERT INTO Cliente (tipoDocumento, documento, nombre, correo, telefono) VALUES
('C', '0912345678',    'Carlos Pérez',            'carlos@example.com', '0991234567'),
('C', '1712345678',    'Ana Gómez',               NULL,                 '0987654321'),
('R', '1790012345001', 'Comercial Andina S.A.',   'compras@example.com', NULL),
('C', '0102030405',    'Luis Castro',             'luis@example.com',   NULL),
('R', '0992233445001', 'Tech Store Cía. Ltda.',   'tech@example.com',   '042345678'),
('P', 'AB123456',      'Marta Ruiz',              NULL,                 NULL);   -- nunca ha comprado
GO

-- Venta -> Cliente es OPCIONAL: en Ecuador se puede vender a "consumidor final".
ALTER TABLE Venta ADD idCliente INT NULL
    CONSTRAINT FK_Venta_Cliente REFERENCES Cliente(idCliente);
GO

-- Repartimos las 24 ventas: las múltiplos de 4 quedan como consumidor final (NULL).
UPDATE Venta
SET idCliente = CASE WHEN idVenta % 4 = 0 THEN NULL ELSE (idVenta - 1) % 5 + 1 END;
GO

/* ---------------------------------------------------------------------
   6.2 y 6.3 Vendedor y jefe
   Venta -> Usuario es OBLIGATORIO. Como Venta ya tiene filas, usamos el
   patrón seguro: 1) columna NULL, 2) llenarla, 3) NOT NULL + FK.
   --------------------------------------------------------------------- */
ALTER TABLE Venta ADD idUsuario INT NULL;                                  -- 1)
GO
UPDATE Venta SET idUsuario = CASE idVenta % 3 WHEN 0 THEN 3 WHEN 1 THEN 2 ELSE 1 END;   -- 2)
GO
ALTER TABLE Venta ALTER COLUMN idUsuario INT NOT NULL;                    -- 3)
ALTER TABLE Venta ADD CONSTRAINT FK_Venta_Usuario FOREIGN KEY (idUsuario) REFERENCES Usuario(idUsuario);
GO

-- Auto-relación: el jefe de un usuario es otro usuario.
ALTER TABLE Usuario ADD idJefe INT NULL
    CONSTRAINT FK_Usuario_Jefe REFERENCES Usuario(idUsuario);
GO
ALTER TABLE Usuario ADD CONSTRAINT CK_Usuario_noEsSuPropioJefe CHECK (idJefe IS NULL OR idJefe <> idUsuario);
GO
UPDATE Usuario SET idJefe = 1 WHERE idUsuario = 3;   -- jose (supervisor) reporta al administrador
UPDATE Usuario SET idJefe = 3 WHERE idUsuario = 2;   -- maria (empleada) reporta a jose
GO

CREATE INDEX IX_Venta_Cliente ON Venta(idCliente);
CREATE INDEX IX_Venta_Usuario ON Venta(idUsuario);
GO

/* ---------------------------------------------------------------------
   6.4 Proveedores: muchos a muchos con datos propios
   Un producto se puede comprar a varios proveedores, y cada proveedor
   vende muchos productos. El costo y los días de entrega no son del
   producto ni del proveedor: son de la PAREJA. Por eso van en la tabla puente.
   --------------------------------------------------------------------- */
CREATE TABLE Proveedor (
    idProveedor INT IDENTITY(1,1) CONSTRAINT PK_Proveedor PRIMARY KEY,
    nombre      VARCHAR(80) NOT NULL,
    ruc         CHAR(13)    NOT NULL CONSTRAINT UQ_Proveedor_ruc UNIQUE
                CONSTRAINT CK_Proveedor_ruc CHECK (ruc NOT LIKE '%[^0-9]%'),
    esActivo    BIT NOT NULL CONSTRAINT DF_Proveedor_activo DEFAULT 1
);
GO

CREATE TABLE ProductoProveedor (
    idProducto   INT NOT NULL CONSTRAINT FK_PP_Producto  REFERENCES Producto(idProducto),
    idProveedor  INT NOT NULL CONSTRAINT FK_PP_Proveedor REFERENCES Proveedor(idProveedor),
    costo        DECIMAL(10,2) NOT NULL CONSTRAINT CK_PP_costo CHECK (costo > 0),
    diasEntrega  TINYINT       NOT NULL CONSTRAINT CK_PP_dias  CHECK (diasEntrega BETWEEN 1 AND 60),
    esPrincipal  BIT           NOT NULL CONSTRAINT DF_PP_principal DEFAULT 0,
    CONSTRAINT PK_ProductoProveedor PRIMARY KEY (idProducto, idProveedor)
);
GO

-- Regla: cada producto tiene como máximo UN proveedor principal.
-- Un UNIQUE normal sobre (idProducto, esPrincipal) no sirve (impediría dos NO principales).
-- Un índice único FILTRADO solo mira las filas con esPrincipal = 1.
CREATE UNIQUE INDEX UX_PP_UnPrincipal ON ProductoProveedor(idProducto) WHERE esPrincipal = 1;
GO

INSERT INTO Proveedor (nombre, ruc) VALUES
('Distribuidora Samsung Ecuador', '1790000000001'),
('Lenovo Partner Quito',          '1790000000002'),
('Gamer Import',                  '0990000000001'),
('Accesorios del Pacífico',       '0990000000002');
GO

-- El producto 13 (memoria kingston rgb) queda sin proveedor, a propósito.
INSERT INTO ProductoProveedor (idProducto, idProveedor, costo, diasEntrega, esPrincipal) VALUES
(1, 1, 2100, 5, 1),  (1, 3, 2150, 10, 0),
(2, 2, 1850, 3, 1),
(3, 2, 1780, 7, 1),  (3, 3, 1750, 15, 0),
(4, 3,  820, 4, 1),
(5, 1, 1150, 5, 1),  (5, 3, 1100, 12, 0),
(6, 3, 1080, 6, 1),
(7, 3,  600, 4, 1),
(8, 3,  780, 4, 1),
(9, 4,  790, 8, 1),  (9, 3,  760, 10, 0),
(10, 4, 620, 6, 1),
(11, 3, 500, 4, 1),  (11, 4, 520, 3, 0),
(12, 3, 730, 5, 1),
(14, 4, 120, 2, 1),
(15, 4, 110, 2, 1);
GO

/* ---------------------------------------------------------------------
   6.5 sp_RegistrarVenta ahora guarda el vendedor y el cliente
   (si el cliente no existe, la FK FK_Venta_Cliente detiene la venta)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_RegistrarVenta
    @tipoPago        VARCHAR(50),
    @detalle         NVARCHAR(MAX),
    @numeroDocumento VARCHAR(40) OUTPUT,
    @idUsuario       INT,                 -- NUEVO: quién vende (obligatorio)
    @idCliente       INT = NULL           -- NUEVO: a quién (NULL = consumidor final)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @items TABLE (idProducto INT, cantidad INT);
    INSERT INTO @items (idProducto, cantidad)
    SELECT idProducto, cantidad
    FROM OPENJSON(@detalle) WITH (idProducto INT '$.idProducto', cantidad INT '$.cantidad');

    IF NOT EXISTS (SELECT 1 FROM @items)
        THROW 50001, 'La venta no tiene productos.', 1;
    IF EXISTS (SELECT 1 FROM @items WHERE cantidad IS NULL OR cantidad <= 0)
        THROW 50004, 'Las cantidades deben ser mayores que cero.', 1;
    IF EXISTS (SELECT 1 FROM @items i
               LEFT JOIN Producto p ON p.idProducto = i.idProducto AND p.esActivo = 1
               WHERE p.idProducto IS NULL)
        THROW 50002, 'Hay un producto que no existe o está inactivo.', 1;
    IF EXISTS (SELECT 1 FROM @items i INNER JOIN Producto p ON p.idProducto = i.idProducto
               WHERE p.stock < i.cantidad)
        THROW 50003, 'Stock insuficiente para uno de los productos.', 1;

    BEGIN TRANSACTION;
        DECLARE @numero INT;
        UPDATE NumeroDocumento SET @numero = ultimo_Numero = ultimo_Numero + 1;
        SET @numeroDocumento = RIGHT('0000' + CAST(@numero AS VARCHAR(10)), 5);

        INSERT INTO Venta (numeroDocumento, tipoPago, total, idUsuario, idCliente)
        VALUES (@numeroDocumento, @tipoPago, 0, @idUsuario, @idCliente);
        DECLARE @idVenta INT = SCOPE_IDENTITY();

        INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, precio, total)
        SELECT @idVenta, p.idProducto, i.cantidad, p.precio, p.precio * i.cantidad
        FROM @items i INNER JOIN Producto p ON p.idProducto = i.idProducto;

        UPDATE p SET p.stock = p.stock - i.cantidad
        FROM Producto p INNER JOIN @items i ON i.idProducto = p.idProducto;

        UPDATE Venta
        SET total = (SELECT SUM(total) FROM DetalleVenta WHERE idVenta = @idVenta)
        WHERE idVenta = @idVenta;
    COMMIT TRANSACTION;
END;
GO

BEGIN TRANSACTION;
    DECLARE @num VARCHAR(40);
    EXEC sp_RegistrarVenta 'Tarjeta', N'[{"idProducto":11,"cantidad":1}]', @num OUTPUT,
         @idUsuario = 2, @idCliente = 6;                 -- maria le vende a Marta Ruiz
    SELECT v.numeroDocumento, v.total, u.nombreCompleto AS vendedor, c.nombre AS cliente
    FROM Venta v
    INNER JOIN Usuario u ON u.idUsuario = v.idUsuario
    LEFT JOIN Cliente c  ON c.idCliente = v.idCliente
    WHERE v.numeroDocumento = @num;
ROLLBACK TRANSACTION;
GO

/* ---------------------------------------------------------------------
   6.6 Consultas con las relaciones nuevas
   --------------------------------------------------------------------- */

-- 6.6.1 Historial con cliente y vendedor. LEFT JOIN a Cliente: si no, las ventas
--       a consumidor final DESAPARECEN del historial (¡6 ventas!).
SELECT v.numeroDocumento,
       ISNULL(c.nombre, 'Consumidor final') AS cliente,
       u.nombreCompleto AS vendedor,
       v.total
FROM Venta v
INNER JOIN Usuario u ON u.idUsuario = v.idUsuario
LEFT JOIN Cliente c  ON c.idCliente = v.idCliente
ORDER BY v.idVenta;
GO

-- 6.6.2 Cuánto compró cada cliente (incluye a quien no compró nada)
SELECT c.nombre, COUNT(v.idVenta) AS compras, ISNULL(SUM(v.total), 0) AS total
FROM Cliente c
LEFT JOIN Venta v ON v.idCliente = c.idCliente
GROUP BY c.idCliente, c.nombre
ORDER BY total DESC;
GO

-- 6.6.3 Organigrama: cada usuario con su jefe (auto-JOIN; LEFT para el que no tiene jefe)
SELECT u.nombreCompleto AS usuario, r.nombre AS rol, ISNULL(j.nombreCompleto, '(sin jefe)') AS jefe
FROM Usuario u
INNER JOIN Rol r     ON r.idRol = u.idRol
LEFT JOIN Usuario j  ON j.idUsuario = u.idJefe;
GO

-- 6.6.4 Lo que vendió cada usuario más quienes le reportan DIRECTAMENTE (un nivel).
--       Para toda la cadena hacia abajo se usa una CTE recursiva (ejercicio 20).
SELECT j.nombreCompleto AS usuario,
       SUM(v.total) AS total_equipo
FROM Usuario j
INNER JOIN Usuario u ON u.idUsuario = j.idUsuario OR u.idJefe = j.idUsuario
INNER JOIN Venta v   ON v.idUsuario = u.idUsuario
GROUP BY j.idUsuario, j.nombreCompleto;
GO

-- 6.6.5 Proveedor principal de cada producto y el margen (precio - costo)
SELECT p.nombre AS producto, pr.nombre AS proveedor, pp.costo, p.precio,
       p.precio - pp.costo AS margen,
       CAST(100.0 * (p.precio - pp.costo) / p.precio AS DECIMAL(5,1)) AS margen_pct
FROM Producto p
INNER JOIN ProductoProveedor pp ON pp.idProducto = p.idProducto AND pp.esPrincipal = 1
INNER JOIN Proveedor pr         ON pr.idProveedor = pp.idProveedor
ORDER BY margen_pct;
GO

-- 6.6.6 Productos sin ningún proveedor (anti-join)
SELECT p.idProducto, p.nombre
FROM Producto p
WHERE NOT EXISTS (SELECT 1 FROM ProductoProveedor pp WHERE pp.idProducto = p.idProducto);
GO
