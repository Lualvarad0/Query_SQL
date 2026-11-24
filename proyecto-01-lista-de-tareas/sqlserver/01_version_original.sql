/* =====================================================================
   PASO 1 · La versión original (SQL Server)

   Es el script original del proyecto (antes Query.txt), ordenado y con GO entre cada lote.
   Una sola tabla con dos columnas: así empiezan muchos proyectos.
   En los pasos siguientes la base CRECE con ALTER TABLE, como pasa en
   un proyecto real, sin borrar los datos que ya existen.
   ===================================================================== */

USE master;
GO

IF DB_ID('DBTareas') IS NOT NULL
BEGIN
    ALTER DATABASE DBTareas SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DBTareas;
END
GO

CREATE DATABASE DBTareas;
GO

USE DBTareas;
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
