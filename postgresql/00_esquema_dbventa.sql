-- =====================================================================
-- 00_esquema_dbventa.sql
-- Esquema DBVENTA (proyecto-VENTASANGULAR) traducido de SQL Server a PostgreSQL.
--
-- Cómo correrlo (desde la terminal):
--   createdb dbventa
--   psql -d dbventa -f postgresql/00_esquema_dbventa.sql
--   psql -d dbventa -f postgresql/01_datos.sql
--
-- En SQL Server el original hacía:  CREATE DATABASE DBVENTA / USE DBVENTA / GO
-- PostgreSQL no tiene USE ni GO: te conectas a la base con  \c dbventa  (o -d dbventa).
-- Ver docs/postgresql_vs_sqlserver.md para todas las diferencias.
-- =====================================================================

-- Permite volver a correr el script desde cero.
DROP TABLE IF EXISTS DetalleVenta, Venta, NumeroDocumento, Producto, Categoria,
                     Usuario, MenuRol, Menu, Rol CASCADE;

CREATE TABLE Rol (
    idRol         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- T-SQL: int primary key identity(1,1)
    nombre        VARCHAR(50),
    fechaRegistro TIMESTAMP DEFAULT now()                          -- T-SQL: datetime default getdate()
);

CREATE TABLE Menu (
    idMenu INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(50),
    icono  VARCHAR(50),
    url    VARCHAR(50)
);

-- Tabla puente (muchos a muchos): un rol ve muchos menús y un menú lo ven muchos roles.
CREATE TABLE MenuRol (
    idMenuRol INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    idMenu    INT REFERENCES Menu(idMenu),
    idRol     INT REFERENCES Rol(idRol)
);

CREATE TABLE Usuario (
    idUsuario      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombreCompleto VARCHAR(100),
    correo         VARCHAR(40),
    idRol          INT REFERENCES Rol(idRol),
    clave          VARCHAR(40),
    esActivo       BOOLEAN DEFAULT TRUE,                           -- T-SQL: bit default 1
    fechaRegistro  TIMESTAMP DEFAULT now()
);

CREATE TABLE Categoria (
    idCategoria   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre        VARCHAR(50),
    esActivo      BOOLEAN DEFAULT TRUE,
    fechaRegistro TIMESTAMP DEFAULT now()
);

CREATE TABLE Producto (
    idProducto    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre        VARCHAR(100),
    idCategoria   INT REFERENCES Categoria(idCategoria),
    stock         INT,
    precio        NUMERIC(10,2),                                   -- T-SQL: decimal(10,2) (en PG también existe DECIMAL)
    esActivo      BOOLEAN DEFAULT TRUE,
    fechaRegistro TIMESTAMP DEFAULT now()
);

CREATE TABLE NumeroDocumento (
    idNumeroDocumento INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ultimo_Numero     INT NOT NULL,
    fechaRegistro     TIMESTAMP DEFAULT now()
);

CREATE TABLE Venta (
    idVenta         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numeroDocumento VARCHAR(40),
    tipoPago        VARCHAR(50),
    total           NUMERIC(10,2),
    fechaRegistro   TIMESTAMP DEFAULT now()
);

CREATE TABLE DetalleVenta (
    idDetalleVenta INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    idVenta        INT REFERENCES Venta(idVenta),
    idProducto     INT REFERENCES Producto(idProducto),
    cantidad       INT,
    precio         NUMERIC(10,2),
    total          NUMERIC(10,2)
);

-- El original terminaba con:
--   ALTER AUTHORIZATION ON DATABASE::DBVENTA TO sa;
-- Eso es solo para los diagramas de SQL Server Management Studio. En PostgreSQL
-- el equivalente sería  ALTER DATABASE dbventa OWNER TO postgres;  y no hace falta aquí.
