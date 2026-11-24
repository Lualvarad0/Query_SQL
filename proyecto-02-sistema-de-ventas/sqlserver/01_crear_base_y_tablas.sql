/* =====================================================================
   PASO 1 · Crear la base DBVENTA y sus tablas (SQL Server)

   Es el mismo modelo del script original del proyecto (antes en un .txt),
   con tres mejoras que no cambian las columnas que usa la app:
     - NOT NULL / UNIQUE / CHECK donde un dato vacío o repetido sería un error
     - nombres para las llaves (así los mensajes de error se entienden)
     - se puede volver a correr: borra la base si ya existe
   Ejecuta todo el archivo en SSMS (F5).
   ===================================================================== */

USE master;
GO

IF DB_ID('DBVENTA') IS NOT NULL
BEGIN
    ALTER DATABASE DBVENTA SET SINGLE_USER WITH ROLLBACK IMMEDIATE;  -- cierra conexiones abiertas
    DROP DATABASE DBVENTA;
END
GO

CREATE DATABASE DBVENTA;
GO

USE DBVENTA;
GO

/* ---------------------------------------------------------------------
   Seguridad: quién entra al sistema y qué menús ve
   --------------------------------------------------------------------- */

-- Rol: Administrador, Empleado, Supervisor
CREATE TABLE Rol (
    idRol         INT IDENTITY(1,1) CONSTRAINT PK_Rol PRIMARY KEY,
    nombre        VARCHAR(50) NOT NULL CONSTRAINT UQ_Rol_nombre UNIQUE,
    fechaRegistro DATETIME DEFAULT GETDATE()
);
GO

-- Menu: cada opción del menú lateral de la app (url = ruta de Angular)
CREATE TABLE Menu (
    idMenu INT IDENTITY(1,1) CONSTRAINT PK_Menu PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    icono  VARCHAR(50),          -- nombre del ícono de Angular Material
    url    VARCHAR(50)
);
GO

-- MenuRol: tabla puente. Relación muchos a muchos entre Menu y Rol.
CREATE TABLE MenuRol (
    idMenuRol INT IDENTITY(1,1) CONSTRAINT PK_MenuRol PRIMARY KEY,
    idMenu    INT NOT NULL CONSTRAINT FK_MenuRol_Menu REFERENCES Menu(idMenu),
    idRol     INT NOT NULL CONSTRAINT FK_MenuRol_Rol  REFERENCES Rol(idRol),
    CONSTRAINT UQ_MenuRol UNIQUE (idMenu, idRol)        -- el mismo menú no se asigna dos veces
);
GO

-- Usuario: cada usuario tiene UN rol
CREATE TABLE Usuario (
    idUsuario      INT IDENTITY(1,1) CONSTRAINT PK_Usuario PRIMARY KEY,
    nombreCompleto VARCHAR(100) NOT NULL,
    correo         VARCHAR(40)  NOT NULL CONSTRAINT UQ_Usuario_correo UNIQUE,  -- se usa para el login
    idRol          INT NOT NULL CONSTRAINT FK_Usuario_Rol REFERENCES Rol(idRol),
    clave          VARCHAR(40)  NOT NULL,   -- OJO: en texto plano. Ver README, sección "Seguridad"
    esActivo       BIT DEFAULT 1,
    fechaRegistro  DATETIME DEFAULT GETDATE()
);
GO

/* ---------------------------------------------------------------------
   Catálogo: qué vendemos
   --------------------------------------------------------------------- */

CREATE TABLE Categoria (
    idCategoria   INT IDENTITY(1,1) CONSTRAINT PK_Categoria PRIMARY KEY,
    nombre        VARCHAR(50) NOT NULL,
    esActivo      BIT DEFAULT 1,
    fechaRegistro DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE Producto (
    idProducto    INT IDENTITY(1,1) CONSTRAINT PK_Producto PRIMARY KEY,
    nombre        VARCHAR(100) NOT NULL,
    idCategoria   INT CONSTRAINT FK_Producto_Categoria REFERENCES Categoria(idCategoria),
    stock         INT NOT NULL CONSTRAINT CK_Producto_stock  CHECK (stock >= 0),
    precio        DECIMAL(10,2) NOT NULL CONSTRAINT CK_Producto_precio CHECK (precio > 0),
    esActivo      BIT DEFAULT 1,
    fechaRegistro DATETIME DEFAULT GETDATE()
);
GO

/* ---------------------------------------------------------------------
   Ventas
   --------------------------------------------------------------------- */

-- NumeroDocumento: una sola fila con el último número de venta usado (00001, 00002, ...)
CREATE TABLE NumeroDocumento (
    idNumeroDocumento INT IDENTITY(1,1) CONSTRAINT PK_NumeroDocumento PRIMARY KEY,
    ultimo_Numero     INT NOT NULL,
    fechaRegistro     DATETIME DEFAULT GETDATE()
);
GO

-- Venta: la cabecera (una fila por venta)
CREATE TABLE Venta (
    idVenta         INT IDENTITY(1,1) CONSTRAINT PK_Venta PRIMARY KEY,
    numeroDocumento VARCHAR(40) NOT NULL CONSTRAINT UQ_Venta_numero UNIQUE,
    tipoPago        VARCHAR(50) NOT NULL,
    total           DECIMAL(10,2) NOT NULL DEFAULT 0,
    fechaRegistro   DATETIME DEFAULT GETDATE()
);
GO

-- DetalleVenta: las líneas de cada venta (qué producto, cuántos, a qué precio)
CREATE TABLE DetalleVenta (
    idDetalleVenta INT IDENTITY(1,1) CONSTRAINT PK_DetalleVenta PRIMARY KEY,
    idVenta        INT NOT NULL CONSTRAINT FK_Detalle_Venta    REFERENCES Venta(idVenta),
    idProducto     INT NOT NULL CONSTRAINT FK_Detalle_Producto REFERENCES Producto(idProducto),
    cantidad       INT NOT NULL CONSTRAINT CK_Detalle_cantidad CHECK (cantidad > 0),
    precio         DECIMAL(10,2) NOT NULL,   -- se copia del producto: si mañana cambia, la venta no cambia
    total          DECIMAL(10,2) NOT NULL
);
GO

-- Para poder crear diagramas en SSMS (solo hace falta en algunos equipos)
ALTER AUTHORIZATION ON DATABASE::DBVENTA TO sa;
GO
