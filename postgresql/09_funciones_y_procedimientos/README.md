# 09 · Funciones y procedimientos almacenados

**Objetivo:** guardar lógica dentro de la base: cálculos reutilizables (funciones) y procesos de
varios pasos (procedimientos).

## Función vs procedimiento

| | Función | Procedimiento |
|---|---|---|
| Se usa | Dentro de un `SELECT` / `WHERE` | Con `CALL` (T-SQL: `EXEC`) |
| Devuelve | Un valor o una tabla | Nada (o parámetros de salida) |
| Para qué | Calcular o consultar | Procesos que modifican datos |
| Transacciones propias | No | Sí, puede hacer `COMMIT` / `ROLLBACK` por dentro |

## Anatomía en PostgreSQL

```sql
CREATE OR REPLACE FUNCTION fn_total_cliente(p_idCliente INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT SUM(total) INTO v_total FROM Venta WHERE idCliente = p_idCliente;
    RETURN COALESCE(v_total, 0);
END;
$$;
```

- `$$ ... $$` encierra el cuerpo (así no tienes que escapar comillas).
- `LANGUAGE sql` para funciones de una sola consulta; `plpgsql` cuando necesitas variables,
  `IF`, `LOOP` o manejo de errores.
- `RAISE EXCEPTION 'mensaje %', valor;` lanza un error y deshace todo.
- `RAISE NOTICE` muestra un mensaje sin cortar nada.

## Diferencias con SQL Server

| Qué | PostgreSQL | SQL Server (T-SQL) |
|---|---|---|
| Variables | `v_total NUMERIC;` en `DECLARE` | `DECLARE @total DECIMAL(12,2);` |
| Asignar desde consulta | `SELECT ... INTO v_total` | `SELECT @total = SUM(total) ...` |
| Crear o cambiar | `CREATE OR REPLACE` | `CREATE OR ALTER` |
| Ejecutar procedimiento | `CALL sp_x(1, 2);` | `EXEC dbo.sp_x 1, 2;` |
| Errores | `RAISE EXCEPTION` / `EXCEPTION WHEN OTHERS` | `THROW` / `BEGIN TRY ... BEGIN CATCH` |
| Listas como parámetro | Arreglos `INT[]` | Table-valued parameters o JSON |
| Lenguaje | PL/pgSQL (también Python, etc.) | Solo T-SQL (o CLR) |

**Siguiente:** [10 · Triggers](../10_triggers/)
