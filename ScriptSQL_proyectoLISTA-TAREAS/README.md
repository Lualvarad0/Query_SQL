# ScriptSQL_proyectoLISTA-TAREAS (SQL Server)

Base de datos del proyecto **Lista de Tareas** (Angular / Blazor), para **SQL Server**.

| Archivo | Qué hace |
|---|---|
| `Query.txt` | Crea la base `DBAngular`, la tabla `Tarea (idTarea, nombre)`, inserta 2 tareas y las consulta |

## Cómo correrlo

En SSMS, abre `Query.txt` y ejecútalo por partes: primero `create database DBAngular`, luego
el resto. (El script no tiene `GO`, por eso conviene ejecutarlo en pasos.)

## Versión PostgreSQL

```sql
CREATE TABLE Tarea (
    idTarea INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,   -- T-SQL: int primary key identity
    nombre  VARCHAR(40)
);
INSERT INTO Tarea (nombre) VALUES ('Aprender Angular'), ('Aprender Blazor');
SELECT * FROM Tarea;
```
