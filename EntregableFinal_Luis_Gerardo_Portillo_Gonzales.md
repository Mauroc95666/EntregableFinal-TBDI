# Entregable Final — Tecnología de Base de Datos I

## Migración de tablas, vistas y consultas de verificación
### MariaDB → PostgreSQL 18

**Estudiante:** Luis Gerardo Portillo Gonzales  
**Asignatura:** Tecnología de Base de Datos I  
**Docente:** Jared Lopez Leaños  
**Unidad:** Bloque 3 — Migración de un sistema informático a otro SGBD  
**Fecha:** 26 de septiembre de 2026  

---

# Índice

1. Introducción  
2. Entorno utilizado  
3. Migración de tablas y datos  
4. Migración de vistas  
5. Consultas de verificación  
6. Problema encontrado y solución  
7. Backup final de PostgreSQL  
8. Conclusiones  
9. Archivos del proyecto  
10. Referencias  

---

# 1. Introducción

El presente entregable corresponde a la fase final del proyecto de migración de la base de datos `employees` desde MariaDB hacia PostgreSQL 18.

Los objetivos desarrollados fueron:

- Verificar la migración de los datos de las seis tablas principales.
- Migrar las vistas existentes en MariaDB hacia PostgreSQL.
- Comparar los resultados entre ambos sistemas gestores.
- Verificar conteos de filas.
- Comprobar integridad referencial mediante búsqueda de registros huérfanos.
- Realizar verificaciones mediante checksums.
- Revisar restricciones de la estructura migrada.
- Generar un backup final de PostgreSQL que incluya tablas, datos y vistas.

Todas las evidencias utilizadas en este informe corresponden a salidas en texto de comandos y consultas.

---

# 2. Entorno utilizado

## 2.1 MariaDB — origen

```text
Host: 127.0.0.1
Puerto: 3306
Usuario: luis
Base de datos: employees
SGBD: MariaDB 11.8.9
```

Conexión:

```bash
mariadb -h 127.0.0.1 -P 3306 -u luis -p employees
```

La base contiene seis tablas principales:

```text
departments
dept_emp
dept_manager
employees
salaries
titles
```

y dos vistas:

```text
current_dept_emp
dept_emp_latest_date
```

---

## 2.2 PostgreSQL — destino

```text
Host: 127.0.0.1
Puerto: 5432
Usuario: luis
Base de datos: pdb_employees
Esquema: employees
SGBD: PostgreSQL 18.6
```

Conexión:

```bash
psql -h 127.0.0.1 -p 5432 -U luis -d pdb_employees
```

---

# 3. Migración de tablas y datos

La migración de las tablas fue realizada previamente con `pgloader`, utilizando MariaDB como origen y PostgreSQL como destino.

Archivo utilizado:

```text
migracion.load
```

Configuración principal:

```text
LOAD DATABASE
    FROM mysql://root:123456@localhost:3306/employees
    INTO postgresql://luis:123456@localhost:5432/pdb_employees

WITH include drop,
    create tables,
    create indexes,
    reset sequences,
    workers = 8, concurrency = 2,
    batch rows = 10000

SET maintenance_work_mem to '256MB',
    work_mem to '32MB'

CAST type datetime to timestamp drop default drop not null
        using zero-dates-to-null,
     type enum to text
;
```

Ejecución:

```bash
pgloader migracion.load
```

Resultado principal:

```text
employees.salaries       2844047 filas
employees.titles          443308 filas
employees.dept_emp        331603 filas
employees.employees       300024 filas
employees.departments          9 filas
employees.dept_manager        24 filas

Create Indexes               9
Primary Keys                 6
Foreign Keys                 6

Total import              3919015 filas
Total size                134.9 MB
Errors                    0
```

---

## 3.1 Conteo de filas en MariaDB

```bash
mariadb -h 127.0.0.1 -P 3306 -u luis -p employees -e "
SELECT 'departments' AS tabla, COUNT(*) AS filas FROM departments
UNION ALL
SELECT 'dept_emp', COUNT(*) FROM dept_emp
UNION ALL
SELECT 'dept_manager', COUNT(*) FROM dept_manager
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'salaries', COUNT(*) FROM salaries
UNION ALL
SELECT 'titles', COUNT(*) FROM titles;
"
```

Resultado:

```text
tabla          filas
departments        9
dept_emp      331603
dept_manager      24
employees     300024
salaries     2844047
titles        443308
```

Salida almacenada en:

```text
final_conteos_mariadb.txt
```

---

## 3.2 Conteo de filas en PostgreSQL

```bash
psql -h 127.0.0.1 -p 5432 -U luis -d pdb_employees -c "
SELECT 'departments' AS tabla, COUNT(*) AS filas FROM employees.departments
UNION ALL
SELECT 'dept_emp', COUNT(*) FROM employees.dept_emp
UNION ALL
SELECT 'dept_manager', COUNT(*) FROM employees.dept_manager
UNION ALL
SELECT 'employees', COUNT(*) FROM employees.employees
UNION ALL
SELECT 'salaries', COUNT(*) FROM employees.salaries
UNION ALL
SELECT 'titles', COUNT(*) FROM employees.titles;
"
```

Resultado:

```text
tabla          filas
departments        9
dept_emp      331603
dept_manager      24
employees     300024
salaries     2844047
titles        443308
```

Salida almacenada en:

```text
final_conteos_postgresql.txt
```

---

## 3.3 Comparación de tablas

| Tabla | MariaDB | PostgreSQL | Resultado |
|---|---:|---:|---|
| `departments` | 9 | 9 | Coincide |
| `dept_emp` | 331603 | 331603 | Coincide |
| `dept_manager` | 24 | 24 | Coincide |
| `employees` | 300024 | 300024 | Coincide |
| `salaries` | 2844047 | 2844047 | Coincide |
| `titles` | 443308 | 443308 | Coincide |

Los conteos de las seis tablas coinciden exactamente entre MariaDB y PostgreSQL.

---

# 4. Migración de vistas

La base `employees` contiene dos vistas en MariaDB:

```text
dept_emp_latest_date
current_dept_emp
```

Antes de crearlas en PostgreSQL se comprobó su inexistencia mediante:

```bash
psql -h 127.0.0.1 -p 5432 -U luis -d pdb_employees -c "\dv employees.*"
```

Resultado:

```text
No se encontraron vistas con el nombre «employees.*».
```

---

## 4.1 Vista `dept_emp_latest_date`

La definición original se obtuvo con:

```bash
mariadb -h 127.0.0.1 -P 3306 -u luis -p employees -e "SHOW CREATE VIEW dept_emp_latest_date\G"
```

Lógica identificada:

```sql
SELECT
    dept_emp.emp_no AS emp_no,
    MAX(dept_emp.from_date) AS from_date,
    MAX(dept_emp.to_date) AS to_date
FROM dept_emp
GROUP BY dept_emp.emp_no;
```

---

## 4.2 Vista `current_dept_emp`

La definición original se obtuvo con:

```bash
mariadb -h 127.0.0.1 -P 3306 -u luis -p employees -e "SHOW CREATE VIEW current_dept_emp\G"
```

Esta vista relaciona `dept_emp` con `dept_emp_latest_date` para obtener la asignación más reciente de cada empleado.

Las definiciones originales fueron almacenadas en:

```text
vista_latest_mariadb.txt
vista_current_mariadb.txt
```

---

## 4.3 Adaptación a PostgreSQL

Archivo:

```text
vistas_postgresql.sql
```

Contenido:

```sql
CREATE OR REPLACE VIEW employees.dept_emp_latest_date AS
SELECT
    emp_no,
    MAX(from_date) AS from_date,
    MAX(to_date) AS to_date
FROM employees.dept_emp
GROUP BY emp_no;


CREATE OR REPLACE VIEW employees.current_dept_emp AS
SELECT
    l.emp_no,
    d.dept_no,
    l.from_date,
    l.to_date
FROM employees.dept_emp AS d
JOIN employees.dept_emp_latest_date AS l
    ON d.emp_no = l.emp_no
   AND d.from_date = l.from_date
   AND d.to_date = l.to_date;
```

---

## 4.4 Creación en PostgreSQL

```bash
psql -h 127.0.0.1 -p 5432 -U luis -d pdb_employees -f vistas_postgresql.sql
```

Resultado:

```text
CREATE VIEW
CREATE VIEW
```

---

## 4.5 Verificación de vistas creadas

```bash
psql -h 127.0.0.1 -p 5432 -U luis -d pdb_employees -c "\dv employees.*"
```

Resultado:

```text
Listado de vistas

Esquema   | Nombre                | Tipo  | Dueño
----------+-----------------------+-------+------
employees | current_dept_emp      | vista | luis
employees | dept_emp_latest_date  | vista | luis

(2 filas)
```

---

## 4.6 Prueba de `dept_emp_latest_date`

```sql
SELECT *
FROM employees.dept_emp_latest_date
LIMIT 10;
```

Resultado:

```text
 emp_no | from_date  |  to_date
--------+------------+------------
 10001  | 1986-06-26 | 9999-01-01
 10002  | 1996-08-03 | 9999-01-01
 10003  | 1995-12-03 | 9999-01-01
 10004  | 1986-12-01 | 9999-01-01
 10005  | 1989-09-12 | 9999-01-01
 10006  | 1990-08-05 | 9999-01-01
 10007  | 1989-02-10 | 9999-01-01
 10008  | 1998-03-11 | 2000-07-31
 10009  | 1985-02-18 | 9999-01-01
 10010  | 2000-06-26 | 9999-01-01

(10 filas)
```

---

## 4.7 Prueba de `current_dept_emp`

```sql
SELECT *
FROM employees.current_dept_emp
LIMIT 10;
```

Resultado:

```text
 emp_no | dept_no | from_date  |  to_date
--------+---------+------------+------------
 10004  | d004    | 1986-12-01 | 9999-01-01
 10018  | d004    | 1992-07-29 | 9999-01-01
 10020  | d004    | 1997-12-30 | 9999-01-01
 10025  | d005    | 1987-08-17 | 1997-10-15
 10027  | d005    | 1995-04-02 | 9999-01-01
 10033  | d006    | 1987-03-18 | 1993-03-24
 10037  | d005    | 1990-12-05 | 9999-01-01
 10038  | d009    | 1989-09-20 | 9999-01-01
 10043  | d005    | 1990-10-20 | 9999-01-01
 10046  | d008    | 1992-06-20 | 9999-01-01

(10 filas)
```

---

## 4.8 Conteos de vistas

MariaDB:

```text
vista                  filas
dept_emp_latest_date   300024
current_dept_emp       300024
```

PostgreSQL:

```text
vista                  filas
dept_emp_latest_date   300024
current_dept_emp       300024
```

| Vista | MariaDB | PostgreSQL | Resultado |
|---|---:|---:|---|
| `dept_emp_latest_date` | 300024 | 300024 | Coincide |
| `current_dept_emp` | 300024 | 300024 | Coincide |

---

# 5. Consultas de verificación

## 5.1 Integridad referencial en MariaDB

Resultado:

```text
relacion                      huerfanos
dept_emp -> employees         0
dept_emp -> departments       0
dept_manager -> employees     0
dept_manager -> departments   0
salaries -> employees         0
titles -> employees           0
```

Archivo:

```text
huerfanos_mariadb.txt
```

---

## 5.2 Integridad referencial en PostgreSQL

Resultado final:

```text
relacion                      huerfanos
dept_emp -> employees         0
dept_emp -> departments       0
dept_manager -> employees     0
dept_manager -> departments   0
salaries -> employees         0
titles -> employees           0

(6 filas)
```

Archivo:

```text
huerfanos_postgresql.txt
```

No se detectaron registros huérfanos en ninguna de las seis relaciones verificadas.

---

## 5.3 Checksums

### `departments`

MariaDB:

```text
5e4c20a53a2dc1d1a236093c4d2cd305
```

PostgreSQL:

```text
5e4c20a53a2dc1d1a236093c4d2cd305
```

Resultado: **coincide**.

### `dept_manager`

MariaDB:

```text
69c48446edd6643439446241674bd217
```

PostgreSQL:

```text
69c48446edd6643439446241674bd217
```

Resultado: **coincide**.

Archivos:

```text
checksums_mariadb.txt
checksums_postgresql.txt
```

---

## 5.4 Restricciones en PostgreSQL

Consulta:

```sql
SELECT
    table_name,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_schema='employees'
ORDER BY table_name, constraint_type, constraint_name;
```

Resultado:

```text
35 filas
```

Se verificaron:

- 6 claves primarias.
- 6 claves foráneas.
- Restricciones de nulabilidad reportadas por esta consulta como `CHECK`.

Entre las claves foráneas se encuentran:

```text
dept_emp_ibfk_1
dept_emp_ibfk_2
dept_manager_ibfk_1
dept_manager_ibfk_2
salaries_ibfk_1
titles_ibfk_1
```

Archivo:

```text
restricciones_postgresql_final.txt
```

---

# 6. Problema encontrado y solución

Durante la ejecución inicial de la verificación de huérfanos en PostgreSQL se produjo:

```text
ERROR: could not resize shared memory segment
"/PostgreSQL.2211827842" to 8388608 bytes:
No space left on device
```

El error volvió a aparecer en un segundo intento.

Se verificó la memoria compartida del host:

```bash
df -h /dev/shm
```

Resultado:

```text
Tamaño: 1.9G
Usado: 0
Disponible: 1.9G
```

Luego se verificó la memoria compartida del contenedor:

```bash
docker exec postgresql df -h /dev/shm
```

Resultado:

```text
Filesystem   Size   Used   Avail   Use%
shm           64M   1.1M    63M    2%
```

El contenedor PostgreSQL disponía de 64 MB de `/dev/shm`.

La consulta se repitió con:

```bash
psql -h 127.0.0.1 -p 5432 -U luis -d pdb_employees -v ON_ERROR_STOP=1 -c "SET max_parallel_workers_per_gather = 0; SET work_mem = '4MB';" -f verificar_huerfanos_postgresql.sql
```

Resultado:

```text
SET
SET

relacion                      huerfanos
dept_emp -> employees         0
dept_emp -> departments       0
dept_manager -> employees     0
dept_manager -> departments   0
salaries -> employees         0
titles -> employees           0

(6 filas)
```

El ajuste permitió completar la verificación sin modificar los datos migrados.

---

# 7. Backup final de PostgreSQL

Comando:

```bash
pg_dump -h 127.0.0.1 -p 5432 -U luis -Fc -f pdb_employees_final.dump pdb_employees
```

Archivo:

```text
pdb_employees_final.dump
```

Tamaño:

```text
35M
```

Verificación:

```bash
pg_restore -l pdb_employees_final.dump | head -30
```

Información principal:

```text
Archive created at 2026-09-26 16:39:38 -04
dbname: pdb_employees
TOC Entries: 35
Compression: gzip
Format: CUSTOM
Dumped from database version: 18.6
Dumped by pg_dump version: 18.6
```

Objetos principales:

```text
SCHEMA employees

TABLE employees dept_emp
TABLE employees departments
TABLE employees dept_manager
TABLE employees employees
TABLE employees salaries
TABLE employees titles

TABLE DATA employees departments
TABLE DATA employees dept_emp
TABLE DATA employees dept_manager
TABLE DATA employees employees
TABLE DATA employees salaries
TABLE DATA employees titles
```

Verificación específica de vistas:

```bash
pg_restore -l pdb_employees_final.dump | grep -i VIEW
```

Resultado:

```text
VIEW employees dept_emp_latest_date
VIEW employees current_dept_emp
```

El backup final contiene tablas, datos y las dos vistas migradas.

---

# 8. Conclusiones

La migración de `employees` desde MariaDB hacia PostgreSQL 18 fue verificada satisfactoriamente.

Los conteos de las seis tablas coincidieron exactamente entre ambos sistemas.

Las vistas `dept_emp_latest_date` y `current_dept_emp` fueron extraídas desde MariaDB, adaptadas a PostgreSQL, creadas y probadas correctamente. Ambas devolvieron 300024 filas en origen y destino.

La verificación de integridad referencial produjo cero registros huérfanos en las seis relaciones analizadas.

Los checksums de `departments` y `dept_manager` coincidieron exactamente entre MariaDB y PostgreSQL.

También se comprobaron las claves primarias, claves foráneas y restricciones del esquema migrado.

Durante la verificación de huérfanos se presentó un problema de memoria compartida en el contenedor PostgreSQL. La consulta pudo completarse desactivando el paralelismo y reduciendo `work_mem`.

Finalmente se generó `pdb_employees_final.dump`, backup en formato `CUSTOM` de PostgreSQL 18.6, de aproximadamente 35 MB, incluyendo las seis tablas, sus datos y las dos vistas migradas.

---

# 9. Archivos del proyecto

```text
EntregableFinal_Luis_Gerardo_Portillo_Gonzales.md
README.md
pdb_employees_final.dump

final_conteos_mariadb.txt
final_conteos_postgresql.txt

vista_latest_mariadb.txt
vista_current_mariadb.txt
vistas_postgresql.sql

evidencia_creacion_vistas.txt
verificacion_vistas_postgresql.txt

prueba_vista_latest.txt
prueba_vista_current.txt

conteos_vistas_mariadb.txt
conteos_vistas_postgresql.txt

verificar_huerfanos_mariadb.sql
verificar_huerfanos_postgresql.sql
huerfanos_mariadb.txt
huerfanos_postgresql.txt

checksums_mariadb.txt
checksums_postgresql.txt

restricciones_postgresql_final.txt
```

---

# 10. Referencias

- Consigna oficial del Entregable Final — Tecnología de Base de Datos I.
- Material de laboratorio de Tecnología de Base de Datos I.
- Documentación oficial de PostgreSQL.
- Documentación oficial de MariaDB.
- Documentación de pgloader.
- Documentación de Docker.
- GitHub Docs.
