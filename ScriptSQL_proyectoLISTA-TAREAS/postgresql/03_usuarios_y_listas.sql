-- =====================================================================
-- PASO 3 · Usuarios y listas (PostgreSQL)
--     Usuario 1──* Lista 1──* Tarea
-- =====================================================================

CREATE TABLE Usuario (
    idUsuario     INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_usuario PRIMARY KEY,
    nombre        VARCHAR(100) NOT NULL,
    correo        VARCHAR(100) NOT NULL CONSTRAINT uq_usuario_correo UNIQUE,
    fechaRegistro TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE Lista (
    idLista   INT GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_lista PRIMARY KEY,
    nombre    VARCHAR(60) NOT NULL,
    color     CHAR(7),
    idUsuario INT NOT NULL CONSTRAINT fk_lista_usuario REFERENCES Usuario(idUsuario)
);

-- Patrón seguro con datos existentes: 1) columna con NULL, 2) llenarla, 3) NOT NULL + FK
ALTER TABLE Tarea ADD COLUMN idLista INT;    -- 1)
-- 2) y 3) en 05_datos.sql
