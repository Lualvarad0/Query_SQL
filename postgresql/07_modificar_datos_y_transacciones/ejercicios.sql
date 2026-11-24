-- =====================================================================
-- Módulo 07 · INSERT, UPDATE, DELETE y transacciones · EJERCICIOS
-- Cada ejercicio corre dentro de BEGIN ... ROLLBACK, así la base vuelve a
-- quedar como estaba y los demás módulos siguen dando los mismos resultados.
-- Cuando practiques de verdad, cambia ROLLBACK por COMMIT para guardar.
-- Escribe tu consulta debajo de cada enunciado y compara con "Resultado esperado".
-- Las respuestas están en soluciones.sql de esta misma carpeta (¡inténtalo primero!).
-- =====================================================================

-- 1. Registra un cliente nuevo de Loja y muestra el id que le asignó la base.
--    Resultado esperado: 1 fila con idCliente 16 (o mayor si ya lo corriste: un ROLLBACK no devuelve los números de la secuencia)


-- 2. Agrega dos ciudades en una sola sentencia y luego cuenta cuántas ciudades hay.
--    Resultado esperado: 10 ciudades


-- 3. INSERT ... SELECT: crea una tabla temporal con los clientes "VIP" (más de 15000 en compras
--    pagadas) y muéstrala.
--    Resultado esperado: 5 clientes, encabezados por Carlos Mendoza con 25949.75


-- 4. Sube 5 % el precio de todos los Monitores (por nombre de categoría, no por id)
--    y muestra cómo quedaron.
--    Resultado esperado: 3 monitores con precios 1102.50, 1417.50 y 1470.00


-- 5. Desactiva (esActivo = FALSE) los productos del proveedor 'Austro Digital'.
--    ¿Cuántas filas se modificaron?
--    Resultado esperado: 4 filas (UPDATE 4)


-- 6. Intenta borrar las ventas ANULADAS. ¿Qué error da? Bórralas bien (con su detalle)
--    dentro de la transacción.
--    Resultado esperado: 57 ventas restantes


-- 7. "UPSERT": registra al cliente con documento '0912345678' con el teléfono '0990000000'.
--    Si ya existe, solo actualiza el teléfono.
--    Resultado esperado: 1 fila: idCliente 1 con el teléfono nuevo (no se creó otro cliente)


-- 8. Transacción completa: registra la venta '00061' a 'Lucía Andrade' (vendedora maria) con
--    2 'auricular hyperx gamer' y 1 'mouse logitech g203', calcula totales, descuenta stock
--    y actualiza NumeroDocumento. Si algo falla, nada debe quedar a medias.
--    Resultado esperado: subtotal 1405.00, impuesto 210.75, total 1615.75 y stock_mouse 3


-- 9. SAVEPOINT: dentro de una transacción, sube el precio del 'teclado logitech', guarda un punto,
--    bórralo por error, vuelve al punto y comprueba que el producto sigue existiendo.
--    Resultado esperado: 1 fila con precio 1050.00 (el borrado se deshizo, la subida de precio no)
