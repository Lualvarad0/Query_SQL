/* =====================================================================
   PASO 9 · Más relaciones: los 3 tipos que faltaban (SQL Server)

   Hasta el paso 5 tenemos:
       Usuario 1──* Lista 1──* Tarea          (uno a muchos)
       Tarea *──* Etiqueta                     (muchos a muchos, con TareaEtiqueta)

   Aquí agregamos:
     9.1 AUTO-RELACIÓN: una tarea puede tener subtareas (Tarea → Tarea),
         y con una llave foránea COMPUESTA obligamos a que la subtarea
         esté en la MISMA lista que su tarea padre.
     9.2 MUCHOS A MUCHOS CON DATOS PROPIOS: compartir una lista con otros
         usuarios, guardando el permiso (LEER o EDITAR) en la tabla puente.
     9.3 UNO A UNO: las credenciales del usuario van en otra tabla
         (UsuarioCredencial), para poder dar permiso sobre Usuario sin
         dar acceso a las claves. Se llena en el paso 10.
     9.4 Consultas que usan estas relaciones.

   Corre después de los pasos 1 a 8.
   ===================================================================== */

USE DBTareas;
GO

/* ---------------------------------------------------------------------
   9.1 Subtareas: auto-relación
   Una llave foránea que apunta a la MISMA tabla. Ejemplo: "Publicar en
   producción" no se puede hacer sin "Crear el login", "Pantalla de listas"
   y "Filtros por etiqueta".

   Truco de seguridad de datos: con una FK simple (idTareaPadre → idTarea)
   alguien podría colgar una subtarea de Luis bajo una tarea de Ana.
   Con una FK compuesta (idTareaPadre, idLista) → (idTarea, idLista)
   la base de datos exige que padre e hija estén en la misma lista.
   Para eso, (idTarea, idLista) debe ser UNIQUE en Tarea.
   --------------------------------------------------------------------- */
ALTER TABLE Tarea ADD idTareaPadre INT NULL;
GO

ALTER TABLE Tarea ADD CONSTRAINT UQ_Tarea_idTarea_idLista UNIQUE (idTarea, idLista);

ALTER TABLE Tarea ADD CONSTRAINT FK_Tarea_Padre
    FOREIGN KEY (idTareaPadre, idLista) REFERENCES Tarea (idTarea, idLista);

-- Una tarea no puede ser subtarea de sí misma
ALTER TABLE Tarea ADD CONSTRAINT CK_Tarea_noEsSuPropioPadre
    CHECK (idTareaPadre IS NULL OR idTareaPadre <> idTarea);
GO

-- 22 'Publicar en producción' tiene 3 subtareas; 3 'Terminar curso de SQL' tiene 2.
UPDATE Tarea SET idTareaPadre = 22 WHERE idTarea IN (19, 20, 21);
UPDATE Tarea SET idTareaPadre = 3  WHERE idTarea IN (4, 5);
GO

/* ---------------------------------------------------------------------
   9.2 Listas compartidas: muchos a muchos con datos propios
   La tabla puente no solo une (idLista, idUsuario): también guarda
   QUÉ puede hacer ese usuario y desde cuándo.
   --------------------------------------------------------------------- */
CREATE TABLE ListaCompartida (
    idLista         INT NOT NULL CONSTRAINT FK_LC_Lista   REFERENCES Lista(idLista) ON DELETE CASCADE,
    idUsuario       INT NOT NULL CONSTRAINT FK_LC_Usuario REFERENCES Usuario(idUsuario),
    permiso         VARCHAR(6) NOT NULL CONSTRAINT CK_LC_permiso CHECK (permiso IN ('LEER', 'EDITAR')),
    fechaCompartida DATETIME   NOT NULL CONSTRAINT DF_LC_fecha DEFAULT GETDATE(),
    CONSTRAINT PK_ListaCompartida PRIMARY KEY (idLista, idUsuario)
);
GO
-- Si se borra la lista, se borra a quién estaba compartida (CASCADE).
-- Si se intenta borrar un usuario que tiene listas compartidas, falla (NO ACTION):
-- borrar personas es una decisión que no debe pasar "sin querer".

INSERT INTO ListaCompartida (idLista, idUsuario, permiso, fechaCompartida) VALUES
(2, 2, 'EDITAR', '2026-11-02'),   -- Ana comparte "Trabajo" con Luis
(4, 1, 'LEER',   '2026-11-05'),   -- Luis comparte "Proyecto Angular" con Ana
(4, 3, 'EDITAR', '2026-11-05'),   -- ... y con Sofía
(6, 4, 'LEER',   '2026-11-20');   -- Sofía comparte "Viaje a Cuenca" con Pedro
GO

/* ---------------------------------------------------------------------
   9.3 Credenciales: uno a uno
   La llave primaria de UsuarioCredencial ES la llave foránea a Usuario:
   así cada usuario tiene como máximo UNA fila de credenciales.
   ¿Por qué separarla? Porque así la app y los reportes pueden leer
   Usuario (nombre, correo) sin poder ver nunca el hash de la clave.
   --------------------------------------------------------------------- */
CREATE TABLE UsuarioCredencial (
    idUsuario        INT NOT NULL
                     CONSTRAINT PK_UsuarioCredencial PRIMARY KEY
                     CONSTRAINT FK_UC_Usuario REFERENCES Usuario(idUsuario) ON DELETE CASCADE,
    sal              VARBINARY(16) NOT NULL,
    claveHash        VARBINARY(32) NOT NULL,      -- SHA2_256 = 32 bytes
    intentosFallidos TINYINT  NOT NULL CONSTRAINT DF_UC_intentos DEFAULT 0
                     CONSTRAINT CK_UC_intentos CHECK (intentosFallidos BETWEEN 0 AND 10),
    bloqueadaHasta   DATETIME NULL,
    fechaCambio      DATETIME NOT NULL CONSTRAINT DF_UC_fecha DEFAULT GETDATE()
);
GO

/* ---------------------------------------------------------------------
   9.4 Consultas con las relaciones nuevas
   --------------------------------------------------------------------- */

-- 9.4.1 Árbol de tareas con una CTE recursiva: cada tarea con su nivel y su "ruta".
WITH arbol AS (
    SELECT idTarea, idTareaPadre, nombre, 0 AS nivel,
           CAST(nombre AS VARCHAR(400)) AS ruta
    FROM Tarea
    WHERE idTareaPadre IS NULL AND idLista = 4
    UNION ALL
    SELECT t.idTarea, t.idTareaPadre, t.nombre, a.nivel + 1,
           CAST(a.ruta + ' > ' + t.nombre AS VARCHAR(400))
    FROM Tarea t
    INNER JOIN arbol a ON t.idTareaPadre = a.idTarea
)
SELECT REPLICATE('    ', nivel) + nombre AS tarea, nivel, ruta
FROM arbol
ORDER BY ruta;
GO

-- 9.4.2 Progreso de cada tarea padre: auto-JOIN de Tarea con sus hijas.
SELECT p.nombre AS tarea_padre,
       COUNT(h.idTarea) AS subtareas,
       SUM(CASE WHEN h.completada = 1 THEN 1 ELSE 0 END) AS hechas
FROM Tarea p
INNER JOIN Tarea h ON h.idTareaPadre = p.idTarea
GROUP BY p.idTarea, p.nombre;
GO

-- 9.4.3 Todas las listas que ve cada usuario: las suyas + las compartidas (UNION ALL).
SELECT u.nombre AS usuario, l.nombre AS lista, 'DUEÑO' AS acceso
FROM Usuario u INNER JOIN Lista l ON l.idUsuario = u.idUsuario
UNION ALL
SELECT u.nombre, l.nombre, lc.permiso
FROM ListaCompartida lc
INNER JOIN Usuario u ON u.idUsuario = lc.idUsuario
INNER JOIN Lista l   ON l.idLista   = lc.idLista
ORDER BY usuario, lista;
GO

-- 9.4.4 ¿Quién puede EDITAR las tareas de la lista 4? El dueño y los que tienen permiso EDITAR.
SELECT u.nombre, 'DUEÑO' AS por
FROM Lista l INNER JOIN Usuario u ON u.idUsuario = l.idUsuario
WHERE l.idLista = 4
UNION
SELECT u.nombre, 'COMPARTIDA'
FROM ListaCompartida lc INNER JOIN Usuario u ON u.idUsuario = lc.idUsuario
WHERE lc.idLista = 4 AND lc.permiso = 'EDITAR';
GO
