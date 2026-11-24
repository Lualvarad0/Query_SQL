/* =====================================================================
   PASO 7 · Seguridad (SQL Server)

     7.1 Lo que el script ORIGINAL dejaba pasar (y cómo lo arregla el paso 1).
     7.2 Claves: guardar un hash con sal, nunca la clave en texto plano.
     7.3 Mínimo privilegio: un cajero y un supervisor con SOLO lo que necesitan.
         GRANT, DENY, permisos por columna y por qué la app no usa 'sa'.
     7.4 Inyección SQL en el login: cómo se entra sin clave, y cómo evitarlo.

   Corre después de los pasos 1 a 6. Se puede volver a correr.
   ===================================================================== */

USE DBVENTA;
GO

-- Limpieza para poder correr el archivo otra vez (primero usuarios, luego roles)
IF USER_ID('cajero1')     IS NOT NULL DROP USER cajero1;
IF USER_ID('supervisor1') IS NOT NULL DROP USER supervisor1;
IF DATABASE_PRINCIPAL_ID('rol_cajero')     IS NOT NULL DROP ROLE rol_cajero;
IF DATABASE_PRINCIPAL_ID('rol_supervisor') IS NOT NULL DROP ROLE rol_supervisor;
GO

/* ---------------------------------------------------------------------
   7.1 Lo que dejaba pasar la tabla Usuario del script original
   El script original creaba Usuario así: todas las columnas opcionales,
   correo sin UNIQUE y la clave en texto plano. La recreamos en una tabla
   temporal para ver qué acepta.
   --------------------------------------------------------------------- */
CREATE TABLE #UsuarioOriginal (
    idUsuario      INT PRIMARY KEY IDENTITY(1,1),
    nombreCompleto VARCHAR(100),
    correo         VARCHAR(40),
    idRol          INT,                -- en el original tenía FK, pero aceptaba NULL
    clave          VARCHAR(40),
    esActivo       BIT DEFAULT 1
);

INSERT INTO #UsuarioOriginal (nombreCompleto, correo, idRol, clave) VALUES
('maria empleada', 'maria@example.com', 2,    '123'),
('maria copia',    'maria@example.com', 1,    '123'),   -- mismo correo: ¿con cuál entra al login?
(NULL,             NULL,                NULL, NULL);    -- un usuario vacío, sin rol y sin clave

SELECT * FROM #UsuarioOriginal;     -- todo aceptado. Y las claves se leen tal cual.
DROP TABLE #UsuarioOriginal;
GO
/*  Lo que corrigió el paso 1 (01_crear_base_y_tablas.sql):
      correo repetido          -> CONSTRAINT UQ_Usuario_correo UNIQUE
      usuario sin nombre/rol   -> NOT NULL en nombreCompleto, correo, idRol y clave
      stock o precio negativos -> CHECK (stock >= 0), CHECK (precio > 0)
      cantidad 0 en una venta  -> CHECK (cantidad > 0)
      menú repetido en un rol  -> UNIQUE (idMenu, idRol)
    Lo que sigue pendiente: la clave en texto plano (7.2).                    */

/* ---------------------------------------------------------------------
   7.2 Claves: hash con sal
   Si alguien roba una copia de la base, hoy ve todas las claves ('123').
   Lo correcto: guardar un HASH (huella que no se puede revertir) calculado
   con una SAL distinta por usuario. En la app real lo hace la API (BCrypt
   en .NET); aquí lo hacemos en SQL para entender la idea, y se deshace al
   final para no romper el login de la pantalla 3.1.
   --------------------------------------------------------------------- */
BEGIN TRANSACTION;

    ALTER TABLE Usuario ADD sal VARBINARY(16) NULL, claveHash VARBINARY(32) NULL;
    -- EXEC(...) porque SQL Server compila el lote antes de que existan las columnas nuevas
    EXEC('UPDATE Usuario SET sal = CRYPT_GEN_RANDOM(16);
          UPDATE Usuario SET claveHash = HASHBYTES(''SHA2_256'', sal + CAST(clave AS VARBINARY(40)));');

    -- Los 3 usuarios tienen la clave '123', pero sus hashes son distintos gracias a la sal:
    EXEC('SELECT correo, sal, claveHash FROM Usuario;');

    -- El login compara hashes; la clave nunca se guarda ni se compara directo
    EXEC('DECLARE @correo VARCHAR(40) = ''maria@example.com'', @clave VARCHAR(40) = ''123'';
          SELECT idUsuario, nombreCompleto,
                 CASE WHEN claveHash = HASHBYTES(''SHA2_256'', sal + CAST(@clave AS VARBINARY(40)))
                      THEN ''Clave correcta'' ELSE ''Clave incorrecta'' END AS resultado
          FROM Usuario WHERE correo = @correo;');

    -- El último paso de una migración real: borrar la columna con la clave en texto plano.
    ALTER TABLE Usuario DROP COLUMN clave;

ROLLBACK TRANSACTION;   -- la tabla vuelve a su forma original
GO

/* ---------------------------------------------------------------------
   7.3 Mínimo privilegio
   Si la API se conecta como 'sa' y alguien encuentra un fallo en ella,
   puede hacer CUALQUIER cosa: borrar ventas, cambiar precios, leer claves.
   Cada tipo de usuario recibe solo lo que necesita:

     rol_cajero      vende: ve productos y clientes, registra clientes y
                     ventas SOLO a través de sp_RegistrarVenta.
     rol_supervisor  consulta: historial, reportes y la lista de usuarios
                     SIN la columna clave.
   --------------------------------------------------------------------- */
CREATE ROLE rol_cajero;
GRANT SELECT ON Producto  TO rol_cajero;
GRANT SELECT ON Categoria TO rol_cajero;
GRANT SELECT, INSERT ON Cliente TO rol_cajero;
GRANT EXECUTE ON sp_RegistrarVenta TO rol_cajero;
GRANT EXECUTE ON sp_ObtenerMenus   TO rol_cajero;
GO

CREATE ROLE rol_supervisor;
GRANT SELECT ON vw_HistorialVenta    TO rol_supervisor;
GRANT SELECT ON vw_VentasPorProducto TO rol_supervisor;
GRANT EXECUTE ON sp_ReporteVentas    TO rol_supervisor;
GRANT EXECUTE ON sp_Dashboard        TO rol_supervisor;
GRANT SELECT ON Usuario              TO rol_supervisor;   -- toda la tabla...
DENY  SELECT ON Usuario (clave)      TO rol_supervisor;   -- ...menos la clave. DENY le gana a GRANT.
GO

CREATE USER cajero1     WITHOUT LOGIN;   -- en producción: CREATE LOGIN ... WITH PASSWORD, luego CREATE USER ... FOR LOGIN
CREATE USER supervisor1 WITHOUT LOGIN;
ALTER ROLE rol_cajero     ADD MEMBER cajero1;
ALTER ROLE rol_supervisor ADD MEMBER supervisor1;
GO

-- Lo que el cajero SÍ y NO puede hacer
EXECUTE AS USER = 'cajero1';
    SELECT TOP 3 nombre, precio, stock FROM Producto;                       -- sí

    BEGIN TRY
        UPDATE Producto SET precio = 1 WHERE idProducto = 1;                 -- ¿bajarse el precio de la laptop?
    END TRY
    BEGIN CATCH SELECT '7.3 a' AS prueba, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;   -- 229

    BEGIN TRY
        DELETE FROM Venta WHERE idVenta = 1;                                 -- ¿borrar una venta?
    END TRY
    BEGIN CATCH SELECT '7.3 b' AS prueba, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;   -- 229
    -- (el mensaje habla de SELECT porque, para aplicar el WHERE, primero hay que leer la tabla)

    BEGIN TRY
        SELECT correo, clave FROM Usuario;                                   -- ¿leer las claves?
    END TRY
    BEGIN CATCH SELECT '7.3 c' AS prueba, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;   -- 229

    -- Pero sí puede vender: el procedimiento actualiza Venta, DetalleVenta y el stock
    -- aunque el cajero no tenga permiso directo sobre esas tablas ("encadenamiento de
    -- propiedad": el procedimiento y las tablas tienen el mismo dueño, dbo).
    -- Así el cajero solo puede cambiar datos de la forma que el procedimiento permite.
    BEGIN TRANSACTION;
        DECLARE @num VARCHAR(40);
        EXEC sp_RegistrarVenta 'Efectivo', N'[{"idProducto":14,"cantidad":1}]', @num OUTPUT, @idUsuario = 2;
        SELECT @num AS venta_registrada_por_el_cajero;
    ROLLBACK TRANSACTION;
REVERT;
GO

-- Lo que el supervisor SÍ y NO puede hacer
EXECUTE AS USER = 'supervisor1';
    SELECT TOP 3 numeroDocumento, total FROM vw_HistorialVenta ORDER BY total DESC;   -- sí
    SELECT idUsuario, nombreCompleto, correo FROM Usuario;                              -- sí (sin la clave)

    BEGIN TRY
        SELECT * FROM Usuario;                                               -- el * incluye la clave
    END TRY
    BEGIN CATCH SELECT '7.3 d' AS prueba, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;   -- 230

    BEGIN TRY
        SELECT COUNT(*) FROM DetalleVenta;                                   -- tablas: no; vistas: sí
    END TRY
    BEGIN CATCH SELECT '7.3 e' AS prueba, ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje; END CATCH;   -- 229
REVERT;
GO

-- ¿Qué permisos tiene cada rol? (útil para revisar)
SELECT pr.name AS rol, pe.permission_name AS permiso, pe.state_desc AS estado,
       OBJECT_NAME(pe.major_id) AS objeto, COL_NAME(pe.major_id, pe.minor_id) AS columna
FROM sys.database_permissions pe
INNER JOIN sys.database_principals pr ON pr.principal_id = pe.grantee_principal_id
WHERE pr.name IN ('rol_cajero', 'rol_supervisor')
ORDER BY rol, objeto;
GO

/* ---------------------------------------------------------------------
   7.4 Inyección SQL en el login
   La pantalla de login manda correo y clave. Si el SQL se arma pegando
   esos textos, el "correo" puede traer SQL.
   --------------------------------------------------------------------- */

-- MAL: SQL dinámico concatenado
CREATE OR ALTER PROCEDURE sp_LoginInseguro @correo VARCHAR(100), @clave VARCHAR(100)
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) =
        N'SELECT TOP 1 u.idUsuario, u.nombreCompleto, r.nombre AS rol
          FROM Usuario u INNER JOIN Rol r ON r.idRol = u.idRol
          WHERE u.correo = ''' + @correo + N''' AND u.clave = ''' + @clave + N'''
          ORDER BY u.idUsuario';
    PRINT @sql;
    EXEC (@sql);
END;
GO

-- BIEN: consulta normal con parámetros (o sp_executesql con parámetros si tiene que ser dinámica)
CREATE OR ALTER PROCEDURE sp_Login @correo VARCHAR(100), @clave VARCHAR(100)
AS
BEGIN
    SELECT u.idUsuario, u.nombreCompleto, r.nombre AS rol
    FROM Usuario u INNER JOIN Rol r ON r.idRol = u.idRol
    WHERE u.correo = @correo AND u.clave = @clave;
END;
GO

-- Login normal: entra maria
EXEC sp_LoginInseguro 'maria@example.com', '123';

-- Ataque: en el correo escribe   ' OR 1=1 --   y cualquier cosa como clave.
-- El -- comenta el resto, la condición queda "OR 1=1" y entra como ADMINISTRADOR.
EXEC sp_LoginInseguro ''' OR 1=1 --', 'no-se-la-clave';

-- El mismo ataque contra la versión segura: busca un correo que se llama así -> 0 filas
EXEC sp_Login ''' OR 1=1 --', 'no-se-la-clave';
GO

DROP PROCEDURE sp_LoginInseguro;   -- un procedimiento así no se deja en la base
GO
