-- =====================================================================
-- 02_datos.sql · Datos de ejemplo para DBVENTA
-- Generados una sola vez y fijos: todos obtienen los mismos resultados,
-- así los ejercicios pueden decir cuántas filas debe devolver cada consulta.
--
-- Casos especiales a propósito (los vas a necesitar en los ejercicios):
--   * Ciudad 'Esmeraldas' sin clientes ni proveedores
--   * Cliente 'Valeria Paredes' registrado pero sin compras
--   * Categoría 'Impresoras' sin productos
--   * Producto 'cable hdmi generico' sin categoría (NULL)
--   * Proveedor 'Distribuidora Andina' sin productos
--   * Productos que nunca se vendieron
--   * Usuario 'pedro inactivo' sin ventas, y el administrador sin jefe
--   * 3 ventas ANULADAS (no deben sumar en los reportes)
-- =====================================================================

INSERT INTO Rol (nombre) VALUES ('Administrador'), ('Empleado'), ('Supervisor');

INSERT INTO Menu (nombre, icono, url) VALUES
('DashBoard',        'dashboard',            '/pages/dashboard'),
('Usuarios',         'group',                '/pages/usuarios'),
('Productos',        'collections_bookmark', '/pages/productos'),
('Venta',            'currency_exchange',    '/pages/venta'),
('Historial Ventas', 'edit_note',            '/pages/historial_venta'),
('Reportes',         'receipt',              '/pages/reportes');

INSERT INTO MenuRol (idMenu, idRol) VALUES
(1,1),(2,1),(3,1),(4,1),(5,1),(6,1),   -- administrador: todo
(4,2),(5,2),                           -- empleado
(3,3),(4,3),(5,3),(6,3);               -- supervisor

-- Jerarquía: 1 admin -> 2 supervisores -> empleados
INSERT INTO Usuario (nombreCompleto, correo, idRol, idJefe, clave, esActivo) VALUES
('codigo estudiante', 'code@example.com',   1, NULL, '123', TRUE),   -- 1
('jose supervisor',   'jose@example.com',   3, 1,    '123', TRUE),   -- 2
('ana supervisora',   'ana@example.com',    3, 1,    '123', TRUE),   -- 3
('maria empleada',    'maria@example.com',  2, 2,    '123', TRUE),   -- 4
('luis empleado',     'luis@example.com',   2, 2,    '123', TRUE),   -- 5
('carla empleada',    'carla@example.com',  2, 3,    '123', TRUE),   -- 6
('pedro inactivo',    'pedro@example.com',  2, 3,    '123', FALSE);  -- 7

INSERT INTO Ciudad (nombre, provincia) VALUES
('Guayaquil','Guayas'), ('Quito','Pichincha'), ('Cuenca','Azuay'), ('Manta','Manabí'),
('Ambato','Tungurahua'), ('Loja','Loja'), ('Machala','El Oro'), ('Esmeraldas','Esmeraldas');

-- Clientes (personas con cédula y empresas con RUC). El 15 nunca compró.
INSERT INTO Cliente (documento, nombreCompleto, correo, telefono, idCiudad, fechaRegistro) VALUES
('0912345678', 'Carlos Mendoza', 'carlos.m@example.com', '0991111111', 1, '2026-01-15'),
('1712345678', 'Lucía Andrade', 'lucia.a@example.com', NULL, 2, '2026-02-03'),
('0112345678', 'Andrés Vega', NULL, '0993333333', 3, '2026-02-20'),
('1312345678', 'Gabriela Torres', 'gaby.t@example.com', '0994444444', 4, '2026-03-11'),
('0923456789', 'Miguel Castro', 'miguel.c@example.com', '0995555555', 1, '2026-03-28'),
('1723456789', 'Sofía Herrera', 'sofia.h@example.com', '0996666666', 2, '2026-04-09'),
('1812345678', 'Diego Ramírez', NULL, NULL, 5, '2026-04-22'),
('1112345678', 'Paola Jiménez', 'paola.j@example.com', '0998888888', 6, '2026-05-05'),
('0712345678', 'Fernando Ruiz', 'fer.r@example.com', '0999999999', 7, '2026-05-19'),
('0934567890', 'Daniela Morales', 'dani.m@example.com', '0981111111', 1, '2026-06-02'),
('1734567890', 'Ricardo Salazar', 'ricardo.s@example.com', NULL, 2, '2026-06-16'),
('0123456789', 'Elena Cordero', 'elena.c@example.com', '0983333333', 3, '2026-07-01'),
('0992345678001', 'Tecnología Global S.A.', 'compras@tecglobal.example.com', '042555000', 1, '2026-07-14'),
('1792345678001', 'Oficinas Pichincha Cía. Ltda.', 'info@ofipich.example.com', '022444000', 2, '2026-08-01'),
('0945678901', 'Valeria Paredes', 'vale.p@example.com', '0985555555', 1, '2026-11-10');

INSERT INTO Categoria (nombre, esActivo) VALUES
('Laptops',TRUE), ('Monitores',TRUE), ('Teclados',TRUE), ('Auriculares',TRUE),
('Memorias',TRUE), ('Accesorios',TRUE), ('Impresoras',TRUE);   -- Impresoras (7) sin productos

INSERT INTO Proveedor (nombre, ruc, idCiudad) VALUES
('TecnoImport S.A.',        '0990011223001', 1),   -- 1
('CompuAndes Cía. Ltda.',   '1790022334001', 2),   -- 2
('Gamer Store Ecuador',     '0990033445001', 1),   -- 3
('Austro Digital',          '0190044556001', 3),   -- 4
('Distribuidora Andina',    '1790055667001', 2);   -- 5: sin productos

-- Productos: los 15 originales + 3 nuevos. costo = lo que pagamos al proveedor.
-- 'cable hdmi generico' no tiene categoría ni proveedor. Dos productos están bajo su stock mínimo.
INSERT INTO Producto (codigo, nombre, idCategoria, idProveedor, stock, stockMinimo, costo, precio) VALUES
('LAP-001', 'laptop samsung book pro', 1, 1, 20, 5, 1900, 2500),
('LAP-002', 'laptop lenovo idea pad', 1, 2, 30, 5, 1650, 2200),
('LAP-003', 'laptop asus zenbook duo', 1, 2, 30, 5, 1600, 2100),
('MON-001', 'monitor teros gaming te-2', 2, 3, 25, 5, 760, 1050),
('MON-002', 'monitor samsung curvo', 2, 1, 15, 5, 1050, 1400),
('MON-003', 'monitor huawei gamer', 2, 4, 10, 5, 990, 1350),
('TEC-001', 'teclado seisen gamer', 3, 3, 10, 5, 520, 800),
('TEC-002', 'teclado antryx gamer', 3, 3, 10, 5, 690, 1000),
('TEC-003', 'teclado logitech', 3, 1, 10, 5, 700, 1000),
('AUR-001', 'auricular logitech gamer', 4, 1, 15, 5, 540, 800),
('AUR-002', 'auricular hyperx gamer', 4, 3, 20, 5, 450, 680),
('AUR-003', 'auricular redragon rgb', 4, 3, 25, 5, 640, 950),
('MEM-001', 'memoria kingston rgb', 5, 4, 10, 5, 130, 200),
('ACC-001', 'ventilador cooler master', 6, 4, 20, 5, 120, 200),
('ACC-002', 'mini ventilador lenono', 6, 2, 15, 5, 110, 200),
('ACC-003', 'cable hdmi generico', NULL, NULL, 50, 5, 6, 15),
('ACC-004', 'mouse logitech g203', 6, 1, 4, 5, 28, 45),
('MEM-002', 'memoria usb sandisk 64gb', 5, 4, 3, 5, 10, 18);

-- 60 ventas entre julio y noviembre 2026. idCliente NULL = consumidor final.
-- subtotal, impuesto y total se calculan al final a partir del detalle.
INSERT INTO Venta (numeroDocumento, idCliente, idUsuario, tipoPago, estado, fechaRegistro) VALUES
('00001', 13, 6, 'Transferencia', 'PAGADA', '2026-07-01 15:40'),
('00002', 9, 3, 'Transferencia', 'PAGADA', '2026-07-02 09:55'),
('00003', 9, 6, 'Tarjeta', 'PAGADA', '2026-07-04 16:55'),
('00004', 11, 6, 'Transferencia', 'PAGADA', '2026-07-10 09:10'),
('00005', 1, 5, 'Transferencia', 'PAGADA', '2026-07-12 17:50'),
('00006', 3, 6, 'Efectivo', 'PAGADA', '2026-07-15 13:35'),
('00007', 10, 4, 'Efectivo', 'PAGADA', '2026-07-19 17:05'),
('00008', 13, 6, 'Tarjeta', 'PAGADA', '2026-07-21 18:45'),
('00009', 13, 5, 'Transferencia', 'ANULADA', '2026-07-26 11:10'),
('00010', 1, 5, 'Efectivo', 'PAGADA', '2026-07-27 15:05'),
('00011', 6, 6, 'Transferencia', 'PAGADA', '2026-07-29 13:35'),
('00012', 1, 4, 'Efectivo', 'PAGADA', '2026-07-31 17:30'),
('00013', 11, 6, 'Tarjeta', 'PAGADA', '2026-08-02 11:10'),
('00014', 8, 6, 'Tarjeta', 'PAGADA', '2026-08-06 11:20'),
('00015', 14, 2, 'Efectivo', 'PAGADA', '2026-08-07 13:05'),
('00016', 9, 4, 'Efectivo', 'PAGADA', '2026-08-09 11:25'),
('00017', 2, 4, 'Efectivo', 'PAGADA', '2026-08-10 10:20'),
('00018', NULL, 6, 'Tarjeta', 'PAGADA', '2026-08-13 11:20'),
('00019', 9, 5, 'Tarjeta', 'PAGADA', '2026-08-14 10:50'),
('00020', 10, 3, 'Tarjeta', 'PAGADA', '2026-08-15 18:15'),
('00021', 6, 3, 'Tarjeta', 'PAGADA', '2026-08-16 13:55'),
('00022', 2, 3, 'Efectivo', 'PAGADA', '2026-08-17 09:55'),
('00023', 7, 5, 'Transferencia', 'PAGADA', '2026-08-18 13:00'),
('00024', 11, 6, 'Tarjeta', 'PAGADA', '2026-08-20 17:00'),
('00025', 7, 5, 'Tarjeta', 'PAGADA', '2026-08-21 17:35'),
('00026', 1, 4, 'Transferencia', 'PAGADA', '2026-08-24 12:35'),
('00027', 4, 6, 'Tarjeta', 'ANULADA', '2026-08-27 18:20'),
('00028', 9, 4, 'Efectivo', 'PAGADA', '2026-08-28 13:25'),
('00029', 1, 6, 'Tarjeta', 'PAGADA', '2026-08-29 13:45'),
('00030', 5, 5, 'Tarjeta', 'PAGADA', '2026-08-31 11:20'),
('00031', 13, 4, 'Efectivo', 'PAGADA', '2026-09-01 15:25'),
('00032', 9, 2, 'Tarjeta', 'PAGADA', '2026-09-02 09:05'),
('00033', 10, 3, 'Tarjeta', 'PAGADA', '2026-09-04 11:45'),
('00034', 2, 6, 'Efectivo', 'PAGADA', '2026-09-07 13:50'),
('00035', 5, 4, 'Tarjeta', 'PAGADA', '2026-09-09 16:20'),
('00036', 3, 6, 'Tarjeta', 'PAGADA', '2026-09-10 15:25'),
('00037', 14, 5, 'Transferencia', 'PAGADA', '2026-09-12 13:25'),
('00038', 5, 6, 'Transferencia', 'PAGADA', '2026-09-13 10:20'),
('00039', 2, 6, 'Tarjeta', 'PAGADA', '2026-09-20 15:25'),
('00040', 12, 5, 'Transferencia', 'PAGADA', '2026-09-21 13:40'),
('00041', 14, 5, 'Efectivo', 'PAGADA', '2026-09-25 10:50'),
('00042', NULL, 4, 'Efectivo', 'PAGADA', '2026-09-26 18:50'),
('00043', 11, 5, 'Efectivo', 'PAGADA', '2026-09-29 12:45'),
('00044', 8, 5, 'Tarjeta', 'PAGADA', '2026-09-30 17:15'),
('00045', 1, 5, 'Tarjeta', 'PAGADA', '2026-10-01 16:10'),
('00046', 14, 3, 'Tarjeta', 'PAGADA', '2026-10-04 18:00'),
('00047', 6, 3, 'Tarjeta', 'PAGADA', '2026-10-06 14:50'),
('00048', 8, 6, 'Tarjeta', 'ANULADA', '2026-10-12 12:00'),
('00049', 10, 4, 'Tarjeta', 'PAGADA', '2026-10-13 15:40'),
('00050', 3, 5, 'Tarjeta', 'PAGADA', '2026-10-14 13:10'),
('00051', 9, 5, 'Tarjeta', 'PAGADA', '2026-10-16 18:35'),
('00052', NULL, 3, 'Tarjeta', 'PAGADA', '2026-10-21 17:00'),
('00053', 14, 4, 'Tarjeta', 'PAGADA', '2026-10-23 15:15'),
('00054', 4, 3, 'Tarjeta', 'PAGADA', '2026-11-03 12:55'),
('00055', 1, 6, 'Tarjeta', 'PAGADA', '2026-11-06 14:30'),
('00056', 10, 2, 'Tarjeta', 'PAGADA', '2026-11-09 16:30'),
('00057', 2, 3, 'Transferencia', 'PAGADA', '2026-11-14 13:00'),
('00058', 2, 4, 'Tarjeta', 'PAGADA', '2026-11-15 11:00'),
('00059', 12, 5, 'Tarjeta', 'PAGADA', '2026-11-17 17:05'),
('00060', 14, 6, 'Efectivo', 'PAGADA', '2026-11-18 12:40');

-- Detalle: (idVenta, idProducto, cantidad, descuento %). El precio se copia del producto.
INSERT INTO DetalleVenta (idVenta, idProducto, cantidad, precio, descuento, total)
SELECT d.idVenta, d.idProducto, d.cantidad, p.precio, d.descuento,
       ROUND(p.precio * d.cantidad * (1 - d.descuento / 100), 2)
FROM (VALUES
    (1, 5, 2, 5), (1, 8, 2, 0), (1, 17, 2, 0), (2, 2, 1, 10), (2, 17, 5, 10),
    (3, 10, 2, 0), (3, 11, 1, 0), (3, 15, 1, 0), (4, 5, 2, 0), (4, 17, 5, 0),
    (5, 10, 3, 5), (6, 2, 2, 0), (6, 5, 2, 0), (6, 10, 1, 0), (6, 14, 2, 5),
    (7, 1, 3, 0), (7, 5, 1, 0), (7, 11, 1, 10), (8, 4, 3, 5), (8, 11, 1, 0),
    (8, 18, 5, 10), (9, 11, 1, 0), (9, 15, 1, 0), (10, 11, 1, 10), (11, 4, 2, 5),
    (11, 11, 1, 10), (11, 12, 3, 0), (12, 10, 1, 0), (12, 11, 3, 10), (12, 14, 1, 0),
    (12, 17, 2, 5), (13, 11, 2, 0), (13, 17, 2, 0), (14, 4, 2, 0), (14, 11, 2, 5),
    (15, 8, 3, 0), (15, 12, 1, 0), (16, 4, 1, 5), (16, 11, 1, 10), (16, 14, 2, 0),
    (17, 1, 1, 5), (17, 7, 1, 0), (17, 12, 2, 0), (17, 15, 1, 0), (18, 1, 1, 0),
    (18, 18, 3, 0), (19, 11, 2, 0), (19, 12, 2, 0), (20, 7, 1, 0), (20, 12, 3, 10),
    (20, 17, 5, 0), (21, 6, 2, 0), (21, 17, 2, 5), (22, 2, 1, 5), (23, 7, 3, 0),
    (23, 14, 1, 0), (24, 4, 1, 0), (25, 11, 2, 0), (25, 12, 1, 10), (25, 17, 3, 0),
    (25, 18, 1, 10), (26, 4, 1, 0), (26, 7, 1, 0), (26, 17, 5, 5), (26, 18, 5, 10),
    (27, 17, 5, 0), (27, 18, 2, 0), (28, 11, 3, 5), (29, 2, 1, 0), (29, 7, 3, 5),
    (29, 11, 3, 0), (30, 4, 1, 5), (30, 14, 3, 0), (31, 6, 1, 0), (32, 7, 1, 5),
    (33, 2, 1, 0), (33, 17, 3, 5), (34, 11, 2, 5), (34, 12, 1, 0), (34, 17, 1, 0),
    (35, 10, 1, 10), (35, 11, 3, 0), (36, 7, 1, 0), (36, 11, 2, 10), (36, 14, 2, 10),
    (36, 17, 2, 0), (37, 4, 1, 0), (37, 12, 1, 5), (38, 11, 1, 10), (39, 6, 2, 10),
    (39, 7, 1, 0), (40, 10, 1, 0), (40, 17, 2, 10), (41, 15, 2, 0), (42, 4, 1, 0),
    (43, 2, 1, 0), (43, 8, 2, 0), (43, 11, 1, 5), (44, 6, 2, 0), (44, 10, 1, 0),
    (45, 4, 3, 0), (45, 5, 1, 0), (46, 11, 2, 5), (46, 17, 3, 0), (47, 11, 2, 10),
    (47, 18, 1, 5), (48, 4, 3, 0), (48, 14, 1, 5), (48, 17, 3, 0), (49, 11, 1, 10),
    (49, 14, 2, 0), (49, 18, 1, 0), (50, 4, 1, 10), (50, 14, 1, 0), (51, 7, 3, 0),
    (51, 10, 1, 0), (51, 11, 1, 10), (52, 6, 1, 0), (52, 14, 2, 0), (52, 17, 1, 0),
    (53, 4, 3, 0), (53, 8, 1, 10), (53, 17, 5, 5), (53, 18, 5, 0), (54, 2, 2, 0),
    (54, 4, 2, 0), (54, 10, 3, 10), (54, 12, 1, 0), (55, 2, 1, 5), (55, 10, 1, 0),
    (56, 2, 2, 0), (56, 18, 1, 0), (57, 2, 2, 0), (57, 15, 2, 0), (57, 18, 2, 0),
    (58, 18, 1, 5), (59, 5, 3, 0), (59, 18, 2, 0), (60, 4, 1, 0), (60, 5, 2, 0)
) AS d(idVenta, idProducto, cantidad, descuento)
JOIN Producto p ON p.idProducto = d.idProducto;

-- Totales de cada venta a partir de su detalle (UPDATE ... FROM es sintaxis de PostgreSQL)
UPDATE Venta v
SET subtotal = s.suma,
    impuesto = ROUND(s.suma * 0.15, 2),
    total    = s.suma + ROUND(s.suma * 0.15, 2)
FROM (SELECT idVenta, SUM(total) AS suma FROM DetalleVenta GROUP BY idVenta) s
WHERE s.idVenta = v.idVenta;

INSERT INTO NumeroDocumento (ultimo_Numero) VALUES (60);
