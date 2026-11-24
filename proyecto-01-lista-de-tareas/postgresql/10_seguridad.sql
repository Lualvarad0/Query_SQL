-- =====================================================================
-- PASO 10 · Seguridad (PostgreSQL)
-- Equivalente de sqlserver/10_seguridad.sql (allí está la explicación larga).
--   10.1 Una tabla mal hecha: todo lo que acepta.
--   10.2 Claves con bcrypt (pgcrypto) y bloqueo por intentos fallidos.
--   10.3 Mínimo privilegio: roles y GRANT.
--   10.4 Seguridad a nivel de fila (Row-Level Security).
--   10.5 Inyección SQL.
-- Corre después del paso 9. Se puede volver a correr.
--
-- OJO: en PostgreSQL los roles son de TODO el servidor, no de una base.
-- Por eso llevan el sufijo _tareas, para no chocar con otros proyectos.
-- =====================================================================

-- Limpieza para poder correr el archivo otra vez
DROP POLICY IF EXISTS pol_tarea_visible ON Tarea;
ALTER TABLE Tarea DISABLE ROW LEVEL SECURITY;
DO $$
DECLARE r TEXT;
BEGIN
    FOREACH r IN ARRAY ARRAY['app_tareas', 'analista_tareas', 'rol_app_tareas', 'rol_reportes_tareas'] LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('DROP OWNED BY %I', r);    -- quita sus permisos en esta base
            EXECUTE format('DROP ROLE %I', r);
        END IF;
    END LOOP;
END $$;

-- ---------------------------------------------------------------------
-- 10.1 Una tabla mal hecha: todo texto, todo opcional, sin llave
-- ---------------------------------------------------------------------
CREATE TEMP TABLE tarea_mal_hecha (
    id          INT,
    nombre      TEXT,
    prioridad   TEXT,
    completada  TEXT,
    fechaLimite TEXT,
    usuario     TEXT
);

INSERT INTO tarea_mal_hecha VALUES
(1, 'Comprar pan',  'alta',     'no',      '2026-11-30', 'Ana Torres'),
(1, NULL,           'altísima', 'tal vez', '30/02/2026', 'ana torres'),
(2, '',             '-5',       '1',       'mañana',     'Ana'),
(3, 'Pagar luz',    NULL,       NULL,      NULL,         'Usuario que no existe');

SELECT * FROM tarea_mal_hecha;                                         -- 4 filas aceptadas
SELECT usuario, COUNT(*) AS tareas FROM tarea_mal_hecha GROUP BY usuario;
-- PostgreSQL distingue mayúsculas: salen 4 grupos. SQL Server (con su collation por defecto,
-- que no distingue mayúsculas) junta 'Ana Torres' y 'ana torres'. Ninguno es "correcto": el dato está mal.
DROP TABLE tarea_mal_hecha;

-- ---------------------------------------------------------------------
-- 10.2 Claves con bcrypt y bloqueo por intentos fallidos
-- bcrypt guarda la sal DENTRO del hash y es lento a propósito: es lo que
-- usaría la API. (T-SQL no tiene bcrypt: allá usamos SHA2_256 + sal.)
-- ---------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DELETE FROM UsuarioCredencial;
INSERT INTO UsuarioCredencial (idUsuario, claveHash)
SELECT idUsuario, crypt('Tareas2026!', gen_salt('bf'))       -- clave de ejemplo para todos
FROM Usuario;

-- Misma clave, hashes distintos (cada uno con su sal):
SELECT u.nombre, c.claveHash
FROM Usuario u JOIN UsuarioCredencial c ON c.idUsuario = u.idUsuario;

-- SECURITY DEFINER: la función corre con los permisos de su DUEÑO, no de quien la llama.
-- Así la app puede hacer login sin tener permiso sobre UsuarioCredencial.
-- (Es lo que en SQL Server hace solo el "encadenamiento de propiedad".)
-- SET search_path evita que alguien "cuele" una tabla o función falsa con el mismo nombre.
CREATE OR REPLACE FUNCTION fn_login(p_correo VARCHAR, p_clave VARCHAR)
RETURNS TABLE (id_usuario INT, resultado TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_id INT; v_hash TEXT; v_bloqueada TIMESTAMP;
BEGIN
    SELECT u.idUsuario, c.claveHash, c.bloqueadaHasta
    INTO v_id, v_hash, v_bloqueada
    FROM Usuario u JOIN UsuarioCredencial c ON c.idUsuario = u.idUsuario
    WHERE u.correo = p_correo;

    IF v_id IS NULL THEN
        RETURN QUERY SELECT NULL::INT, 'Correo o clave incorrectos'; RETURN;
    END IF;

    IF v_bloqueada > now() THEN
        RETURN QUERY SELECT NULL::INT, 'Cuenta bloqueada. Intenta más tarde'; RETURN;
    END IF;

    IF crypt(p_clave, v_hash) = v_hash THEN           -- se compara el hash, nunca la clave
        UPDATE UsuarioCredencial SET intentosFallidos = 0, bloqueadaHasta = NULL WHERE idUsuario = v_id;
        RETURN QUERY SELECT v_id, 'OK';
    ELSE
        UPDATE UsuarioCredencial
        SET intentosFallidos = intentosFallidos + 1,
            bloqueadaHasta   = CASE WHEN intentosFallidos + 1 >= 3 THEN now() + INTERVAL '15 minutes' END
        WHERE idUsuario = v_id;
        RETURN QUERY SELECT NULL::INT, 'Correo o clave incorrectos';
    END IF;
END;
$$;

BEGIN;
    SELECT * FROM fn_login('ana@example.com', 'Tareas2026!');   -- OK
    SELECT * FROM fn_login('ana@example.com', 'mala1');
    SELECT * FROM fn_login('ana@example.com', 'mala2');
    SELECT * FROM fn_login('ana@example.com', 'mala3');         -- se bloquea
    SELECT * FROM fn_login('ana@example.com', 'Tareas2026!');   -- bloqueada
    SELECT * FROM fn_login('nadie@example.com', 'x');           -- mismo mensaje
ROLLBACK;

-- ---------------------------------------------------------------------
-- 10.3 Mínimo privilegio
-- En PostgreSQL un "usuario" es un rol con LOGIN. Para probar sin clave
-- usamos NOLOGIN y SET ROLE. En producción:
--     CREATE ROLE app_tareas LOGIN PASSWORD '...' IN ROLE rol_app_tareas;
-- ---------------------------------------------------------------------
CREATE ROLE rol_app_tareas NOLOGIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON Lista, Tarea, TareaEtiqueta, ListaCompartida TO rol_app_tareas;
GRANT SELECT, INSERT ON Etiqueta TO rol_app_tareas;
GRANT SELECT (idUsuario, nombre, correo) ON Usuario TO rol_app_tareas;   -- solo esas columnas

-- Diferencia importante con SQL Server: en PostgreSQL TODO el mundo (PUBLIC)
-- puede ejecutar una función nueva. Hay que quitarlo y dar el permiso a quien toca.
REVOKE EXECUTE ON FUNCTION fn_login(VARCHAR, VARCHAR) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION fn_crear_tarea(INT, VARCHAR, SMALLINT, DATE, TEXT) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION fn_login(VARCHAR, VARCHAR) TO rol_app_tareas;
GRANT  EXECUTE ON FUNCTION fn_crear_tarea(INT, VARCHAR, SMALLINT, DATE, TEXT) TO rol_app_tareas;

CREATE OR REPLACE VIEW vw_resumen_lista AS
SELECT l.idLista, l.nombre AS lista, u.nombre AS duenio,
       COUNT(t.idTarea) AS tareas,
       COUNT(*) FILTER (WHERE t.completada) AS completadas
FROM Lista l
JOIN Usuario u    ON u.idUsuario = l.idUsuario
LEFT JOIN Tarea t ON t.idLista   = l.idLista
GROUP BY l.idLista, u.nombre;

CREATE ROLE rol_reportes_tareas NOLOGIN;
GRANT SELECT ON vw_resumen_lista TO rol_reportes_tareas;

CREATE ROLE app_tareas      NOLOGIN IN ROLE rol_app_tareas;
CREATE ROLE analista_tareas NOLOGIN IN ROLE rol_reportes_tareas;

-- Probar con SET ROLE ... RESET ROLE (T-SQL: EXECUTE AS USER ... REVERT)
SET ROLE app_tareas;
SELECT COUNT(*) AS tareas_que_ve_la_app FROM Tarea;                -- permitido: 25

DO $$ BEGIN
    PERFORM * FROM UsuarioCredencial;                              -- NO permitido
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE '10.3 a -> [%] %', SQLSTATE, SQLERRM;             -- 42501
END $$;

DO $$ BEGIN
    PERFORM idUsuario, nombre, fechaRegistro FROM Usuario;         -- fechaRegistro no se dio
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE '10.3 b -> [%] %', SQLSTATE, SQLERRM;
END $$;

DO $$ BEGIN
    DROP TABLE Etiqueta;                                           -- solo el dueño puede borrarla
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE '10.3 c -> [%] %', SQLSTATE, SQLERRM;
END $$;

SELECT * FROM fn_login('luis@example.com', 'Tareas2026!');        -- sí puede: SECURITY DEFINER
RESET ROLE;

SET ROLE analista_tareas;
SELECT * FROM vw_resumen_lista ORDER BY idLista;                   -- permitido
DO $$ BEGIN
    PERFORM * FROM Tarea;                                          -- NO permitido
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE '10.3 d -> [%] %', SQLSTATE, SQLERRM;
END $$;
RESET ROLE;

-- ---------------------------------------------------------------------
-- 10.4 Seguridad a nivel de fila (RLS)
-- La API le dice a la base quién es el usuario de la petición:
--     SET app.id_usuario = '1';         (T-SQL: sp_set_session_context)
-- El dueño de la tabla y los superusuarios no pasan por la política
-- (salvo que se use ALTER TABLE ... FORCE ROW LEVEL SECURITY).
-- Un rol que no está en ninguna política no ve NINGUNA fila: se niega por defecto.
-- ---------------------------------------------------------------------
ALTER TABLE Tarea ENABLE ROW LEVEL SECURITY;

CREATE POLICY pol_tarea_visible ON Tarea
    FOR ALL                                   -- SELECT, INSERT, UPDATE y DELETE
    TO rol_app_tareas
    USING (                                   -- qué filas puede VER
        EXISTS (SELECT 1 FROM Lista l
                WHERE l.idLista = Tarea.idLista
                  AND l.idUsuario = NULLIF(current_setting('app.id_usuario', true), '')::INT)
     OR EXISTS (SELECT 1 FROM ListaCompartida c
                WHERE c.idLista = Tarea.idLista
                  AND c.idUsuario = NULLIF(current_setting('app.id_usuario', true), '')::INT)
    )
    WITH CHECK (                              -- qué filas puede ESCRIBIR
        EXISTS (SELECT 1 FROM Lista l
                WHERE l.idLista = Tarea.idLista
                  AND l.idUsuario = NULLIF(current_setting('app.id_usuario', true), '')::INT)
     OR EXISTS (SELECT 1 FROM ListaCompartida c
                WHERE c.idLista = Tarea.idLista
                  AND c.idUsuario = NULLIF(current_setting('app.id_usuario', true), '')::INT)
    );

SET ROLE app_tareas;
SET app.id_usuario = '1';                                          -- Ana
SELECT COUNT(*) AS tareas_de_ana FROM Tarea;                       -- 17
SET app.id_usuario = '4';                                          -- Pedro
SELECT COUNT(*) AS tareas_de_pedro FROM Tarea;                     -- 0
SET app.id_usuario = '1';
DO $$ BEGIN
    INSERT INTO Tarea (idLista, nombre) VALUES (3, 'Tarea colada en la lista de Luis');
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE '10.4 -> [%] %', SQLSTATE, SQLERRM;               -- viola la política
END $$;
RESET app.id_usuario;
RESET ROLE;

SELECT COUNT(*) AS tareas_que_ve_el_duenio FROM Tarea;             -- 25

-- ---------------------------------------------------------------------
-- 10.5 Inyección SQL
-- ---------------------------------------------------------------------
-- MAL: SQL armado pegando el texto del usuario
CREATE OR REPLACE FUNCTION fn_buscar_tarea_inseguro(p_idUsuario INT, p_texto TEXT)
RETURNS TABLE (id_tarea INT, tarea VARCHAR, id_usuario INT)
LANGUAGE plpgsql
AS $$
DECLARE v_sql TEXT;
BEGIN
    v_sql := 'SELECT t.idTarea, t.nombre, l.idUsuario
              FROM Tarea t JOIN Lista l ON l.idLista = t.idLista
              WHERE l.idUsuario = ' || p_idUsuario || '
                AND t.nombre LIKE ''%' || p_texto || '%''';
    RAISE NOTICE '%', v_sql;                   -- mira cómo queda el SQL
    RETURN QUERY EXECUTE v_sql;
END;
$$;

-- BIEN: el texto es un parámetro, nunca parte del SQL
CREATE OR REPLACE FUNCTION fn_buscar_tarea(p_idUsuario INT, p_texto TEXT)
RETURNS TABLE (id_tarea INT, tarea VARCHAR, id_usuario INT)
LANGUAGE sql
AS $$
    SELECT t.idTarea, t.nombre, l.idUsuario
    FROM Tarea t JOIN Lista l ON l.idLista = t.idLista
    WHERE l.idUsuario = p_idUsuario
      AND t.nombre LIKE '%' || p_texto || '%';
$$;
-- Si de verdad necesitas SQL dinámico: EXECUTE '... LIKE $1' USING p_texto
-- o format('... LIKE %L', p_texto), que pone las comillas de forma segura.

SELECT * FROM fn_buscar_tarea_inseguro(1, 'SQL');                  -- uso normal: 1 fila
SELECT * FROM fn_buscar_tarea_inseguro(1, $$' OR 1=1 --$$);       -- ataque: las 25 tareas de todos
SELECT * FROM fn_buscar_tarea(1, $$' OR 1=1 --$$);                -- versión segura: 0 filas
-- $$...$$ es otra forma de escribir texto en PostgreSQL, útil cuando el texto tiene comillas.
