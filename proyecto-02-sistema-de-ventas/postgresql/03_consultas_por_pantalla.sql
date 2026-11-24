-- =====================================================================
-- PASO 3 · Las consultas que necesita cada pantalla de la app (PostgreSQL)
--
-- Mismas consultas que sqlserver/03_consultas_por_pantalla.sql.
-- PostgreSQL no tiene DECLARE fuera de un bloque, así que los parámetros
-- van escritos directamente (en la app los manda la API como $1, $2...).
-- Los cambios van en BEGIN ... ROLLBACK para no alterar los datos.
-- =====================================================================

-- ---------------------------------------------------------------------
-- PANTALLA LOGIN
-- ---------------------------------------------------------------------

-- 3.1 Validar usuario y clave. Si no devuelve filas, el login falla.
SELECT u.idUsuario, u.nombreCompleto, u.correo, r.nombre AS rol
FROM Usuario u
JOIN Rol r ON r.idRol = u.idRol
WHERE u.correo = 'maria@example.com'
  AND u.clave  = '123'
  AND u.esActivo;                      -- T-SQL: AND u.esActivo = 1

-- 3.2 Menús que ve el usuario que acaba de entrar. Usuario -> Rol -> MenuRol -> Menu
SELECT m.idMenu, m.nombre, m.icono, m.url
FROM Usuario u
JOIN MenuRol mr ON mr.idRol = u.idRol
JOIN Menu m     ON m.idMenu = mr.idMenu
WHERE u.idUsuario = 2
ORDER BY m.idMenu;

-- ---------------------------------------------------------------------
-- PANTALLA DASHBOARD (fecha de referencia fija: 2026-11-23; en la app sería CURRENT_DATE)
-- ---------------------------------------------------------------------

-- 3.3 Tarjetas: ventas e ingresos de los últimos 7 días, y productos activos.
SELECT
    (SELECT COUNT(*)             FROM Venta WHERE fechaRegistro::date BETWEEN DATE '2026-11-23' - 6 AND DATE '2026-11-23') AS ventas_semana,
    (SELECT COALESCE(SUM(total),0) FROM Venta WHERE fechaRegistro::date BETWEEN DATE '2026-11-23' - 6 AND DATE '2026-11-23') AS ingresos_semana,
    (SELECT COUNT(*)             FROM Producto WHERE esActivo)                                                      AS productos_activos;
-- T-SQL: DATEADD(DAY, -6, @hoy)  ·  PG: fecha - 6  (restar enteros a un DATE resta días)

-- 3.4 Gráfico: ventas por día de la última semana.
SELECT fechaRegistro::date AS dia, COUNT(*) AS ventas, SUM(total) AS total
FROM Venta
WHERE fechaRegistro::date BETWEEN DATE '2026-11-23' - 6 AND DATE '2026-11-23'
GROUP BY dia                                  -- PostgreSQL sí acepta el alias
ORDER BY dia;

-- ---------------------------------------------------------------------
-- PANTALLA USUARIOS
-- ---------------------------------------------------------------------

-- 3.5 Usuarios con su rol.
SELECT u.idUsuario, u.nombreCompleto, u.correo, r.nombre AS rol,
       CASE WHEN u.esActivo THEN 'Activo' ELSE 'No activo' END AS estado
FROM Usuario u
JOIN Rol r ON r.idRol = u.idRol
ORDER BY u.idUsuario;

-- 3.6 Roles para el combo del formulario.
SELECT idRol, nombre FROM Rol ORDER BY nombre;

-- 3.7 CRUD de usuarios.
BEGIN;
    INSERT INTO Usuario (nombreCompleto, correo, idRol, clave)
    VALUES ('ana nueva', 'ana@example.com', 2, 'abc')
    RETURNING idUsuario;                                   -- T-SQL: SCOPE_IDENTITY()

    UPDATE Usuario SET nombreCompleto = 'ana empleada', idRol = 3 WHERE correo = 'ana@example.com';
    UPDATE Usuario SET esActivo = FALSE WHERE correo = 'ana@example.com';
    SELECT idUsuario, nombreCompleto, idRol, esActivo FROM Usuario WHERE correo = 'ana@example.com';
    DELETE FROM Usuario WHERE correo = 'ana@example.com';
ROLLBACK;

-- ---------------------------------------------------------------------
-- PANTALLA PRODUCTOS
-- ---------------------------------------------------------------------

-- 3.8 Productos con su categoría.
SELECT p.idProducto, p.nombre, c.nombre AS categoria, p.stock, p.precio,
       CASE WHEN p.esActivo THEN 'Activo' ELSE 'No activo' END AS estado
FROM Producto p
JOIN Categoria c ON c.idCategoria = p.idCategoria
ORDER BY c.nombre, p.nombre;

-- 3.9 Productos con poco stock.
SELECT nombre, stock FROM Producto WHERE stock <= 10 ORDER BY stock;

-- ---------------------------------------------------------------------
-- PANTALLA VENTA
-- ---------------------------------------------------------------------

-- 3.10 Buscador de productos ("auto-complete"): activos y con stock.
SELECT idProducto, nombre, precio, stock
FROM Producto
WHERE esActivo
  AND stock > 0
  AND nombre ILIKE '%' || 'gamer' || '%'      -- T-SQL: LIKE '%' + @texto + '%'
ORDER BY nombre
LIMIT 10;                                     -- T-SQL: SELECT TOP 10

-- 3.11 Registrar una venta "a mano" (5 pasos juntos). En el PASO 4 es un procedimiento.
BEGIN;
    UPDATE NumeroDocumento SET ultimo_Numero = ultimo_Numero + 1;          -- 1. siguiente número

    INSERT INTO Venta (numeroDocumento, tipoPago, total)                   -- 2. cabecera
    SELECT lpad(ultimo_Numero::text, 5, '0'), 'Efectivo', 0 FROM NumeroDocumento;
                                                                           -- T-SQL: RIGHT('0000' + CAST(n AS VARCHAR), 5)
    INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, precio, total) -- 3. detalle
    SELECT (SELECT max(idVenta) FROM Venta), p.idProducto, x.cantidad, p.precio, p.precio * x.cantidad
    FROM (VALUES (11, 2), (14, 1)) AS x(idProducto, cantidad)
    JOIN Producto p ON p.idProducto = x.idProducto;

    UPDATE Producto p SET stock = p.stock - d.cantidad                     -- 4. stock
    FROM DetalleVenta d
    WHERE d.idProducto = p.idProducto AND d.idVenta = (SELECT max(idVenta) FROM Venta);

    UPDATE Venta v SET total = (SELECT SUM(total) FROM DetalleVenta d WHERE d.idVenta = v.idVenta)  -- 5. total
    WHERE v.idVenta = (SELECT max(idVenta) FROM Venta);

    SELECT numeroDocumento, tipoPago, total FROM Venta ORDER BY idVenta DESC LIMIT 1;
ROLLBACK;
-- "max(idVenta)" sirve para el ejemplo, pero con dos cajeros vendiendo a la vez podría tomar
-- la venta del otro. El procedimiento del PASO 4 guarda el id en una variable con RETURNING.

-- ---------------------------------------------------------------------
-- PANTALLA HISTORIAL VENTAS
-- ---------------------------------------------------------------------

-- 3.12 Por rango de fechas.
SELECT idVenta, numeroDocumento, tipoPago, total,
       to_char(fechaRegistro, 'DD/MM/YYYY') AS fecha          -- T-SQL: CONVERT(VARCHAR(10), f, 103)
FROM Venta
WHERE fechaRegistro >= DATE '2026-11-10'
  AND fechaRegistro <  DATE '2026-11-15' + 1
ORDER BY fechaRegistro;

-- 3.13 Por número de venta, con su detalle.
SELECT v.numeroDocumento, p.nombre AS producto, d.cantidad, d.precio, d.total
FROM Venta v
JOIN DetalleVenta d ON d.idVenta    = v.idVenta
JOIN Producto p     ON p.idProducto = d.idProducto
WHERE v.numeroDocumento = '00010';

-- ---------------------------------------------------------------------
-- PANTALLA REPORTES
-- ---------------------------------------------------------------------

-- 3.14 Reporte por rango: una fila por producto vendido.
SELECT v.numeroDocumento, v.tipoPago,
       to_char(v.fechaRegistro, 'DD/MM/YYYY') AS fecha,
       v.total AS totalVenta, p.nombre AS producto, d.cantidad, d.precio, d.total AS totalLinea
FROM Venta v
JOIN DetalleVenta d ON d.idVenta    = v.idVenta
JOIN Producto p     ON p.idProducto = d.idProducto
WHERE v.fechaRegistro >= DATE '2026-11-01'
  AND v.fechaRegistro <  DATE '2026-11-07' + 1
ORDER BY v.fechaRegistro, p.nombre;
