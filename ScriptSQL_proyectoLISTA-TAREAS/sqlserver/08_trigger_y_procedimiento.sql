/* =====================================================================
   PASO 8 · Trigger y procedimiento (SQL Server)

   8.1 TRIGGER: cuando una tarea se marca como completada, llenar
       fechaCompletada sola; si se desmarca, borrarla.
       ¿Por qué trigger y no la app? Porque la regla debe cumplirse siempre,
       venga el cambio de Angular, de Blazor o de alguien en SSMS.
   8.2 PROCEDIMIENTO: crear una tarea con sus etiquetas en una sola llamada,
       creando las etiquetas que no existan.
   ===================================================================== */

USE DBAngular;
GO

/* ---------------------------------------------------------------------
   8.1 Trigger
   SQL Server no tiene BEFORE: usamos AFTER UPDATE y corregimos la fila.
   La regla CK_Tarea_completada se revisa ANTES del trigger, así que la
   quitamos: ahora el trigger es quien mantiene la fecha coherente.
   --------------------------------------------------------------------- */
IF OBJECT_ID('CK_Tarea_completada') IS NOT NULL
    ALTER TABLE Tarea DROP CONSTRAINT CK_Tarea_completada;
GO

CREATE OR ALTER TRIGGER tr_Tarea_FechaCompletada
ON Tarea
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- "inserted" tiene las filas nuevas o modificadas (puede ser MÁS de una)
    IF NOT UPDATE(completada) RETURN;      -- solo actúa si el cambio tocó la columna completada

    UPDATE t
    SET fechaCompletada = CASE
                              WHEN i.completada = 1 THEN ISNULL(t.fechaCompletada, GETDATE())
                              ELSE NULL
                          END
    FROM Tarea t
    INNER JOIN inserted i ON i.idTarea = t.idTarea;
END;
GO

-- Prueba: marcar 2 tareas a la vez y luego desmarcar una
BEGIN TRANSACTION;
    UPDATE Tarea SET completada = 1 WHERE idTarea IN (6, 10);
    SELECT idTarea, completada, CASE WHEN fechaCompletada IS NULL THEN 'sin fecha' ELSE 'con fecha' END AS fecha
    FROM Tarea WHERE idTarea IN (6, 10);                       -- las 2 "con fecha"

    UPDATE Tarea SET completada = 0 WHERE idTarea = 6;
    SELECT idTarea, completada, fechaCompletada FROM Tarea WHERE idTarea = 6;   -- fecha NULL
ROLLBACK TRANSACTION;
GO

/* ---------------------------------------------------------------------
   8.2 Procedimiento sp_CrearTarea
   Las etiquetas llegan como texto separado por comas: 'estudio,sql,nueva'
   STRING_SPLIT (SQL Server 2016+) lo convierte en filas.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_CrearTarea
    @idLista     INT,
    @nombre      VARCHAR(100),
    @prioridad   TINYINT = 2,
    @fechaLimite DATE    = NULL,
    @etiquetas   VARCHAR(300) = NULL,
    @idTarea     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM Lista WHERE idLista = @idLista)
        THROW 50010, 'La lista no existe.', 1;

    BEGIN TRANSACTION;

        INSERT INTO Tarea (idLista, nombre, prioridad, fechaLimite)
        VALUES (@idLista, @nombre, @prioridad, @fechaLimite);
        SET @idTarea = SCOPE_IDENTITY();

        -- Lista limpia de etiquetas (sin espacios, sin vacías, sin repetidas)
        DECLARE @tags TABLE (nombre VARCHAR(30) PRIMARY KEY);
        INSERT INTO @tags (nombre)
        SELECT DISTINCT LOWER(LTRIM(RTRIM(value)))
        FROM STRING_SPLIT(ISNULL(@etiquetas, ''), ',')
        WHERE LTRIM(RTRIM(value)) <> '';

        -- Crear las que no existen
        INSERT INTO Etiqueta (nombre)
        SELECT g.nombre FROM @tags g
        WHERE NOT EXISTS (SELECT 1 FROM Etiqueta e WHERE e.nombre = g.nombre);

        -- Asignarlas
        INSERT INTO TareaEtiqueta (idTarea, idEtiqueta)
        SELECT @idTarea, e.idEtiqueta
        FROM Etiqueta e INNER JOIN @tags g ON g.nombre = e.nombre;

    COMMIT TRANSACTION;
END;
GO

BEGIN TRANSACTION;
    DECLARE @id INT;
    EXEC sp_CrearTarea @idLista = 1, @nombre = 'Estudiar triggers', @prioridad = 1,
                       @fechaLimite = '2026-11-29', @etiquetas = 'estudio, SQL ,urgente,', @idTarea = @id OUTPUT;

    SELECT t.idTarea, t.nombre, STRING_AGG(e.nombre, ', ') AS etiquetas
    FROM Tarea t
    INNER JOIN TareaEtiqueta te ON te.idTarea = t.idTarea
    INNER JOIN Etiqueta e       ON e.idEtiqueta = te.idEtiqueta
    WHERE t.idTarea = @id
    GROUP BY t.idTarea, t.nombre;            -- 3 etiquetas; 'sql' se creó nueva
ROLLBACK TRANSACTION;
GO
