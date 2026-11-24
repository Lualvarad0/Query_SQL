/* =====================================================================
   PASO 4 · Procedimientos almacenados (SQL Server)

   Convierte las consultas del PASO 3 en procedimientos que la API puede
   llamar con un EXEC. Ventajas: la lógica vive en un solo lugar, la venta
   se registra completa o no se registra (transacción), y la API solo
   manda parámetros.
   ===================================================================== */

USE DBVENTA;
GO

/* ---------------------------------------------------------------------
   4.1 sp_ObtenerMenus: menús de un usuario (pantalla Login)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_ObtenerMenus
    @idUsuario INT
AS
BEGIN
    SET NOCOUNT ON;     -- no devuelve el mensaje "(n rows affected)" a la app

    SELECT m.idMenu, m.nombre, m.icono, m.url
    FROM Usuario u
    INNER JOIN MenuRol mr ON mr.idRol = u.idRol
    INNER JOIN Menu m     ON m.idMenu = mr.idMenu
    WHERE u.idUsuario = @idUsuario
    ORDER BY m.idMenu;
END;
GO

/* ---------------------------------------------------------------------
   4.2 sp_RegistrarVenta: toda la venta en una sola llamada (pantalla Venta)

   El detalle llega como JSON, que es lo que Angular manda naturalmente:
     '[{"idProducto":11,"cantidad":2},{"idProducto":14,"cantidad":1}]'
   OPENJSON (SQL Server 2016+) lo convierte en una tabla.
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_RegistrarVenta
    @tipoPago        VARCHAR(50),
    @detalle         NVARCHAR(MAX),
    @numeroDocumento VARCHAR(40) OUTPUT          -- devuelve el número generado
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;   -- ante cualquier error, deshace toda la transacción

    -- Pasar el JSON a una tabla variable
    DECLARE @items TABLE (idProducto INT, cantidad INT);
    INSERT INTO @items (idProducto, cantidad)
    SELECT idProducto, cantidad
    FROM OPENJSON(@detalle)
         WITH (idProducto INT '$.idProducto', cantidad INT '$.cantidad');

    -- Validaciones antes de tocar nada
    IF NOT EXISTS (SELECT 1 FROM @items)
        THROW 50001, 'La venta no tiene productos.', 1;

    IF EXISTS (SELECT 1 FROM @items i
               LEFT JOIN Producto p ON p.idProducto = i.idProducto AND p.esActivo = 1
               WHERE p.idProducto IS NULL)
        THROW 50002, 'Hay un producto que no existe o está inactivo.', 1;

    IF EXISTS (SELECT 1 FROM @items i
               INNER JOIN Producto p ON p.idProducto = i.idProducto
               WHERE p.stock < i.cantidad)
        THROW 50003, 'Stock insuficiente para uno de los productos.', 1;

    BEGIN TRANSACTION;

        DECLARE @numero INT;
        UPDATE NumeroDocumento SET @numero = ultimo_Numero = ultimo_Numero + 1;
        SET @numeroDocumento = RIGHT('0000' + CAST(@numero AS VARCHAR(10)), 5);

        INSERT INTO Venta (numeroDocumento, tipoPago, total)
        VALUES (@numeroDocumento, @tipoPago, 0);
        DECLARE @idVenta INT = SCOPE_IDENTITY();

        INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, precio, total)
        SELECT @idVenta, p.idProducto, i.cantidad, p.precio, p.precio * i.cantidad
        FROM @items i
        INNER JOIN Producto p ON p.idProducto = i.idProducto;

        UPDATE p SET p.stock = p.stock - i.cantidad
        FROM Producto p
        INNER JOIN @items i ON i.idProducto = p.idProducto;

        UPDATE Venta
        SET total = (SELECT SUM(total) FROM DetalleVenta WHERE idVenta = @idVenta)
        WHERE idVenta = @idVenta;

    COMMIT TRANSACTION;
END;
GO

/* ---------------------------------------------------------------------
   4.3 sp_ReporteVentas: reporte por rango de fechas (pantalla Reportes)
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_ReporteVentas
    @fechaInicio DATE,
    @fechaFin    DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT v.numeroDocumento, v.tipoPago,
           CONVERT(VARCHAR(10), v.fechaRegistro, 103) AS fecha,
           v.total AS totalVenta, p.nombre AS producto,
           d.cantidad, d.precio, d.total AS totalLinea
    FROM Venta v
    INNER JOIN DetalleVenta d ON d.idVenta    = v.idVenta
    INNER JOIN Producto p     ON p.idProducto = d.idProducto
    WHERE v.fechaRegistro >= @fechaInicio
      AND v.fechaRegistro <  DATEADD(DAY, 1, @fechaFin)
    ORDER BY v.fechaRegistro, p.nombre;
END;
GO

/* ---------------------------------------------------------------------
   4.4 sp_Dashboard: los números del dashboard en dos resultados
   --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE sp_Dashboard
    @hoy DATE = NULL                       -- si no se manda, usa la fecha de hoy
AS
BEGIN
    SET NOCOUNT ON;
    SET @hoy = ISNULL(@hoy, CAST(GETDATE() AS DATE));
    DECLARE @desde DATE = DATEADD(DAY, -6, @hoy);

    -- Resultado 1: tarjetas
    SELECT COUNT(*)              AS ventas_semana,
           ISNULL(SUM(total), 0) AS ingresos_semana,
           (SELECT COUNT(*) FROM Producto WHERE esActivo = 1) AS productos_activos
    FROM Venta
    WHERE CAST(fechaRegistro AS DATE) BETWEEN @desde AND @hoy;

    -- Resultado 2: ventas por día
    SELECT CAST(fechaRegistro AS DATE) AS dia, COUNT(*) AS ventas, SUM(total) AS total
    FROM Venta
    WHERE CAST(fechaRegistro AS DATE) BETWEEN @desde AND @hoy
    GROUP BY CAST(fechaRegistro AS DATE)
    ORDER BY dia;
END;
GO

/* ---------------------------------------------------------------------
   Pruebas
   --------------------------------------------------------------------- */

EXEC sp_ObtenerMenus @idUsuario = 3;        -- supervisor: 4 menús
EXEC sp_Dashboard @hoy = '2026-11-23';
EXEC sp_ReporteVentas @fechaInicio = '2026-11-01', @fechaFin = '2026-11-03';
GO

-- Registrar una venta y deshacerla al final (para no cambiar los datos de ejemplo)
BEGIN TRANSACTION;
    DECLARE @num VARCHAR(40);
    EXEC sp_RegistrarVenta
         @tipoPago = 'Tarjeta',
         @detalle  = N'[{"idProducto":11,"cantidad":2},{"idProducto":14,"cantidad":1}]',
         @numeroDocumento = @num OUTPUT;
    SELECT numeroDocumento, total FROM Venta WHERE numeroDocumento = @num;   -- 00025, 1560.00
ROLLBACK TRANSACTION;
GO

-- Un error controlado: pedir más stock del que hay
BEGIN TRY
    DECLARE @num VARCHAR(40);
    EXEC sp_RegistrarVenta 'Efectivo', N'[{"idProducto":6,"cantidad":99}]', @num OUTPUT;
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS error, ERROR_MESSAGE() AS mensaje;   -- 50003, Stock insuficiente...
END CATCH;
GO
