-- =====================================================================
-- Módulo 08 · Vistas e índices · EJERCICIOS
-- Este módulo SÍ crea objetos que se quedan en la base (vistas e índices).
-- Puedes volver a correrlo: usa CREATE OR REPLACE / IF NOT EXISTS.
-- Escribe tu consulta debajo de cada enunciado y compara con "Resultado esperado".
-- Las respuestas están en soluciones.sql de esta misma carpeta (¡inténtalo primero!).
-- =====================================================================

-- 1. Crea la vista vw_detalle_venta con una fila por línea vendida: documento, fecha, estado,
--    cliente (o 'Consumidor final'), ciudad, vendedor, producto, categoría, cantidad, total de la
--    línea y ganancia de la línea. Luego úsala para ver la venta '00006'.
--    Resultado esperado: 4 filas


-- 2. Usando SOLO la vista: ganancia total por vendedor en ventas pagadas.
--    Resultado esperado: 5 filas


-- 3. Crea una vista materializada mv_ventas_mensuales (mes, ventas, total) de ventas pagadas,
--    consúltala, y explica cuándo hay que refrescarla.
--    Resultado esperado: 5 filas


-- 4. Mira el plan de ejecución de buscar un cliente por documento y de buscarlo por nombre.
--    ¿Cuál usa índice?
--    Resultado esperado: la primera usa "Index Scan using cliente_documento_key", la segunda "Seq Scan"


-- 5. Crea un índice para búsquedas por nombre de cliente sin importar mayúsculas y comprueba
--    que el plan puede usarlo.
--    Resultado esperado: "Index Scan using ix_cliente_nombre_lower"


-- 6. Crea un índice compuesto para el reporte "ventas pagadas por rango de fechas" y un índice
--    parcial solo con ventas pagadas. Lista los índices de la tabla Venta.
--    Resultado esperado: 6 índices (PK, UNIQUE de numeroDocumento, los 2 del esquema y los 2 nuevos)
