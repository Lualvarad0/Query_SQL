-- =====================================================================
-- 01_esquema.sql · Base de datos DBVENTA en PostgreSQL
--
-- Es la base de proyecto-VENTASANGULAR (SQL Server) ampliada con clientes,
-- ciudades, proveedores, vendedores, costos e impuestos, para que las
-- consultas se parezcan a las de un sistema de ventas real.
--
-- No lo corras suelto: usa instalar.sql (ver README.md de esta carpeta).
-- Las líneas marcadas "T-SQL:" muestran cómo se escribe en SQL Server.
-- =====================================================================

-- Permite reinstalar desde cero.
DROP TABLE IF EXISTS AuditoriaPrecio, MovimientoInventario, DetalleVenta, Venta,
                     NumeroDocumento, Producto, Proveedor, Categoria, Cliente,
                     Ciudad, Usuario, MenuRol, Menu, Rol CASCADE;

-- ---------------------------------------------------------------------
-- Seguridad: roles, menús y usuarios (igual que el proyecto original)
-- ---------------------------------------------------------------------
CREATE TABLE Rol (
    idRol         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- T-SQL: int primary key identity(1,1)
    nombre        VARCHAR(50) NOT NULL UNIQUE,
    fechaRegistro TIMESTAMP DEFAULT now()                          -- T-SQL: datetime default getdate()
);

CREATE TABLE Menu (
    idMenu INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    icono  VARCHAR(50),
    url    VARCHAR(50)
);

-- Tabla puente (muchos a muchos): un rol ve muchos menús y un menú lo ven muchos roles.
CREATE TABLE MenuRol (
    idMenuRol INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    idMenu    INT NOT NULL REFERENCES Menu(idMenu),
    idRol     INT NOT NULL REFERENCES Rol(idRol),
    UNIQUE (idMenu, idRol)
);

CREATE TABLE Usuario (
    idUsuario      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombreCompleto VARCHAR(100) NOT NULL,
    correo         VARCHAR(60) UNIQUE,
    idRol          INT NOT NULL REFERENCES Rol(idRol),
    idJefe         INT REFERENCES Usuario(idUsuario),             -- NUEVO: jefe directo (auto-relación)
    clave          VARCHAR(40),
    esActivo       BOOLEAN DEFAULT TRUE,                           -- T-SQL: bit default 1
    fechaRegistro  TIMESTAMP DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Clientes y ubicación (NUEVO)
-- ---------------------------------------------------------------------
CREATE TABLE Ciudad (
    idCiudad  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre    VARCHAR(60) NOT NULL,
    provincia VARCHAR(60) NOT NULL
);

CREATE TABLE Cliente (
    idCliente      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    documento      VARCHAR(13) NOT NULL UNIQUE,                    -- cédula (10) o RUC (13)
    nombreCompleto VARCHAR(100) NOT NULL,
    correo         VARCHAR(60),                                    -- puede faltar (NULL)
    telefono       VARCHAR(15),                                    -- puede faltar (NULL)
    idCiudad       INT REFERENCES Ciudad(idCiudad),
    fechaRegistro  DATE NOT NULL
);

-- ---------------------------------------------------------------------
-- Catálogo
-- ---------------------------------------------------------------------
CREATE TABLE Categoria (
    idCategoria   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre        VARCHAR(50) NOT NULL,
    esActivo      BOOLEAN DEFAULT TRUE,
    fechaRegistro TIMESTAMP DEFAULT now()
);

CREATE TABLE Proveedor (                                           -- NUEVO
    idProveedor INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      VARCHAR(80) NOT NULL,
    ruc         VARCHAR(13) NOT NULL UNIQUE,
    idCiudad    INT REFERENCES Ciudad(idCiudad)
);

CREATE TABLE Producto (
    idProducto    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo        VARCHAR(20) NOT NULL UNIQUE,                     -- NUEVO: SKU
    nombre        VARCHAR(100) NOT NULL,
    idCategoria   INT REFERENCES Categoria(idCategoria),          -- puede ser NULL (a propósito)
    idProveedor   INT REFERENCES Proveedor(idProveedor),
    stock         INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    stockMinimo   INT NOT NULL DEFAULT 5,                          -- NUEVO
    costo         NUMERIC(10,2) NOT NULL,                          -- NUEVO: lo que nos cuesta
    precio        NUMERIC(10,2) NOT NULL CHECK (precio > 0),       -- T-SQL: decimal(10,2)
    esActivo      BOOLEAN DEFAULT TRUE,
    fechaRegistro TIMESTAMP DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Ventas
-- ---------------------------------------------------------------------
CREATE TABLE NumeroDocumento (
    idNumeroDocumento INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ultimo_Numero     INT NOT NULL,
    fechaRegistro     TIMESTAMP DEFAULT now()
);

CREATE TABLE Venta (
    idVenta         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numeroDocumento VARCHAR(40) NOT NULL UNIQUE,
    idCliente       INT REFERENCES Cliente(idCliente),            -- NUEVO
    idUsuario       INT NOT NULL REFERENCES Usuario(idUsuario),   -- NUEVO: vendedor
    tipoPago        VARCHAR(50) NOT NULL,
    estado          VARCHAR(10) NOT NULL DEFAULT 'PAGADA'
                    CHECK (estado IN ('PAGADA', 'ANULADA')),       -- NUEVO
    subtotal        NUMERIC(10,2) NOT NULL DEFAULT 0,              -- NUEVO
    impuesto        NUMERIC(10,2) NOT NULL DEFAULT 0,              -- NUEVO: IVA 15 %
    total           NUMERIC(10,2) NOT NULL DEFAULT 0,
    fechaRegistro   TIMESTAMP DEFAULT now()
);

CREATE TABLE DetalleVenta (
    idDetalleVenta INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    idVenta        INT NOT NULL REFERENCES Venta(idVenta),
    idProducto     INT NOT NULL REFERENCES Producto(idProducto),
    cantidad       INT NOT NULL CHECK (cantidad > 0),
    precio         NUMERIC(10,2) NOT NULL,                         -- precio al momento de vender
    descuento      NUMERIC(5,2) NOT NULL DEFAULT 0,                -- NUEVO: porcentaje (0 a 100)
    total          NUMERIC(10,2) NOT NULL
);

-- Índices en las llaves foráneas: PostgreSQL NO los crea solo (SQL Server tampoco).
CREATE INDEX ix_usuario_rol       ON Usuario(idRol);
CREATE INDEX ix_cliente_ciudad    ON Cliente(idCiudad);
CREATE INDEX ix_producto_cat      ON Producto(idCategoria);
CREATE INDEX ix_venta_cliente     ON Venta(idCliente);
CREATE INDEX ix_venta_usuario     ON Venta(idUsuario);
CREATE INDEX ix_detalle_venta     ON DetalleVenta(idVenta);
CREATE INDEX ix_detalle_producto  ON DetalleVenta(idProducto);
