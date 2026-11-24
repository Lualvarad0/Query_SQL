# 01 · SELECT básico

**Objetivo:** leer datos de una tabla eligiendo columnas, renombrándolas y calculando valores nuevos.

## La forma de un SELECT

```sql
SELECT columna1, columna2 AS alias, expresion AS otro_alias
FROM tabla;
```

| Concepto | Ejemplo |
|---|---|
| Todas las columnas | `SELECT * FROM Categoria;` (útil para mirar, evítalo en código real) |
| Alias | `precio AS "precio de venta"` |
| Cálculos | `precio - costo AS ganancia` |
| Redondear | `ROUND(precio * 1.15, 2)` |
| Sin repetidos | `SELECT DISTINCT tipoPago FROM Venta;` |
| Condiciones | `CASE WHEN precio >= 1500 THEN 'Premium' ELSE 'Otro' END` |
| Unir textos | `nombre \|\| ' ' \|\| apellido` |
| Reemplazar NULL | `COALESCE(correo, 'sin correo')` |

## Diferencias con SQL Server

| PostgreSQL | SQL Server |
|---|---|
| `'a' \|\| 'b'` | `'a' + 'b'` |
| `COALESCE(x, 0)` | `ISNULL(x, 0)` o `COALESCE` |
| `LENGTH(x)` | `LEN(x)` |
| `"alias con espacios"` | `[alias con espacios]` |

> **Ojo con NULL:** cualquier operación con `NULL` da `NULL`. `'Hola ' || NULL` es `NULL`.

## Archivos

- `ejercicios.sql`: 10 ejercicios.
- `soluciones.sql`: las respuestas comentadas.

**Siguiente:** [02 · Filtros y orden](../02_filtros_y_orden/)
