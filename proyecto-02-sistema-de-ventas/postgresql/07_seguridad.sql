-- =====================================================================
-- PASO 7 · Seguridad (PostgreSQL)
-- Equivalente de sqlserver/07_seguridad.sql (allí está la explicación larga).
--   7.1 Lo que el script original dejaba pasar.
--   7.2 Claves con bcrypt (pgcrypto).
--   7.3 Mínimo privilegio: cajero y supervisor.
--   7.4 Inyección SQL en el login.
-- Corre después de los pasos 1 a 6. Se puede volver a correr.
-- Los roles de PostgreSQL son de TODO el servidor: llevan el prefijo ventas_.
-- =====================================================================

-- Limpieza
DO $$
DECLARE r TEXT;
BEGIN
    FOREACH r IN ARRAY ARRAY['ventas_cajero1', 'ventas_supervisor1', 'ventas_rol_cajero', 'ventas_rol_supervisor'] LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('DROP OWNED BY %I', r);
            EXECUTE format('DROP ROLE %I', r);
        END IF;
    END LOOP;
END $$;

-- ---------------------------------------------------------------------
-- 7.1 La tabla Usuario como la creaba el script original
-- ---------------------------------------------------------------------
CREATE TEMP TABLE usuario_original (
    idUsuario      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombreCompleto VARCHAR(100),
    correo         VARCHAR(40),
    idRol          INT,
    clave          VARCHAR(40),
    esActivo       BOOLEAN DEFAULT TRUE
);

INSERT INTO usuario_original (nombreCompleto, correo, idRol, clave) VALUES
('maria empleada', 'maria@example.com', 2,    '123'),
('maria copia',    'maria@example.com', 1,    '123'),   -- mismo correo
(NULL,             NULL,                NULL, NULL);    -- usuario vacío

SELECT * FROM usuario_original;      -- todo aceptado, y las claves se leen tal cual
DROP TABLE usuario_original;

-- ---------------------------------------------------------------------
-- 7.2 Claves con bcrypt (la sal va dentro del hash). Se deshace al final.
-- ---------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;

BEGIN;
    ALTER TABLE Usuario ADD COLUMN claveHash TEXT;
    UPDATE Usuario SET claveHash = crypt(clave, gen_salt('bf'));   -- T-SQL: HASHBYTES('SHA2_256', sal + clave)

    SELECT correo, claveHash FROM Usuario;                          -- misma clave '123', hashes distintos

    SELECT idUsuario, nombreCompleto,
           CASE WHEN claveHash = crypt('123', claveHash) THEN 'Clave correcta' ELSE 'Clave incorrecta' END AS resultado
    FROM Usuario WHERE correo = 'maria@example.com';

    ALTER TABLE Usuario DROP COLUMN clave;                          -- el último paso de una migración real
ROLLBACK;
-- bcrypt es mejor que SHA-256 para claves porque es lento a propósito (frena a quien intenta adivinar).

-- ---------------------------------------------------------------------
-- 7.3 Mínimo privilegio
-- ---------------------------------------------------------------------
CREATE ROLE ventas_rol_cajero NOLOGIN;
GRANT SELECT ON Producto, Categoria TO ventas_rol_cajero;
GRANT SELECT, INSERT ON Cliente TO ventas_rol_cajero;

-- En PostgreSQL un procedimiento corre con los permisos de QUIEN LO LLAMA.
-- Para que el cajero venda sin tener permiso directo sobre Venta, DetalleVenta y el
-- stock, el procedimiento corre como su dueño (SECURITY DEFINER).
-- (En SQL Server esto pasa solo, por el "encadenamiento de propiedad".)
ALTER PROCEDURE sp_registrar_venta(VARCHAR, JSONB, INT, INT, VARCHAR)
    SECURITY DEFINER
    SET search_path = public, pg_temp;        -- nadie puede colar una tabla falsa con el mismo nombre

-- En PostgreSQL, TODOS (PUBLIC) pueden ejecutar funciones y procedimientos nuevos.
REVOKE EXECUTE ON PROCEDURE sp_registrar_venta(VARCHAR, JSONB, INT, INT, VARCHAR) FROM PUBLIC;
GRANT  EXECUTE ON PROCEDURE sp_registrar_venta(VARCHAR, JSONB, INT, INT, VARCHAR) TO ventas_rol_cajero;
GRANT  EXECUTE ON FUNCTION  fn_obtener_menus(INT) TO ventas_rol_cajero;

CREATE ROLE ventas_rol_supervisor NOLOGIN;
GRANT SELECT ON vw_historial_venta, vw_ventas_por_producto TO ventas_rol_supervisor;
GRANT EXECUTE ON FUNCTION fn_reporte_ventas(DATE, DATE), fn_dashboard_ventas_por_dia(DATE) TO ventas_rol_supervisor;
-- PostgreSQL no tiene DENY: en vez de "toda la tabla menos la clave", se dan las columnas permitidas.
GRANT SELECT (idUsuario, nombreCompleto, correo, idRol, esActivo, idJefe) ON Usuario TO ventas_rol_supervisor;

CREATE ROLE ventas_cajero1     NOLOGIN IN ROLE ventas_rol_cajero;       -- producción: LOGIN PASSWORD '...'
CREATE ROLE ventas_supervisor1 NOLOGIN IN ROLE ventas_rol_supervisor;

-- El cajero
SET ROLE ventas_cajero1;
SELECT nombre, precio, stock FROM Producto ORDER BY idProducto LIMIT 3;            -- sí

DO $$ BEGIN
    UPDATE Producto SET precio = 1 WHERE idProducto = 1;                         -- ¿bajarse el precio?
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE '7.3 a -> [%] %', SQLSTATE, SQLERRM;
END $$;

DO $$ BEGIN
    DELETE FROM Venta WHERE idVenta = 1;                                         -- ¿borrar una venta?
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE '7.3 b -> [%] %', SQLSTATE, SQLERRM;
END $$;

DO $$ BEGIN
    PERFORM correo, clave FROM Usuario;                                          -- ¿leer las claves?
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE '7.3 c -> [%] %', SQLSTATE, SQLERRM;
END $$;

BEGIN;                                                                           -- pero sí puede vender
    CALL sp_registrar_venta('Efectivo', '[{"idProducto":14,"cantidad":1}]', 2);
ROLLBACK;
RESET ROLE;

-- El supervisor
SET ROLE ventas_supervisor1;
SELECT numeroDocumento, total FROM vw_historial_venta ORDER BY total DESC LIMIT 3;  -- sí
SELECT idUsuario, nombreCompleto, correo FROM Usuario;                               -- sí, sin la clave

DO $$ BEGIN
    PERFORM * FROM Usuario;                                                      -- el * incluye la clave
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE '7.3 d -> [%] %', SQLSTATE, SQLERRM;
END $$;

DO $$ BEGIN
    PERFORM COUNT(*) FROM DetalleVenta;                                          -- tablas no, vistas sí
EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE '7.3 e -> [%] %', SQLSTATE, SQLERRM;
END $$;
RESET ROLE;

-- Revisar qué permisos tiene cada rol sobre las tablas
SELECT grantee AS rol, table_name AS objeto, privilege_type AS permiso
FROM information_schema.role_table_grants
WHERE grantee IN ('ventas_rol_cajero', 'ventas_rol_supervisor')
ORDER BY rol, objeto, permiso;

-- ---------------------------------------------------------------------
-- 7.4 Inyección SQL en el login
-- ---------------------------------------------------------------------
-- MAL: SQL armado pegando textos
CREATE OR REPLACE FUNCTION fn_login_inseguro(p_correo TEXT, p_clave TEXT)
RETURNS TABLE (id_usuario INT, nombre VARCHAR, rol VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE v_sql TEXT;
BEGIN
    v_sql := 'SELECT u.idUsuario, u.nombreCompleto, r.nombre
              FROM Usuario u JOIN Rol r ON r.idRol = u.idRol
              WHERE u.correo = ''' || p_correo || ''' AND u.clave = ''' || p_clave || '''
              ORDER BY u.idUsuario LIMIT 1';
    RAISE NOTICE '%', v_sql;
    RETURN QUERY EXECUTE v_sql;
END;
$$;

-- BIEN: parámetros (en SQL dinámico: EXECUTE ... USING p_correo, p_clave)
CREATE OR REPLACE FUNCTION fn_login(p_correo TEXT, p_clave TEXT)
RETURNS TABLE (id_usuario INT, nombre VARCHAR, rol VARCHAR)
LANGUAGE sql
AS $$
    SELECT u.idUsuario, u.nombreCompleto, r.nombre
    FROM Usuario u JOIN Rol r ON r.idRol = u.idRol
    WHERE u.correo = p_correo AND u.clave = p_clave;
$$;

SELECT * FROM fn_login_inseguro('maria@example.com', '123');                 -- login normal
SELECT * FROM fn_login_inseguro($$' OR 1=1 --$$, 'no-se-la-clave');         -- ¡entra como Administrador!
SELECT * FROM fn_login($$' OR 1=1 --$$, 'no-se-la-clave');                  -- versión segura: 0 filas

DROP FUNCTION fn_login_inseguro(TEXT, TEXT);   -- una función así no se deja en la base
