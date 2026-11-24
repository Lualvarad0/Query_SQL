/* =====================================================================
   PASO 10 · Seguridad (SQL Server)

   La seguridad de una base de datos empieza al CREAR las tablas, no
   después. Este paso tiene 5 partes:
     10.1 Una tabla mal hecha: todo lo que acepta sin quejarse.
     10.2 Claves: guardar un hash con sal, nunca la clave, y bloquear
          la cuenta después de varios intentos fallidos.
     10.3 Mínimo privilegio: roles y usuarios que solo pueden lo justo.
     10.4 Seguridad a nivel de fila: cada usuario solo ve SUS tareas.
     10.5 Inyección SQL: por qué nunca se arma SQL pegando texto.

   Corre después del paso 9. Se puede volver a correr.
   ===================================================================== */

USE DBTareas;
GO

-- Limpieza para poder correr el archivo otra vez (el orden importa:
-- primero la política, luego la función, luego usuarios y roles).
IF EXISTS (SELECT 1 FROM sys.security_policies WHERE name = 'pol_Tarea') DROP SECURITY POLICY Seguridad.pol_Tarea;
IF OBJECT_ID('Seguridad.fn_TareaVisible') IS NOT NULL DROP FUNCTION Seguridad.fn_TareaVisible;
IF SCHEMA_ID('Seguridad') IS NOT NULL DROP SCHEMA Seguridad;
IF USER_ID('app_tareas') IS NOT NULL DROP USER app_tareas;
IF USER_ID('analista')   IS NOT NULL DROP USER analista;
IF DATABASE_PRINCIPAL_ID('rol_app')      IS NOT NULL DROP ROLE rol_app;
IF DATABASE_PRINCIPAL_ID('rol_reportes') IS NOT NULL DROP ROLE rol_reportes;
GO

/* ---------------------------------------------------------------------
   10.1 Una tabla mal hecha
   Así se ve una tabla creada "rápido": todo texto, todo opcional, sin
   llave primaria, sin reglas. Mira todo lo que acepta.
   --------------------------------------------------------------------- */
CREATE TABLE #TareaMalHecha (
    id          INT,              -- sin PRIMARY KEY: se puede repetir
    nombre      VARCHAR(MAX),     -- sin NOT NULL y sin límite de tamaño
    prioridad   VARCHAR(20),      -- texto: acepta 'altísima' o 'abc'
    completada  VARCHAR(10),      -- texto: acepta 'tal vez'
    fechaLimite VARCHAR(20),      -- texto: acepta '30/02/2026'
    usuario     VARCHAR(100)      -- el nombre copiado: si cambia, quedan datos viejos
);

INSERT INTO #TareaMalHecha VALUES
(1, 'Comprar pan',  'alta',     'no',      '2026-11-30', 'Ana Torres'),
(1, NULL,           'altísima', 'tal vez', '30/02/2026', 'ana torres'),  -- id repetido, sin nombre, fecha que no existe
(2, '',             '-5',       '1',       'mañana',     'Ana'),         -- tres formas de escribir a la misma persona
(3, 'Pagar luz',    NULL,       NULL,      NULL,         'Usuario que no existe');

SELECT * FROM #TareaMalHecha;   -- 4 filas aceptadas. Ninguna regla las detuvo.

-- ¿Cuántas tareas tiene Ana? Imposible saberlo bien: 'Ana Torres', 'ana torres', 'Ana'...
SELECT usuario, COUNT(*) AS tareas FROM #TareaMalHecha GROUP BY usuario;

DROP TABLE #TareaMalHecha;
GO
/*  Cómo lo resuelve la tabla Tarea de este proyecto:
      Problema                         Solución en el CREATE / ALTER TABLE
      id repetido                      PRIMARY KEY + IDENTITY
      nombre vacío o NULL              NOT NULL (y un tamaño máximo: VARCHAR(100))
      prioridad 'altísima' o -5        TINYINT + CHECK (prioridad BETWEEN 1 AND 3)
      completada 'tal vez'             BIT NOT NULL DEFAULT 0
      fecha '30/02/2026'               tipo DATE: la base rechaza fechas que no existen
      usuario escrito a mano           idLista INT + FOREIGN KEY: solo ids que existen
    En 11_errores_comunes.sql intentamos cada una de estas cosas en las
    tablas reales y vemos el error que devuelve SQL Server.                 */

/* ---------------------------------------------------------------------
   10.2 Claves con hash y sal, y bloqueo por intentos fallidos
   - HASH: una huella de la clave que no se puede revertir.
   - SAL: bytes al azar, distintos por usuario. Así dos usuarios con la
     misma clave tienen hashes distintos.
   - En una app real el hash se hace en la API con BCrypt o Argon2, que
     son lentos a propósito. SHA2_256 aquí es para entender la idea.
   --------------------------------------------------------------------- */
DELETE FROM UsuarioCredencial;

-- Clave de ejemplo para todos: 'Tareas2026!'
INSERT INTO UsuarioCredencial (idUsuario, sal, claveHash)
SELECT idUsuario, s.sal, HASHBYTES('SHA2_256', s.sal + CAST('Tareas2026!' AS VARBINARY(100)))
FROM Usuario
CROSS APPLY (SELECT CRYPT_GEN_RANDOM(16) AS sal) s;   -- CROSS APPLY: una sal nueva por fila
GO

-- Misma clave, hashes distintos gracias a la sal:
SELECT u.nombre, c.sal, c.claveHash
FROM Usuario u INNER JOIN UsuarioCredencial c ON c.idUsuario = u.idUsuario;
GO

CREATE OR ALTER PROCEDURE sp_Login
    @correo VARCHAR(100),
    @clave  VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id INT, @sal VARBINARY(16), @hash VARBINARY(32), @bloqueada DATETIME;
    DECLARE @ahora DATETIME = GETDATE();

    SELECT @id = u.idUsuario, @sal = c.sal, @hash = c.claveHash, @bloqueada = c.bloqueadaHasta
    FROM Usuario u INNER JOIN UsuarioCredencial c ON c.idUsuario = u.idUsuario
    WHERE u.correo = @correo;                 -- consulta con PARÁMETRO: no hay inyección posible

    -- Mismo mensaje si el correo no existe o si la clave está mal:
    -- así nadie puede averiguar qué correos están registrados.
    IF @id IS NULL
    BEGIN SELECT CAST(NULL AS INT) AS idUsuario, 'Correo o clave incorrectos' AS resultado; RETURN; END;

    IF @bloqueada > @ahora
    BEGIN SELECT CAST(NULL AS INT) AS idUsuario, 'Cuenta bloqueada. Intenta más tarde' AS resultado; RETURN; END;

    IF HASHBYTES('SHA2_256', @sal + CAST(@clave AS VARBINARY(100))) = @hash
    BEGIN
        UPDATE UsuarioCredencial SET intentosFallidos = 0, bloqueadaHasta = NULL WHERE idUsuario = @id;
        SELECT @id AS idUsuario, 'OK' AS resultado;
    END
    ELSE
    BEGIN
        -- Al tercer intento fallido, la cuenta se bloquea 15 minutos.
        UPDATE UsuarioCredencial
        SET intentosFallidos = intentosFallidos + 1,
            bloqueadaHasta   = CASE WHEN intentosFallidos + 1 >= 3 THEN DATEADD(MINUTE, 15, @ahora) END
        WHERE idUsuario = @id;
        SELECT CAST(NULL AS INT) AS idUsuario, 'Correo o clave incorrectos' AS resultado;
    END
END;
GO

BEGIN TRANSACTION;   -- las pruebas se deshacen al final
    EXEC sp_Login 'ana@example.com', 'Tareas2026!';   -- OK
    EXEC sp_Login 'ana@example.com', 'mala1';          -- incorrecta (1)
    EXEC sp_Login 'ana@example.com', 'mala2';          -- incorrecta (2)
    EXEC sp_Login 'ana@example.com', 'mala3';          -- incorrecta (3) -> se bloquea
    EXEC sp_Login 'ana@example.com', 'Tareas2026!';   -- bloqueada, aunque ahora la clave es correcta
    EXEC sp_Login 'nadie@example.com', 'x';            -- mismo mensaje que una clave mala
ROLLBACK TRANSACTION;
GO

/* ---------------------------------------------------------------------
   10.3 Mínimo privilegio: roles y usuarios
   La app NO debe conectarse como 'sa' o dueño de la base. Se crea un
   usuario para la app con SOLO los permisos que necesita.
     rol_app       -> la API: leer y escribir tareas, listas y etiquetas;
                      leer Usuario; NADA sobre UsuarioCredencial.
     rol_reportes  -> un analista: solo una vista de resumen.
   (WITHOUT LOGIN crea usuarios de prueba sin clave; en producción se
    crea un LOGIN con clave y luego el USER.)
   --------------------------------------------------------------------- */
CREATE ROLE rol_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON Lista           TO rol_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON Tarea           TO rol_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON TareaEtiqueta   TO rol_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ListaCompartida TO rol_app;
GRANT SELECT, INSERT                 ON Etiqueta        TO rol_app;
GRANT SELECT (idUsuario, nombre, correo) ON Usuario     TO rol_app;   -- solo esas columnas
GRANT EXECUTE ON sp_Login      TO rol_app;
GRANT EXECUTE ON sp_CrearTarea TO rol_app;
GO

CREATE OR ALTER VIEW vw_ResumenLista AS
SELECT l.idLista, l.nombre AS lista, u.nombre AS duenio,
       COUNT(t.idTarea) AS tareas,
       SUM(CASE WHEN t.completada = 1 THEN 1 ELSE 0 END) AS completadas
FROM Lista l
INNER JOIN Usuario u ON u.idUsuario = l.idUsuario
LEFT JOIN Tarea t    ON t.idLista   = l.idLista
GROUP BY l.idLista, l.nombre, u.nombre;
GO

CREATE ROLE rol_reportes;
GRANT SELECT ON vw_ResumenLista TO rol_reportes;    -- ve el resumen, no las tablas
GO

CREATE USER app_tareas WITHOUT LOGIN;
CREATE USER analista   WITHOUT LOGIN;
ALTER ROLE rol_app      ADD MEMBER app_tareas;
ALTER ROLE rol_reportes ADD MEMBER analista;
GO

-- Probar los permisos haciéndonos pasar por cada usuario (EXECUTE AS ... REVERT)
EXECUTE AS USER = 'app_tareas';
    SELECT COUNT(*) AS tareas_que_ve_la_app FROM Tarea;                 -- permitido

    BEGIN TRY
        SELECT * FROM UsuarioCredencial;                                -- NO permitido
    END TRY
    BEGIN CATCH
        SELECT '10.3 a' AS prueba, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje;   -- 229
    END CATCH;

    BEGIN TRY
        SELECT idUsuario, nombre, fechaRegistro FROM Usuario;           -- fechaRegistro no se dio
    END TRY
    BEGIN CATCH
        SELECT '10.3 b' AS prueba, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje;   -- 230
    END CATCH;

    BEGIN TRY
        EXEC('DROP TABLE Etiqueta');                                    -- la app no puede borrar tablas
    END TRY
    BEGIN CATCH
        SELECT '10.3 c' AS prueba, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje;   -- 3701
    END CATCH;

    -- Pero SÍ puede usar sp_Login, que lee UsuarioCredencial por dentro.
    -- Esto se llama "encadenamiento de propiedad": el procedimiento y la tabla
    -- tienen el mismo dueño (dbo), así que el permiso de EXECUTE alcanza.
    EXEC sp_Login 'luis@example.com', 'Tareas2026!';
REVERT;
GO

EXECUTE AS USER = 'analista';
    SELECT * FROM vw_ResumenLista;                                      -- permitido
    BEGIN TRY
        SELECT * FROM Tarea;                                            -- NO permitido
    END TRY
    BEGIN CATCH
        SELECT '10.3 d' AS prueba, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje;   -- 229
    END CATCH;
REVERT;
GO

/* ---------------------------------------------------------------------
   10.4 Seguridad a nivel de fila (Row-Level Security, SQL Server 2016+)
   Con permisos normales, app_tareas puede leer TODAS las tareas de TODOS
   los usuarios. Con una política de seguridad, la propia base filtra:
   cada usuario ve solo las tareas de sus listas y de las compartidas con él.

   La API, al recibir una petición, le dice a la base quién es el usuario:
       EXEC sp_set_session_context N'idUsuario', 1;
   --------------------------------------------------------------------- */
CREATE SCHEMA Seguridad;
GO

CREATE FUNCTION Seguridad.fn_TareaVisible (@idLista INT)
RETURNS TABLE
WITH SCHEMABINDING                 -- obligatorio: nadie puede cambiar las tablas que usa
AS
RETURN
    SELECT 1 AS visible
    WHERE IS_MEMBER('rol_app') = 0          -- quien no es de la app (dbo, admin) ve todo
       OR EXISTS (SELECT 1 FROM dbo.Lista l
                  WHERE l.idLista = @idLista
                    AND l.idUsuario = CAST(SESSION_CONTEXT(N'idUsuario') AS INT))
       OR EXISTS (SELECT 1 FROM dbo.ListaCompartida c
                  WHERE c.idLista = @idLista
                    AND c.idUsuario = CAST(SESSION_CONTEXT(N'idUsuario') AS INT));
GO

CREATE SECURITY POLICY Seguridad.pol_Tarea
    ADD FILTER PREDICATE Seguridad.fn_TareaVisible(idLista) ON dbo.Tarea,                -- filtra lo que se LEE
    ADD BLOCK  PREDICATE Seguridad.fn_TareaVisible(idLista) ON dbo.Tarea AFTER INSERT    -- bloquea lo que se ESCRIBE
    WITH (STATE = ON);
GO

EXECUTE AS USER = 'app_tareas';
    EXEC sp_set_session_context N'idUsuario', 1;            -- Ana
    SELECT COUNT(*) AS tareas_de_ana FROM Tarea;              -- 17: Estudios + Trabajo + Proyecto Angular (compartida)

    EXEC sp_set_session_context N'idUsuario', 4;            -- Pedro
    SELECT COUNT(*) AS tareas_de_pedro FROM Tarea;            -- 0: solo tiene "Viaje a Cuenca", que está vacía

    EXEC sp_set_session_context N'idUsuario', 1;            -- Ana intenta crear una tarea en "Casa" (lista de Luis)
    BEGIN TRY
        INSERT INTO Tarea (idLista, nombre) VALUES (3, 'Tarea colada en la lista de Luis');
    END TRY
    BEGIN CATCH
        SELECT '10.4' AS prueba, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje;     -- 33504
    END CATCH;

    EXEC sp_set_session_context N'idUsuario', NULL;
REVERT;
GO

SELECT COUNT(*) AS tareas_que_ve_dbo FROM Tarea;   -- 25: el administrador ve todo
GO

/* ---------------------------------------------------------------------
   10.5 Inyección SQL
   El buscador de la app recibe un texto del usuario. Si el SQL se arma
   PEGANDO ese texto, el usuario puede escribir SQL en vez de texto.
   --------------------------------------------------------------------- */

-- MAL: SQL dinámico concatenado
CREATE OR ALTER PROCEDURE sp_BuscarTareaInseguro @idUsuario INT, @texto VARCHAR(100)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) =
        N'SELECT t.idTarea, t.nombre, l.idUsuario
          FROM Tarea t INNER JOIN Lista l ON l.idLista = t.idLista
          WHERE l.idUsuario = ' + CAST(@idUsuario AS NVARCHAR(10)) + N'
            AND t.nombre LIKE ''%' + @texto + N'%''';
    PRINT @sql;           -- mira en "Mensajes" cómo queda el SQL armado
    EXEC (@sql);
END;
GO

-- BIEN: el texto viaja como PARÁMETRO; nunca se mezcla con el SQL
CREATE OR ALTER PROCEDURE sp_BuscarTarea @idUsuario INT, @texto VARCHAR(100)
AS
BEGIN
    SELECT t.idTarea, t.nombre, l.idUsuario
    FROM Tarea t INNER JOIN Lista l ON l.idLista = t.idLista
    WHERE l.idUsuario = @idUsuario
      AND t.nombre LIKE '%' + @texto + '%';
    -- Si de verdad necesitas SQL dinámico, usa sp_executesql con parámetros:
    --   EXEC sp_executesql N'... WHERE t.nombre LIKE @t', N'@t VARCHAR(102)', @t = ...
END;
GO

-- Uso normal: Ana (1) busca 'SQL' -> 1 fila
EXEC sp_BuscarTareaInseguro 1, 'SQL';

-- Ataque: el "texto" cierra la comilla y agrega OR 1=1. Ana ve las 25 tareas de TODOS.
EXEC sp_BuscarTareaInseguro 1, ''' OR 1=1 --';

-- El mismo ataque contra la versión segura: busca literalmente ese texto -> 0 filas
EXEC sp_BuscarTarea 1, ''' OR 1=1 --';
GO
