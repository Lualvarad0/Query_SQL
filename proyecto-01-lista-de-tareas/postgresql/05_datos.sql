-- =====================================================================
-- PASO 5 · Datos de ejemplo y cerrar la relación Tarea-Lista (PostgreSQL)
-- 4 usuarios, 6 listas, 25 tareas, 9 etiquetas.
-- Fecha de referencia ("hoy") para todo el proyecto: 2026-11-23.
-- =====================================================================

-- Usuarios. 'Pedro Sin Listas' no tiene listas (para practicar LEFT JOIN).
INSERT INTO Usuario (nombre, correo) VALUES
('Ana Torres', 'ana@example.com'),
('Luis Mora', 'luis@example.com'),
('Sofía Ríos', 'sofia@example.com'),
('Pedro Sin Listas', 'pedro@example.com');

-- Listas. 'Viaje a Cuenca' no tiene tareas; en 'Gimnasio' todas están completadas.
INSERT INTO Lista (nombre, color, idUsuario) VALUES
('Estudios', '#3F51B5', 1),
('Trabajo', '#F44336', 1),
('Casa', '#4CAF50', 2),
('Proyecto Angular', '#FF9800', 2),
('Gimnasio', '#9C27B0', 3),
('Viaje a Cuenca', '#009688', 3);

-- Las 2 tareas originales ya existen (pasos 1 a 3): se completan sus datos.
UPDATE Tarea SET descripcion = 'Componentes, servicios y rutas', prioridad = 1, fechaCreacion = '2026-10-01', fechaLimite = '2026-11-30', idLista = 1 WHERE idTarea = 1;
UPDATE Tarea SET descripcion = 'Revisar el tutorial oficial', prioridad = 3, fechaCreacion = '2026-10-01', fechaLimite = NULL, idLista = 1 WHERE idTarea = 2;

-- Tareas nuevas. Fecha de referencia de todo el proyecto: "hoy" = 2026-11-23.
INSERT INTO Tarea (idLista, nombre, descripcion, prioridad, fechaCreacion, fechaLimite, completada, fechaCompletada) VALUES
(1, 'Terminar curso de SQL', 'Módulos 01 a 10 del repo Query_SQL', 1, '2026-11-01', '2026-11-28', FALSE, NULL),
(1, 'Practicar JOINs', 'Ejercicios del módulo 04', 2, '2026-11-02', '2026-11-15', TRUE, '2026-11-14 20:10'),
(1, 'Leer sobre índices', 'Capítulo de índices y EXPLAIN', 3, '2026-11-05', NULL, TRUE, '2026-11-20 21:00'),
(1, 'Repasar TypeScript', NULL, 2, '2026-11-10', '2026-11-20', FALSE, NULL),
(2, 'Enviar informe mensual', 'Ventas de octubre', 1, '2026-11-01', '2026-11-05', TRUE, '2026-11-05 17:30'),
(2, 'Reunión con el equipo', NULL, 2, '2026-11-03', '2026-11-24', FALSE, NULL),
(2, 'Actualizar la API de ventas', 'Agregar endpoint de reportes', 1, '2026-11-08', '2026-11-22', FALSE, NULL),
(2, 'Revisar pull requests', NULL, 2, '2026-11-12', '2026-11-23', FALSE, NULL),
(2, 'Preparar presentación', 'Para el cliente nuevo', 1, '2026-11-15', '2026-11-27', FALSE, NULL),
(2, 'Responder correos pendientes', NULL, 3, '2026-11-18', '2026-11-19', TRUE, '2026-11-19 09:15'),
(3, 'Pagar luz y agua', NULL, 1, '2026-11-01', '2026-11-10', TRUE, '2026-11-09 12:00'),
(3, 'Comprar víveres', 'Arroz, huevos, frutas', 2, '2026-11-20', '2026-11-23', FALSE, NULL),
(3, 'Arreglar la puerta del baño', NULL, 3, '2026-10-15', NULL, FALSE, NULL),
(3, 'Limpiar el garaje', NULL, 3, '2026-11-02', '2026-11-16', FALSE, NULL),
(3, 'Llevar el carro al mecánico', 'Cambio de aceite', 2, '2026-11-11', '2026-11-21', TRUE, '2026-11-21 10:30'),
(4, 'Diseñar la base de datos', 'Tablas Tarea, Lista, Usuario, Etiqueta', 1, '2026-10-20', '2026-10-31', TRUE, '2026-10-30 18:00'),
(4, 'Crear el login', NULL, 1, '2026-10-25', '2026-11-10', TRUE, '2026-11-12 16:45'),
(4, 'Pantalla de listas', NULL, 2, '2026-11-01', '2026-11-20', TRUE, '2026-11-18 19:20'),
(4, 'Filtros por etiqueta', NULL, 2, '2026-11-10', '2026-11-30', FALSE, NULL),
(4, 'Publicar en producción', NULL, 1, '2026-11-15', '2026-12-05', FALSE, NULL),
(5, 'Inscribirse en el gimnasio', NULL, 2, '2026-10-01', '2026-10-05', TRUE, '2026-10-03 07:00'),
(5, 'Comprar zapatillas', NULL, 3, '2026-10-02', NULL, TRUE, '2026-10-10 15:00'),
(5, 'Rutina de 4 semanas', NULL, 2, '2026-10-05', '2026-11-05', TRUE, '2026-11-04 06:30');

-- Etiquetas. 'personal' no se usa en ninguna tarea.
INSERT INTO Etiqueta (nombre) VALUES
('estudio'),
('trabajo'),
('casa'),
('urgente'),
('reunion'),
('compras'),
('salud'),
('lectura'),
('personal');

-- Qué etiquetas tiene cada tarea (tabla puente).
INSERT INTO TareaEtiqueta (idTarea, idEtiqueta) VALUES
    (1, 1), (1, 4), (2, 1), (3, 1), (3, 4), (4, 1), (5, 1), (5, 8),
    (6, 1), (7, 2), (7, 4), (8, 2), (8, 5), (9, 2), (10, 2), (11, 2),
    (11, 5), (12, 2), (13, 3), (13, 4), (14, 3), (14, 6), (15, 3), (16, 3),
    (17, 3), (18, 2), (19, 2), (20, 2), (21, 2), (22, 2), (22, 4), (23, 7),
    (24, 7), (24, 6), (25, 7);

-- 3) del PASO 3: ya todas las tareas tienen lista
ALTER TABLE Tarea ALTER COLUMN idLista SET NOT NULL;            -- T-SQL: ALTER COLUMN idLista INT NOT NULL
ALTER TABLE Tarea ADD CONSTRAINT fk_tarea_lista FOREIGN KEY (idLista) REFERENCES Lista(idLista);

SELECT COUNT(*) AS tareas FROM Tarea;
