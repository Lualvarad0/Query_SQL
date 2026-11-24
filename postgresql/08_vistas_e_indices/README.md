# 08 · Vistas e índices

**Objetivo:** guardar consultas que usas siempre (vistas) y hacer que las búsquedas sean rápidas (índices).

## Vistas

```sql
CREATE OR REPLACE VIEW vw_detalle_venta AS
SELECT ... FROM DetalleVenta d JOIN Venta v ON ... JOIN Producto p ON ...;

SELECT * FROM vw_detalle_venta WHERE numeroDocumento = '00006';
```

| | Vista | Vista materializada |
|---|---|---|
| Guarda datos | No, ejecuta la consulta cada vez | Sí, guarda el resultado |
| Siempre actualizada | Sí | No, hasta `REFRESH MATERIALIZED VIEW` |
| Uso típico | Esconder JOINs complicados | Reportes pesados que no cambian a cada minuto |

## Índices

Un índice es como el índice de un libro: evita leer la tabla completa para encontrar algo.

| Tipo | Ejemplo | Cuándo |
|---|---|---|
| Simple | `CREATE INDEX ON Venta (idCliente)` | Columnas de `WHERE` y `JOIN` (¡las llaves foráneas!) |
| Compuesto | `CREATE INDEX ON Venta (estado, fechaRegistro)` | Filtros que siempre van juntos. El orden importa |
| De expresión | `CREATE INDEX ON Cliente (lower(nombreCompleto))` | Búsquedas con funciones |
| Parcial | `CREATE INDEX ON Venta (fechaRegistro) WHERE estado = 'PAGADA'` | Cuando casi siempre filtras lo mismo |

`PRIMARY KEY` y `UNIQUE` crean su índice automáticamente. Las `FOREIGN KEY` **no**.

Los índices tienen costo: ocupan espacio y hacen más lentos los `INSERT` y `UPDATE`. No indexes
todo; indexa lo que de verdad filtras.

## EXPLAIN

`EXPLAIN SELECT ...` muestra cómo PostgreSQL piensa ejecutar la consulta:
`Seq Scan` = lee toda la tabla, `Index Scan` = usa un índice. `EXPLAIN ANALYZE` además la
ejecuta y muestra el tiempo real. Con tablas pequeñas, como las de esta base, PostgreSQL suele
preferir `Seq Scan` aunque haya índice, y está bien.

## Diferencias con SQL Server

| PostgreSQL | SQL Server |
|---|---|
| `CREATE OR REPLACE VIEW` | `CREATE OR ALTER VIEW` |
| Vista materializada | "Indexed view" (`WITH SCHEMABINDING` + índice clustered) |
| Índice parcial | "Filtered index" (mismo `WHERE`) |
| Índice de expresión | Columna calculada + índice sobre ella |
| `EXPLAIN` | Plan de ejecución en SSMS (Ctrl+M) |

**Siguiente:** [09 · Funciones y procedimientos](../09_funciones_y_procedimientos/)
