# proyecto-VENTASANGULAR (SQL Server)

Scripts originales de la base de datos del **sistema de ventas en Angular**, escritos para
**SQL Server** (T-SQL). Se guardan tal como se usaron en el proyecto.

| Archivo | Qué hace |
|---|---|
| `01_CREAR_BASE_DATOS_TABLAS.txt` | Crea la base `DBVENTA` y sus 9 tablas: `Rol`, `Menu`, `MenuRol`, `Usuario`, `Categoria`, `Producto`, `NumeroDocumento`, `Venta`, `DetalleVenta` |
| `02_INSERTAR DATOS EN TABLAS.txt` | Carga roles, un usuario, 6 categorías, 15 productos y los menús de cada rol |

## Cómo correrlo en SQL Server

1. Abre **SQL Server Management Studio** (SSMS) y conéctate a tu servidor.
2. Abre `01_CREAR_BASE_DATOS_TABLAS.txt`, ejecútalo (F5).
3. Abre `02_INSERTAR DATOS EN TABLAS.txt` y ejecútalo.

La última línea del primer script (`ALTER AUTHORIZATION ... TO sa`) solo sirve para poder
crear diagramas en SSMS.

## ¿Y en PostgreSQL?

La misma base, traducida y ampliada con clientes, proveedores y 60 ventas, está en
[`postgresql/00_base_de_datos`](../postgresql/00_base_de_datos/). Es la que usa la ruta de aprendizaje.
