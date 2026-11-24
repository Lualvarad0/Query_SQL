# 06 · Funciones de ventana

**Objetivo:** calcular rankings, acumulados y comparaciones con la fila anterior **sin perder el detalle**.

`GROUP BY` junta las filas y te deja una por grupo. Una función de ventana deja todas las
filas y les agrega una columna calculada sobre un grupo de filas relacionadas (la "ventana").

```sql
funcion() OVER (PARTITION BY grupo ORDER BY orden ROWS BETWEEN ... )
```

| Parte | Qué hace |
|---|---|
| `PARTITION BY` | Reinicia el cálculo por cada grupo (como un GROUP BY que no junta filas) |
| `ORDER BY` | Orden dentro de la ventana (para rankings y acumulados) |
| `ROWS BETWEEN` | Qué filas cuentan: `2 PRECEDING AND CURRENT ROW` = la actual y las 2 anteriores |

## Funciones más usadas

| Función | Para qué |
|---|---|
| `ROW_NUMBER()` | Numerar 1, 2, 3... (el "top N por grupo") |
| `RANK()` / `DENSE_RANK()` | Rankings con empates (1, 2, 2, 4 / 1, 2, 2, 3) |
| `SUM(x) OVER (ORDER BY fecha)` | Total acumulado |
| `LAG(x)` / `LEAD(x)` | Valor de la fila anterior / siguiente |
| `FIRST_VALUE` / `LAST_VALUE` | Primer / último valor de la ventana |
| `NTILE(4)` | Repartir en 4 grupos iguales (cuartiles) |
| `SUM(x) OVER ()` | Total general en cada fila (para porcentajes) |

## Reglas

- No puedes filtrar una función de ventana en el `WHERE` de la misma consulta: envuélvela en
  una subconsulta o CTE y filtra afuera (ejercicio 2).
- `LAST_VALUE` necesita `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`, si no
  devuelve la fila actual (ejercicio 10).

## Diferencias con SQL Server

Las funciones de ventana son casi idénticas. Cambian las funciones de fecha que las rodean
(`date_trunc` vs `DATEFROMPARTS`, restar fechas vs `DATEDIFF`) y la cláusula `WINDOW w AS (...)`,
que SQL Server tiene desde la versión 2022.

**Siguiente:** [07 · Modificar datos y transacciones](../07_modificar_datos_y_transacciones/)
