/* =====================================================================
   PASO 6 · Las consultas de la app de tareas (SQL Server)

   Lo que hace cada botón de la app, en SQL. Los cambios van dentro de
   BEGIN TRANSACTION ... ROLLBACK para que puedas repetirlos.
   "Hoy" = 2026-11-23 (en la app sería CAST(GETDATE() AS DATE)).
   ===================================================================== */

USE DBAngular;
GO

-- 6.1 Pantalla de inicio: las listas de un usuario con cuántas tareas pendientes tiene cada una.
DECLARE @idUsuario INT = 1;

SELECT l.idLista, l.nombre, l.color,
       COUNT(t.idTarea) AS pendientes
FROM Lista l
LEFT JOIN Tarea t ON t.idLista = l.idLista AND t.completada = 0
WHERE l.idUsuario = @idUsuario
GROUP BY l.idLista, l.nombre, l.color
ORDER BY l.nombre;
GO

-- 6.2 Abrir una lista: sus tareas, pendientes primero, luego por prioridad y fecha límite.
--     Las tareas sin fecha límite van al final.
DECLARE @idLista INT = 2;

SELECT idTarea, nombre, prioridad, fechaLimite, completada
FROM Tarea
WHERE idLista = @idLista
ORDER BY completada,
         prioridad,
         CASE WHEN fechaLimite IS NULL THEN 1 ELSE 0 END,
         fechaLimite;
GO

-- 6.3 Lo mismo, pero mostrando las etiquetas de cada tarea en una columna.
DECLARE @idLista INT = 1;

SELECT t.idTarea, t.nombre,
       STRING_AGG(e.nombre, ', ') WITHIN GROUP (ORDER BY e.nombre) AS etiquetas
FROM Tarea t
LEFT JOIN TareaEtiqueta te ON te.idTarea = t.idTarea
LEFT JOIN Etiqueta e       ON e.idEtiqueta = te.idEtiqueta
WHERE t.idLista = @idLista
GROUP BY t.idTarea, t.nombre
ORDER BY t.idTarea;
GO

-- 6.4 Botón "Nueva tarea" (con dos etiquetas)
BEGIN TRANSACTION;
    INSERT INTO Tarea (idLista, nombre, prioridad, fechaLimite)
    VALUES (1, 'Estudiar funciones de ventana', 2, '2026-11-30');

    DECLARE @idTarea INT = SCOPE_IDENTITY();

    INSERT INTO TareaEtiqueta (idTarea, idEtiqueta)
    SELECT @idTarea, idEtiqueta FROM Etiqueta WHERE nombre IN ('estudio', 'lectura');

    SELECT @idTarea AS idNueva, COUNT(*) AS etiquetas FROM TareaEtiqueta WHERE idTarea = @idTarea;
ROLLBACK TRANSACTION;
GO

-- 6.5 Botón "Editar": cambiar nombre, prioridad y fecha.
BEGIN TRANSACTION;
    UPDATE Tarea
    SET nombre = 'Repasar TypeScript y RxJS', prioridad = 1, fechaLimite = '2026-11-26'
    WHERE idTarea = 6;
    SELECT idTarea, nombre, prioridad, fechaLimite FROM Tarea WHERE idTarea = 6;
ROLLBACK TRANSACTION;
GO

-- 6.6 Casilla "completada": marcar y desmarcar.
--     La regla CK_Tarea_completada obliga a llenar fechaCompletada (en el PASO 8 lo hace un trigger).
BEGIN TRANSACTION;
    UPDATE Tarea SET completada = 1, fechaCompletada = GETDATE() WHERE idTarea = 10;
    SELECT idTarea, completada, fechaCompletada FROM Tarea WHERE idTarea = 10;
    UPDATE Tarea SET completada = 0, fechaCompletada = NULL WHERE idTarea = 10;
ROLLBACK TRANSACTION;
GO

-- 6.7 Botón "Eliminar": gracias a ON DELETE CASCADE, sus etiquetas se van solas.
BEGIN TRANSACTION;
    DELETE FROM Tarea WHERE idTarea = 3;
    SELECT COUNT(*) AS etiquetas_que_quedan FROM TareaEtiqueta WHERE idTarea = 3;   -- 0
ROLLBACK TRANSACTION;
GO

-- 6.8 Buscador: tareas del usuario 1 que contengan un texto en el nombre o la descripción.
DECLARE @idUsuario INT = 1, @texto VARCHAR(50) = 'sql';

SELECT t.idTarea, t.nombre, l.nombre AS lista
FROM Tarea t
INNER JOIN Lista l ON l.idLista = t.idLista
WHERE l.idUsuario = @idUsuario
  AND (t.nombre LIKE '%' + @texto + '%' OR t.descripcion LIKE '%' + @texto + '%');
GO

-- 6.9 Filtros rápidos del usuario 1: vencidas, para hoy y próximos 7 días.
DECLARE @idUsuario INT = 1, @hoy DATE = '2026-11-23';

SELECT t.nombre, t.fechaLimite,
       CASE
           WHEN t.fechaLimite <  @hoy THEN 'Vencida'
           WHEN t.fechaLimite =  @hoy THEN 'Para hoy'
           ELSE 'Próximos 7 días'
       END AS estado,
       DATEDIFF(DAY, @hoy, t.fechaLimite) AS dias        -- negativo = días de retraso
FROM Tarea t
INNER JOIN Lista l ON l.idLista = t.idLista
WHERE l.idUsuario = @idUsuario
  AND t.completada = 0
  AND t.fechaLimite <= DATEADD(DAY, 7, @hoy)
ORDER BY t.fechaLimite;
GO

-- 6.10 Filtro por etiqueta: todas las tareas 'urgente' pendientes, de cualquier usuario.
SELECT u.nombre AS usuario, l.nombre AS lista, t.nombre AS tarea, t.fechaLimite
FROM Etiqueta e
INNER JOIN TareaEtiqueta te ON te.idEtiqueta = e.idEtiqueta
INNER JOIN Tarea t          ON t.idTarea     = te.idTarea
INNER JOIN Lista l          ON l.idLista     = t.idLista
INNER JOIN Usuario u        ON u.idUsuario   = l.idUsuario
WHERE e.nombre = 'urgente'
  AND t.completada = 0
ORDER BY t.fechaLimite;
GO
