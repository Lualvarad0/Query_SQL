/* =====================================================================
   PASO 2 · Hacer crecer la tabla Tarea con ALTER TABLE (SQL Server)

   Una lista de tareas de verdad necesita saber si la tarea está hecha,
   cuándo vence y qué tan importante es. En vez de borrar y crear la tabla
   de nuevo (y perder los datos), la modificamos.
   ===================================================================== */

USE DBTareas;
GO

-- 2.1 Agregar columnas.
--     Si la columna es NOT NULL y tiene DEFAULT, SQL Server llena las filas
--     que ya existen con ese valor por defecto.
ALTER TABLE Tarea ADD
    descripcion     VARCHAR(300) NULL,
    completada      BIT      NOT NULL CONSTRAINT DF_Tarea_completada    DEFAULT 0,
    prioridad       TINYINT  NOT NULL CONSTRAINT DF_Tarea_prioridad     DEFAULT 2,   -- 1 alta, 2 media, 3 baja
    fechaCreacion   DATETIME NOT NULL CONSTRAINT DF_Tarea_fechaCreacion DEFAULT GETDATE(),
    fechaLimite     DATE     NULL,                                                   -- puede no tener fecha
    fechaCompletada DATETIME NULL;
GO

-- 2.2 Reglas de negocio con CHECK
ALTER TABLE Tarea ADD CONSTRAINT CK_Tarea_prioridad CHECK (prioridad BETWEEN 1 AND 3);
ALTER TABLE Tarea ADD CONSTRAINT CK_Tarea_completada
    CHECK ((completada = 1 AND fechaCompletada IS NOT NULL) OR (completada = 0 AND fechaCompletada IS NULL));
GO

-- 2.3 Cambiar una columna existente: el nombre se queda corto (40) y no debería ser vacío.
ALTER TABLE Tarea ALTER COLUMN nombre VARCHAR(100) NOT NULL;
GO

-- 2.4 Las 2 tareas originales siguen ahí, con los valores por defecto.
SELECT idTarea, nombre, completada, prioridad, fechaLimite FROM Tarea;
GO

-- Para ver la estructura de la tabla:
EXEC sp_help 'Tarea';
GO
