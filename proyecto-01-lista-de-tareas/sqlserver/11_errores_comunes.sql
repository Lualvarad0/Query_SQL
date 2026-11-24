/* =====================================================================
   PASO 11 · Errores comunes: lo que NO se debe hacer (SQL Server)

   Parte A: cosas que la base de datos RECHAZA. Cada intento va dentro de
            TRY/CATCH, así el archivo sigue corriendo y ves el error.
            Lee el mensaje: aprender a leer errores es la mitad del trabajo.
   Parte B: cosas que la base ACEPTA pero dan un resultado equivocado.
            Son más peligrosas, porque no avisan.

   Cada caso dice: qué intentamos, qué error sale, por qué y cómo hacerlo bien.
   Corre después de los pasos 1 a 10. No cambia ningún dato.
   ===================================================================== */

USE DBTareas;
GO

/* =====================================================================
   PARTE A · La base de datos te protege
   ===================================================================== */

-- A1. Crear una tarea en una lista que no existe.
--     Error 547 (FOREIGN KEY). La FK solo deja usar listas que existen.
BEGIN TRY
    INSERT INTO Tarea (idLista, nombre) VALUES (99, 'Tarea huérfana');
END TRY
BEGIN CATCH SELECT 'A1' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A2. Borrar una lista que todavía tiene tareas.
--     Error 547 (FOREIGN KEY). Sin esta regla, las tareas quedarían apuntando a la nada.
--     Bien: primero mover o borrar sus tareas, o desactivar la lista en vez de borrarla.
BEGIN TRY
    DELETE FROM Lista WHERE idLista = 1;
END TRY
BEGIN CATCH SELECT 'A2' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A3. Prioridad fuera de rango.
--     Error 547 (CHECK CK_Tarea_prioridad). El nombre de la regla aparece en el mensaje:
--     por eso conviene ponerles nombre a las restricciones.
BEGIN TRY
    UPDATE Tarea SET prioridad = 5 WHERE idTarea = 1;
END TRY
BEGIN CATCH SELECT 'A3' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A4. Tarea sin nombre.
--     Error 515 (NOT NULL).
BEGIN TRY
    INSERT INTO Tarea (idLista, nombre) VALUES (1, NULL);
END TRY
BEGIN CATCH SELECT 'A4' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A5. Etiqueta repetida.
--     Error 2627 (UNIQUE). Sin UNIQUE tendríamos 'urgente' dos veces y los conteos saldrían partidos.
BEGIN TRY
    INSERT INTO Etiqueta (nombre) VALUES ('urgente');
END TRY
BEGIN CATCH SELECT 'A5' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A6. Poner dos veces la misma etiqueta a una tarea.
--     Error 2627 (PRIMARY KEY compuesta de TareaEtiqueta). La tarea 1 ya tiene la etiqueta 1.
BEGIN TRY
    INSERT INTO TareaEtiqueta (idTarea, idEtiqueta) VALUES (1, 1);
END TRY
BEGIN CATCH SELECT 'A6' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A7. Un nombre más largo de lo permitido (100 caracteres).
--     Error 2628 (se truncaría). SQL Server no corta el texto en silencio: se niega.
--     El mensaje sale con '******' porque Tarea tiene seguridad a nivel de fila (paso 10):
--     SQL Server oculta el valor para no mostrar datos. En otra tabla verías la tabla, la columna y el valor.
BEGIN TRY
    INSERT INTO Tarea (idLista, nombre) VALUES (1, REPLICATE('x', 150));
END TRY
BEGIN CATCH SELECT 'A7' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A8. Una fecha que no existe.
--     Error 241 (conversión). Por eso la fecha va en una columna DATE y no en VARCHAR.
--     Consejo: escribe fechas como 'AAAA-MM-DD'; '05/11/2026' se lee distinto según el idioma del servidor.
BEGIN TRY
    UPDATE Tarea SET fechaLimite = '2026-02-30' WHERE idTarea = 1;
END TRY
BEGIN CATCH SELECT 'A8' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A9. Colgar una subtarea de una tarea de OTRA lista.
--     Error 547 (FK compuesta FK_Tarea_Padre del paso 9). La tarea 22 está en la lista 4
--     y la tarea 1 en la lista 1: la base no lo permite.
BEGIN TRY
    UPDATE Tarea SET idTareaPadre = 22 WHERE idTarea = 1;
END TRY
BEGIN CATCH SELECT 'A9' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A10. Una tarea que es subtarea de sí misma.
--      Error 547 (CHECK CK_Tarea_noEsSuPropioPadre).
BEGIN TRY
    UPDATE Tarea SET idTareaPadre = 3 WHERE idTarea = 3;
END TRY
BEGIN CATCH SELECT 'A10' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A11. Escribir el id a mano en una columna IDENTITY.
--      Error 544. El id lo pone la base; si cada uno inventa ids, tarde o temprano chocan.
BEGIN TRY
    INSERT INTO Etiqueta (idEtiqueta, nombre) VALUES (100, 'inventada');
END TRY
BEGIN CATCH SELECT 'A11' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A12. Agregar una columna NOT NULL sin DEFAULT a una tabla que ya tiene filas.
--      Error 4901. ¿Qué valor tendrían las 25 tareas existentes? La base no adivina.
--      Bien: agrega la columna con DEFAULT, o el patrón del paso 3 (NULL, llenar, NOT NULL).
BEGIN TRY
    ALTER TABLE Tarea ADD responsable VARCHAR(100) NOT NULL;
END TRY
BEGIN CATCH SELECT 'A12' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A13. Borrar una tabla de la que dependen otras.
--      Error 3726. TareaEtiqueta tiene una FK hacia Etiqueta.
BEGIN TRY
    DROP TABLE Etiqueta;
END TRY
BEGIN CATCH SELECT 'A13' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

-- A14. Dividir entre cero: porcentaje de completadas de una lista vacía.
--      Error 8134. Ojo: alcanza a mostrar algunas filas ANTES de fallar.
--      Bien: NULLIF(divisor, 0) devuelve NULL en vez de fallar.
BEGIN TRY
    SELECT l.nombre, 100 * SUM(CASE WHEN t.completada = 1 THEN 1 ELSE 0 END) / COUNT(t.idTarea) AS porcentaje
    FROM Lista l LEFT JOIN Tarea t ON t.idLista = l.idLista
    GROUP BY l.idLista, l.nombre;
END TRY
BEGIN CATCH SELECT 'A14' AS caso, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;
GO

/* =====================================================================
   PARTE B · La base de datos NO te avisa
   ===================================================================== */

-- B1. Comparar con NULL usando "=".
--     NULL significa "no sé". "fechaLimite = NULL" nunca es verdadero, ni siquiera para las NULL.
SELECT 'B1 mal'  AS caso, COUNT(*) AS sin_fecha FROM Tarea WHERE fechaLimite = NULL;    -- 0  (¡mentira!)
SELECT 'B1 bien' AS caso, COUNT(*) AS sin_fecha FROM Tarea WHERE fechaLimite IS NULL;   -- 4
GO

-- B2. NOT IN con una subconsulta que trae NULL.
--     "Tareas que no son padre de nadie". idTareaPadre tiene NULLs, y "x NOT IN (..., NULL)"
--     nunca es verdadero. Resultado: 0 filas, sin ningún error.
SELECT 'B2 mal' AS caso, COUNT(*) AS tareas
FROM Tarea WHERE idTarea NOT IN (SELECT idTareaPadre FROM Tarea);                     -- 0
SELECT 'B2 bien' AS caso, COUNT(*) AS tareas
FROM Tarea t WHERE NOT EXISTS (SELECT 1 FROM Tarea h WHERE h.idTareaPadre = t.idTarea); -- 23
GO

-- B3. COUNT(*) en un LEFT JOIN.
--     La lista vacía "Viaje a Cuenca" aparece con 1 tarea: COUNT(*) cuenta la fila que
--     agrega el LEFT JOIN (llena de NULL). Bien: contar una columna de la tabla derecha.
SELECT 'B3 mal' AS caso, l.nombre, COUNT(*) AS tareas
FROM Lista l LEFT JOIN Tarea t ON t.idLista = l.idLista
WHERE l.idLista = 6 GROUP BY l.nombre;                                                 -- 1
SELECT 'B3 bien' AS caso, l.nombre, COUNT(t.idTarea) AS tareas
FROM Lista l LEFT JOIN Tarea t ON t.idLista = l.idLista
WHERE l.idLista = 6 GROUP BY l.nombre;                                                 -- 0
GO

-- B4. Un filtro en el WHERE que "apaga" el LEFT JOIN.
--     Queremos TODAS las listas con sus tareas urgentes (prioridad 1). Al poner la
--     condición en el WHERE, las listas sin tareas urgentes desaparecen.
--     Bien: la condición de la tabla derecha va en el ON.
SELECT 'B4 mal' AS caso, COUNT(DISTINCT l.idLista) AS listas
FROM Lista l LEFT JOIN Tarea t ON t.idLista = l.idLista
WHERE t.prioridad = 1;                                                                  -- 4
SELECT 'B4 bien' AS caso, COUNT(DISTINCT l.idLista) AS listas
FROM Lista l LEFT JOIN Tarea t ON t.idLista = l.idLista AND t.prioridad = 1;          -- 6
GO

-- B5. JOIN con la condición equivocada (o sin condición): producto cartesiano.
--     Se unió Usuario con Tarea sin pasar por Lista: cada tarea sale una vez POR CADA usuario.
SELECT 'B5 mal' AS caso, COUNT(*) AS filas
FROM Usuario u CROSS JOIN Tarea t;                                                      -- 100 (4 x 25)
SELECT 'B5 bien' AS caso, COUNT(*) AS filas
FROM Usuario u
INNER JOIN Lista l ON l.idUsuario = u.idUsuario
INNER JOIN Tarea t ON t.idLista = l.idLista;                                            -- 25
GO

-- B6. División entera.
--     12 completadas / 25 tareas = 0 en SQL Server, porque los dos son enteros.
--     Bien: multiplicar por 100.0 (decimal) ANTES de dividir.
SELECT 'B6' AS caso,
       SUM(CASE WHEN completada = 1 THEN 1 ELSE 0 END) / COUNT(*)           AS mal,     -- 0
       100.0 * SUM(CASE WHEN completada = 1 THEN 1 ELSE 0 END) / COUNT(*)   AS bien     -- 48.0
FROM Tarea;
GO

-- B7. UPDATE sin WHERE.
--     Querías completar UNA tarea y completaste las 25. La base lo hace sin preguntar.
--     Bien: 1) escribe primero el SELECT con el WHERE y revisa las filas,
--           2) trabaja dentro de una transacción y revisa @@ROWCOUNT antes del COMMIT.
BEGIN TRANSACTION;
    UPDATE Tarea SET completada = 1;          -- olvidamos: WHERE idTarea = 6
    SELECT 'B7' AS caso, @@ROWCOUNT AS filas_cambiadas;                                 -- 25
ROLLBACK TRANSACTION;                         -- uf: se deshace
GO

-- B8. DELETE en cascada "silencioso".
--     Borrar la etiqueta 'urgente' parece inofensivo, pero ON DELETE CASCADE quita
--     también sus 5 vínculos en TareaEtiqueta. No hay error ni aviso.
--     Bien: usar CASCADE solo donde de verdad quieres borrar los hijos, y revisar antes.
BEGIN TRANSACTION;
    SELECT COUNT(*) AS vinculos_antes FROM TareaEtiqueta;                                -- 35
    DELETE FROM Etiqueta WHERE nombre = 'urgente';
    SELECT COUNT(*) AS vinculos_despues FROM TareaEtiqueta;                              -- 30
ROLLBACK TRANSACTION;
GO

-- B9. Guardar la fecha como texto.
--     Ordenar fechas guardadas como VARCHAR 'DD/MM/AAAA' compara letra por letra:
--     el '05/12/2026' sale antes que el '20/11/2026'.
SELECT 'B9 mal' AS caso, f AS fecha_texto
FROM (VALUES ('20/11/2026'), ('05/12/2026'), ('01/01/2027')) v(f)
ORDER BY f;                                     -- 01/01/2027, 05/12/2026, 20/11/2026
GO
