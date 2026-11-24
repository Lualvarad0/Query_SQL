/* =====================================================================
   PASO 1 · La versión original (SQL Server)

   Es el mismo Query.txt del proyecto, ordenado y con GO entre cada lote.
   Una sola tabla con dos columnas: así empiezan muchos proyectos.
   En los pasos siguientes la base CRECE con ALTER TABLE, como pasa en
   un proyecto real, sin borrar los datos que ya existen.
   ===================================================================== */

USE master;
GO

IF DB_ID('DBAngular') IS NOT NULL
BEGIN
    ALTER DATABASE DBAngular SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DBAngular;
END
GO

CREATE DATABASE DBAngular;
GO

USE DBAngular;
GO

CREATE TABLE Tarea (
    idTarea INT PRIMARY KEY IDENTITY,   -- IDENTITY sin parámetros = IDENTITY(1,1)
    nombre  VARCHAR(40)
);
GO

INSERT INTO Tarea (nombre) VALUES
('Aprender Angular'),
('Aprender Blazor');
GO

SELECT * FROM Tarea;
GO
