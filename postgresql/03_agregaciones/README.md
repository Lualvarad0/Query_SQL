# 03 · Funciones de agregación, GROUP BY y HAVING

**Objetivo:** resumir muchas filas en números: cuántas ventas, cuánto dinero, promedio por mes.

## Funciones de agregación

| Función | Devuelve |
|---|---|
| `COUNT(*)` | Número de filas |
| `COUNT(columna)` | Número de valores **no nulos** de esa columna |
| `COUNT(DISTINCT columna)` | Número de valores distintos |
| `SUM`, `AVG`, `MIN`, `MAX` | Suma, promedio, mínimo, máximo |

## GROUP BY y HAVING

```sql
SELECT tipoPago, COUNT(*) AS ventas, SUM(total) AS total
FROM Venta
WHERE estado = 'PAGADA'          -- 1. filtra filas
GROUP BY tipoPago                -- 2. arma un grupo por cada tipo de pago
HAVING SUM(total) > 50000        -- 3. filtra grupos
ORDER BY total DESC;
```

**Regla de oro:** toda columna del `SELECT` que no esté dentro de una función de agregación
debe estar en el `GROUP BY`.

**WHERE vs HAVING:** `WHERE` decide qué filas entran a los grupos; `HAVING` decide qué grupos
salen. Si el filtro no usa `SUM`, `COUNT`, etc., va en `WHERE`.

## Fechas útiles

| Qué | PostgreSQL | SQL Server |
|---|---|---|
| Mes como texto | `to_char(f, 'YYYY-MM')` | `FORMAT(f, 'yyyy-MM')` |
| Primer día del mes | `date_trunc('month', f)` | `DATEFROMPARTS(YEAR(f), MONTH(f), 1)` |
| Parte de la fecha | `EXTRACT(MONTH FROM f)` | `MONTH(f)` o `DATEPART(month, f)` |
| Día de la semana | `EXTRACT(ISODOW FROM f)` (1 = lunes) | `DATEPART(weekday, f)` |

## Otras diferencias con SQL Server

- PostgreSQL deja usar el **alias** en `GROUP BY` (`GROUP BY mes`); SQL Server no.
- `SUM(total) FILTER (WHERE tipoPago = 'Tarjeta')` es de PostgreSQL. En SQL Server se escribe
  `SUM(CASE WHEN tipoPago = 'Tarjeta' THEN total END)`, que funciona en los dos.

**Siguiente:** [04 · JOINs](../04_joins/)
