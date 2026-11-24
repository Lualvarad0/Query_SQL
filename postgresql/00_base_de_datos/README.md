# 00 · La base de datos de práctica

`DBVENTA` es la base del proyecto de ventas en Angular
([`proyecto-02-sistema-de-ventas`](../../proyecto-02-sistema-de-ventas/)), traducida a PostgreSQL y
ampliada para que las consultas se parezcan a las de un sistema real.

## Instalar

```bash
createdb dbventa
psql -d dbventa -f postgresql/00_base_de_datos/instalar.sql
```

| Archivo | Qué hace |
|---|---|
| `01_esquema.sql` | Crea las 12 tablas con llaves primarias, foráneas, `CHECK` e índices |
| `02_datos.sql` | Carga los datos de ejemplo (siempre los mismos) |
| `instalar.sql` | Corre los dos anteriores en orden. Úsalo también para reiniciar todo |

## Las tablas

```
Rol 1──* Usuario *──1 Usuario (idJefe: su jefe)
Rol 1──* MenuRol *──1 Menu                      (muchos a muchos)

Ciudad 1──* Cliente 1──* Venta *──1 Usuario (vendedor)
Ciudad 1──* Proveedor 1──* Producto *──1 Categoria
Venta 1──* DetalleVenta *──1 Producto
```

| Tabla | Filas | Para qué |
|---|---|---|
| `Rol`, `Menu`, `MenuRol` | 3, 6, 12 | Permisos: qué menús ve cada rol |
| `Usuario` | 7 | Empleados. `idJefe` apunta a otro usuario (organigrama) |
| `Ciudad` | 8 | Ciudades de Ecuador con su provincia |
| `Cliente` | 15 | Personas (cédula) y empresas (RUC). Algunos sin correo o teléfono |
| `Proveedor` | 5 | Quién nos vende cada producto |
| `Categoria` | 7 | Laptops, Monitores, Teclados... |
| `Producto` | 18 | Con `codigo`, `costo`, `precio`, `stock` y `stockMinimo` |
| `Venta` | 60 | Julio a noviembre 2026, con `subtotal`, `impuesto` (IVA 15 %), `total` y `estado` |
| `DetalleVenta` | 140 | Las líneas de cada venta, con `descuento` en porcentaje |
| `NumeroDocumento` | 1 | Último número de factura usado |

El módulo 10 agrega `AuditoriaPrecio` y `MovimientoInventario`.

## Casos especiales (a propósito)

Los datos traen "huecos" para que los `LEFT JOIN` y los `NULL` tengan sentido:

- La ciudad **Esmeraldas** no tiene clientes ni proveedores.
- La clienta **Valeria Paredes** nunca compró.
- La categoría **Impresoras** no tiene productos.
- El producto **cable hdmi generico** no tiene categoría ni proveedor.
- El proveedor **Distribuidora Andina** no tiene productos.
- 4 productos nunca se vendieron.
- 3 ventas no tienen cliente (consumidor final).
- 3 ventas están **ANULADAS**: no deben sumar en los reportes.
- El usuario **pedro inactivo** no tiene ventas, y el administrador no tiene jefe.

## Qué cambió respecto al original de SQL Server

| SQL Server | PostgreSQL |
|---|---|
| `int primary key identity(1,1)` | `INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY` |
| `bit default 1` | `BOOLEAN DEFAULT TRUE` |
| `datetime default getdate()` | `TIMESTAMP DEFAULT now()` |
| `create database` / `use` / `go` | `createdb` y conectarse con `-d dbventa`; no hay `GO` |
