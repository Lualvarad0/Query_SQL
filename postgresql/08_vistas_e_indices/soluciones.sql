-- =====================================================================
-- Módulo 08 · Vistas e índices · SOLUCIONES
-- Este módulo SÍ crea objetos que se quedan en la base (vistas e índices).
-- Puedes volver a correrlo: usa CREATE OR REPLACE / IF NOT EXISTS.
-- =====================================================================

-- 1. Crea la vista vw_detalle_venta con una fila por línea vendida: documento, fecha, estado,
--    cliente (o 'Consumidor final'), ciudad, vendedor, producto, categoría, cantidad, total de la
--    línea y ganancia de la línea. Luego úsala para ver la venta '00006'.
CREATE OR REPLACE VIEW vw_detalle_venta AS
SELECT v.numeroDocumento,
       v.fechaRegistro,
       v.estado,
       COALESCE(cl.nombreCompleto, 'Consumidor final') AS cliente,
       ci.nombre                                        AS ciudad,
       u.nombreCompleto                                 AS vendedor,
       p.nombre                                         AS producto,
       COALESCE(c.nombre, 'Sin categoría')              AS categoria,
       d.cantidad,
       d.total,
       d.total - p.costo * d.cantidad                   AS ganancia
FROM DetalleVenta d
JOIN Venta v          ON v.idVenta     = d.idVenta
JOIN Usuario u        ON u.idUsuario   = v.idUsuario
JOIN Producto p       ON p.idProducto  = d.idProducto
LEFT JOIN Categoria c ON c.idCategoria = p.idCategoria
LEFT JOIN Cliente cl  ON cl.idCliente  = v.idCliente
LEFT JOIN Ciudad ci   ON ci.idCiudad   = cl.idCiudad;

SELECT producto, cantidad, total, ganancia
FROM vw_detalle_venta
WHERE numeroDocumento = '00006';
-- Una vista es una consulta guardada con nombre: no guarda datos, se ejecuta cada vez.
-- T-SQL: CREATE OR ALTER VIEW vw_detalle_venta AS ...

-- 2. Usando SOLO la vista: ganancia total por vendedor en ventas pagadas.
SELECT vendedor, SUM(ganancia) AS ganancia
FROM vw_detalle_venta
WHERE estado = 'PAGADA'
GROUP BY vendedor
ORDER BY ganancia DESC;

-- 3. Crea una vista materializada mv_ventas_mensuales (mes, ventas, total) de ventas pagadas,
--    consúltala, y explica cuándo hay que refrescarla.
DROP MATERIALIZED VIEW IF EXISTS mv_ventas_mensuales;
CREATE MATERIALIZED VIEW mv_ventas_mensuales AS
SELECT date_trunc('month', fechaRegistro)::date AS mes, COUNT(*) AS ventas, SUM(total) AS total
FROM Venta
WHERE estado = 'PAGADA'
GROUP BY 1;

SELECT * FROM mv_ventas_mensuales ORDER BY mes;
REFRESH MATERIALIZED VIEW mv_ventas_mensuales;   -- vuelve a calcular con los datos actuales
-- La materializada SÍ guarda el resultado: es rápida de leer pero no ve ventas nuevas hasta REFRESH.
-- SQL Server no tiene "materialized view"; lo parecido es una "indexed view"
-- (CREATE VIEW ... WITH SCHEMABINDING + CREATE UNIQUE CLUSTERED INDEX).

-- 4. Mira el plan de ejecución de buscar un cliente por documento y de buscarlo por nombre.
--    ¿Cuál usa índice?
EXPLAIN SELECT * FROM Cliente WHERE documento = '0923456789';
EXPLAIN SELECT * FROM Cliente WHERE nombreCompleto = 'Miguel Castro';
-- @esperado: la primera usa "Index Scan using cliente_documento_key", la segunda "Seq Scan"
-- documento tiene UNIQUE, y UNIQUE crea un índice automáticamente. nombreCompleto no tiene índice.
-- Con tablas tan pequeñas PostgreSQL puede preferir leer toda la tabla (Seq Scan) aunque haya
-- índice: leer 15 filas es más barato. Los índices brillan con miles o millones de filas.
-- T-SQL: en SSMS activa "Include Actual Execution Plan" (Ctrl+M) o usa SET SHOWPLAN_TEXT ON.

-- 5. Crea un índice para búsquedas por nombre de cliente sin importar mayúsculas y comprueba
--    que el plan puede usarlo.
CREATE INDEX IF NOT EXISTS ix_cliente_nombre_lower ON Cliente (lower(nombreCompleto));
SET enable_seqscan = off;     -- solo para la demostración: obliga a no leer toda la tabla
EXPLAIN SELECT * FROM Cliente WHERE lower(nombreCompleto) = 'miguel castro';
RESET enable_seqscan;
-- @esperado: "Index Scan using ix_cliente_nombre_lower"
-- Es un índice "de expresión": solo se usa si la consulta escribe exactamente lower(nombreCompleto).
-- T-SQL: crea una columna calculada (ALTER TABLE ... ADD nombre_lower AS LOWER(...)) e indexa esa.

-- 6. Crea un índice compuesto para el reporte "ventas pagadas por rango de fechas" y un índice
--    parcial solo con ventas pagadas. Lista los índices de la tabla Venta.
CREATE INDEX IF NOT EXISTS ix_venta_estado_fecha ON Venta (estado, fechaRegistro);
CREATE INDEX IF NOT EXISTS ix_venta_pagada_fecha ON Venta (fechaRegistro) WHERE estado = 'PAGADA';

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'venta'
ORDER BY indexname;
-- @esperado: 6 índices (PK, UNIQUE de numeroDocumento, los 2 del esquema y los 2 nuevos)
-- En un índice compuesto el orden importa: (estado, fecha) sirve para "estado = X AND fecha entre ...",
-- y también para "estado = X" solo, pero NO para "fecha entre ..." solo.
-- T-SQL: índice parcial = "filtered index": CREATE INDEX ... ON Venta(fechaRegistro) WHERE estado = 'PAGADA';
-- T-SQL: listar índices: EXEC sp_helpindex 'Venta';
