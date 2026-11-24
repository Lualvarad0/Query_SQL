-- =====================================================================
-- PASO 2 · Datos de ejemplo
-- Los datos originales del proyecto (antes en un .txt), más:
--   - 2 usuarios (un empleado y un supervisor) para probar el login por rol
--   - 24 ventas de noviembre 2026 con su detalle, para que el dashboard,
--     el historial y los reportes tengan algo que mostrar
-- Productos que nunca se venden: 'laptop asus zenbook duo', 'teclado logitech'
-- y 'memoria kingston rgb' (útil para los ejercicios con LEFT JOIN).
-- Corre después de 01_crear_base_y_tablas.sql
-- =====================================================================

INSERT INTO Rol (nombre) VALUES
('Administrador'),
('Empleado'),
('Supervisor');

INSERT INTO Usuario (nombreCompleto, correo, idRol, clave) VALUES
('codigo estudiante', 'code@example.com',  1, '123'),
('maria empleada',    'maria@example.com', 2, '123'),
('jose supervisor',   'jose@example.com',  3, '123');

INSERT INTO Categoria (nombre, esActivo) VALUES
('Laptops', TRUE), ('Monitores', TRUE), ('Teclados', TRUE),
('Auriculares', TRUE), ('Memorias', TRUE), ('Accesorios', TRUE);

INSERT INTO Producto (nombre, idCategoria, stock, precio, esActivo) VALUES
('laptop samsung book pro',   1, 20, 2500, TRUE),
('laptop lenovo idea pad',    1, 30, 2200, TRUE),
('laptop asus zenbook duo',   1, 30, 2100, TRUE),
('monitor teros gaming te-2', 2, 25, 1050, TRUE),
('monitor samsung curvo',     2, 15, 1400, TRUE),
('monitor huawei gamer',      2, 10, 1350, TRUE),
('teclado seisen gamer',      3, 10,  800, TRUE),
('teclado antryx gamer',      3, 10, 1000, TRUE),
('teclado logitech',          3, 10, 1000, TRUE),
('auricular logitech gamer',  4, 15,  800, TRUE),
('auricular hyperx gamer',    4, 20,  680, TRUE),
('auricular redragon rgb',    4, 25,  950, TRUE),
('memoria kingston rgb',      5, 10,  200, TRUE),
('ventilador cooler master',  6, 20,  200, TRUE),
('mini ventilador lenono',    6, 15,  200, TRUE);

INSERT INTO Menu (nombre, icono, url) VALUES
('DashBoard',        'dashboard',            '/pages/dashboard'),
('Usuarios',         'group',                '/pages/usuarios'),
('Productos',        'collections_bookmark', '/pages/productos'),
('Venta',            'currency_exchange',    '/pages/venta'),
('Historial Ventas', 'edit_note',            '/pages/historial_venta'),
('Reportes',         'receipt',              '/pages/reportes');

-- Administrador: todos los menús
INSERT INTO MenuRol (idMenu, idRol) VALUES (1,1), (2,1), (3,1), (4,1), (5,1), (6,1);
-- Empleado: vender y ver el historial
INSERT INTO MenuRol (idMenu, idRol) VALUES (4,2), (5,2);
-- Supervisor: productos, venta, historial y reportes
INSERT INTO MenuRol (idMenu, idRol) VALUES (3,3), (4,3), (5,3), (6,3);

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

-- Total de cada venta = suma de su detalle (T-SQL: UPDATE v SET ... FROM Venta v JOIN ...)
UPDATE Venta v
SET total = s.suma
FROM (SELECT idVenta, SUM(total) AS suma FROM DetalleVenta GROUP BY idVenta) s
WHERE s.idVenta = v.idVenta;

-- El stock baja con lo vendido
UPDATE Producto p
SET stock = p.stock - s.vendido
FROM (SELECT idProducto, SUM(cantidad) AS vendido FROM DetalleVenta GROUP BY idProducto) s
WHERE s.idProducto = p.idProducto;

INSERT INTO NumeroDocumento (ultimo_Numero) VALUES (24);
