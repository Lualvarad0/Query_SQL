-- =====================================================================
-- 01_datos.sql
-- Datos de ejemplo para DBVENTA en PostgreSQL.
-- Incluye los datos originales de "02_INSERTAR DATOS EN TABLAS.txt" y agrega
-- (marcado con NUEVO) lo necesario para practicar JOINs:
--   * una categoría sin productos            -> para LEFT JOIN / anti-join
--   * un producto sin categoría (NULL)       -> para FULL JOIN
--   * dos usuarios más
--   * 12 ventas con su detalle               -> para JOIN + GROUP BY
-- Correr después de 00_esquema_dbventa.sql
-- =====================================================================

INSERT INTO Rol (nombre) VALUES
('Administrador'),
('Empleado'),
('Supervisor');

INSERT INTO Usuario (nombreCompleto, correo, idRol, clave) VALUES
('codigo estudiante', 'code@example.com', 1, '123'),
('maria empleada',    'maria@example.com', 2, '123'),   -- NUEVO
('jose supervisor',   'jose@example.com',  3, '123');   -- NUEVO

INSERT INTO Categoria (nombre, esActivo) VALUES
('Laptops',     TRUE),
('Monitores',   TRUE),
('Teclados',    TRUE),
('Auriculares', TRUE),
('Memorias',    TRUE),
('Accesorios',  TRUE),
('Impresoras',  TRUE);   -- NUEVO: categoría sin productos (id 7)

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
('mini ventilador lenono',    6, 15,  200, TRUE),
('cable hdmi generico',    NULL, 50,   15, TRUE);   -- NUEVO: producto sin categoría (id 16)

INSERT INTO Menu (nombre, icono, url) VALUES
('DashBoard',        'dashboard',            '/pages/dashboard'),
('Usuarios',         'group',                '/pages/usuarios'),
('Productos',        'collections_bookmark', '/pages/productos'),
('Venta',            'currency_exchange',    '/pages/venta'),
('Historial Ventas', 'edit_note',            '/pages/historial_venta'),
('Reportes',         'receipt',              '/pages/reportes');

-- menus para administrador
INSERT INTO MenuRol (idMenu, idRol) VALUES (1,1),(2,1),(3,1),(4,1),(5,1),(6,1);
-- menus para empleado
INSERT INTO MenuRol (idMenu, idRol) VALUES (4,2),(5,2);
-- menus para supervisor
INSERT INTO MenuRol (idMenu, idRol) VALUES (3,3),(4,3),(5,3),(6,3);

-- NUEVO: ventas de octubre y noviembre 2026 (el total se calcula al final)
INSERT INTO Venta (numeroDocumento, tipoPago, total, fechaRegistro) VALUES
('00001', 'Efectivo', 0, '2026-10-02 10:15'),
('00002', 'Tarjeta',  0, '2026-10-05 16:40'),
('00003', 'Efectivo', 0, '2026-10-11 12:05'),
('00004', 'Tarjeta',  0, '2026-10-18 18:30'),
('00005', 'Tarjeta',  0, '2026-10-25 11:00'),
('00006', 'Efectivo', 0, '2026-10-30 09:45'),
('00007', 'Tarjeta',  0, '2026-11-03 15:20'),
('00008', 'Efectivo', 0, '2026-11-07 17:10'),
('00009', 'Tarjeta',  0, '2026-11-12 13:35'),
('00010', 'Efectivo', 0, '2026-11-15 10:50'),
('00011', 'Tarjeta',  0, '2026-11-19 19:05'),
('00012', 'Tarjeta',  0, '2026-11-22 14:25');

-- Detalle: (idVenta, idProducto, cantidad). El precio se copia del producto.
-- Productos que NUNCA se venden: 3, 9, 13, 15 y 16  -> útiles para LEFT JOIN.
INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, precio, total)
SELECT d.idVenta, d.idProducto, d.cantidad, p.precio, p.precio * d.cantidad
FROM (VALUES
    (1, 1, 1), (1, 7, 1),
    (2, 4, 2),
    (3, 11, 3), (3, 14, 2),
    (4, 2, 1), (4, 5, 1), (4, 10, 1),
    (5, 12, 2),
    (6, 6, 1), (6, 8, 1),
    (7, 1, 2),
    (8, 11, 1), (8, 14, 1),
    (9, 2, 1), (9, 12, 1),
    (10, 4, 1), (10, 7, 2),
    (11, 5, 2),
    (12, 1, 1), (12, 10, 2), (12, 11, 1)
) AS d(idVenta, idProducto, cantidad)
JOIN Producto p ON p.idProducto = d.idProducto;   -- ¡tu primer JOIN ya está aquí!

-- El total de cada venta = suma de su detalle (UPDATE ... FROM es sintaxis de PostgreSQL)
UPDATE Venta v
SET total = s.suma
FROM (SELECT idVenta, SUM(total) AS suma FROM DetalleVenta GROUP BY idVenta) s
WHERE s.idVenta = v.idVenta;

INSERT INTO NumeroDocumento (ultimo_Numero, fechaRegistro) VALUES (12, now());
