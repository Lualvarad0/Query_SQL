/* =====================================================================
   PASO 4 · Etiquetas: una relación muchos a muchos (SQL Server)

   Una tarea puede tener varias etiquetas ("urgente", "trabajo") y una
   etiqueta está en muchas tareas. Eso necesita una TABLA PUENTE:
       Tarea 1──* TareaEtiqueta *──1 Etiqueta
   (Es el mismo patrón que MenuRol en el proyecto de ventas.)
   ===================================================================== */

USE DBTareas;
GO

CREATE TABLE Etiqueta (
    idEtiqueta INT IDENTITY(1,1) CONSTRAINT PK_Etiqueta PRIMARY KEY,
    nombre     VARCHAR(30) NOT NULL CONSTRAINT UQ_Etiqueta_nombre UNIQUE
);
GO

CREATE TABLE TareaEtiqueta (
    idTarea    INT NOT NULL CONSTRAINT FK_TE_Tarea    REFERENCES Tarea(idTarea)       ON DELETE CASCADE,
    idEtiqueta INT NOT NULL CONSTRAINT FK_TE_Etiqueta REFERENCES Etiqueta(idEtiqueta) ON DELETE CASCADE,
    CONSTRAINT PK_TareaEtiqueta PRIMARY KEY (idTarea, idEtiqueta)   -- llave compuesta: no repite pares
);
GO
-- ON DELETE CASCADE: si borras una tarea, sus filas en TareaEtiqueta se borran solas.
