# 10 · Triggers (disparadores)

**Objetivo:** entender qué es un trigger, cómo se crea en PostgreSQL y en SQL Server, y sobre
todo **cuándo conviene usarlo y cuándo no**.

## Qué es

Un trigger es código que la base ejecuta **sola** cuando pasa algo en una tabla
(`INSERT`, `UPDATE` o `DELETE`). Nadie lo llama: se dispara.

```
INSERT INTO DetalleVenta ...
        │
        ├── BEFORE  → puede cambiar la fila (calcular el total) o rechazarla
        ├── se guarda la fila
        └── AFTER   → reacciona: descuenta stock, registra auditoría, recalcula la venta
```

## Cuándo SÍ usar un trigger

| Caso | Ejemplo en este módulo |
|---|---|
| **Auditoría / historial** de cambios | Ejercicio 1: guardar cada cambio de precio |
| **Valores derivados** que nunca deben quedar desincronizados | Ejercicio 2 y 4: total de la línea y totales de la venta |
| **Efectos que deben pasar siempre**, venga el cambio de donde venga | Ejercicio 3: descontar stock al vender |
| **Reglas entre tablas** que un `CHECK` no puede validar | Ejercicio 5: no tocar el detalle de una venta anulada |

La razón de fondo: el trigger se cumple aunque el cambio venga de la app en Angular, de un
script, de otro sistema o de alguien editando a mano en pgAdmin. Nadie puede "olvidarse".

## Cuándo NO usar un trigger

| Situación | Mejor usa |
|---|---|
| Lo resuelve una regla simple de la tabla | `NOT NULL`, `CHECK`, `DEFAULT`, `UNIQUE`, `FOREIGN KEY` |
| Una columna calculada de la misma fila | `GENERATED ALWAYS AS (...) STORED` |
| Lógica de negocio larga o que cambia seguido | El backend (C#, Node...) o un procedimiento (módulo 09) |
| Enviar correos, llamar APIs, escribir archivos | El backend o una cola de mensajes. Si falla el correo, ¿se cae la venta? |
| Cargas masivas (importar 1 millón de filas) | Desactivar triggers durante la carga y validar después |
| Triggers que disparan otros triggers en cadena | Rediseñar: se vuelve imposible de depurar |

**Regla práctica:** si alguien nuevo en el equipo no entendería por qué cambió un dato al hacer
un `INSERT`, el trigger está escondiendo demasiado. Documéntalo o muévelo al código.

## Cómo se escribe en PostgreSQL

Dos piezas: una función que `RETURNS trigger` y el trigger que la llama.

```sql
CREATE OR REPLACE FUNCTION trg_auditar_precio() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO AuditoriaPrecio (idProducto, precioAnterior, precioNuevo)
    VALUES (NEW.idProducto, OLD.precio, NEW.precio);
    RETURN NEW;
END;
$$;

CREATE TRIGGER tr_producto_auditar_precio
AFTER UPDATE OF precio ON Producto
FOR EACH ROW EXECUTE FUNCTION trg_auditar_precio();
```

| Elemento | Significado |
|---|---|
| `BEFORE` / `AFTER` / `INSTEAD OF` | Antes de guardar, después, o en lugar de (solo en vistas) |
| `FOR EACH ROW` / `FOR EACH STATEMENT` | Una vez por fila afectada, o una vez por sentencia |
| `NEW` / `OLD` | La fila nueva (INSERT/UPDATE) y la anterior (UPDATE/DELETE) |
| `TG_OP` | Qué operación lo disparó: `'INSERT'`, `'UPDATE'` o `'DELETE'` |
| `RETURN NEW` en un BEFORE | Lo que devuelves es lo que se guarda. `RETURN NULL` cancela la fila |
| `REFERENCING NEW TABLE AS x` | En triggers por sentencia, todas las filas nuevas como una tabla |

## Diferencias con SQL Server

| Qué | PostgreSQL | SQL Server |
|---|---|---|
| Estructura | Función + `CREATE TRIGGER` | Todo en `CREATE TRIGGER ... AS BEGIN ... END` |
| BEFORE | Sí | No existe. Se usa `INSTEAD OF` (haces tú el INSERT) |
| Por fila | `FOR EACH ROW` con `NEW` / `OLD` | No existe: siempre por sentencia |
| Filas afectadas | `NEW`/`OLD` o tablas de transición | Tablas especiales `inserted` y `deleted` |
| Rechazar | `RAISE EXCEPTION` | `THROW` o `RAISERROR` + `ROLLBACK` |
| Desactivar | `ALTER TABLE t DISABLE TRIGGER nombre` | `DISABLE TRIGGER nombre ON t` |

Ejemplo del ejercicio 3 (descontar stock) en SQL Server:

```sql
CREATE OR ALTER TRIGGER tr_detalle_descontar_stock
ON DetalleVenta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i JOIN Producto p ON p.idProducto = i.idProducto
               WHERE p.stock < i.cantidad)
    BEGIN
        THROW 50001, 'Stock insuficiente', 1;   -- deshace el INSERT
    END;

    UPDATE p SET p.stock = p.stock - i.cantidad
    FROM Producto p
    JOIN inserted i ON i.idProducto = p.idProducto;
END;
```

Fíjate que en SQL Server el trigger siempre debe pensar en **varias filas a la vez**
(`inserted` puede traer 100 líneas). Es el error más común al escribir triggers allá.

## Ejercicios

| # | Trigger | Momento |
|---|---|---|
| 1 | Auditoría de precios | AFTER UPDATE, por fila |
| 2 | Calcular precio y total de la línea | BEFORE INSERT/UPDATE, por fila |
| 3 | Descontar stock y registrar el movimiento | AFTER INSERT, por fila |
| 4 | Recalcular los totales de la venta | AFTER INSERT/UPDATE/DELETE, por sentencia |
| 5 | Bloquear cambios en ventas anuladas | BEFORE UPDATE/DELETE, por fila |
| 6 y 7 | Listar los triggers y probar una venta completa | |

> Hazlos en orden: el 3 y el 7 usan los triggers que creaste antes.
> Para quitar todos los triggers, reinstala la base con `00_base_de_datos/instalar.sql`.

**¡Terminaste la ruta!** Repasa la [guía PostgreSQL vs SQL Server](../../docs/postgresql_vs_sqlserver.md).
