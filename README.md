# Query_SQL

Scripts SQL de mis proyectos y mi ruta para aprender JOINs.

## Contenido

| Carpeta | Qué hay |
|---|---|
| `proyecto-VENTASANGULAR/` | Base `DBVENTA` original en **SQL Server** (tablas y datos) |
| `ScriptSQL_proyectoLISTA-TAREAS/` | Tabla `Tarea` del proyecto Lista de Tareas (SQL Server) |
| `postgresql/` | `DBVENTA` traducida a **PostgreSQL** + ejercicios de JOINs con soluciones |
| `docs/postgresql_vs_sqlserver.md` | Diferencias entre PostgreSQL y SQL Server con ejemplos |

## Practicar JOINs en PostgreSQL

```bash
createdb dbventa
psql -d dbventa -f postgresql/00_esquema_dbventa.sql
psql -d dbventa -f postgresql/01_datos.sql
```

Luego abre `postgresql/02_ejercicios_joins.sql` (en pgAdmin, DBeaver o `psql -d dbventa`) y
resuelve los ejercicios. Cada uno dice cuántas filas debe devolver. Las respuestas están en
`postgresql/03_soluciones_joins.sql`.

| Nivel | Tema |
|---|---|
| 1 | `INNER JOIN` |
| 2 | Varias tablas y la tabla puente `MenuRol` |
| 3 | `LEFT JOIN`, anti-join y la trampa `ON` vs `WHERE` |
| 4 | JOIN + `GROUP BY`, `LIMIT`, `STRING_AGG` |
| 5 | `FULL`, `SELF` y `CROSS JOIN` |
| 6 | Errores típicos (filas duplicadas) y un reto con CTE + `ROW_NUMBER()` |

El esquema:

```
Rol 1──* Usuario
Rol 1──* MenuRol *──1 Menu
Categoria 1──* Producto 1──* DetalleVenta *──1 Venta
```
