/* =====================================================================
   PASO 3 · Usuarios y listas: de 1 tabla a 3 relacionadas (SQL Server)

   Cada usuario tiene varias listas ("Trabajo", "Casa"...) y cada lista
   tiene varias tareas:   Usuario 1──* Lista 1──* Tarea
   ===================================================================== */

USE DBAngular;
GO

CREATE TABLE Usuario (
    idUsuario     INT IDENTITY(1,1) CONSTRAINT PK_Usuario PRIMARY KEY,
    nombre        VARCHAR(100) NOT NULL,
    correo        VARCHAR(100) NOT NULL CONSTRAINT UQ_Usuario_correo UNIQUE,
    fechaRegistro DATETIME NOT NULL DEFAULT GETDATE()
);
GO

CREATE TABLE Lista (
    idLista   INT IDENTITY(1,1) CONSTRAINT PK_Lista PRIMARY KEY,
    nombre    VARCHAR(60) NOT NULL,
    color     CHAR(7) NULL,                         -- color hexadecimal para la app: '#3F51B5'
    idUsuario INT NOT NULL CONSTRAINT FK_Lista_Usuario REFERENCES Usuario(idUsuario)
);
GO

-- Conectar Tarea con Lista. Patrón seguro para una tabla que YA tiene datos:
--   1) agregar la columna permitiendo NULL
--   2) llenarla
--   3) recién ahí volverla NOT NULL y crear la llave foránea
ALTER TABLE Tarea ADD idLista INT NULL;      -- 1)
GO
-- 2) se llena en 05_datos.sql, cuando ya existan listas
