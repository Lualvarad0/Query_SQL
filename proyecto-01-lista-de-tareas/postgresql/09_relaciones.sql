-- =====================================================================
-- PASO 9 · Más relaciones: los 3 tipos que faltaban (PostgreSQL)
-- Equivalente de sqlserver/09_relaciones.sql (allí está la explicación larga).
--   9.1 Auto-relación: subtareas, con FK compuesta para que padre e hija
--       estén en la misma lista.
--   9.2 Muchos a muchos con datos propios: listas compartidas con permiso.
--   9.3 Uno a uno: credenciales en su propia tabla (se llenan en el paso 10).
--   9.4 Consultas.
-- Corre después de los pasos 1 a 8.
-- =====================================================================

-- 9.1 Subtareas
ALTER TABLE Tarea ADD COLUMN idTareaPadre INT;

ALTER TABLE Tarea ADD CONSTRAINT uq_tarea_idtarea_idlista UNIQUE (idTarea, idLista);

ALTER TABLE Tarea ADD CONSTRAINT fk_tarea_padre
    FOREIGN KEY (idTareaPadre, idLista) REFERENCES Tarea (idTarea, idLista);

ALTER TABLE Tarea ADD CONSTRAINT ck_tarea_no_es_su_propio_padre
    CHECK (idTareaPadre IS NULL OR idTareaPadre <> idTarea);

UPDATE Tarea SET idTareaPadre = 22 WHERE idTarea IN (19, 20, 21);
UPDATE Tarea SET idTareaPadre = 3  WHERE idTarea IN (4, 5);

-- 9.2 Listas compartidas
CREATE TABLE ListaCompartida (
    idLista         INT NOT NULL CONSTRAINT fk_lc_lista   REFERENCES Lista(idLista) ON DELETE CASCADE,
    idUsuario       INT NOT NULL CONSTRAINT fk_lc_usuario REFERENCES Usuario(idUsuario),
    permiso         VARCHAR(6) NOT NULL CONSTRAINT ck_lc_permiso CHECK (permiso IN ('LEER', 'EDITAR')),
    fechaCompartida TIMESTAMP  NOT NULL DEFAULT now(),
    CONSTRAINT pk_listacompartida PRIMARY KEY (idLista, idUsuario)
);

INSERT INTO ListaCompartida (idLista, idUsuario, permiso, fechaCompartida) VALUES
(2, 2, 'EDITAR', '2026-11-02'),   -- Ana comparte "Trabajo" con Luis
(4, 1, 'LEER',   '2026-11-05'),   -- Luis comparte "Proyecto Angular" con Ana
(4, 3, 'EDITAR', '2026-11-05'),   -- ... y con Sofía
(6, 4, 'LEER',   '2026-11-20');   -- Sofía comparte "Viaje a Cuenca" con Pedro

-- 9.3 Credenciales (uno a uno: la PK es también la FK)
-- En PostgreSQL usamos bcrypt (extensión pgcrypto): el hash es texto y ya incluye la sal.
CREATE TABLE UsuarioCredencial (
    idUsuario        INT NOT NULL
                     CONSTRAINT pk_usuariocredencial PRIMARY KEY
                     CONSTRAINT fk_uc_usuario REFERENCES Usuario(idUsuario) ON DELETE CASCADE,
    claveHash        TEXT      NOT NULL,                     -- T-SQL: sal VARBINARY(16) + claveHash VARBINARY(32)
    intentosFallidos SMALLINT  NOT NULL DEFAULT 0 CONSTRAINT ck_uc_intentos CHECK (intentosFallidos BETWEEN 0 AND 10),
    bloqueadaHasta   TIMESTAMP,
    fechaCambio      TIMESTAMP NOT NULL DEFAULT now()
);

-- 9.4.1 Árbol de tareas de la lista 4 (CTE recursiva)
WITH RECURSIVE arbol AS (                                  -- T-SQL: WITH arbol AS (sin RECURSIVE)
    SELECT idTarea, idTareaPadre, nombre, 0 AS nivel, nombre::TEXT AS ruta
    FROM Tarea
    WHERE idTareaPadre IS NULL AND idLista = 4
    UNION ALL
    SELECT t.idTarea, t.idTareaPadre, t.nombre, a.nivel + 1, a.ruta || ' > ' || t.nombre
    FROM Tarea t
    JOIN arbol a ON t.idTareaPadre = a.idTarea
)
SELECT repeat('    ', nivel) || nombre AS tarea, nivel, ruta   -- T-SQL: REPLICATE
FROM arbol
ORDER BY ruta;

-- 9.4.2 Progreso de cada tarea padre (auto-JOIN)
SELECT p.nombre AS tarea_padre,
       COUNT(h.idTarea) AS subtareas,
       COUNT(*) FILTER (WHERE h.completada) AS hechas
FROM Tarea p
JOIN Tarea h ON h.idTareaPadre = p.idTarea
GROUP BY p.idTarea, p.nombre;

-- 9.4.3 Listas que ve cada usuario: propias + compartidas
SELECT u.nombre AS usuario, l.nombre AS lista, 'DUEÑO' AS acceso
FROM Usuario u JOIN Lista l ON l.idUsuario = u.idUsuario
UNION ALL
SELECT u.nombre, l.nombre, lc.permiso
FROM ListaCompartida lc
JOIN Usuario u ON u.idUsuario = lc.idUsuario
JOIN Lista l   ON l.idLista   = lc.idLista
ORDER BY usuario, lista;

-- 9.4.4 ¿Quién puede editar las tareas de la lista 4?
SELECT u.nombre, 'DUEÑO' AS por
FROM Lista l JOIN Usuario u ON u.idUsuario = l.idUsuario
WHERE l.idLista = 4
UNION
SELECT u.nombre, 'COMPARTIDA'
FROM ListaCompartida lc JOIN Usuario u ON u.idUsuario = lc.idUsuario
WHERE lc.idLista = 4 AND lc.permiso = 'EDITAR';
