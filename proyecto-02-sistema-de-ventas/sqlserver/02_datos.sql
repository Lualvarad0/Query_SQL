/* =====================================================================
   PASO 2 · Datos de ejemplo
   Los datos originales del proyecto (antes en un .txt), más:
     - 2 usuarios (un empleado y un supervisor) para probar el login por rol
     - 24 ventas de noviembre 2026 con su detalle, para que el dashboard,
       el historial y los reportes tengan algo que mostrar
   Productos que nunca se venden: 'laptop asus zenbook duo', 'teclado logitech'
   y 'memoria kingston rgb' (útil para los ejercicios con LEFT JOIN).
   Corre después de 01_crear_base_y_tablas.sql
   ===================================================================== */

USE DBVENTA;
GO

INSERT INTO Rol (nombre) VALUES
('Administrador'),
('Empleado'),
('Supervisor');
GO
INSERT INTO Usuario (nombreCompleto, correo, idRol, clave) VALUES
('codigo estudiante', 'code@example.com',  1, '123'),
('maria empleada',    'maria@example.com', 2, '123'),
('jose supervisor',   'jose@example.com',  3, '123');
GO
INSERT INTO Categoria (nombre, esActivo) VALUES
('Laptops', 1), ('Monitores', 1), ('Teclados', 1),
('Auriculares', 1), ('Memorias', 1), ('Accesorios', 1);
GO
INSERT INTO Producto (nombre, idCategoria, stock, precio, esActivo) VALUES
('laptop samsung book pro',   1, 20, 2500, 1),
('laptop lenovo idea pad',    1, 30, 2200, 1),
('laptop asus zenbook duo',   1, 30, 2100, 1),
('monitor teros gaming te-2', 2, 25, 1050, 1),
('monitor samsung curvo',     2, 15, 1400, 1),
('monitor huawei gamer',      2, 10, 1350, 1),
('teclado seisen gamer',      3, 10,  800, 1),
('teclado antryx gamer',      3, 10, 1000, 1),
('teclado logitech',          3, 10, 1000, 1),
('auricular logitech gamer',  4, 15,  800, 1),
('auricular hyperx gamer',    4, 20,  680, 1),
('auricular redragon rgb',    4, 25,  950, 1),
('memoria kingston rgb',      5, 10,  200, 1),
('ventilador cooler master',  6, 20,  200, 1),
('mini ventilador lenono',    6, 15,  200, 1);
GO
INSERT INTO Menu (nombre, icono, url) VALUES
('DashBoard',        'dashboard',            '/pages/dashboard'),
('Usuarios',         'group',                '/pages/usuarios'),
('Productos',        'collections_bookmark', '/pages/productos'),
('Venta',            'currency_exchange',    '/pages/venta'),
('Historial Ventas', 'edit_note',            '/pages/historial_venta'),
('Reportes',         'receipt',              '/pages/reportes');
GO
-- Administrador: todos los menús
INSERT INTO MenuRol (idMenu, idRol) VALUES (1,1), (2,1), (3,1), (4,1), (5,1), (6,1);
-- Empleado: vender y ver el historial
INSERT INTO MenuRol (idMenu, idRol) VALUES (4,2), (5,2);
-- Supervisor: productos, venta, historial y reportes
INSERT INTO MenuRol (idMenu, idRol) VALUES (3,3), (4,3), (5,3), (6,3);
GO
-- 24 ventas de noviembre 2026. El total se calcula al final desde el detalle.
INSERT INTO Venta (numeroDocumento, tipoPago, total, fechaRegistro) VALUES
('00001', 'Tarjeta', 0, '2026-11-01 12:40'),
('00002', 'Tarjeta', 0, '2026-11-03 10:40'),
('00003', 'Tarjeta', 0, '2026-11-04 17:30'),
('00004', 'Tarjeta', 0, '2026-11-04 12:50'),
('00005', 'Efectivo', 0, '2026-11-05 10:40'),
('00006', 'Tarjeta', 0, '2026-11-07 09:30'),
('00007', 'Tarjeta', 0, '2026-11-07 16:30'),
('00008', 'Tarjeta', 0, '2026-11-08 09:30'),
('00009', 'Tarjeta', 0, '2026-11-09 10:20'),
('00010', 'Efectivo', 0, '2026-11-10 17:00'),
('00011', 'Efectivo', 0, '2026-11-11 09:50'),
('00012', 'Tarjeta', 0, '2026-11-13 10:30'),
('00013', 'Efectivo', 0, '2026-11-14 12:00'),
('00014', 'Tarjeta', 0, '2026-11-15 12:50'),
('00015', 'Tarjeta', 0, '2026-11-16 18:30'),
('00016', 'Efectivo', 0, '2026-11-17 16:00'),
('00017', 'Tarjeta', 0, '2026-11-17 09:00'),
('00018', 'Efectivo', 0, '2026-11-18 10:30'),
('00019', 'Tarjeta', 0, '2026-11-18 13:30'),
('00020', 'Efectivo', 0, '2026-11-21 14:20'),
('00021', 'Tarjeta', 0, '2026-11-21 17:40'),
('00022', 'Efectivo', 0, '2026-11-22 13:50'),
('00023', 'Tarjeta', 0, '2026-11-23 09:10'),
('00024', 'Tarjeta', 0, '2026-11-23 18:00');
GO

-- Detalle: (idVenta, idProducto, cantidad). El precio se copia del producto.
INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, precio, total)
SELECT d.idVenta, d.idProducto, d.cantidad, p.precio, p.precio * d.cantidad
FROM (VALUES
    (1, 7, 2), (2, 5, 1), (2, 14, 1), (2, 15, 1), (3, 2, 2), (4, 2, 2),
    (5, 10, 1), (5, 14, 2), (6, 5, 2), (7, 8, 1), (8, 15, 2), (9, 1, 2),
    (9, 10, 1), (9, 14, 1), (10, 7, 1), (10, 8, 1), (10, 12, 3), (11, 2, 2),
    (12, 4, 1), (13, 4, 1), (14, 8, 1), (14, 12, 2), (14, 15, 1), (15, 6, 1),
    (15, 10, 1), (16, 15, 1), (17, 11, 1), (18, 14, 3), (19, 5, 1), (19, 8, 1),
    (19, 14, 1), (20, 7, 3), (20, 14, 3), (21, 8, 2), (21, 11, 2), (22, 4, 1),
    (23, 11, 1), (24, 6, 1)
) AS d(idVenta, idProducto, cantidad)
JOIN Producto p ON p.idProducto = d.idProducto;
GO

-- Total de cada venta = suma de su detalle
UPDATE v
SET total = s.suma
FROM Venta v
JOIN (SELECT idVenta, SUM(total) AS suma FROM DetalleVenta GROUP BY idVenta) s
  ON s.idVenta = v.idVenta;
GO

-- El stock baja con lo vendido
UPDATE p
SET stock = p.stock - s.vendido
FROM Producto p
JOIN (SELECT idProducto, SUM(cantidad) AS vendido FROM DetalleVenta GROUP BY idProducto) s
  ON s.idProducto = p.idProducto;
GO

INSERT INTO NumeroDocumento (ultimo_Numero, fechaRegistro) VALUES (24, GETDATE());
GO
