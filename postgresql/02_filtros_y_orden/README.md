# 02 · Filtros (WHERE) y orden (ORDER BY)

**Objetivo:** quedarte solo con las filas que te interesan y mostrarlas en el orden correcto.

## Orden en que se escribe una consulta

```sql
SELECT ...
FROM ...
WHERE ...        -- filtra filas
ORDER BY ...     -- ordena el resultado
LIMIT ...;       -- corta el resultado
```

## Operadores de WHERE

| Operador | Ejemplo |
|---|---|
| Comparar | `precio > 1000`, `estado <> 'ANULADA'` |
| Y / O / No | `a AND b`, `a OR b`, `NOT a` (`AND` se evalúa antes que `OR`: usa paréntesis) |
| Lista | `tipoPago IN ('Tarjeta', 'Transferencia')` |
| Rango | `precio BETWEEN 100 AND 500` (incluye los extremos) |
| Patrón | `nombre LIKE 'laptop%'` (`%` = cualquier texto, `_` = un carácter) |
| Sin mayúsculas | `nombre ILIKE '%logitech%'` (solo PostgreSQL) |
| Nulos | `correo IS NULL`, `correo IS NOT NULL` |

## Las 3 trampas de este módulo

1. **`= NULL` nunca funciona.** Usa `IS NULL`.
2. **`columna <> 1` excluye los NULL.** Si quieres incluirlos usa `IS DISTINCT FROM 1`.
3. **Fechas con hora:** `BETWEEN '2026-10-01' AND '2026-10-31'` pierde el día 31 después de
   las 00:00. Usa `>= '2026-10-01' AND < '2026-11-01'`.

## Diferencias con SQL Server

| PostgreSQL | SQL Server |
|---|---|
| `ORDER BY precio DESC LIMIT 5` | `SELECT TOP 5 ... ORDER BY precio DESC` |
| `LIMIT 5 OFFSET 10` | `OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY` (también vale en PG) |
| `LIKE` distingue mayúsculas; existe `ILIKE` | `LIKE` no distingue mayúsculas (por la intercalación) |

**Siguiente:** [03 · Agregaciones](../03_agregaciones/)
