# Proyecto 01 · Lista de Tareas

> Es el primer proyecto: empieza aquí. Después sigue con el
> [Proyecto 02 · Sistema de Ventas](../proyecto-02-sistema-de-ventas/).

El script original del proyecto (Angular / Blazor) creaba una sola tabla con dos columnas:

```sql
create table Tarea(idTarea int primary key identity, nombre varchar(40))
```

Eso alcanza para un "hola mundo", pero una app de tareas de verdad necesita saber **si la
tarea está hecha, cuándo vence, de quién es, en qué lista está y qué etiquetas tiene**.
Esta carpeta hace crecer esa tabla **paso a paso, sin borrarla**, igual que pasa en un
proyecto real: la base ya tiene datos y hay que modificarla con `ALTER TABLE`. Termina con
7 tablas relacionadas, todos los tipos de relación, seguridad (claves, permisos, seguridad
por fila, inyección SQL) y una colección de errores que conviene ver una vez para no
cometerlos nunca.

Cada paso está en **SQL Server** (`sqlserver/`) y en **PostgreSQL** (`postgresql/`), con los
mismos nombres de archivo y los mismos resultados. Todo se probó en SQL Server 2022 y en
PostgreSQL 16.

> Fecha de referencia de todo el proyecto: **"hoy" = 2026-11-23**. Así las consultas de
> "vencidas" o "para hoy" siempre dan el mismo resultado, sin importar cuándo las corras.

---

## Contenido de la carpeta

| Archivo | Qué hace |
|---|---|
| `sqlserver/01_version_original.sql` | Paso 1: la base `DBTareas` y la tabla `Tarea` tal como estaban en el script original |
| `sqlserver/02_mejorar_tarea.sql` | Paso 2: `ALTER TABLE` para agregar estado, prioridad y fechas |
| `sqlserver/03_usuarios_y_listas.sql` | Paso 3: tablas `Usuario` y `Lista` (uno a muchos) |
| `sqlserver/04_etiquetas.sql` | Paso 4: `Etiqueta` y la tabla puente `TareaEtiqueta` (muchos a muchos) |
| `sqlserver/05_datos.sql` | Paso 5: datos de ejemplo y cerrar la relación Tarea → Lista |
| `sqlserver/06_consultas_de_la_app.sql` | Paso 6: el SQL que dispara cada botón de la app |
| `sqlserver/07_reportes.sql` | Paso 7: reportes de progreso, retrasos y etiquetas |
| `sqlserver/08_trigger_y_procedimiento.sql` | Paso 8: un trigger y un procedimiento almacenado |
| `sqlserver/09_relaciones.sql` | Paso 9: subtareas (auto-relación), listas compartidas y credenciales (uno a uno) |
| `sqlserver/10_seguridad.sql` | Paso 10: tabla mal hecha vs bien hecha, claves con hash, permisos, seguridad por fila e inyección SQL |
| `sqlserver/11_errores_comunes.sql` | Paso 11: 14 errores que la base rechaza y 9 que acepta sin avisar |
| `sqlserver/12_soluciones.sql` | Soluciones de `ejercicios.sql` |
| `postgresql/` | Los mismos pasos en PostgreSQL, más `instalar.sql` (pasos 1 a 5 de una vez) |
| `ejercicios.sql` | 19 ejercicios con el número de filas esperado (sirven para los dos motores) |

> El script original estaba en `Query.txt`. Ya no hace falta: el paso 1 es ese mismo script,
> ordenado y listo para correr.

---

## La app en 1 minuto

Es una lista de tareas al estilo Todoist o Microsoft To Do:

| Pantalla / botón | Qué hace | Consulta |
|---|---|---|
| Inicio | Muestra mis listas y cuántas tareas pendientes tiene cada una | 6.1 |
| Abrir una lista | Tareas pendientes primero, luego por prioridad y fecha límite | 6.2 y 6.3 |
| Nueva tarea | Crea la tarea y le pone etiquetas | 6.4 |
| Editar | Cambia nombre, prioridad o fecha | 6.5 |
| Casilla ✔ | Marca o desmarca como completada | 6.6 |
| Eliminar | Borra la tarea (y sus etiquetas, solas) | 6.7 |
| Buscador | Busca texto en el nombre o la descripción | 6.8 |
| Filtros rápidos | Vencidas, para hoy, próximos 7 días | 6.9 |
| Filtro por etiqueta | Todas las tareas `urgente` pendientes | 6.10 |

---

## El modelo de datos

Al final del paso 5 la base queda así:

```
  Usuario 1 ───< Lista 1 ───< Tarea 1 ───< TareaEtiqueta >─── 1 Etiqueta
  (dueño)        (Casa,        (lo que       (tabla puente:     (urgente,
                  Trabajo...)   hay que       qué etiquetas      trabajo,
                                hacer)        tiene cada tarea)  casa...)
```

- `1 ───<` se lee "uno a muchos": un usuario tiene muchas listas; una lista tiene muchas tareas.
- `TareaEtiqueta` existe porque la relación Tarea–Etiqueta es **muchos a muchos**: una tarea
  tiene varias etiquetas y una etiqueta está en varias tareas. Es el mismo patrón que
  `MenuRol` en el proyecto de ventas.

Y al final del paso 9:

```
                ┌───────────── ListaCompartida ─────────────┐
                │  (idLista, idUsuario, permiso LEER/EDITAR) │
                *                                            *
  Usuario 1 ───< Lista 1 ───< Tarea 1 ───< TareaEtiqueta >─── 1 Etiqueta
     1                          │  ^
     │                          └──┘ idTareaPadre (subtareas)
     1
  UsuarioCredencial  (uno a uno: hash de la clave, intentos fallidos)
```

| Tipo de relación | Dónde está | Cómo se hace |
|---|---|---|
| Uno a muchos | `Usuario → Lista → Tarea` | FK en la tabla "muchos" |
| Muchos a muchos | `Tarea ↔ Etiqueta` | Tabla puente con llave primaria compuesta |
| Muchos a muchos con datos propios | `Lista ↔ Usuario` (compartir) | La tabla puente guarda además el `permiso` y la fecha |
| Auto-relación | `Tarea.idTareaPadre → Tarea` | FK hacia la misma tabla. Con una FK **compuesta** `(idTareaPadre, idLista)` la base exige que la subtarea esté en la misma lista |
| Uno a uno | `Usuario ↔ UsuarioCredencial` | La llave primaria **es** la llave foránea. Se separa por seguridad: se puede dar permiso sobre `Usuario` sin dar acceso a las claves |

### Tabla por tabla

**Usuario**: quién usa la app.

| Columna | Tipo | Para qué |
|---|---|---|
| idUsuario | INT identidad | Llave primaria |
| nombre | VARCHAR(100) | Nombre visible |
| correo | VARCHAR(100) UNIQUE | Login; no puede repetirse |
| fechaRegistro | DATETIME / TIMESTAMP | Cuándo se registró |

**Lista**: agrupa tareas ("Trabajo", "Casa").

| Columna | Tipo | Para qué |
|---|---|---|
| idLista | INT identidad | Llave primaria |
| nombre | VARCHAR(60) | Nombre de la lista |
| color | CHAR(7) | Color en la app, por ejemplo `#3F51B5` |
| idUsuario | INT → Usuario | Dueño de la lista |

**Tarea**: la tabla original, ya crecida.

| Columna | Tipo | Para qué |
|---|---|---|
| idTarea | INT identidad | Llave primaria (original) |
| nombre | VARCHAR(100) NOT NULL | Era VARCHAR(40) y aceptaba NULL; se cambia en el paso 2 |
| descripcion | VARCHAR(300) | Opcional |
| completada | BIT / BOOLEAN | 0 = pendiente, 1 = hecha |
| prioridad | TINYINT / SMALLINT | 1 alta, 2 media, 3 baja (CHECK entre 1 y 3) |
| fechaCreacion | DATETIME / TIMESTAMP | Cuándo se creó |
| fechaLimite | DATE | Cuándo vence; NULL = sin fecha |
| fechaCompletada | DATETIME / TIMESTAMP | Cuándo se marcó; la llena el trigger del paso 8 |
| idLista | INT → Lista | Lista a la que pertenece |

**Etiqueta** y **TareaEtiqueta**

| Tabla | Columnas | Detalle |
|---|---|---|
| Etiqueta | idEtiqueta, nombre UNIQUE | `urgente`, `trabajo`, `casa`... |
| TareaEtiqueta | idTarea, idEtiqueta | Llave primaria **compuesta** (no se repite el par) y `ON DELETE CASCADE` en las dos llaves |

### Los datos de ejemplo (paso 5)

Están pensados para que cada tipo de JOIN tenga algo que mostrar:

| Dato | Para qué sirve |
|---|---|
| 4 usuarios; **Pedro Sin Listas** no tiene listas | `LEFT JOIN` y "usuarios sin..." |
| 6 listas; **Viaje a Cuenca** está vacía | Contar con `LEFT JOIN` y que salga 0 |
| La lista **Gimnasio** tiene todas sus tareas completadas | "Listas donde TODO está hecho" |
| 25 tareas, algunas sin fecha límite y otras vencidas | Manejo de `NULL` y fechas |
| 9 etiquetas; **personal** no se usa | Anti-join (`NOT EXISTS`) |
| 35 vínculos tarea–etiqueta | Muchos a muchos, pares de etiquetas |

---

## Instalar

### SQL Server (SSMS)

1. Abre **SQL Server Management Studio** y conéctate a tu servidor.
2. Abre `sqlserver/01_version_original.sql` y ejecútalo con **F5**. Crea la base `DBTareas`;
   si ya existe, la borra y la crea de nuevo.
3. Ejecuta en orden `02`, `03`, `04` y `05`. **El orden importa**: cada paso modifica lo que
   dejó el anterior.
4. Sigue con `06` a `11`, también en orden, y resuelve `ejercicios.sql`.
   Para empezar de cero, vuelve a correr el paso 1.

Desde la terminal (Windows, autenticación de Windows):

```bash
cd proyecto-01-lista-de-tareas\sqlserver
for %f in (01 02 03 04 05 06 07 08 09 10 11) do sqlcmd -S localhost -E -b -i %f_*.sql
```

> Si usas usuario y clave en vez de `-E`: `sqlcmd -S localhost -U sa -P "tu_clave" -C -b -i archivo.sql`.

### PostgreSQL

```bash
createdb dbtareas
psql -d dbtareas -f proyecto-01-lista-de-tareas/postgresql/instalar.sql
psql -d dbtareas -f proyecto-01-lista-de-tareas/postgresql/06_consultas_de_la_app.sql
```

`instalar.sql` corre los pasos 1 a 5. Después corre `06` a `11` uno por uno, en orden.
El paso 10 crea **roles** (`rol_app_tareas`, `app_tareas`...). En PostgreSQL los roles son de
todo el servidor, por eso tu usuario necesita permiso para crear roles (`postgres` lo tiene). En pgAdmin: abre la base `dbtareas`, abre el
**Query Tool**, carga cada archivo y ejecútalo con **F5**.

---

## Paso a paso

### Paso 1 · La versión original (`01_version_original.sql`)

Es el script original limpio y ejecutable de una vez (con `GO` entre bloques en SQL Server). El
punto de partida: una tabla `Tarea (idTarea, nombre)` con 2 filas.

**Qué aprendes:** `CREATE DATABASE`, `CREATE TABLE`, `IDENTITY` frente a
`GENERATED ALWAYS AS IDENTITY`.

### Paso 2 · Hacer crecer la tabla (`02_mejorar_tarea.sql`)

En lugar de borrar la tabla y crearla de nuevo (perderías los datos), se modifica:

```sql
ALTER TABLE Tarea ADD
    completada BIT     NOT NULL CONSTRAINT DF_Tarea_completada DEFAULT 0,
    prioridad  TINYINT NOT NULL CONSTRAINT DF_Tarea_prioridad  DEFAULT 2,
    fechaLimite DATE NULL, ...;
```

- Si agregas una columna `NOT NULL` con `DEFAULT`, las filas que ya existían reciben ese valor.
  Sin `DEFAULT`, el `ALTER` falla porque esas filas quedarían en NULL.
- Las reglas de negocio van en `CHECK`: la prioridad va de 1 a 3, y una tarea completada debe
  tener `fechaCompletada` (y una pendiente no).
- `ALTER COLUMN` cambia el tipo: `nombre` pasa de `VARCHAR(40)` a `VARCHAR(100) NOT NULL`.

**Qué aprendes:** `ALTER TABLE ADD / ALTER COLUMN`, `DEFAULT`, `CHECK`, restricciones con nombre.

### Paso 3 · Usuarios y listas (`03_usuarios_y_listas.sql`)

Se pasa de 1 tabla a 3 relacionadas. Lo interesante es cómo se conecta `Tarea` (que ya tiene
filas) con `Lista`:

1. Agregar `idLista` **permitiendo NULL** (si fuera NOT NULL, las tareas existentes fallarían).
2. Llenar la columna (se hace en el paso 5, cuando ya existen listas).
3. Recién entonces volverla `NOT NULL` y crear la llave foránea.

Este patrón de tres tiempos es el que se usa en producción para no romper datos.

**Qué aprendes:** relaciones uno a muchos, `FOREIGN KEY`, migrar una tabla con datos.

### Paso 4 · Etiquetas (`04_etiquetas.sql`)

Muchos a muchos con una tabla puente. `PRIMARY KEY (idTarea, idEtiqueta)` impide poner dos
veces la misma etiqueta a una tarea, y `ON DELETE CASCADE` hace que al borrar una tarea sus
filas en `TareaEtiqueta` se borren solas.

**Qué aprendes:** llave compuesta, tabla puente, `ON DELETE CASCADE`.

### Paso 5 · Datos y cierre de la relación (`05_datos.sql`)

Carga los datos de ejemplo (tabla de arriba), completa las 2 tareas originales con `UPDATE`
y cierra el paso 3: `idLista` pasa a `NOT NULL` y se crea `FK_Tarea_Lista`.

**Qué aprendes:** `INSERT` de varias filas, `UPDATE`, el orden correcto para cargar datos
relacionados (primero padres, luego hijos).

### Paso 6 · El SQL de la app (`06_consultas_de_la_app.sql`)

Cada consulta corresponde a un botón (ver "La app en 1 minuto"). Algunas que vale la pena mirar:

- **6.1** cuenta pendientes por lista con `LEFT JOIN` y la condición `completada = 0` dentro
  del `ON` (no en el `WHERE`), para que una lista sin pendientes salga con 0 en vez de desaparecer.
- **6.3** junta las etiquetas en una sola columna con `STRING_AGG`.
- **6.4 a 6.7** son `INSERT`, `UPDATE` y `DELETE` dentro de una transacción que termina en
  `ROLLBACK`, así puedes correrlas muchas veces sin cambiar los datos.
- **6.9** filtra por rangos de fecha relativos a "hoy".

### Paso 7 · Reportes (`07_reportes.sql`)

| # | Reporte | Técnica |
|---|---|---|
| 7.1 | Progreso de cada lista (porcentaje completado) | `LEFT JOIN`, agregación, división sin error por cero |
| 7.2 | Resumen por usuario | Varios `LEFT JOIN` sin duplicar conteos |
| 7.3 | Etiquetas más usadas | `LEFT JOIN` a la tabla puente |
| 7.4 | Días promedio para completar, por lista | Diferencia de fechas |
| 7.5 | Tareas completadas tarde | Comparar dos fechas de la misma fila |
| 7.6 | Completadas por semana ISO | `DATEPART(ISO_WEEK)` / `EXTRACT(WEEK)` |
| 7.7 | La tarea más urgente de cada lista | `ROW_NUMBER() OVER (PARTITION BY ...)` |
| 7.8 | Pares de etiquetas que aparecen juntas | **Self-join** sobre `TareaEtiqueta` |

### Paso 8 · Trigger y procedimiento (`08_trigger_y_procedimiento.sql`)

**El trigger** llena `fechaCompletada` sola cuando marcas una tarea, y la vacía si la
desmarcas. Así ninguna pantalla (Angular, Blazor, un script) puede olvidarse de hacerlo.

| | SQL Server | PostgreSQL |
|---|---|---|
| Tipo | `AFTER INSERT, UPDATE` (no existe `BEFORE`) | `BEFORE INSERT OR UPDATE ... FOR EACH ROW` |
| Cómo ve las filas | Tabla `inserted` (puede traer **varias** filas) | `NEW` (una fila por vez) |
| Qué hace | `UPDATE Tarea ... JOIN inserted` | Modifica `NEW` antes de guardar |
| El CHECK del paso 2 | Se quita: el AFTER corre después de validar | Se queda: el BEFORE corre antes del CHECK |

> **¿Trigger o código de la app?** Aquí conviene trigger porque es una regla de los datos
> (fecha coherente con el estado) y hay más de una app escribiendo en la tabla. No conviene
> para cosas como enviar un correo al completar una tarea: eso es lógica de la app y en un
> trigger es difícil de depurar. Más detalle en
> [`postgresql/10_triggers`](../postgresql/10_triggers/).

**El procedimiento** `sp_CrearTarea` (en PostgreSQL, la función `fn_crear_tarea`) crea una
tarea con sus etiquetas en un solo llamado. Recibe las etiquetas como texto
`'urgente,trabajo'`, lo separa con `STRING_SPLIT` / `string_to_array` + `unnest`, crea las
etiquetas que no existan y devuelve el id nuevo (`OUTPUT` en T-SQL, `RETURNING` en PostgreSQL).

### Paso 9 · Más relaciones (`09_relaciones.sql`)

**Qué aprendes:** auto-relación, llave foránea compuesta, muchos a muchos con datos propios,
uno a uno, CTE recursiva, `UNION ALL`.

- **Subtareas.** `Tarea.idTareaPadre` apunta a otra tarea. "Publicar en producción" tiene 3
  subtareas y "Terminar curso de SQL" tiene 2. Con una FK simple, alguien podría colgar una
  tarea de Ana debajo de una de Luis; la FK compuesta `(idTareaPadre, idLista) → (idTarea, idLista)`
  lo impide. Para eso `(idTarea, idLista)` tiene que ser `UNIQUE`.
- **Listas compartidas.** `ListaCompartida` une listas y usuarios, y guarda el permiso
  (`LEER` o `EDITAR`). Si se borra la lista, se borra con quién estaba compartida
  (`ON DELETE CASCADE`); si se intenta borrar al usuario, falla, porque borrar personas no
  debe pasar "sin querer".
- **Credenciales.** `UsuarioCredencial` tiene una fila por usuario como máximo (su llave
  primaria es la FK). Se llena en el paso 10.
- **Consultas:** el árbol de tareas con una CTE recursiva, el progreso de cada tarea padre
  y todas las listas que ve cada usuario (propias + compartidas).

### Paso 10 · Seguridad (`10_seguridad.sql`)

**Qué aprendes:** que la seguridad empieza en el `CREATE TABLE`, hash con sal, bloqueo por
intentos fallidos, roles, `GRANT`, permisos por columna, seguridad a nivel de fila, inyección SQL.

**10.1 · Una tabla mal hecha.** Se crea una tabla temporal "rápida": todo texto, todo
opcional, sin llave primaria. Acepta un id repetido, una tarea sin nombre, la prioridad
`'altísima'`, la fecha `'30/02/2026'` y el mismo usuario escrito de tres formas. Así se ve
lo que evita cada regla de la tabla `Tarea` real:

| Problema en la tabla mal hecha | Solución en la tabla real |
|---|---|
| id repetido | `PRIMARY KEY` + `IDENTITY` |
| nombre vacío o NULL | `NOT NULL` y un tamaño máximo |
| prioridad `'altísima'` o `-5` | `TINYINT` + `CHECK (prioridad BETWEEN 1 AND 3)` |
| completada `'tal vez'` | `BIT NOT NULL DEFAULT 0` |
| fecha `'30/02/2026'` | tipo `DATE`: rechaza fechas que no existen |
| usuario escrito a mano | `idLista` + `FOREIGN KEY` |

**10.2 · Claves.** Se guarda un **hash con sal** en `UsuarioCredencial` (clave de ejemplo
`Tareas2026!`). El procedimiento `sp_Login` (en PostgreSQL `fn_login`) compara hashes,
responde lo mismo si el correo no existe o si la clave está mal (para no revelar qué correos
están registrados) y **bloquea la cuenta 15 minutos** al tercer intento fallido.

**10.3 · Mínimo privilegio.** La app nunca se conecta como `sa` o como dueño de la base:

| Rol | Puede | No puede |
|---|---|---|
| `rol_app` (usuario `app_tareas`) | Leer y escribir listas, tareas y etiquetas; leer nombre y correo de `Usuario`; usar `sp_Login` y `sp_CrearTarea` | Leer `UsuarioCredencial`, ver otras columnas de `Usuario`, borrar tablas |
| `rol_reportes` (usuario `analista`) | Leer la vista `vw_ResumenLista` | Leer las tablas |

**10.4 · Seguridad a nivel de fila (RLS).** Con permisos normales, la app puede leer las
tareas de **todos** los usuarios. Con una política de seguridad, la base filtra sola: cada
usuario ve solo las tareas de sus listas y de las compartidas con él, y no puede crear
tareas en listas ajenas. Ana ve 17 tareas, Pedro 0, y el administrador las 25.

**10.5 · Inyección SQL.** El buscador arma el SQL pegando el texto del usuario. Escribiendo
`' OR 1=1 --` en el buscador, Ana ve las 25 tareas de todos. La versión con parámetros
devuelve 0 filas.

### Paso 11 · Errores comunes (`11_errores_comunes.sql`)

**Qué aprendes:** a leer los mensajes de error y a reconocer las consultas que "funcionan"
pero mienten.

**Parte A · La base te protege:**

| # | Intento | SQL Server | PostgreSQL |
|---|---|---|---|
| A1 | Tarea en una lista que no existe | 547 (FK) | 23503 |
| A2 | Borrar una lista que tiene tareas | 547 (FK) | 23503 |
| A3 | Prioridad 5 | 547 (CHECK) | 23514 |
| A4 | Tarea sin nombre | 515 (NOT NULL) | 23502 |
| A5 | Etiqueta repetida | 2627 (UNIQUE) | 23505 |
| A6 | La misma etiqueta dos veces en una tarea | 2627 (PK compuesta) | 23505 |
| A7 | Nombre de 150 caracteres | 2628 | 22001 |
| A8 | Fecha `2026-02-30` | 241 | 22008 |
| A9 | Subtarea de una tarea de otra lista | 547 (FK compuesta) | 23503 |
| A10 | Una tarea subtarea de sí misma | 547 (CHECK) | 23514 |
| A11 | Escribir el id a mano | 544 | 428C9 |
| A12 | Columna `NOT NULL` sin `DEFAULT` en una tabla con datos | 4901 | 23502 |
| A13 | Borrar una tabla de la que dependen otras | 3726 | 2BP01 |
| A14 | Dividir entre cero (lista vacía) | 8134 | 22012 |

**Parte B · La base NO te avisa:**

| # | Error | Mal | Bien |
|---|---|---|---|
| B1 | `fechaLimite = NULL` | 0 | 4 con `IS NULL` |
| B2 | `NOT IN` con una subconsulta que trae `NULL` | 0 | 23 con `NOT EXISTS` |
| B3 | `COUNT(*)` en un `LEFT JOIN` | lista vacía con 1 | 0 con `COUNT(t.idTarea)` |
| B4 | Filtro de la tabla derecha en el `WHERE` | 4 listas | 6 con la condición en el `ON` |
| B5 | Unir sin la condición correcta | 100 filas | 25 |
| B6 | División entera | 0 | 48.0 |
| B7 | `UPDATE` sin `WHERE` | 25 tareas cambiadas | 1 |
| B8 | `ON DELETE CASCADE` al borrar una etiqueta | 5 vínculos borrados sin aviso | revisar antes de usar CASCADE |
| B9 | Fechas guardadas como texto | se ordenan mal | tipo `DATE` |

### Ejercicios (`ejercicios.sql`)

19 ejercicios. Cada uno dice cuántas filas debe devolver tu consulta, para que sepas si vas
bien antes de mirar la solución.

| Nivel | Ejercicios | Temas |
|---|---|---|
| 1 | 1 a 6 | JOINs, `LEFT JOIN`, `NULL`, anti-join |
| 2 | 7 a 11 | `GROUP BY`, `HAVING`, fechas, "todas completadas" |
| 3 | 12 a 15 | Funciones de ventana, `RANK`, retos |
| 4 | 16 y 17 | Relaciones del paso 9: subtareas y listas compartidas |
| 5 | 18 y 19 | **Arregla la consulta**: dos consultas que no dan error pero devuelven mal |

Soluciones: `sqlserver/12_soluciones.sql` y `postgresql/12_soluciones.sql`.

---

## SQL Server vs PostgreSQL en este proyecto

| Tema | SQL Server | PostgreSQL |
|---|---|---|
| Autonumérico | `INT IDENTITY(1,1)` | `INT GENERATED ALWAYS AS IDENTITY` |
| Verdadero / falso | `BIT` (0 / 1) | `BOOLEAN` (`TRUE` / `FALSE`) |
| Entero pequeño | `TINYINT` (0 a 255) | `SMALLINT` (no hay TINYINT) |
| Fecha y hora actual | `GETDATE()` | `now()` |
| Cambiar tipo de columna | `ALTER COLUMN nombre VARCHAR(100) NOT NULL` | `ALTER COLUMN nombre TYPE VARCHAR(100), ALTER COLUMN nombre SET NOT NULL` |
| Separar lotes | `GO` | No hace falta |
| Unir textos | `STRING_AGG(x, ', ') WITHIN GROUP (ORDER BY x)` | `STRING_AGG(x, ', ' ORDER BY x)` |
| Contar con condición | `SUM(CASE WHEN ... THEN 1 ELSE 0 END)` | `COUNT(*) FILTER (WHERE ...)` |
| Días entre fechas | `DATEDIFF(DAY, a, b)` | `b - a` (con fechas `DATE`) |
| Semana ISO | `DATEPART(ISO_WEEK, f)` | `EXTRACT(WEEK FROM f)` |
| Formato `YYYY-MM` | `FORMAT(f, 'yyyy-MM')` | `to_char(f, 'YYYY-MM')` |
| Separar `'a,b,c'` | `STRING_SPLIT(@txt, ',')` | `unnest(string_to_array(txt, ','))` |
| Id recién creado | `SCOPE_IDENTITY()` | `INSERT ... RETURNING idTarea` |
| Trigger | `AFTER` + tabla `inserted` | `BEFORE ... FOR EACH ROW` + `NEW` |
| Hash de clave | `HASHBYTES('SHA2_256', sal + clave)` con `CRYPT_GEN_RANDOM(16)` | `crypt(clave, gen_salt('bf'))` (pgcrypto, bcrypt) |
| Probar como otro usuario | `EXECUTE AS USER = 'x'` ... `REVERT` | `SET ROLE x` ... `RESET ROLE` |
| Quién ejecuta una función nueva | Nadie, hasta `GRANT EXECUTE` | **Todos** (`PUBLIC`): hay que hacer `REVOKE` |
| Función con permisos de su dueño | Automático (encadenamiento de propiedad) | `SECURITY DEFINER` |
| Seguridad por fila | `CREATE SECURITY POLICY` + función con `SESSION_CONTEXT` | `ENABLE ROW LEVEL SECURITY` + `CREATE POLICY` con `current_setting` |
| Capturar un error | `BEGIN TRY ... BEGIN CATCH`, `ERROR_NUMBER()` | `EXCEPTION WHEN ... THEN`, `SQLSTATE` |
| Mayúsculas al comparar texto | No las distingue (collation por defecto) | Sí las distingue: `'Ana' <> 'ana'` |

Guía completa de diferencias: [`docs/postgresql_vs_sqlserver.md`](../docs/postgresql_vs_sqlserver.md).

---

## Ideas para seguir avanzando

Subtareas y listas compartidas ya están en el paso 9. Otras ideas:

1. **Permiso EDITAR de verdad:** hoy la seguridad por fila deja escribir a quien puede ver.
   Cambia la política para que solo el dueño y quien tiene `EDITAR` puedan escribir.
2. **Que nadie se comparta una lista a sí mismo:** un `CHECK` no puede mirar otra tabla.
   Prueba con un trigger.
3. **Historial:** un trigger que guarde en `TareaHistorial` cada cambio de nombre o prioridad.
4. **Tareas repetitivas:** una columna `repetir` ('DIARIA', 'SEMANAL') y un procedimiento que
   cree la siguiente cuando se completa la actual.
5. **Papelera:** en vez de `DELETE`, una columna `fechaEliminada` y una vista
   `vw_TareaActiva` que solo muestre las no eliminadas.
