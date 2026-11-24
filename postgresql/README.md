# Ruta de SQL con PostgreSQL

Todo lo de esta carpeta corre en **PostgreSQL 14 o superior** (probado en la 16).
Cada ejercicio indica qué cambia si lo escribieras en **SQL Server**.

## 1. Instalar PostgreSQL en Windows

1. Descarga el instalador desde [postgresql.org/download/windows](https://www.postgresql.org/download/windows/).
2. Durante la instalación deja marcados **pgAdmin 4** y **Command Line Tools**, y anota la
   contraseña del usuario `postgres`.
3. Para usar `psql` desde la terminal, agrega `C:\Program Files\PostgreSQL\16\bin` al `PATH`
   (cambia `16` por tu versión).

## 2. Crear la base de práctica

Desde la carpeta raíz del repo:

```bash
createdb -U postgres dbventa
psql -U postgres -d dbventa -f postgresql/00_base_de_datos/instalar.sql
```

En **pgAdmin**: clic derecho en *Databases* > *Create* > *Database* con el nombre `dbventa`.
Luego abre el *Query Tool*, carga `00_base_de_datos/01_esquema.sql`, ejecútalo (F5) y haz
lo mismo con `02_datos.sql`.

Si algún día rompes los datos, vuelve a correr `instalar.sql`: borra todo y lo crea de nuevo.

## 3. Cómo estudiar cada módulo

1. Lee el `README.md` del módulo (5 minutos).
2. Abre `ejercicios.sql`, escribe tu consulta debajo de cada enunciado y ejecútala.
3. Compara con el **Resultado esperado** (cuántas filas o qué valor debe salir).
4. Si no coincide o te trabas, mira `soluciones.sql`. Lee también los comentarios: ahí
   están las trampas y la versión de SQL Server.

Para correr un archivo entero desde la terminal:

```bash
psql -U postgres -d dbventa -f postgresql/04_joins/soluciones.sql
```

## Orden de los módulos

| Módulo | Modifica la base |
|---|---|
| 01 a 06 | No, solo consultan |
| 07 Modificar datos | No: todo va dentro de `BEGIN ... ROLLBACK` |
| 08 Vistas e índices | Sí, crea vistas e índices (no cambia los datos) |
| 09 Funciones y procedimientos | Crea funciones; las pruebas hacen `ROLLBACK` |
| 10 Triggers | Crea triggers que cambian cómo se comportan los `INSERT` en `DetalleVenta` |

> Si ya hiciste el módulo 10 y quieres repetir el 07 o el 09, reinstala la base primero:
> los triggers descuentan stock y recalculan totales solos, y los resultados cambiarían.
