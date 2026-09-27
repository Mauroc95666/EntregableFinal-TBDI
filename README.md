# Entregable Final - Tecnología de Base de Datos I

**Estudiante:** Luis Gerardo Portillo Gonzales
**Docente:** Jared Lopez Leaños
**Unidad:** Bloque 3 - Migración de un sistema informático a otro SGBD

## Descripción

Este repositorio reúne el entregable final del Bloque 3. El proyecto migra la base de datos `employees` de MariaDB a PostgreSQL 18 y comprueba que todo haya llegado completo y sin cambios.

El trabajo incluye:

- Migración de las seis tablas y sus datos con pgloader.
- Migración manual de las dos vistas.
- Comparación de conteos entre MariaDB y PostgreSQL.
- Búsqueda de registros huérfanos (integridad referencial).
- Comparación por checksums.
- Revisión de restricciones.
- Backup final de PostgreSQL.

## Entorno utilizado

| Parámetro | MariaDB (origen) | PostgreSQL (destino) |
|---|---|---|
| Versión | 11.8.9 | 18.6 |
| Host | 127.0.0.1 | 127.0.0.1 |
| Puerto | 3306 | 5432 |
| Usuario | luis | luis |
| Base | employees | pdb_employees |
| Esquema | - | employees |

## Resultados principales

### Conteo de tablas

| Tabla | MariaDB | PostgreSQL | Resultado |
|---|---:|---:|---|
| departments | 9 | 9 | Coincide |
| dept_emp | 331603 | 331603 | Coincide |
| dept_manager | 24 | 24 | Coincide |
| employees | 300024 | 300024 | Coincide |
| salaries | 2844047 | 2844047 | Coincide |
| titles | 443308 | 443308 | Coincide |

### Vistas

| Vista | MariaDB | PostgreSQL | Resultado |
|---|---:|---:|---|
| dept_emp_latest_date | 300024 | 300024 | Coincide |
| current_dept_emp | 300024 | 300024 | Coincide |

### Verificaciones

- **Huérfanos:** 0 en las seis relaciones, tanto en MariaDB como en PostgreSQL.
- **Checksums:** `departments` y `dept_manager` dieron el mismo valor en ambos motores.
- **Restricciones:** se conservaron las 6 claves primarias y las 6 claves foráneas.

### Problema resuelto

La primera vez que corrí la búsqueda de huérfanos en PostgreSQL, falló con el error `could not resize shared memory segment`. La causa es que el contenedor Docker tiene solo 64 MB de `/dev/shm`. Lo resolví desactivando el paralelismo y bajando `work_mem` para esa sesión:

```bash
psql -h 127.0.0.1 -p 5432 -U luis -d pdb_employees -v ON_ERROR_STOP=1 \
  -c "SET max_parallel_workers_per_gather = 0; SET work_mem = '4MB';" \
  -f verificar_huerfanos_postgresql.sql
```

## Backup final

```bash
pg_dump -h 127.0.0.1 -p 5432 -U luis -Fc -f pdb_employees_final.dump pdb_employees
```

| Característica | Valor |
|---|---|
| Archivo | pdb_employees_final.dump |
| Formato | CUSTOM (comprimido) |
| PostgreSQL | 18.6 |
| Tamaño aproximado | 35 MB |
| Contenido | 6 tablas, datos y 2 vistas |

Para restaurarlo en una base nueva:

```bash
createdb -h 127.0.0.1 -U luis pdb_employees_restore
pg_restore -h 127.0.0.1 -U luis -d pdb_employees_restore pdb_employees_final.dump
```

## Archivos principales

| Archivo | Contenido |
|---|---|
| EntregableFinal_Luis_Gerardo_Portillo_Gonzales.md | Informe completo |
| ProyectoFinalTecbd1.pdf | Informe en PDF |
| pdb_employees_final.dump | Backup final de PostgreSQL |
| docker-compose.yml | Definición de los contenedores |
| migracion.load | Configuración de pgloader |
| employees-estructura.sql | Estructura original exportada de MariaDB |
| vistas_postgresql.sql | Vistas adaptadas a PostgreSQL |
| verificar_huerfanos_mariadb.sql | Búsqueda de huérfanos en MariaDB |
| verificar_huerfanos_postgresql.sql | Búsqueda de huérfanos en PostgreSQL |
| final_conteos_mariadb.txt | Conteo de tablas en MariaDB |
| final_conteos_postgresql.txt | Conteo de tablas en PostgreSQL |
| conteos_vistas_mariadb.txt | Conteo de vistas en MariaDB |
| conteos_vistas_postgresql.txt | Conteo de vistas en PostgreSQL |
| checksums_mariadb.txt | Checksums en MariaDB |
| checksums_postgresql.txt | Checksums en PostgreSQL |
| huerfanos_mariadb.txt | Resultado de huérfanos en MariaDB |
| huerfanos_postgresql.txt | Resultado de huérfanos en PostgreSQL |
| restricciones_postgresql_final.txt | Restricciones del esquema migrado |

## Informe

El detalle completo del proceso está en `EntregableFinal_Luis_Gerardo_Portillo_Gonzales.md`.
