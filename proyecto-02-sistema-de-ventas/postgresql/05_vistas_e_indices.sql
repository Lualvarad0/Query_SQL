-- =====================================================================
-- PASO 5 · Vistas, índices y seguridad (PostgreSQL)
-- Equivalente de sqlserver/05_vistas_indices_y_seguridad.sql
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

-- 5.3 Seguridad: hash de claves con la extensión pgcrypto (bcrypt, igual que usaría la API)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

BEGIN;
    ALTER TABLE Usuario ADD COLUMN claveHash TEXT;
    UPDATE Usuario SET claveHash = crypt(clave, gen_salt('bf'));   -- bcrypt: la sal va dentro del hash

    SELECT idUsuario, nombreCompleto,
           CASE WHEN claveHash = crypt('123', claveHash) THEN 'Clave correcta' ELSE 'Clave incorrecta' END AS resultado
    FROM Usuario WHERE correo = 'maria@example.com';
ROLLBACK;
-- T-SQL: HASHBYTES('SHA2_256', sal + clave). bcrypt es mejor para claves porque es lento a propósito.
