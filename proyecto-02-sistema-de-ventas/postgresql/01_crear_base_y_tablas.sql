-- =====================================================================
-- PASO 1 · Crear las tablas de DBVENTA (PostgreSQL)
--
-- Mismo modelo que sqlserver/01_crear_base_y_tablas.sql.
-- Antes de correrlo crea la base y conéctate a ella:
--     createdb dbventa_app
--     psql -d dbventa_app -f postgresql/01_crear_base_y_tablas.sql
-- (PostgreSQL no tiene USE ni GO: cada archivo se corre conectado a una base.)
-- =====================================================================

DROP TABLE IF EXISTS DetalleVenta, Venta, NumeroDocumento, Producto, Categoria,
                     Usuario, MenuRol, Menu, Rol CASCADE;

-- Seguridad ------------------------------------------------------------
CREATE TABLE Rol (
    idRol         INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_rol PRIMARY KEY,
    nombre        VARCHAR(50) NOT NULL CONSTRAINT uq_rol_nombre UNIQUE,
    fechaRegistro TIMESTAMP DEFAULT now()
);

CREATE TABLE Menu (
    idMenu INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_menu PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    icono  VARCHAR(50),
    url    VARCHAR(50)
);

CREATE TABLE MenuRol (
    idMenuRol INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_menurol PRIMARY KEY,
    idMenu    INT NOT NULL CONSTRAINT fk_menurol_menu REFERENCES Menu(idMenu),
    idRol     INT NOT NULL CONSTRAINT fk_menurol_rol  REFERENCES Rol(idRol),
    CONSTRAINT uq_menurol UNIQUE (idMenu, idRol)
);

CREATE TABLE Usuario (
    idUsuario      INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_usuario PRIMARY KEY,
    nombreCompleto VARCHAR(100) NOT NULL,
    correo         VARCHAR(40)  NOT NULL CONSTRAINT uq_usuario_correo UNIQUE,
    idRol          INT NOT NULL CONSTRAINT fk_usuario_rol REFERENCES Rol(idRol),
    clave          VARCHAR(40)  NOT NULL,
    esActivo       BOOLEAN DEFAULT TRUE,                 -- T-SQL: BIT DEFAULT 1
    fechaRegistro  TIMESTAMP DEFAULT now()               -- T-SQL: DATETIME DEFAULT GETDATE()
);

-- Catálogo -------------------------------------------------------------
CREATE TABLE Categoria (
    idCategoria   INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_categoria PRIMARY KEY,
    nombre        VARCHAR(50) NOT NULL,
    esActivo      BOOLEAN DEFAULT TRUE,
    fechaRegistro TIMESTAMP DEFAULT now()
);

CREATE TABLE Producto (
    idProducto    INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_producto PRIMARY KEY,
    nombre        VARCHAR(100) NOT NULL,
    idCategoria   INT CONSTRAINT fk_producto_categoria REFERENCES Categoria(idCategoria),
    stock         INT NOT NULL CONSTRAINT ck_producto_stock  CHECK (stock >= 0),
    precio        NUMERIC(10,2) NOT NULL CONSTRAINT ck_producto_precio CHECK (precio > 0),
    esActivo      BOOLEAN DEFAULT TRUE,
    fechaRegistro TIMESTAMP DEFAULT now()
);

-- Ventas ---------------------------------------------------------------
CREATE TABLE NumeroDocumento (
    idNumeroDocumento INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_numerodocumento PRIMARY KEY,
    ultimo_Numero     INT NOT NULL,
    fechaRegistro     TIMESTAMP DEFAULT now()
);

CREATE TABLE Venta (
    idVenta         INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_venta PRIMARY KEY,
    numeroDocumento VARCHAR(40) NOT NULL CONSTRAINT uq_venta_numero UNIQUE,
    tipoPago        VARCHAR(50) NOT NULL,
    total           NUMERIC(10,2) NOT NULL DEFAULT 0,
    fechaRegistro   TIMESTAMP DEFAULT now()
);

CREATE TABLE DetalleVenta (
    idDetalleVenta INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_detalleventa PRIMARY KEY,
    idVenta        INT NOT NULL CONSTRAINT fk_detalle_venta    REFERENCES Venta(idVenta),
    idProducto     INT NOT NULL CONSTRAINT fk_detalle_producto REFERENCES Producto(idProducto),
    cantidad       INT NOT NULL CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0),
    precio         NUMERIC(10,2) NOT NULL,
    total          NUMERIC(10,2) NOT NULL
);
