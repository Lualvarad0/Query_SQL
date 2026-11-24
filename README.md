# Query_SQL

Scripts SQL de mis proyectos y una **ruta paso a paso para aprender SQL** con
PostgreSQL, comparando siempre con SQL Server.

## Qué hay en cada carpeta

| Carpeta | Qué hay |
|---|---|
| [`postgresql/`](postgresql/) | **La ruta de aprendizaje**: base de datos de práctica y 10 módulos con ejercicios y soluciones |
| [`docs/`](docs/) | Guía de diferencias entre PostgreSQL y SQL Server |
| [`proyecto-01-lista-de-tareas/`](proyecto-01-lista-de-tareas/) | **Proyecto 01 · Lista de Tareas**: de 1 tabla a 7 con `ALTER TABLE`, todos los tipos de relación, trigger, seguridad (claves, permisos, seguridad por fila, inyección SQL), errores comunes y 19 ejercicios |
| [`proyecto-02-sistema-de-ventas/`](proyecto-02-sistema-de-ventas/) | **Proyecto 02 · Sistema de Ventas**: el SQL de cada pantalla, procedimientos, vistas, clientes y proveedores, seguridad, errores comunes y 22 ejercicios |

## La ruta, paso a paso

Cada módulo es una carpeta con tres archivos: `README.md` (la teoría corta),
`ejercicios.sql` (los enunciados, con el resultado esperado) y `soluciones.sql`.

| Paso | Módulo | Aprendes |
|---|---|---|
| 0 | [Base de datos](postgresql/00_base_de_datos/) | Instalar la base de práctica y entender sus tablas |
| 1 | [SELECT básico](postgresql/01_select_basico/) | Elegir columnas, alias, cálculos, `DISTINCT`, `CASE` |
| 2 | [Filtros y orden](postgresql/02_filtros_y_orden/) | `WHERE`, `IN`, `LIKE`, `NULL`, `ORDER BY`, `LIMIT` |
| 3 | [Agregaciones](postgresql/03_agregaciones/) | `COUNT`, `SUM`, `AVG`, `GROUP BY`, `HAVING`, fechas |
| 4 | [JOINs](postgresql/04_joins/) | `INNER`, `LEFT`, `SELF`, `FULL`, `CROSS` y errores típicos |
| 5 | [Subconsultas y CTE](postgresql/05_subconsultas_y_cte/) | `IN`, `EXISTS`, `WITH`, CTE recursivas |
| 6 | [Funciones de ventana](postgresql/06_funciones_de_ventana/) | `ROW_NUMBER`, `RANK`, `LAG`, acumulados |
| 7 | [Modificar datos](postgresql/07_modificar_datos_y_transacciones/) | `INSERT`, `UPDATE`, `DELETE`, upsert, transacciones |
| 8 | [Vistas e índices](postgresql/08_vistas_e_indices/) | Vistas, vistas materializadas, `EXPLAIN`, índices |
| 9 | [Funciones y procedimientos](postgresql/09_funciones_y_procedimientos/) | PL/pgSQL, procedimientos, manejo de errores |
| 10 | [Triggers](postgresql/10_triggers/) | Qué son, **cuándo usarlos y cuándo no**, auditoría, stock |

## Empezar en 3 pasos

1. Instala PostgreSQL (ver [`postgresql/README.md`](postgresql/README.md)).
2. Crea la base e instala los datos:
   ```bash
   createdb dbventa
   psql -d dbventa -f postgresql/00_base_de_datos/instalar.sql
   ```
3. Abre `postgresql/01_select_basico/ejercicios.sql` y empieza.

## Los dos proyectos

Además de la ruta, hay dos proyectos completos para aprender con algo real. Cada paso está
en **SQL Server** y en **PostgreSQL**, con los mismos resultados.

| Orden | Proyecto | Por qué en ese orden |
|---|---|---|
| 1 | [Lista de Tareas](proyecto-01-lista-de-tareas/) | Empieza con una sola tabla y la hace crecer: ves nacer cada relación |
| 2 | [Sistema de Ventas](proyecto-02-sistema-de-ventas/) | Un modelo más grande, con plata de por medio: totales, stock, permisos por rol |

Los dos terminan con un paso de **seguridad** (qué acepta una tabla mal hecha, claves con
hash, permisos, inyección SQL) y otro de **errores comunes**: lo que la base de datos
rechaza, con el mensaje que da, y lo que acepta en silencio aunque el resultado esté mal.
