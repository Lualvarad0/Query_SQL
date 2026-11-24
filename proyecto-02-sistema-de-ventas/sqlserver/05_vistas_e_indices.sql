/* =====================================================================
   PASO 5 · Vistas, índices y seguridad (SQL Server)

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

/* ---------------------------------------------------------------------
   5.3 Seguridad: no guardar claves en texto plano
   La tabla original guarda clave = '123'. Si alguien roba la base, ve todas
   las claves. Lo correcto es guardar un HASH (una huella que no se puede
   revertir) con una "sal" distinta por usuario.

   En la app real esto se hace en la API (por ejemplo con BCrypt en .NET).
   Aquí lo mostramos en SQL para entender la idea, y se deshace al final
   para no romper el login de la app.
   --------------------------------------------------------------------- */
BEGIN TRANSACTION;

    ALTER TABLE Usuario ADD sal UNIQUEIDENTIFIER NULL, claveHash VARBINARY(32) NULL;
    EXEC('UPDATE Usuario SET sal = NEWID();
          UPDATE Usuario
          SET claveHash = HASHBYTES(''SHA2_256'', CAST(sal AS VARCHAR(36)) + clave);');
          -- EXEC(...) porque SQL Server compila el lote antes de que existan las columnas nuevas

    -- El login ahora compara hashes, nunca la clave
    EXEC('DECLARE @correo VARCHAR(40) = ''maria@example.com'', @clave VARCHAR(40) = ''123'';
          SELECT idUsuario, nombreCompleto,
                 CASE WHEN claveHash = HASHBYTES(''SHA2_256'', CAST(sal AS VARCHAR(36)) + @clave)
                      THEN ''Clave correcta'' ELSE ''Clave incorrecta'' END AS resultado
          FROM Usuario WHERE correo = @correo;');

ROLLBACK TRANSACTION;   -- la tabla vuelve a su forma original
GO
