# 05 · Subconsultas y CTE (WITH)

**Objetivo:** resolver preguntas en varios pasos, usando el resultado de una consulta dentro de otra.

## Tipos de subconsulta

| Tipo | Ejemplo | Devuelve |
|---|---|---|
| Escalar | `WHERE precio > (SELECT AVG(precio) FROM Producto)` | 1 valor |
| De lista | `WHERE idCliente IN (SELECT idCliente FROM Venta ...)` | 1 columna |
| `EXISTS` | `WHERE EXISTS (SELECT 1 FROM Venta v WHERE v.idCliente = c.idCliente)` | verdadero/falso |
| En el FROM | `FROM (SELECT ... GROUP BY ...) t` | una tabla (necesita alias) |
| Correlacionada | la de adentro usa columnas de la de afuera | se evalúa por cada fila |

## CTE: subconsultas con nombre

```sql
WITH por_cliente AS (
    SELECT idCliente, SUM(total) AS gastado
    FROM Venta WHERE estado = 'PAGADA'
    GROUP BY idCliente
)
SELECT c.nombreCompleto, pc.gastado
FROM por_cliente pc
JOIN Cliente c ON c.idCliente = pc.idCliente;
```

Una CTE hace lo mismo que una subconsulta en el FROM, pero se lee de arriba hacia abajo,
como una receta. Puedes encadenar varias separadas por comas.

## CTE recursiva

Sirve para jerarquías (organigramas, categorías dentro de categorías) y para generar series:

```sql
WITH RECURSIVE organigrama AS (
    SELECT idUsuario, nombreCompleto, 1 AS nivel FROM Usuario WHERE idJefe IS NULL  -- inicio
    UNION ALL
    SELECT u.idUsuario, u.nombreCompleto, o.nivel + 1                              -- paso
    FROM Usuario u JOIN organigrama o ON u.idJefe = o.idUsuario
)
SELECT * FROM organigrama;
```

## La trampa más famosa: NOT IN con NULL

Si la subconsulta devuelve algún `NULL`, `NOT IN` no devuelve **nada**. Usa `NOT EXISTS`.
Lo compruebas en el ejercicio 5.

## Diferencias con SQL Server

- SQL Server escribe `WITH` sin la palabra `RECURSIVE`.
- Todo lo demás de este módulo es igual.

**Siguiente:** [06 · Funciones de ventana](../06_funciones_de_ventana/)
