/* =====================================================================
   PASO 3 · Las consultas que necesita cada pantalla de la app (SQL Server)

   La app de Angular tiene un menú lateral con 6 opciones (tabla Menu).
   Aquí está, pantalla por pantalla, el SQL que hay detrás.
   En la app los valores (correo, fechas, ids) llegan como parámetros desde
   la API; aquí los ponemos en variables con DECLARE para que se vea igual.
   Los cambios (INSERT/UPDATE/DELETE) van dentro de una transacción que se
   deshace al final, para que puedas correr el archivo las veces que quieras.
   ===================================================================== */

USE DBVENTA;
GO

/* ---------------------------------------------------------------------
   PANTALLA LOGIN
   --------------------------------------------------------------------- */

-- 3.1 Validar usuario y clave. Si no devuelve filas, el login falla.
DECLARE @correo VARCHAR(40) = 'maria@example.com',
        @clave  VARCHAR(40) = '123';

SELECT u.idUsuario, u.nombreCompleto, u.correo, r.nombre AS rol
FROM Usuario u
INNER JOIN Rol r ON r.idRol = u.idRol
WHERE u.correo = @correo
  AND u.clave  = @clave
  AND u.esActivo = 1;
GO

-- 3.2 Menús que ve el usuario que acaba de entrar (arma el menú lateral).
--     Usuario -> Rol -> MenuRol -> Menu
DECLARE @idUsuario INT = 2;

SELECT m.idMenu, m.nombre, m.icono, m.url
FROM Usuario u
INNER JOIN MenuRol mr ON mr.idRol = u.idRol
INNER JOIN Menu m     ON m.idMenu = mr.idMenu
WHERE u.idUsuario = @idUsuario
ORDER BY m.idMenu;
GO

/* ---------------------------------------------------------------------
   PANTALLA DASHBOARD
   En la app la fecha de referencia es GETDATE(). Aquí usamos una fija
   para que siempre salgan los mismos números con los datos de ejemplo.
   --------------------------------------------------------------------- */

DECLARE @hoy DATE = '2026-11-23';
DECLARE @desde DATE = DATEADD(DAY, -6, @hoy);   -- últimos 7 días contando hoy

-- 3.3 Tarjetas del dashboard: ventas e ingresos de la última semana, y productos.
SELECT
    (SELECT COUNT(*)            FROM Venta WHERE CAST(fechaRegistro AS DATE) BETWEEN @desde AND @hoy) AS ventas_semana,
    (SELECT ISNULL(SUM(total),0) FROM Venta WHERE CAST(fechaRegistro AS DATE) BETWEEN @desde AND @hoy) AS ingresos_semana,
    (SELECT COUNT(*)            FROM Producto WHERE esActivo = 1)                                       AS productos_activos;

-- 3.4 Gráfico de barras: ventas por día de la última semana.
SELECT CAST(fechaRegistro AS DATE) AS dia,
       COUNT(*)                     AS ventas,
       SUM(total)                   AS total
FROM Venta
WHERE CAST(fechaRegistro AS DATE) BETWEEN @desde AND @hoy
GROUP BY CAST(fechaRegistro AS DATE)       -- SQL Server no deja usar el alias "dia" aquí
ORDER BY dia;
GO

/* ---------------------------------------------------------------------
   PANTALLA USUARIOS (solo Administrador)
   --------------------------------------------------------------------- */

-- 3.5 Tabla de usuarios con su rol (la app muestra "Activo"/"No activo").
SELECT u.idUsuario, u.nombreCompleto, u.correo, r.nombre AS rol,
       CASE WHEN u.esActivo = 1 THEN 'Activo' ELSE 'No activo' END AS estado
FROM Usuario u
INNER JOIN Rol r ON r.idRol = u.idRol
ORDER BY u.idUsuario;

-- 3.6 Lista de roles para el combo del formulario.
SELECT idRol, nombre FROM Rol ORDER BY nombre;
GO

-- 3.7 Crear, editar, desactivar y eliminar (CRUD).
BEGIN TRANSACTION;

    INSERT INTO Usuario (nombreCompleto, correo, idRol, clave)
    VALUES ('ana nueva', 'ana@example.com', 2, 'abc');

    DECLARE @nuevo INT = SCOPE_IDENTITY();         -- id que se acaba de generar

    UPDATE Usuario
    SET nombreCompleto = 'ana empleada', idRol = 3
    WHERE idUsuario = @nuevo;

    UPDATE Usuario SET esActivo = 0 WHERE idUsuario = @nuevo;   -- "borrado lógico"

    SELECT idUsuario, nombreCompleto, idRol, esActivo FROM Usuario WHERE idUsuario = @nuevo;

    DELETE FROM Usuario WHERE idUsuario = @nuevo;               -- borrado real

ROLLBACK TRANSACTION;   -- deshace todo: la tabla queda como estaba
GO

/* ---------------------------------------------------------------------
   PANTALLA PRODUCTOS
   --------------------------------------------------------------------- */

-- 3.8 Tabla de productos con el nombre de la categoría.
SELECT p.idProducto, p.nombre, c.nombre AS categoria, p.stock, p.precio,
       CASE WHEN p.esActivo = 1 THEN 'Activo' ELSE 'No activo' END AS estado
FROM Producto p
INNER JOIN Categoria c ON c.idCategoria = p.idCategoria
ORDER BY c.nombre, p.nombre;

-- 3.9 Productos con poco stock (para avisar que hay que reponer).
SELECT nombre, stock FROM Producto WHERE stock <= 10 ORDER BY stock;
GO

/* ---------------------------------------------------------------------
   PANTALLA VENTA
   --------------------------------------------------------------------- */

-- 3.10 Buscador de productos mientras se escribe ("auto-complete").
--      Solo activos y con stock.
DECLARE @texto VARCHAR(50) = 'gamer';

SELECT TOP 10 idProducto, nombre, precio, stock
FROM Producto
WHERE esActivo = 1
  AND stock > 0
  AND nombre LIKE '%' + @texto + '%'        -- en SQL Server LIKE no distingue mayúsculas
ORDER BY nombre;
GO

-- 3.11 Registrar una venta "a mano": son 5 pasos que deben ir juntos.
--      En el PASO 4 esto se convierte en un procedimiento almacenado.
BEGIN TRANSACTION;

    DECLARE @numero INT;
    UPDATE NumeroDocumento SET @numero = ultimo_Numero = ultimo_Numero + 1;   -- 1. siguiente número
    DECLARE @numeroDocumento VARCHAR(40) = RIGHT('0000' + CAST(@numero AS VARCHAR), 5);

    INSERT INTO Venta (numeroDocumento, tipoPago, total)                       -- 2. cabecera
    VALUES (@numeroDocumento, 'Efectivo', 0);
    DECLARE @idVenta INT = SCOPE_IDENTITY();

    INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, precio, total)    -- 3. detalle
    SELECT @idVenta, p.idProducto, x.cantidad, p.precio, p.precio * x.cantidad
    FROM (VALUES (11, 2), (14, 1)) AS x(idProducto, cantidad)
    INNER JOIN Producto p ON p.idProducto = x.idProducto;

    UPDATE p SET p.stock = p.stock - d.cantidad                                 -- 4. stock
    FROM Producto p
    INNER JOIN DetalleVenta d ON d.idProducto = p.idProducto
    WHERE d.idVenta = @idVenta;

    UPDATE Venta                                                                -- 5. total
    SET total = (SELECT SUM(total) FROM DetalleVenta WHERE idVenta = @idVenta)
    WHERE idVenta = @idVenta;

    SELECT numeroDocumento, tipoPago, total FROM Venta WHERE idVenta = @idVenta;

ROLLBACK TRANSACTION;
GO

/* ---------------------------------------------------------------------
   PANTALLA HISTORIAL VENTAS
   --------------------------------------------------------------------- */

-- 3.12 Buscar por rango de fechas.
DECLARE @fechaInicio DATE = '2026-11-10',
        @fechaFin    DATE = '2026-11-15';

SELECT idVenta, numeroDocumento, tipoPago, total,
       CONVERT(VARCHAR(10), fechaRegistro, 103) AS fecha      -- 103 = dd/mm/yyyy
FROM Venta
WHERE fechaRegistro >= @fechaInicio
  AND fechaRegistro <  DATEADD(DAY, 1, @fechaFin)             -- incluye todo el último día
ORDER BY fechaRegistro;
GO

-- 3.13 Buscar por número de venta y ver su detalle (el modal "ver detalle").
DECLARE @buscar VARCHAR(40) = '00010';

SELECT v.numeroDocumento, p.nombre AS producto, d.cantidad, d.precio, d.total
FROM Venta v
INNER JOIN DetalleVenta d ON d.idVenta    = v.idVenta
INNER JOIN Producto p     ON p.idProducto = d.idProducto
WHERE v.numeroDocumento = @buscar;
GO

/* ---------------------------------------------------------------------
   PANTALLA REPORTES
   --------------------------------------------------------------------- */

-- 3.14 Reporte de ventas por rango: una fila por producto vendido (lo que se exporta a Excel).
DECLARE @fechaInicio DATE = '2026-11-01',
        @fechaFin    DATE = '2026-11-07';

SELECT v.numeroDocumento,
       v.tipoPago,
       CONVERT(VARCHAR(10), v.fechaRegistro, 103) AS fecha,
       v.total        AS totalVenta,
       p.nombre       AS producto,
       d.cantidad,
       d.precio,
       d.total        AS totalLinea
FROM Venta v
INNER JOIN DetalleVenta d ON d.idVenta    = v.idVenta
INNER JOIN Producto p     ON p.idProducto = d.idProducto
WHERE v.fechaRegistro >= @fechaInicio
  AND v.fechaRegistro <  DATEADD(DAY, 1, @fechaFin)
ORDER BY v.fechaRegistro, p.nombre;
GO
