# Proyecto 02 · Sistema de Ventas

Base de datos `DBVENTA` del sistema de ventas hecho en Angular. Aquí la desarmamos
pieza por pieza para aprender SQL con un proyecto real: qué guarda cada tabla, qué
consulta hay detrás de cada pantalla de la app, cómo relacionar clientes, vendedores y
proveedores, cómo protegerla (reglas, permisos, inyección SQL) y qué errores aparecen
cuando se hace lo que no se debe.

> Si recién empiezas, haz antes el [Proyecto 01 · Lista de Tareas](../proyecto-01-lista-de-tareas/):
> es más corto y muestra cómo una tabla suelta se convierte en un modelo relacionado.

Todo está en **dos versiones**: `sqlserver/` (el motor original del proyecto) y
`postgresql/`. Las dos versiones devuelven los mismos resultados.

---

## Contenido de la carpeta

| Archivo | Qué es |
|---|---|
| `sqlserver/01_crear_base_y_tablas.sql` | Paso 1: el modelo del script original, con reglas (`NOT NULL`, `UNIQUE`, `CHECK`) y comentado |
| `sqlserver/02_datos.sql` | Paso 2: los datos originales + usuarios de prueba + 24 ventas |
| `sqlserver/03_consultas_por_pantalla.sql` | Paso 3: el SQL de cada pantalla de la app |
| `sqlserver/04_procedimientos.sql` | Paso 4: procedimientos almacenados para la API |
| `sqlserver/05_vistas_e_indices.sql` | Paso 5: vistas e índices |
| `sqlserver/06_relaciones.sql` | Paso 6: clientes, vendedores, jefes y proveedores (todos los tipos de relación) |
| `sqlserver/07_seguridad.sql` | Paso 7: lo que el script original dejaba pasar, claves con hash, permisos e inyección SQL |
| `sqlserver/08_errores_comunes.sql` | Paso 8: 14 errores que la base rechaza y 9 que acepta sin avisar |
| `sqlserver/09_soluciones.sql` | Soluciones de los ejercicios |
| `postgresql/` | Los mismos pasos en PostgreSQL, más `instalar.sql` (pasos 1 y 2) |
| `ejercicios.sql` | 22 ejercicios sobre esta base (sirven para los dos motores) |

> Los scripts originales del proyecto estaban en archivos `.txt`. Ya no hacen falta:
> el paso 1 y el paso 2 son esos mismos scripts, ordenados y corregidos. Lo que el
> original dejaba pasar se muestra en el paso 7.

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

Después del **paso 6** se suman estas relaciones:

```
 Cliente 1 ───< Venta >─── 1 Usuario (vendedor)       Usuario 1 ───< Usuario (idJefe)
   (opcional: NULL = consumidor final)                 (auto-relación: cada uno tiene un jefe)

 Producto 1 ───< ProductoProveedor >─── 1 Proveedor
                 (costo, diasEntrega, esPrincipal: datos de la PAREJA producto-proveedor)
```

| Tipo de relación | Dónde está en este proyecto |
|---|---|
| Uno a muchos obligatoria | `Rol → Usuario`, `Venta → DetalleVenta`, `Usuario → Venta` (vendedor) |
| Uno a muchos opcional | `Cliente → Venta` (`idCliente` puede ser NULL), `Categoria → Producto` |
| Muchos a muchos | `Menu ↔ Rol` con `MenuRol` |
| Muchos a muchos con datos propios | `Producto ↔ Proveedor` con `ProductoProveedor` (costo, días de entrega) |
| Auto-relación | `Usuario.idJefe → Usuario` |

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
4. Sigue con los pasos 3 a 8 **en orden** (el 6 cambia tablas que usan el 7 y el 8).
   Para empezar de cero, vuelve a correr el paso 1.

Desde la terminal (Windows, autenticación de Windows):

```bash
sqlcmd -S . -E -i sqlserver\01_crear_base_y_tablas.sql,sqlserver\02_datos.sql
```

### PostgreSQL

```bash
createdb dbventa_app
psql -d dbventa_app -f proyecto-02-sistema-de-ventas/postgresql/instalar.sql
psql -d dbventa_app -f proyecto-02-sistema-de-ventas/postgresql/03_consultas_por_pantalla.sql
# ... y así con 04, 05, 06, 07 y 08, en orden
```

El paso 7 crea **roles** (`ventas_rol_cajero`, `ventas_cajero1`...). En PostgreSQL los roles son
de todo el servidor, por eso tu usuario necesita permiso para crear roles (el usuario
`postgres` lo tiene).

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

### Paso 5 · Vistas e índices (`05_vistas_e_indices.sql`)

**Aprendes:** `CREATE INDEX`, `sp_helpindex`, `CREATE VIEW`.

- **Índices** en las llaves foráneas y en `Venta.fechaRegistro`. SQL Server no los crea
  solo, y sin ellos el historial y los reportes leen la tabla completa.
- **Vistas**: `vw_HistorialVenta` (cada venta con cuántos productos y unidades tiene) y
  `vw_VentasPorProducto` (ranking de productos, incluidos los que no se vendieron). En el
  paso 7 las vistas sirven también para dar permisos: el supervisor ve la vista, no las tablas.

### Paso 6 · Relacionar más (`06_relaciones.sql`)

**Aprendes:** `ALTER TABLE ADD ... REFERENCES`, relación opcional vs obligatoria, auto-relación,
muchos a muchos con datos propios, índice único filtrado, `CHECK` con patrones.

| Parte | Qué agrega | La idea importante |
|---|---|---|
| 6.1 | `Cliente` y `Venta.idCliente` | Relación **opcional**: `NULL` = consumidor final. El documento se valida con `CHECK` (cédula 10 dígitos, RUC 13, sin letras) |
| 6.2 | `Venta.idUsuario` (vendedor) | Relación **obligatoria** en una tabla que ya tiene datos: columna NULL → llenarla → `NOT NULL` + FK |
| 6.3 | `Usuario.idJefe` | **Auto-relación**, con un `CHECK` para que nadie sea su propio jefe |
| 6.4 | `Proveedor` y `ProductoProveedor` | Muchos a muchos **con datos propios** (costo, días de entrega) y un **índice único filtrado**: un solo proveedor principal por producto |
| 6.5 | `sp_RegistrarVenta` | Ahora recibe `@idUsuario` y `@idCliente`, y valida cantidades mayores que cero |
| 6.6 | Consultas | Historial con cliente y vendedor, compras por cliente, organigrama, margen por proveedor |

Fíjate en 6.6.1: si unes `Venta` con `Cliente` con `INNER JOIN`, **desaparecen las 6 ventas a
consumidor final**. En una relación opcional casi siempre va `LEFT JOIN`.

### Paso 7 · Seguridad (`07_seguridad.sql`)

**Aprendes:** por qué la seguridad empieza en el `CREATE TABLE`, hash con sal,
`CREATE ROLE`, `GRANT`, `DENY`, permisos por columna, `EXECUTE AS`, inyección SQL.

**7.1 · Lo que el script original dejaba pasar.** Se recrea la tabla `Usuario` del script
original en una tabla temporal y se le meten datos absurdos: dos usuarios con el mismo
correo y un usuario sin nombre, sin rol y sin clave. Los acepta todos. Por eso el paso 1
agregó `NOT NULL`, `UNIQUE` y `CHECK`.

**7.2 · Claves con hash.** La base guarda `clave = '123'`. Si alguien copia la base, ve todas
las claves. Se muestra cómo guardar un **hash con sal** (huella irreversible, distinta por
usuario) y comparar hashes en el login. Se deshace al final para no romper la pantalla de
login. En la app real lo hace la API con BCrypt.

**7.3 · Mínimo privilegio.** La API nunca debe conectarse como `sa`. Se crean dos roles:

| Rol | Puede | No puede |
|---|---|---|
| `rol_cajero` | Ver productos y clientes, crear clientes, vender con `sp_RegistrarVenta` | Cambiar precios, borrar ventas, leer claves |
| `rol_supervisor` | Ver las vistas de historial, los reportes y la lista de usuarios | Ver la columna `clave` (`DENY` por columna), leer las tablas de ventas directamente |

Lo interesante: el cajero **no** tiene permiso de escribir en `Venta`, pero sí puede vender,
porque el procedimiento lo hace por él. Así solo se pueden cambiar datos de la forma que el
procedimiento permite. En SQL Server esto se llama *encadenamiento de propiedad*; en PostgreSQL
se logra con `SECURITY DEFINER`.

**7.4 · Inyección SQL en el login.** Un procedimiento arma el SQL pegando el correo y la clave.
Escribiendo `' OR 1=1 --` como correo se entra **como Administrador sin saber la clave**. La
versión con parámetros devuelve 0 filas con el mismo ataque.

### Paso 8 · Errores comunes (`08_errores_comunes.sql`)

**Aprendes:** a leer mensajes de error, `TRY...CATCH`, `XACT_STATE()`, y a reconocer las
consultas que "funcionan" pero dan números equivocados.

**Parte A · La base te protege** (cada intento muestra su número de error):

| # | Intento | Error SQL Server | Error PostgreSQL |
|---|---|---|---|
| A1 | Vender un producto que no existe | 547 (FK) | 23503 |
| A2 | Borrar una categoría con productos | 547 (FK) | 23503 |
| A3 | Dejar el stock en negativo | 547 (CHECK) | 23514 |
| A4 | Precio cero | 547 (CHECK) | 23514 |
| A5 | Dos usuarios con el mismo correo | 2627 (UNIQUE) | 23505 |
| A6 | Usuario sin rol | 515 (NOT NULL) | 23502 |
| A7 | Cédula con letras | 547 (CHECK) | 23514 |
| A8 | Venta sin vendedor | 515 (NOT NULL) | 23502 |
| A9 | Número de factura repetido | 2627 (UNIQUE) | 23505 |
| A10 | Dos proveedores principales para un producto | 2601 (índice único filtrado) | 23505 |
| A11 | Borrar un cliente con ventas | 547 (FK) | 23503 |
| A12 | Venta a un cliente que no existe (dentro del procedimiento) | 547, y la transacción se deshace entera | 23503 |
| A13 | Convertir `'12abc'` a número | 245 | 22P02 |
| A14 | Borrar la tabla `Producto` | 3726 | 2BP01 |

A12 enseña algo extra: cuando el error ocurre **dentro de una transacción**, el `CATCH`
tiene que hacer `ROLLBACK` (se revisa con `XACT_STATE()`); si no, SQL Server avisa al final
del lote que quedó una transacción sin cerrar.

**Parte B · La base NO te avisa** (el resultado sale, pero está mal):

| # | Error | Mal | Bien |
|---|---|---|---|
| B1 | Sumar `Venta.total` después de unir con `DetalleVenta` | 99 530.00 | 53 520.00 |
| B2 | `INNER JOIN` con `Cliente` (relación opcional) | 18 ventas | 24 ventas |
| B3 | `NOT IN` con una subconsulta que trae `NULL` | 0 clientes | 1 cliente |
| B4 | `= NULL` en vez de `IS NULL` | 0 | 6 |
| B5 | Calcular ventas pasadas con el precio actual | 6 000.00 | 5 000.00 |
| B6 | Dinero en `FLOAT`: 0.1 + 0.2 = 0.3 | distinto | igual con `DECIMAL` |
| B7 | División entera | 1 | 1.5 |
| B8 | `UPDATE` sin `WHERE` | 15 productos cambiados | 1 |
| B9 | Filtrar la tabla derecha en el `WHERE` de un `LEFT JOIN` | 5 categorías | 6 |

### Paso 9 · Ejercicios (`ejercicios.sql`)

22 ejercicios, cada uno con el resultado esperado. Soluciones en `sqlserver/09_soluciones.sql`
y `postgresql/09_soluciones.sql`.

| Nivel | Ejercicios | Ejemplos |
|---|---|---|
| JOINs básicos | 1–5 | Productos con categoría, menús por rol, quién puede ver "Reportes" |
| Agrupaciones y subconsultas | 6–13 | Ventas por día y por semana, porcentaje por tipo de pago, top 5, productos sin ventas |
| Avanzados | 14–16 | Porcentaje de cada línea en su venta (ventanas), productos que se compran juntos, stock inicial |
| Relaciones del paso 6 | 17–21 | Compras por cliente, clientes sin compras, ventas por vendedor con su jefe, cadena de mando (CTE recursiva), ahorro por proveedor |
| Arregla la consulta | 22 | Un total inflado por un `JOIN` que repite filas |

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
| Validar solo dígitos | `documento NOT LIKE '%[^0-9]%'` | `documento ~ '^[0-9]+$'` (expresión regular) |
| Índice único sobre algunas filas | Índice **filtrado** `... WHERE esPrincipal = 1` | Índice **parcial** `... WHERE esPrincipal` |
| Quitar un permiso a una columna | `DENY SELECT ON Usuario (clave)` | No hay `DENY`: se hace `GRANT` solo de las columnas permitidas |
| Probar como otro usuario | `EXECUTE AS USER = 'x'` ... `REVERT` | `SET ROLE x` ... `RESET ROLE` |
| Procedimiento con permisos de su dueño | Automático (encadenamiento de propiedad) | `SECURITY DEFINER` |
| Quién puede ejecutar una función nueva | Nadie, hasta que se da `GRANT EXECUTE` | **Todos** (`PUBLIC`): hay que hacer `REVOKE` |
| Convertir sin error | `TRY_CAST('12abc' AS INT)` → NULL | No existe: se valida antes con `~` |

---

## Ideas para seguir avanzando

Estas mejoras cambian las tablas, así que la app también tendría que cambiar. Varias ya
están hechas en la base ampliada de la ruta ([`postgresql/00_base_de_datos`](../postgresql/00_base_de_datos/)):

Vendedor (`Venta.idUsuario`), clientes y proveedores ya se agregaron en el paso 6. Faltan:

| Mejora | Para qué | Dónde verla |
|---|---|---|
| `Venta.estado` (PAGADA / ANULADA) | Anular sin borrar | Ruta, módulos 03 y 10 |
| `subtotal` e `impuesto` (IVA 15 %) | Comprobantes reales | Ruta, módulo 00 |
| Trigger que descuenta stock | Que el stock baje aunque la venta no venga de la app | Ruta, módulo 10 |
| Auditoría de cambios de precio | Saber quién cambió qué y cuándo | Ruta, módulo 10 |
