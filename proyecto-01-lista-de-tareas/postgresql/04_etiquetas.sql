-- =====================================================================
-- PASO 4 · Etiquetas: relación muchos a muchos (PostgreSQL)
--     Tarea 1──* TareaEtiqueta *──1 Etiqueta
-- =====================================================================

CREATE TABLE Etiqueta (
    idEtiqueta INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_etiqueta PRIMARY KEY,
    nombre     VARCHAR(30) NOT NULL CONSTRAINT uq_etiqueta_nombre UNIQUE
);

CREATE TABLE TareaEtiqueta (
    idTarea    INT NOT NULL REFERENCES Tarea(idTarea)       ON DELETE CASCADE,
    idEtiqueta INT NOT NULL REFERENCES Etiqueta(idEtiqueta) ON DELETE CASCADE,
    CONSTRAINT pk_tareaetiqueta PRIMARY KEY (idTarea, idEtiqueta)
);
