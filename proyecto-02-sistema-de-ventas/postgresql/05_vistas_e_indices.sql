-- =====================================================================
-- PASO 5 · Vistas e índices (PostgreSQL)
-- Equivalente de sqlserver/05_vistas_e_indices.sql
-- =====================================================================

-- 5.1 Índices en llaves foráneas y fechas (PostgreSQL tampoco los crea solo)
CREATE INDEX IF NOT EXISTS ix_detalleventa_idventa    ON DetalleVenta (idVenta);
CREATE INDEX IF NOT EXISTS ix_detalleventa_idproducto ON DetalleVenta (idProducto);
CREATE INDEX IF NOT EXISTS ix_producto_idcategoria    ON Producto (idCategoria);
CREATE INDEX IF NOT EXISTS ix_usuario_idrol           ON Usuario (idRol);
CREATE INDEX IF NOT EXISTS ix_venta_fecharegistro     ON Venta (fechaRegistro);

SELECT indexname FROM pg_indexes WHERE tablename = 'venta' ORDER BY 1;   -- T-SQL: EXEC sp_helpindex 'Venta'

-- 5.2 Vistas
CREATE OR REPLACE VIEW vw_historial_venta AS
SELECT v.idVenta, v.numeroDocumento, v.tipoPago, v.fechaRegistro,
       COUNT(d.idDetalleVenta) AS productosDistintos,
       SUM(d.cantidad)         AS unidades,
       v.total
FROM Venta v
JOIN DetalleVenta d ON d.idVenta = v.idVenta
GROUP BY v.idVenta;          -- PG permite agrupar solo por la PK y usar las demás columnas de Venta

CREATE OR REPLACE VIEW vw_ventas_por_producto AS
SELECT p.idProducto, p.nombre, c.nombre AS categoria,
       COALESCE(SUM(d.cantidad), 0) AS unidadesVendidas,
       COALESCE(SUM(d.total), 0)    AS ingresos,
       p.stock                      AS stockActual
FROM Producto p
JOIN Categoria c         ON c.idCategoria = p.idCategoria
LEFT JOIN DetalleVenta d ON d.idProducto  = p.idProducto
GROUP BY p.idProducto, c.nombre;

SELECT * FROM vw_historial_venta ORDER BY total DESC LIMIT 5;   -- T-SQL: SELECT TOP 5
SELECT * FROM vw_ventas_por_producto ORDER BY ingresos DESC;

-- La seguridad (claves con hash, permisos e inyección SQL) está en el paso 7: 07_seguridad.sql
