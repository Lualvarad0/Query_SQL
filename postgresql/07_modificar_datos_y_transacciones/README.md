# 07 · Modificar datos y transacciones

**Objetivo:** insertar, actualizar y borrar datos sin romper nada, y agrupar varios cambios en una
transacción que se guarda completa o no se guarda.

> Todos los ejercicios van entre `BEGIN;` y `ROLLBACK;`, así puedes repetirlos sin dañar la base.
> Cambia `ROLLBACK` por `COMMIT` cuando quieras guardar de verdad.

## Las 3 sentencias

```sql
INSERT INTO Ciudad (nombre, provincia) VALUES ('Riobamba', 'Chimborazo');
UPDATE Producto SET precio = precio * 1.05 WHERE idCategoria = 2;
DELETE FROM Cliente WHERE idCliente = 15;
```

**Antes de cada `UPDATE` o `DELETE`, corre un `SELECT` con el mismo `WHERE`.** Un `UPDATE` sin
`WHERE` cambia todas las filas de la tabla.

## Transacciones

```sql
BEGIN;                         -- T-SQL: BEGIN TRANSACTION
  ... varios cambios ...
COMMIT;                        -- guarda todo
-- o ROLLBACK;                 -- deshace todo
```

Una venta son varios pasos (venta, detalle, stock, número de documento). Si falla uno a la
mitad, la transacción evita que quede una venta sin detalle o un stock mal descontado.
`SAVEPOINT` permite deshacer solo una parte.

## Diferencias con SQL Server

| Qué | PostgreSQL | SQL Server |
|---|---|---|
| Obtener el id insertado | `INSERT ... RETURNING idCliente` | `OUTPUT inserted.idCliente` o `SCOPE_IDENTITY()` |
| UPDATE con JOIN | `UPDATE p SET ... FROM Categoria c WHERE ...` | `UPDATE p SET ... FROM Producto p JOIN Categoria c ON ...` |
| Insertar o actualizar | `INSERT ... ON CONFLICT (col) DO UPDATE` | `MERGE` |
| Tabla temporal | `CREATE TEMP TABLE t (...)` | `CREATE TABLE #t (...)` |
| Punto de guardado | `SAVEPOINT x` / `ROLLBACK TO SAVEPOINT x` | `SAVE TRANSACTION x` / `ROLLBACK TRANSACTION x` |

**Siguiente:** [08 · Vistas e índices](../08_vistas_e_indices/)
