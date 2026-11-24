# Proyecto: Sistema de Ventas (Angular)

Base de datos `DBVENTA` del sistema de ventas hecho en Angular. Aquí la desarmamos
pieza por pieza para aprender SQL con un proyecto real: qué guarda cada tabla, qué
consulta hay detrás de cada pantalla de la app, y cómo mejorarla con procedimientos,
vistas, índices y seguridad.

Todo está en **dos versiones**: `sqlserver/` (el motor original del proyecto) y
`postgresql/`. Las dos versiones devuelven los mismos resultados.

---

## Contenido de la carpeta

| Archivo | Qué es |
|---|---|
| `01_CREAR_BASE_DATOS_TABLAS.txt` | Script **original** del proyecto (sin cambios) |
| `02_INSERTAR DATOS EN TABLAS.txt` | Datos **originales** del proyecto (sin cambios) |
| `sqlserver/01_crear_base_y_tablas.sql` | Paso 1: el mismo modelo, con reglas (`NOT NULL`, `UNIQUE`, `CHECK`) y comentado |
| `sqlserver/02_datos.sql` | Paso 2: los datos originales + usuarios de prueba + 24 ventas |
| `sqlserver/03_consultas_por_pantalla.sql` | Paso 3: el SQL de cada pantalla de la app |
| `sqlserver/04_procedimientos.sql` | Paso 4: procedimientos almacenados para la API |
| `sqlserver/05_vistas_indices_y_seguridad.sql` | Paso 5: vistas, índices y claves con hash |
| `sqlserver/06_soluciones.sql` | Paso 6: soluciones de los ejercicios |
| `postgresql/` | Los mismos 6 pasos en PostgreSQL, más `instalar.sql` |
| `ejercicios.sql` | 16 ejercicios sobre esta base (sirven para los dos motores) |

---

## La app en 1 minuto

Es un punto de venta con login. Cada usuario tiene un **rol**, y el rol decide qué
opciones del menú lateral ve:

| Pantalla | Administrador | Supervisor | Empleado | Qué hace |
|---|:-:|:-:|:-:|---|
| DashBoard | ✔ | | | Ventas e ingresos de la última semana, gráfico por día |
| Usuarios | ✔ | | | Crear, editar y desactivar usuarios |
| Productos | ✔ | ✔ | | Catálogo con categoría, stock y precio |
| Venta | ✔ | ✔ | ✔ | Buscar productos, armar el carrito y registrar la venta |
| Historial Ventas | ✔ | ✔ | ✔ | Buscar ventas por fecha o número y ver su detalle |
| Reportes | ✔ | ✔ | | Ventas por rango de fechas, para exportar |

Esa tabla de permisos **está en la base de datos** (tablas `Rol`, `Menu` y `MenuRol`).
No está escrita en el código de Angular.

---

## El modelo de datos

```
                 ┌─────────┐
                 │   Rol   │
                 └────┬────┘
           1          │ 1
     ┌────────────────┴───────────┐
     │ *                          │ *
┌────┴────┐                  ┌────┴────┐   *     1 ┌────────┐
│ Usuario │                  │ MenuRol ├───────────┤  Menu  │
└─────────┘                  └─────────┘           └────────┘

┌───────────┐ 1      * ┌──────────┐ 1      * ┌──────────────┐ *      1 ┌─────────┐
│ Categoria ├──────────┤ Producto ├──────────┤ DetalleVenta ├──────────┤  Venta  │
└───────────┘          └──────────┘          └──────────────┘          └─────────┘

┌─────────────────┐
│ NumeroDocumento │   (una sola fila: el último número de venta usado)
└─────────────────┘
```

### Tabla por tabla

**Seguridad**

| Tabla | Para qué | Columnas importantes |
|---|---|---|
| `Rol` | Los perfiles: Administrador, Empleado, Supervisor | `nombre` (único) |
| `Menu` | Cada opción del menú lateral | `url` es la ruta de Angular (`/pages/venta`); `icono` es el ícono de Angular Material |
| `MenuRol` | **Tabla puente**: qué menús ve cada rol | `idMenu` + `idRol`. Un rol ve muchos menús y un menú lo ven muchos roles (relación muchos a muchos) |
| `Usuario` | Quién entra al sistema | `correo` (único, se usa para el login), `idRol`, `esActivo` (para "desactivar" sin borrar) |

**Catálogo**

| Tabla | Para qué | Columnas importantes |
|---|---|---|
| `Categoria` | Agrupa productos: Laptops, Monitores... | `esActivo` |
| `Producto` | Lo que se vende | `stock` (con `CHECK >= 0`), `precio` (con `CHECK > 0`), `idCategoria` |

**Ventas**

| Tabla | Para qué | Columnas importantes |
|---|---|---|
| `Venta` | La **cabecera**: una fila por venta | `numeroDocumento` (00001, 00002...), `tipoPago`, `total` |
| `DetalleVenta` | Las **líneas**: qué productos llevó y cuántos | `cantidad`, `precio`, `total` |
| `NumeroDocumento` | Contador para generar el siguiente número de venta | `ultimo_Numero` |

### Tres decisiones de diseño que vale la pena entender

1. **¿Por qué `DetalleVenta` guarda el `precio` si ya está en `Producto`?**
   Porque el precio del producto cambia con el tiempo. La venta del lunes tiene que
   seguir mostrando lo que se cobró el lunes, aunque el martes suba el precio.
2. **¿Por qué una tabla `NumeroDocumento` en vez de usar `idVenta`?**
   El número de documento es lo que ve el cliente en su comprobante. Separarlo del id
   interno permite darle formato (`00025`), reiniciarlo o tener series distintas.
3. **¿Por qué `esActivo` en vez de borrar?**
   Un usuario o producto que ya tiene ventas no se puede borrar sin romper la historia
   (las llaves foráneas lo impiden). Se "desactiva" y deja de aparecer en la app.

---

## Instalar

### SQL Server (SSMS)

1. Abre **SQL Server Management Studio** y conéctate a tu servidor.
2. Abre `sqlserver/01_crear_base_y_tablas.sql` y ejecútalo con **F5**. Crea la base `DBVENTA`;
   si ya existe, la borra y la crea de nuevo.
3. Haz lo mismo con `sqlserver/02_datos.sql`.
4. Sigue con los pasos 3, 4 y 5 en orden.

Desde la terminal (Windows, autenticación de Windows):

```bash
sqlcmd -S . -E -i sqlserver\01_crear_base_y_tablas.sql,sqlserver\02_datos.sql
```

### PostgreSQL

```bash
createdb dbventa_app
psql -d dbventa_app -f proyecto-VENTASANGULAR/postgresql/instalar.sql
psql -d dbventa_app -f proyecto-VENTASANGULAR/postgresql/03_consultas_por_pantalla.sql
```

> Usa una base distinta (`dbventa_app`) a la de la ruta de aprendizaje (`dbventa`), porque
> esa tiene una versión ampliada de estas tablas.

---

## Paso a paso

### Paso 1 · Crear las tablas (`01_crear_base_y_tablas.sql`)

**Aprendes:** `CREATE DATABASE`, `CREATE TABLE`, tipos de datos, `IDENTITY`, llaves
primarias y foráneas, `NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT`.

Comparado con el script original, se agregaron reglas que la base hace cumplir sola:

| Regla | Evita |
|---|---|
| `correo NOT NULL UNIQUE` | Dos usuarios con el mismo correo (el login no sabría cuál es) |
| `stock CHECK (stock >= 0)` | Vender más de lo que hay |
| `precio CHECK (precio > 0)` | Productos gratis por error |
| `UNIQUE (idMenu, idRol)` | Asignar dos veces el mismo menú a un rol |
| `numeroDocumento UNIQUE` | Dos ventas con el mismo número |

También se les puso nombre a las llaves (`CONSTRAINT FK_Usuario_Rol ...`). Así, cuando
algo falla, el error dice `FK_Usuario_Rol` y no un nombre generado como `FK__Usuario__idRol__3B75D760`.

### Paso 2 · Cargar datos (`02_datos.sql`)

**Aprendes:** `INSERT ... VALUES` de varias filas, `INSERT ... SELECT`, `UPDATE` con `JOIN`.

Además de los datos originales agrega:

- 2 usuarios: `maria@example.com` (Empleado) y `jose@example.com` (Supervisor). La clave es `123`, como en el original.
- 24 ventas del 1 al 23 de noviembre de 2026, con 38 líneas de detalle.
- El `total` de cada venta y el `stock` se calculan a partir del detalle, con `UPDATE ... FROM`.

Productos que **nunca** se venden: *laptop asus zenbook duo*, *teclado logitech* y
*memoria kingston rgb*. Los vas a buscar con `LEFT JOIN` en los ejercicios.

### Paso 3 · El SQL de cada pantalla (`03_consultas_por_pantalla.sql`)

**Aprendes:** `SELECT` con `JOIN` de 2 a 4 tablas, `WHERE`, `LIKE`, `GROUP BY`, subconsultas,
fechas y transacciones.

| # | Pantalla | Consulta |
|---|---|---|
| 3.1 | Login | Validar correo y clave, y traer el rol |
| 3.2 | Login | Armar el menú del usuario: `Usuario → MenuRol → Menu` |
| 3.3 | Dashboard | Tarjetas: ventas e ingresos de los últimos 7 días, productos activos |
| 3.4 | Dashboard | Gráfico: ventas por día |
| 3.5–3.7 | Usuarios | Listar con rol, combo de roles, crear / editar / desactivar / eliminar |
| 3.8–3.9 | Productos | Catálogo con categoría, productos con poco stock |
| 3.10 | Venta | Buscador mientras se escribe (solo activos y con stock) |
| 3.11 | Venta | **Registrar una venta a mano**: los 5 pasos que deben ir juntos |
| 3.12–3.13 | Historial | Buscar por fechas, buscar por número y ver el detalle |
| 3.14 | Reportes | Una fila por producto vendido en un rango de fechas |

Fíjate en 3.11: registrar una venta son 5 sentencias (número, cabecera, detalle, stock,
total). Si se corta la luz entre la 3 y la 4, el stock queda mal. Por eso van dentro de
una **transacción**, y en el paso 4 se convierten en un procedimiento.

### Paso 4 · Procedimientos almacenados (`04_procedimientos.sql`)

**Aprendes:** `CREATE PROCEDURE`, parámetros de entrada y de salida (`OUTPUT`),
`SET XACT_ABORT ON`, `THROW`, `TRY...CATCH`, leer JSON con `OPENJSON`.

| Procedimiento | Pantalla | Qué hace |
|---|---|---|
| `sp_ObtenerMenus @idUsuario` | Login | Devuelve el menú del usuario |
| `sp_RegistrarVenta @tipoPago, @detalle, @numeroDocumento OUTPUT` | Venta | Valida, genera el número, guarda cabecera y detalle, descuenta stock y calcula el total. Todo o nada |
| `sp_ReporteVentas @fechaInicio, @fechaFin` | Reportes | El reporte por rango |
| `sp_Dashboard @hoy` | Dashboard | Devuelve 2 resultados: tarjetas y ventas por día |

El detalle de la venta llega como **JSON**, que es justo lo que manda Angular:

```sql
EXEC sp_RegistrarVenta
     @tipoPago = 'Tarjeta',
     @detalle  = N'[{"idProducto":11,"cantidad":2},{"idProducto":14,"cantidad":1}]',
     @numeroDocumento = @num OUTPUT;
```

Antes de guardar, el procedimiento valida tres cosas y lanza un error claro si falla
alguna: que haya productos, que existan y estén activos, y que haya stock.

### Paso 5 · Vistas, índices y seguridad (`05_vistas_indices_y_seguridad.sql`)

**Aprendes:** `CREATE INDEX`, `sp_helpindex`, `CREATE VIEW`, `HASHBYTES`, `ALTER TABLE ADD`.

- **Índices** en las llaves foráneas y en `Venta.fechaRegistro`. SQL Server no los crea
  solo, y sin ellos el historial y los reportes leen la tabla completa.
- **Vistas**: `vw_HistorialVenta` (cada venta con cuántos productos y unidades tiene) y
  `vw_VentasPorProducto` (ranking de productos, incluidos los que no se vendieron).
- **Seguridad de claves**: la tabla original guarda la clave en texto (`'123'`). Si alguien
  copia la base, ve todas las claves. El script muestra cómo guardar un **hash con sal**
  y validar el login comparando hashes. Va dentro de una transacción que se deshace, para
  no romper el login de la app. En la app real, el hash lo calcula la API (por ejemplo con BCrypt).

### Paso 6 · Ejercicios (`ejercicios.sql`)

16 ejercicios, cada uno con el resultado esperado. Soluciones en `sqlserver/06_soluciones.sql`
y `postgresql/06_soluciones.sql`.

| Nivel | Ejercicios | Ejemplos |
|---|---|---|
| JOINs básicos | 1–5 | Productos con categoría, menús por rol, quién puede ver "Reportes" |
| Agrupaciones y subconsultas | 6–13 | Ventas por día y por semana, porcentaje por tipo de pago, top 5, productos sin ventas |
| Avanzados | 14–16 | Porcentaje de cada línea en su venta (ventanas), productos que se compran juntos, stock inicial |

---

## SQL Server vs PostgreSQL en este proyecto

| Qué | SQL Server | PostgreSQL |
|---|---|---|
| Autoincremento | `INT IDENTITY(1,1)` | `INT GENERATED ALWAYS AS IDENTITY` |
| Booleano | `BIT` con `1` / `0` | `BOOLEAN` con `TRUE` / `FALSE` |
| Fecha actual | `GETDATE()` | `now()` |
| Separar lotes / cambiar de base | `GO` / `USE DBVENTA` | No existen; te conectas con `-d dbventa_app` |
| Variables sueltas | `DECLARE @x INT = 1;` | Solo dentro de funciones o bloques `DO` |
| Id recién insertado | `SCOPE_IDENTITY()` | `INSERT ... RETURNING idVenta` |
| Primeras N filas | `SELECT TOP 10` | `LIMIT 10` |
| Formato de fecha | `CONVERT(VARCHAR(10), f, 103)` | `to_char(f, 'DD/MM/YYYY')` |
| Sumar días | `DATEADD(DAY, -6, @hoy)` | `fecha - 6` |
| Leer JSON | `OPENJSON(@detalle) WITH (...)` | `jsonb_array_elements(p_detalle)` |
| Procedimiento que devuelve filas | `PROCEDURE` con un `SELECT` | `FUNCTION ... RETURNS TABLE` |
| Error controlado | `THROW` y `BEGIN TRY / BEGIN CATCH` | `RAISE EXCEPTION` y `EXCEPTION WHEN` |
| Hash de clave | `HASHBYTES('SHA2_256', sal + clave)` | `crypt(clave, gen_salt('bf'))` (extensión pgcrypto) |

---

## Ideas para seguir avanzando

Estas mejoras cambian las tablas, así que la app también tendría que cambiar. Varias ya
están hechas en la base ampliada de la ruta ([`postgresql/00_base_de_datos`](../postgresql/00_base_de_datos/)):

| Mejora | Para qué | Dónde verla |
|---|---|---|
| `Venta.idUsuario` | Saber qué vendedor hizo cada venta | Ruta, módulo 04 |
| Tabla `Cliente` y `Venta.idCliente` | Historial por cliente, facturas con datos | Ruta, módulo 04 |
| `Venta.estado` (PAGADA / ANULADA) | Anular sin borrar | Ruta, módulos 03 y 10 |
| `subtotal` e `impuesto` (IVA 15 %) | Comprobantes reales | Ruta, módulo 00 |
| Trigger que descuenta stock | Que el stock baje aunque la venta no venga de la app | Ruta, módulo 10 |
| Auditoría de cambios de precio | Saber quién cambió qué y cuándo | Ruta, módulo 10 |
