/* =====================================================================
   PASO 5 · Vistas e índices (SQL Server)

   Mejoras que un sistema de ventas real necesita y que no cambian lo que
   la app ya usa.
   ===================================================================== */

USE DBVENTA;
GO

/* ---------------------------------------------------------------------
   5.1 Índices
   SQL Server NO crea índices en las llaves foráneas. Sin ellos, cada JOIN
   entre Venta y DetalleVenta lee la tabla completa. Con 24 ventas no se
   nota; con 200.000 sí.
   --------------------------------------------------------------------- */
CREATE INDEX IX_DetalleVenta_idVenta    ON DetalleVenta (idVenta);
CREATE INDEX IX_DetalleVenta_idProducto ON DetalleVenta (idProducto);
CREATE INDEX IX_Producto_idCategoria    ON Producto (idCategoria);
CREATE INDEX IX_Usuario_idRol           ON Usuario (idRol);
CREATE INDEX IX_Venta_fechaRegistro     ON Venta (fechaRegistro);   -- historial y reportes filtran por fecha
GO

-- Ver los índices de una tabla
EXEC sp_helpindex 'Venta';
GO

/* ---------------------------------------------------------------------
   5.2 Vistas: consultas con nombre que la API puede leer como si fueran tablas
   --------------------------------------------------------------------- */

-- Historial con un resumen de cada venta
CREATE OR ALTER VIEW vw_HistorialVenta AS
SELECT v.idVenta,
       v.numeroDocumento,
       v.tipoPago,
       v.fechaRegistro,
       COUNT(d.idDetalleVenta) AS productosDistintos,
       SUM(d.cantidad)         AS unidades,
       v.total
FROM Venta v
INNER JOIN DetalleVenta d ON d.idVenta = v.idVenta
GROUP BY v.idVenta, v.numeroDocumento, v.tipoPago, v.fechaRegistro, v.total;
GO

-- Ranking de productos (incluye los que nunca se vendieron)
CREATE OR ALTER VIEW vw_VentasPorProducto AS
SELECT p.idProducto,
       p.nombre,
       c.nombre                    AS categoria,
       ISNULL(SUM(d.cantidad), 0)  AS unidadesVendidas,
       ISNULL(SUM(d.total), 0)     AS ingresos,
       p.stock                     AS stockActual
FROM Producto p
INNER JOIN Categoria c         ON c.idCategoria = p.idCategoria
LEFT  JOIN DetalleVenta d      ON d.idProducto  = p.idProducto
GROUP BY p.idProducto, p.nombre, c.nombre, p.stock;
GO

SELECT TOP 5 * FROM vw_HistorialVenta ORDER BY total DESC;
SELECT * FROM vw_VentasPorProducto ORDER BY ingresos DESC;
GO

-- La seguridad (claves con hash, permisos e inyección SQL) está en el paso 7: 07_seguridad.sql
