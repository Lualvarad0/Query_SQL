-- =====================================================================
-- Módulo 09 · Funciones y procedimientos almacenados · EJERCICIOS
-- Las funciones y procedimientos se quedan creados en la base.
-- Las pruebas que modifican datos van dentro de BEGIN ... ROLLBACK.
-- Escribe tu consulta debajo de cada enunciado y compara con "Resultado esperado".
-- Las respuestas están en soluciones.sql de esta misma carpeta (¡inténtalo primero!).
-- =====================================================================

-- 1. Función fn_precio_con_iva(precio) que devuelva el precio con 15 % de IVA, redondeado.
--    Úsala para listar los 3 productos más caros con su precio final.
--    Resultado esperado: 3 filas


-- 2. Función fn_total_cliente(idCliente) que devuelva cuánto ha gastado un cliente en ventas
--    pagadas (0 si nada). Úsala con todos los clientes de Guayaquil.
--    Resultado esperado: 5 filas


-- 3. Función que devuelve una TABLA: fn_ventas_entre(desde, hasta) con documento, fecha,
--    cliente y total de las ventas pagadas en ese rango. Pruébala con la primera semana de noviembre.
--    Resultado esperado: 2 filas


-- 4. Procedimiento sp_registrar_venta que haga TODO lo del ejercicio 8 del módulo 07 en una
--    llamada: recibe cliente, vendedor, tipo de pago y listas de códigos y cantidades; valida
--    el stock, crea la venta con el siguiente número, inserta el detalle, calcula totales y
--    descuenta el stock. Pruébalo vendiendo 2 'AUR-002' y 1 'ACC-004'.
--    Resultado esperado: venta 00061 con subtotal 1405.00, impuesto 210.75 y total 1615.75


-- 5. Prueba el control de errores: intenta vender 10 'mouse logitech g203' (solo hay 4).
--    Atrapa el error en un bloque DO y muestra el mensaje sin que se corte el script.
--    Resultado esperado: el aviso "No se pudo vender: Stock insuficiente..." y ultimo_Numero sigue en 60


-- 6. ¿Función o procedimiento? Responde con tus palabras y luego compara:
--    Función: devuelve un valor o una tabla y se usa DENTRO de un SELECT/WHERE. Debería solo leer.
--    Procedimiento: se ejecuta con CALL (EXEC en T-SQL), hace un proceso de varios pasos que
--    modifica datos y puede manejar transacciones (COMMIT/ROLLBACK) por dentro.
--    Resultado esperado: tu explicación en un comentario
