-- =====================================================================
-- Módulo 10 · Triggers (disparadores) · EJERCICIOS
-- Lee primero el README.md de esta carpeta: explica cuándo SÍ y cuándo NO usar un trigger.
-- Los triggers se quedan creados. Las pruebas van dentro de BEGIN ... ROLLBACK.
-- Para quitarlos todos: vuelve a correr 00_base_de_datos/instalar.sql
-- En PostgreSQL un trigger son 2 piezas: una FUNCIÓN que RETURNS trigger y el TRIGGER que la llama.
-- Escribe tu consulta debajo de cada enunciado y compara con "Resultado esperado".
-- Las respuestas están en soluciones.sql de esta misma carpeta (¡inténtalo primero!).
-- =====================================================================

-- 1. AUDITORÍA. Cada vez que cambie el precio de un producto, guarda en AuditoriaPrecio el
--    producto, el precio anterior, el nuevo, quién lo cambió y cuándo. Prueba subiendo el
--    precio de 'teclado logitech' dos veces.
--    Resultado esperado: 2 filas: 1000.00 -> 1050.00 y 1050.00 -> 1100.00


-- 2. COMPLETAR DATOS (BEFORE). Al insertar en DetalleVenta, si no mandan el precio, cópialo del
--    producto, y calcula siempre el total de la línea con el descuento. Así nadie puede guardar
--    un total mal calculado.
--    Resultado esperado: precio 680.00 y total 1224.00 (680 x 2 - 10 %)


-- 3. INVENTARIO (AFTER). Al vender (insertar en DetalleVenta) descuenta el stock del producto y
--    registra el movimiento en MovimientoInventario. Si no hay stock suficiente, rechaza la venta.
--    Resultado esperado: stock del mouse en 1 y 1 movimiento SALIDA "Venta 00060"


-- 4. TOTALES DERIVADOS. Mantén subtotal, impuesto y total de Venta siempre sincronizados con su
--    detalle: recalcula cuando se inserta, cambia o borra una línea. Usa un trigger por sentencia
--    (FOR EACH STATEMENT) con tablas de transición para no recalcular fila por fila.
--    Resultado esperado: el subtotal sube 418.00 (2 x 200 + 18) al insertar y vuelve al valor original al borrar


-- 5. PROTEGER DATOS. Impide modificar o borrar el detalle de una venta ANULADA (BEFORE que
--    lanza error). Pruébalo con la venta '00009', que está anulada.
--    Resultado esperado: aviso "Bloqueado: La venta 9 está anulada..." y las líneas siguen ahí


-- 6. Lista los triggers que creaste y en qué tabla y momento se disparan.
--    Resultado esperado: 7 triggers (1 en producto, 6 en detalleventa)


-- 7. Prueba final: con los triggers activos, una venta completa son solo 2 INSERT.
--    Compáralo con los 4 pasos manuales del ejercicio 8 del módulo 07.
--    Resultado esperado: total 1615.75, stock_mouse 3 y 2 movimientos: lo mismo que antes, sin pasos manuales
