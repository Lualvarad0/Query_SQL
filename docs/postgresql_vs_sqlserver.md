# PostgreSQL vs SQL Server (T-SQL)

Guía rápida con ejemplos tomados de este mismo repo. Los dos proyectos
(`proyecto-01-lista-de-tareas/` y `proyecto-02-sistema-de-ventas/`) tienen cada paso en
`sqlserver/` y en `postgresql/`, así que puedes comparar archivo con archivo.

## Lo más importante: los JOINs son iguales

`INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `FULL OUTER JOIN` y `CROSS JOIN` se escriben
exactamente igual en los dos motores. Lo que aprendas en `postgresql/04_joins/`
te sirve tal cual en SQL Server. Las diferencias están alrededor: tipos de datos, funciones,
límites de filas y algunos extras.

| Tema de JOIN | PostgreSQL | SQL Server |
|---|---|---|
| `JOIN ... ON` | Sí | Sí |
| `JOIN ... USING (col)` | Sí | No |
| `NATURAL JOIN` | Sí (mejor evitarlo) | No |
| JOIN con subconsulta por fila | `LEFT JOIN LATERAL (...) ON true` | `OUTER APPLY (...)` |
| | `CROSS JOIN LATERAL (...)` | `CROSS APPLY (...)` |
| `UPDATE` con JOIN | `UPDATE v SET ... FROM otra o WHERE o.id = v.id` | `UPDATE v SET ... FROM Venta v JOIN otra o ON ...` |
| `DELETE` con JOIN | `DELETE FROM t USING otra o WHERE ...` | `DELETE t FROM t JOIN otra o ON ...` |

## Crear tablas

```sql
-- SQL Server (original)
create table Rol(
  idRol int primary key identity(1,1),
  nombre varchar(50),
  fechaRegistro datetime default getdate()
)
go
```

```sql
-- PostgreSQL
CREATE TABLE Rol (
  idRol INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,   -- o SERIAL (forma antigua)
  nombre VARCHAR(50),
  fechaRegistro TIMESTAMP DEFAULT now()
);
```

| Concepto | SQL Server | PostgreSQL |
|---|---|---|
| Autoincremento | `identity(1,1)` | `GENERATED ALWAYS AS IDENTITY` / `SERIAL` |
| Booleano | `bit` (0/1) | `BOOLEAN` (`TRUE`/`FALSE`) |
| Fecha y hora | `datetime`, `datetime2` | `TIMESTAMP`, `TIMESTAMPTZ` (con zona horaria) |
| Fecha/hora actual | `getdate()`, `sysdatetime()` | `now()`, `CURRENT_TIMESTAMP` |
| Texto largo | `varchar(max)`, `nvarchar(max)` | `TEXT` |
| Unicode | `nvarchar` y literales `N'...'` | `VARCHAR`/`TEXT` ya son UTF-8 |
| Separar lotes | `GO` | No existe; cada sentencia termina en `;` |
| Cambiar de base | `USE DBVENTA` | `\c dbventa` en psql (o conectarte a otra base) |

## Consultas del día a día

| Qué quieres | SQL Server | PostgreSQL |
|---|---|---|
| Primeras N filas | `SELECT TOP 3 ...` | `... LIMIT 3` |
| Paginación | `OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY` | igual, o `LIMIT 5 OFFSET 10` |
| Reemplazar NULL | `ISNULL(x, 0)` o `COALESCE` | `COALESCE(x, 0)` |
| Concatenar | `'a' + 'b'` o `CONCAT` | `'a' \|\| 'b'` o `CONCAT` |
| Largo de texto | `LEN(x)` | `LENGTH(x)` |
| Convertir | `CAST(x AS date)`, `CONVERT(date, x)` | `CAST(x AS date)` o `x::date` |
| Formatear fecha | `FORMAT(f, 'yyyy-MM')` | `to_char(f, 'YYYY-MM')` |
| Sumar días | `DATEADD(day, 7, f)` | `f + INTERVAL '7 days'` |
| Diferencia en días | `DATEDIFF(day, a, b)` | `b::date - a::date` |
| Agrupar textos | `STRING_AGG(x, ', ') WITHIN GROUP (ORDER BY x)` | `STRING_AGG(x, ', ' ORDER BY x)` |
| Agregado con filtro | `SUM(CASE WHEN ... THEN x END)` | `SUM(x) FILTER (WHERE ...)` o el `CASE` |
| Alias en `GROUP BY` | No se puede | Sí (`GROUP BY mes`) |
| Id recién insertado | `SCOPE_IDENTITY()` u `OUTPUT inserted.id` | `INSERT ... RETURNING id` |
| Insertar o actualizar | `MERGE` | `INSERT ... ON CONFLICT ... DO UPDATE` (o `MERGE` desde PG 15) |

## Mayúsculas y comparaciones de texto (te va a pasar)

- **Nombres de tablas y columnas:** PostgreSQL convierte a minúsculas lo que no va entre comillas.
  `idCategoria` se guarda como `idcategoria`. Si escribes `"idCategoria"` con comillas, tendrás que
  usar comillas siempre. Por eso en PostgreSQL se suele usar `snake_case` (`id_categoria`).
  En SQL Server los nombres se escapan con corchetes: `[Detalle Venta]`.
- **Comparar textos:** SQL Server, con su intercalación por defecto, no distingue mayúsculas:
  `WHERE nombre = 'LAPTOPS'` encuentra `'Laptops'`. En PostgreSQL **sí** las distingue; usa
  `ILIKE 'laptops'` o `lower(nombre) = 'laptops'`.

## Código procedural

- SQL Server usa T-SQL: variables `DECLARE @x INT`, `IF`, `WHILE`, `CREATE PROCEDURE` directamente.
- PostgreSQL usa PL/pgSQL dentro de `CREATE FUNCTION` / `CREATE PROCEDURE ... LANGUAGE plpgsql`,
  o bloques anónimos `DO $$ ... $$;`. Las variables no llevan `@`.

## Triggers

| | PostgreSQL | SQL Server |
|---|---|---|
| Estructura | `CREATE FUNCTION ... RETURNS trigger` + `CREATE TRIGGER ... EXECUTE FUNCTION` | `CREATE TRIGGER ... AS BEGIN ... END` |
| Momento | `BEFORE`, `AFTER`, `INSTEAD OF` (vistas) | `AFTER` (o `FOR`), `INSTEAD OF` |
| Granularidad | `FOR EACH ROW` o `FOR EACH STATEMENT` | Siempre por sentencia |
| Filas afectadas | `NEW`, `OLD`, o `REFERENCING NEW/OLD TABLE` | Tablas `inserted` y `deleted` |
| Operación | `TG_OP` | `IF EXISTS (SELECT 1 FROM inserted)` / `deleted` |

Más detalle y cuándo conviene usarlos: [`postgresql/10_triggers/README.md`](../postgresql/10_triggers/README.md).

## Herramientas

| | SQL Server | PostgreSQL |
|---|---|---|
| Cliente gráfico | SQL Server Management Studio (SSMS) | pgAdmin, DBeaver |
| Consola | `sqlcmd` | `psql` |
| Usuario admin | `sa` | `postgres` |
| Diagramas | Database Diagrams en SSMS (`ALTER AUTHORIZATION ... TO sa`) | ERD Tool de pgAdmin o DBeaver |
