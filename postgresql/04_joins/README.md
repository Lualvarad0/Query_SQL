# 04 · JOINs

**Objetivo:** combinar varias tablas en una sola consulta. Es lo que más se usa en el día a día
y lo que más se pregunta en entrevistas.

## Mapa de relaciones

```
Usuario (vendedor) 1──* Venta *──1 Cliente *──1 Ciudad
                         │
                         1
                         │
                         *
                   DetalleVenta *──1 Producto *──1 Categoria
                                         │
                                         *──1 Proveedor *──1 Ciudad
Usuario *──1 Usuario (idJefe)
Usuario *──1 Rol 1──* MenuRol *──1 Menu
```

## Tipos de JOIN

| JOIN | Devuelve | Úsalo para |
|---|---|---|
| `INNER JOIN` (o `JOIN`) | Solo filas que coinciden en ambas tablas | Lo normal: venta con su cliente |
| `LEFT JOIN` | Todas las de la izquierda; NULL si no hay pareja | "Todos los clientes, aunque no compren" |
| `RIGHT JOIN` | Al revés que LEFT | Casi nunca: mejor invierte las tablas y usa LEFT |
| `FULL OUTER JOIN` | Todas las de ambos lados | Encontrar huérfanos de los dos lados |
| `CROSS JOIN` | Todas las combinaciones | Matrices: vendedor x mes |
| `SELF JOIN` | Una tabla con ella misma | Jerarquías: usuario y su jefe |

## Patrones que vas a usar siempre

```sql
-- Anti-join: lo que NO tiene pareja
SELECT c.nombre FROM Ciudad c
LEFT JOIN Cliente cl ON cl.idCiudad = c.idCiudad
WHERE cl.idCliente IS NULL;
```

```sql
-- Filtro de la tabla derecha en un LEFT JOIN: va en el ON
LEFT JOIN Venta v ON v.idCliente = cl.idCliente AND v.estado = 'PAGADA'
```

## Errores típicos (los ves en el nivel 6)

1. **Filtrar la tabla de la derecha en el `WHERE`** convierte el `LEFT JOIN` en `INNER JOIN`.
2. **Unir una tabla "de muchos" y sumar una columna "de uno"** infla los totales
   (cada venta se repite por cada línea de detalle).
3. **`COUNT(*)` en un LEFT JOIN** cuenta 1 aunque no haya pareja. Usa `COUNT(columna_derecha)`.

## Niveles de ejercicios

| Nivel | Ejercicios | Tema |
|---|---|---|
| 1 | 1 a 3 | INNER JOIN |
| 2 | 4 a 9 | Cadenas de 4 o 5 tablas y reportes con ganancia |
| 3 | 10 a 15 | LEFT JOIN y anti-joins |
| 4 | 16 a 18 | SELF JOIN (jefes, equipos, pares) |
| 5 | 19 a 21 | FULL, CROSS y JOIN por rangos |
| 6 | 22 a 23 | Errores típicos y reto |

## Diferencias con SQL Server

La sintaxis de los JOINs es **idéntica**. Lo único distinto en este módulo:

- `DISTINCT ON (...)` (reto 23) solo existe en PostgreSQL.
- `generate_series` (ejercicio 20) es de PostgreSQL; SQL Server 2022 tiene `GENERATE_SERIES`.
- `STRING_AGG(x, ', ' ORDER BY x)` en SQL Server es `STRING_AGG(x, ', ') WITHIN GROUP (ORDER BY x)`.
- PostgreSQL tiene `JOIN ... USING (columna)` y `LATERAL`; SQL Server tiene `CROSS/OUTER APPLY`.

**Siguiente:** [05 · Subconsultas y CTE](../05_subconsultas_y_cte/)
