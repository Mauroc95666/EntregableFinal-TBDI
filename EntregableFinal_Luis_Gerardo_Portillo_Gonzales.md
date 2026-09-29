# Proyecto Final - Migracion de MariaDB a PostgreSQL

## Tecnologia de Base de Datos I

### Migracion de tablas, vistas y verificacion de MariaDB a PostgreSQL

**Estudiante:** Luis Gerardo Portillo Gonzales  
**Asignatura:** Tecnologia de Base de Datos I  
**Docente:** Jared Lopez Leanos  
**Fecha:** 28 de septiembre de 2026  

---

# Indice

- [1. Migracion de tablas](#1-migracion-de-tablas)
  - [1.1 Objetivo](#11-objetivo)
  - [1.2 Entorno utilizado](#12-entorno-utilizado)
  - [1.3 Herramienta utilizada para la migracion](#13-herramienta-utilizada-para-la-migracion)
  - [1.4 Configuracion utilizada en pgloader](#14-configuracion-utilizada-en-pgloader)
  - [1.5 Resultado de la migracion](#15-resultado-de-la-migracion)
  - [1.6 Conteo de registros en MariaDB](#16-conteo-de-registros-en-mariadb)
  - [1.7 Conteo de registros en PostgreSQL](#17-conteo-de-registros-en-postgresql)
  - [1.8 Comparacion MariaDB vs PostgreSQL](#18-comparacion-mariadb-vs-postgresql)
  - [1.9 Restricciones verificadas en PostgreSQL](#19-restricciones-verificadas-en-postgresql)
  - [1.10 Conclusion de la migracion de tablas](#110-conclusion-de-la-migracion-de-tablas)
- [2. Migracion de vistas](#2-migracion-de-vistas)
  - [2.1 Objetivo](#21-objetivo)
  - [2.2 Vistas originales en MariaDB](#22-vistas-originales-en-mariadb)
  - [2.3 Definicion original de dept_emp_latest_date](#23-definicion-original-de-dept_emp_latest_date)
  - [2.4 Definicion original de current_dept_emp](#24-definicion-original-de-current_dept_emp)
  - [2.5 Adaptacion de sintaxis a PostgreSQL](#25-adaptacion-de-sintaxis-a-postgresql)
  - [2.6 Creacion de las vistas en PostgreSQL](#26-creacion-de-las-vistas-en-postgresql)
  - [2.7 Prueba de dept_emp_latest_date](#27-prueba-de-dept_emp_latest_date)
  - [2.8 Prueba de current_dept_emp](#28-prueba-de-current_dept_emp)
  - [2.9 Conteo de vistas en MariaDB y PostgreSQL](#29-conteo-de-vistas-en-mariadb-y-postgresql)
  - [2.10 Resultado de la migracion de vistas](#210-resultado-de-la-migracion-de-vistas)
- [3. Consultas de verificacion](#3-consultas-de-verificacion)
  - [3.1 Objetivo de la verificacion](#31-objetivo-de-la-verificacion)
  - [3.2 Comparacion de conteos](#32-comparacion-de-conteos)
  - [3.3 Checksums comparativos](#33-checksums-comparativos)
  - [3.4 Verificacion de registros huerfanos en MariaDB](#34-verificacion-de-registros-huerfanos-en-mariadb)
  - [3.5 Verificacion de registros huerfanos en PostgreSQL](#35-verificacion-de-registros-huerfanos-en-postgresql)
  - [3.6 Problema encontrado durante la verificacion](#36-problema-encontrado-durante-la-verificacion)
  - [3.7 Analisis comparativo de resultados](#37-analisis-comparativo-de-resultados)
  - [3.8 Resultado final de la verificacion](#38-resultado-final-de-la-verificacion)
- [4. Respaldo final de PostgreSQL](#4-respaldo-final-de-postgresql)
  - [4.1 Generacion del respaldo](#41-generacion-del-respaldo)
  - [4.2 Verificacion del respaldo](#42-verificacion-del-respaldo)
  - [4.3 Resultado del respaldo](#43-resultado-del-respaldo)
- [5. Archivos incluidos](#5-archivos-incluidos)
- [6. Conclusiones](#6-conclusiones)
- [Referencias](#referencias)

---

# 1. Migracion de tablas

## 1.1 Objetivo

El objetivo de esta etapa fue migrar la base de datos `employees` desde MariaDB hacia PostgreSQL 18, conservando las seis tablas principales, sus registros y sus relaciones.

Las tablas involucradas fueron:

- `departments`
- `dept_emp`
- `dept_manager`
- `employees`
- `salaries`
- `titles`

La base de datos origen fue `employees` en MariaDB y la base destino fue `pdb_employees` en PostgreSQL. En PostgreSQL se trabajo dentro del esquema `employees`.

---

## 1.2 Entorno utilizado

| Parametro | MariaDB origen | PostgreSQL destino |
|---|---|---|
| Version | MariaDB 11.8.9 | PostgreSQL 18.6 |
| Host | `127.0.0.1` | `127.0.0.1` |
| Puerto | `3306` | `5432` |
| Usuario | `luis` | `luis` |
| Base de datos | `employees` | `pdb_employees` |
| Esquema | - | `employees` |

Conexion a MariaDB:

```bash
mariadb -h 127.0.0.1 -P 3306 -u luis -p employees
```

Conexion a PostgreSQL:

```bash
psql -h 127.0.0.1 -p 5432 -U luis -d pdb_employees
```

---

## 1.3 Herramienta utilizada para la migracion

Para realizar la migracion se utilizo `pgloader`, una herramienta que permite cargar datos desde MariaDB hacia PostgreSQL y crear automaticamente tablas, indices y restricciones.

El archivo utilizado para ejecutar la migracion fue:

```text
migracion.load
```

---

## 1.4 Configuracion utilizada en pgloader

El contenido principal del archivo `migracion.load` fue:

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

La configuracion indica que:

- El origen fue MariaDB, base `employees`.
- El destino fue PostgreSQL, base `pdb_employees`.
- Se crearon tablas, indices y secuencias.
- Se convirtieron tipos incompatibles entre MariaDB y PostgreSQL.
- Los tipos `datetime` se adaptaron a `timestamp`.
- Los tipos `enum` se convirtieron a `text`.

---

## 1.5 Resultado de la migracion

La migracion cargo correctamente las seis tablas principales.

Resumen de registros migrados:

| Tabla | Filas |
|---|---:|
| `departments` | 9 |
| `dept_emp` | 331603 |
| `dept_manager` | 24 |
| `employees` | 300024 |
| `salaries` | 2844047 |
| `titles` | 443308 |
| **Total** | **3919015** |

Tambien se verifico que PostgreSQL conservara:

- 6 claves primarias.
- 6 claves foraneas.
- Indices.
- Restricciones de no nulidad reportadas como `CHECK`.

---

## 1.6 Conteo de registros en MariaDB

Para comprobar la cantidad de registros en MariaDB se ejecuto un conteo sobre las seis tablas.

Resultado almacenado en `final_conteos_mariadb.txt`:

```text
tabla	filas
departments	9
dept_emp	331603
dept_manager	24
employees	300024
salaries	2844047
titles	443308
```

El total de registros en MariaDB fue:

```text
3919015 registros
```

---

## 1.7 Conteo de registros en PostgreSQL

Luego se ejecuto el mismo conteo en PostgreSQL sobre el esquema `employees`.

Resultado almacenado en `final_conteos_postgresql.txt`:

```text
    tabla     |  filas  
--------------+---------
 departments  |       9
 dept_emp     |  331603
 dept_manager |      24
 employees    |  300024
 salaries     | 2844047
 titles       |  443308
(6 filas)
```

El total de registros en PostgreSQL fue:

```text
3919015 registros
```

---

## 1.8 Comparacion MariaDB vs PostgreSQL

| Tabla | MariaDB | PostgreSQL | Resultado |
|---|---:|---:|---|
| `departments` | 9 | 9 | Coincide |
| `dept_emp` | 331603 | 331603 | Coincide |
| `dept_manager` | 24 | 24 | Coincide |
| `employees` | 300024 | 300024 | Coincide |
| `salaries` | 2844047 | 2844047 | Coincide |
| `titles` | 443308 | 443308 | Coincide |
| **Total** | **3919015** | **3919015** | **Coincide** |

La diferencia total entre MariaDB y PostgreSQL fue:

```text
0 registros
```

Por lo tanto, no se detecto perdida de registros mediante la comparacion de conteos.

---

## 1.9 Restricciones verificadas en PostgreSQL

Se verificaron las restricciones existentes en PostgreSQL mediante `information_schema.table_constraints`.

Resultado almacenado en `restricciones_postgresql_final.txt`:

```text
  table_name  |         constraint_name         | constraint_type 
--------------+---------------------------------+-----------------
 departments  | departments_dept_name_not_null  | CHECK
 departments  | departments_dept_no_not_null    | CHECK
 departments  | idx_16578_primary               | PRIMARY KEY
 dept_emp     | dept_emp_dept_no_not_null       | CHECK
 dept_emp     | dept_emp_emp_no_not_null        | CHECK
 dept_emp     | dept_emp_from_date_not_null     | CHECK
 dept_emp     | dept_emp_to_date_not_null       | CHECK
 dept_emp     | dept_emp_ibfk_1                 | FOREIGN KEY
 dept_emp     | dept_emp_ibfk_2                 | FOREIGN KEY
 dept_emp     | idx_16583_primary               | PRIMARY KEY
 dept_manager | dept_manager_dept_no_not_null   | CHECK
 dept_manager | dept_manager_emp_no_not_null    | CHECK
 dept_manager | dept_manager_from_date_not_null | CHECK
 dept_manager | dept_manager_to_date_not_null   | CHECK
 dept_manager | dept_manager_ibfk_1             | FOREIGN KEY
 dept_manager | dept_manager_ibfk_2             | FOREIGN KEY
 dept_manager | idx_16590_primary               | PRIMARY KEY
 employees    | employees_birth_date_not_null   | CHECK
 employees    | employees_emp_no_not_null       | CHECK
 employees    | employees_first_name_not_null   | CHECK
 employees    | employees_gender_not_null       | CHECK
 employees    | employees_hire_date_not_null    | CHECK
 employees    | employees_last_name_not_null    | CHECK
 employees    | idx_16597_primary               | PRIMARY KEY
 salaries     | salaries_emp_no_not_null        | CHECK
 salaries     | salaries_from_date_not_null     | CHECK
 salaries     | salaries_salary_not_null        | CHECK
 salaries     | salaries_to_date_not_null       | CHECK
 salaries     | salaries_ibfk_1                 | FOREIGN KEY
 salaries     | idx_16608_primary               | PRIMARY KEY
 titles       | titles_emp_no_not_null          | CHECK
 titles       | titles_from_date_not_null       | CHECK
 titles       | titles_title_not_null           | CHECK
 titles       | titles_ibfk_1                   | FOREIGN KEY
 titles       | idx_16615_primary               | PRIMARY KEY
(35 filas)
```

Se confirmo la existencia de:

- 6 claves primarias.
- 6 claves foraneas.
- Restricciones de no nulidad.

---

## 1.10 Conclusion de la migracion de tablas

La migracion de tablas fue correcta porque:

- Se migraron las seis tablas principales.
- Los conteos de MariaDB y PostgreSQL coinciden exactamente.
- El total de registros coincide: `3919015`.
- La diferencia de registros fue `0`.
- PostgreSQL conserva claves primarias y claves foraneas.

Por lo tanto, la migracion de tablas cumple con el criterio de migrar correctamente, documentar y verificar conteos.

---

# 2. Migracion de vistas

## 2.1 Objetivo

El objetivo de esta etapa fue migrar las vistas existentes en MariaDB hacia PostgreSQL.

Las vistas originales fueron:

- `dept_emp_latest_date`
- `current_dept_emp`

Estas vistas no fueron migradas automaticamente por pgloader, por lo que se extrajeron desde MariaDB, se adaptaron a sintaxis PostgreSQL y se crearon manualmente en el esquema `employees`.

---

## 2.2 Vistas originales en MariaDB

Las definiciones originales fueron guardadas en:

```text
vista_latest_mariadb.txt
vista_current_mariadb.txt
```

---

## 2.3 Definicion original de dept_emp_latest_date

Resultado obtenido desde MariaDB:

```text
*************************** 1. row ***************************
                View: dept_emp_latest_date
         Create View: CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `dept_emp_latest_date` AS select `dept_emp`.`emp_no` AS `emp_no`,max(`dept_emp`.`from_date`) AS `from_date`,max(`dept_emp`.`to_date`) AS `to_date` from `dept_emp` group by `dept_emp`.`emp_no`
character_set_client: utf8mb3
collation_connection: utf8mb3_uca1400_ai_ci
```

La vista obtiene por cada empleado la fecha mas reciente de asignacion a departamento.

---

## 2.4 Definicion original de current_dept_emp

Resultado obtenido desde MariaDB:

```text
*************************** 1. row ***************************
                View: current_dept_emp
         Create View: CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `current_dept_emp` AS select `l`.`emp_no` AS `emp_no`,`d`.`dept_no` AS `dept_no`,`l`.`from_date` AS `from_date`,`l`.`to_date` AS `to_date` from (`dept_emp` `d` join `dept_emp_latest_date` `l` on(`d`.`emp_no` = `l`.`emp_no` and `d`.`from_date` = `l`.`from_date` and `l`.`to_date` = `d`.`to_date`))
character_set_client: utf8mb3
collation_connection: utf8mb3_uca1400_ai_ci
```

Esta vista relaciona `dept_emp` con `dept_emp_latest_date` para obtener la asignacion actual o mas reciente de cada empleado.

---

## 2.5 Adaptacion de sintaxis a PostgreSQL

Las vistas fueron adaptadas en el archivo:

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

Cambios realizados:

- Se elimino la sintaxis propia de MariaDB: `CREATE ALGORITHM`, `DEFINER` y `SQL SECURITY`.
- Se agrego el esquema `employees`.
- Se mantuvo la logica original de ambas vistas.
- Se utilizo `CREATE OR REPLACE VIEW` para crear las vistas en PostgreSQL.

---

## 2.6 Creacion de las vistas en PostgreSQL

Las vistas fueron creadas ejecutando:

```bash
psql -h 127.0.0.1 -p 5432 -U luis -d pdb_employees -f vistas_postgresql.sql
```

Resultado guardado en `evidencia_creacion_vistas.txt`:

```text
CREATE VIEW
CREATE VIEW
```

Esto confirma que PostgreSQL creo correctamente las dos vistas.

---

## 2.7 Prueba de dept_emp_latest_date

Se realizo una consulta de prueba sobre la vista `employees.dept_emp_latest_date`.

Resultado guardado en `prueba_vista_latest.txt`:

```text
 emp_no | from_date  |  to_date   
--------+------------+------------
  10001 | 1986-06-26 | 9999-01-01
  10002 | 1996-08-03 | 9999-01-01
  10003 | 1995-12-03 | 9999-01-01
  10004 | 1986-12-01 | 9999-01-01
  10005 | 1989-09-12 | 9999-01-01
  10006 | 1990-08-05 | 9999-01-01
  10007 | 1989-02-10 | 9999-01-01
  10008 | 1998-03-11 | 2000-07-31
  10009 | 1985-02-18 | 9999-01-01
  10010 | 2000-06-26 | 9999-01-01
(10 filas)
```

La vista devuelve registros correctamente.

---

## 2.8 Prueba de current_dept_emp

Se realizo una consulta de prueba sobre la vista `employees.current_dept_emp`.

Resultado guardado en `prueba_vista_current.txt`:

```text
 emp_no | dept_no | from_date  |  to_date   
--------+---------+------------+------------
  10004 | d004    | 1986-12-01 | 9999-01-01
  10018 | d004    | 1992-07-29 | 9999-01-01
  10020 | d004    | 1997-12-30 | 9999-01-01
  10025 | d005    | 1987-08-17 | 1997-10-15
  10027 | d005    | 1995-04-02 | 9999-01-01
  10033 | d006    | 1987-03-18 | 1993-03-24
  10037 | d005    | 1990-12-05 | 9999-01-01
  10038 | d009    | 1989-09-20 | 9999-01-01
  10043 | d005    | 1990-10-20 | 9999-01-01
  10046 | d008    | 1992-06-20 | 9999-01-01
(10 filas)
```

La vista devuelve correctamente empleados, departamentos y fechas.

---

## 2.9 Conteo de vistas en MariaDB y PostgreSQL

Conteo en MariaDB, guardado en `conteos_vistas_mariadb.txt`:

```text
vista	filas
dept_emp_latest_date	300024
current_dept_emp	300024
```

Conteo en PostgreSQL, guardado en `conteos_vistas_postgresql.txt`:

```text
        vista         | filas  
----------------------+--------
 dept_emp_latest_date | 300024
 current_dept_emp     | 300024
(2 filas)
```

Comparacion:

| Vista | MariaDB | PostgreSQL | Resultado |
|---|---:|---:|---|
| `dept_emp_latest_date` | 300024 | 300024 | Coincide |
| `current_dept_emp` | 300024 | 300024 | Coincide |

---

## 2.10 Resultado de la migracion de vistas

La migracion de vistas fue correcta porque:

- Se identificaron las dos vistas originales en MariaDB.
- Se extrajeron sus definiciones.
- Se adapto la sintaxis a PostgreSQL.
- PostgreSQL creo ambas vistas correctamente.
- Las vistas devolvieron registros en pruebas de consulta.
- Los conteos de ambas vistas coincidieron entre MariaDB y PostgreSQL.

Por lo tanto, se cumple el criterio de migrar vistas, adaptar sintaxis, documentar y probar.

---

# 3. Consultas de verificacion

## 3.1 Objetivo de la verificacion

El objetivo de esta etapa fue comprobar que la migracion mantuvo la cantidad de registros, contenido basico e integridad referencial de la base `employees`.

Las verificaciones realizadas fueron:

- Conteos de registros entre MariaDB y PostgreSQL.
- Conteos de vistas entre MariaDB y PostgreSQL.
- Checksums comparativos.
- Verificacion de registros huerfanos.
- Verificacion de restricciones.
- Validacion del backup.

---

## 3.2 Comparacion de conteos

Los conteos finales de las seis tablas fueron:

| Tabla | MariaDB | PostgreSQL | Diferencia |
|---|---:|---:|---:|
| `departments` | 9 | 9 | 0 |
| `dept_emp` | 331603 | 331603 | 0 |
| `dept_manager` | 24 | 24 | 0 |
| `employees` | 300024 | 300024 | 0 |
| `salaries` | 2844047 | 2844047 | 0 |
| `titles` | 443308 | 443308 | 0 |
| **Total** | **3919015** | **3919015** | **0** |

Los conteos demuestran que no hubo perdida de registros durante la migracion.

---

## 3.3 Checksums comparativos

Se calcularon checksums para comparar contenido entre MariaDB y PostgreSQL.

Resultados en MariaDB, guardados en `checksums_mariadb.txt`:

```text
tabla	checksum
departments	5e4c20a53a2dc1d1a236093c4d2cd305
tabla	checksum
dept_manager	69c48446edd6643439446241674bd217
```

Resultados en PostgreSQL, guardados en `checksums_postgresql.txt`:

```text
    tabla    |             checksum             
-------------+----------------------------------
 departments | 5e4c20a53a2dc1d1a236093c4d2cd305
(1 fila)

    tabla     |             checksum             
--------------+----------------------------------
 dept_manager | 69c48446edd6643439446241674bd217
(1 fila)
```

Comparacion:

| Tabla | Checksum MariaDB | Checksum PostgreSQL | Resultado |
|---|---|---|---|
| `departments` | `5e4c20a53a2dc1d1a236093c4d2cd305` | `5e4c20a53a2dc1d1a236093c4d2cd305` | Coincide |
| `dept_manager` | `69c48446edd6643439446241674bd217` | `69c48446edd6643439446241674bd217` | Coincide |

Los checksums verificados coinciden exactamente entre ambos gestores.

---

## 3.4 Verificacion de registros huerfanos en MariaDB

Se verifico la integridad referencial del origen mediante consultas que buscan registros sin correspondencia en las tablas referenciadas.

Resultado guardado en `huerfanos_mariadb.txt`:

```text
relacion	huerfanos
dept_emp -> employees	0
dept_emp -> departments	0
dept_manager -> employees	0
dept_manager -> departments	0
salaries -> employees	0
titles -> employees	0
```

No se encontraron registros huerfanos en MariaDB.

---

## 3.5 Verificacion de registros huerfanos en PostgreSQL

Se realizo la misma comprobacion sobre PostgreSQL.

Resultado guardado en `huerfanos_postgresql.txt`:

```text
SET
SET
          relacion           | huerfanos 
-----------------------------+-----------
 dept_emp -> employees       |         0
 dept_emp -> departments     |         0
 dept_manager -> employees   |         0
 dept_manager -> departments |         0
 salaries -> employees       |         0
 titles -> employees         |         0
(6 filas)
```

Las seis relaciones verificadas devolvieron `0` registros huerfanos.

---

## 3.6 Problema encontrado durante la verificacion

Durante la verificacion de huerfanos en PostgreSQL se presento un problema de memoria compartida del contenedor:

```text
ERROR: could not resize shared memory segment
No space left on device
```

Se comprobo que el host tenia memoria compartida disponible, pero el contenedor PostgreSQL tenia solamente 64 MB en `/dev/shm`.

Para completar la consulta se desactivo temporalmente el paralelismo y se redujo `work_mem` en la sesion:

```bash
psql -h 127.0.0.1 -p 5432 -U luis -d pdb_employees -v ON_ERROR_STOP=1 \
  -c "SET max_parallel_workers_per_gather = 0; SET work_mem = '4MB';" \
  -f verificar_huerfanos_postgresql.sql
```

El ajuste solo afecto la sesion de verificacion y no modifico los datos migrados.

Despues de aplicar el ajuste, la consulta finalizo correctamente y mostro `0` registros huerfanos.

---

## 3.7 Analisis comparativo de resultados

Las verificaciones permiten concluir lo siguiente:

### Conteos

Las seis tablas tienen la misma cantidad de registros en MariaDB y PostgreSQL.

```text
MariaDB:     3919015 registros
PostgreSQL:  3919015 registros
Diferencia:        0 registros
```

### Vistas

Las dos vistas fueron creadas y probadas en PostgreSQL. Sus conteos coinciden con MariaDB:

```text
dept_emp_latest_date: 300024 filas
current_dept_emp:     300024 filas
```

### Checksums

Los checksums calculados para `departments` y `dept_manager` coinciden entre ambos gestores.

### Integridad referencial

Las seis relaciones verificadas presentan:

```text
0 registros huerfanos
```

tanto en MariaDB como en PostgreSQL.

### Restricciones

PostgreSQL conserva:

```text
6 claves primarias
6 claves foraneas
35 restricciones registradas
```

### Backup

El backup fue validado con `pg_restore -l` y contiene:

- Esquema `employees`.
- Seis tablas.
- Datos de las seis tablas.
- Dos vistas.
- Claves primarias.
- Claves foraneas.

---

## 3.8 Resultado final de la verificacion

La verificacion final fue completa porque:

- Se compararon conteos entre MariaDB y PostgreSQL.
- Se verificaron las dos vistas migradas.
- Se calcularon checksums comparativos.
- Se comprobaron registros huerfanos en las seis relaciones.
- Se revisaron restricciones en PostgreSQL.
- Se valido el backup final.
- Se documento el problema de memoria compartida y su solucion.

Por lo tanto, las pruebas confirman que la migracion conserva cantidad, estructura e integridad de los datos.

---

# 4. Respaldo final de PostgreSQL

## 4.1 Generacion del respaldo

Como parte del entregable final se genero un respaldo de la base `pdb_employees` usando `pg_dump` en formato personalizado.

Comando utilizado:

```bash
pg_dump -h 127.0.0.1 -p 5432 -U luis -Fc -f pdb_employees_final.dump pdb_employees
```

Archivo generado:

```text
pdb_employees_final.dump
```

Formato:

```text
CUSTOM
```

Tamaño aproximado:

```text
35 MB
```

---

## 4.2 Verificacion del respaldo

Para validar el contenido del backup se utilizo:

```bash
pg_restore -l pdb_employees_final.dump
```

Resultado guardado en `verificacion_backup.txt`:

```text
;
; Archive created at 2026-09-26 16:39:38 -04
;     dbname: pdb_employees
;     TOC Entries: 35
;     Compression: gzip
;     Dump Version: 1.16-0
;     Format: CUSTOM
;     Integer: 4 bytes
;     Offset: 8 bytes
;     Dumped from database version: 18.6 (Debian 18.6-1.pgdg13+2)
;     Dumped by pg_dump version: 18.6 (Debian 18.6-1.pgdg12+2)
;
;
; Selected TOC Entries:
;
6; 2615 16391 SCHEMA - employees luis
227; 1259 16583 TABLE employees dept_emp luis
232; 1259 16672 VIEW employees dept_emp_latest_date luis
233; 1259 16676 VIEW employees current_dept_emp luis
226; 1259 16578 TABLE employees departments luis
228; 1259 16590 TABLE employees dept_manager luis
229; 1259 16597 TABLE employees employees luis
230; 1259 16608 TABLE employees salaries luis
231; 1259 16615 TABLE employees titles luis
3493; 0 16578 TABLE DATA employees departments luis
3494; 0 16583 TABLE DATA employees dept_emp luis
3495; 0 16590 TABLE DATA employees dept_manager luis
3496; 0 16597 TABLE DATA employees employees luis
3497; 0 16608 TABLE DATA employees salaries luis
3498; 0 16615 TABLE DATA employees titles luis
3325; 2606 16638 CONSTRAINT employees departments idx_16578_primary luis
3328; 2606 16637 CONSTRAINT employees dept_emp idx_16583_primary luis
3331; 2606 16636 CONSTRAINT employees dept_manager idx_16590_primary luis
3333; 2606 16639 CONSTRAINT employees employees idx_16597_primary luis
3335; 2606 16640 CONSTRAINT employees salaries idx_16608_primary luis
3337; 2606 16635 CONSTRAINT employees titles idx_16615_primary luis
3323; 1259 16625 INDEX employees idx_16578_dept_name luis
3326; 1259 16623 INDEX employees idx_16583_dept_no luis
3329; 1259 16622 INDEX employees idx_16590_dept_no luis
3338; 2606 16641 FK CONSTRAINT employees dept_emp dept_emp_ibfk_1 luis
3339; 2606 16646 FK CONSTRAINT employees dept_emp dept_emp_ibfk_2 luis
3340; 2606 16651 FK CONSTRAINT employees dept_manager dept_manager_ibfk_1 luis
3341; 2606 16656 FK CONSTRAINT employees dept_manager dept_manager_ibfk_2 luis
3342; 2606 16661 FK CONSTRAINT employees salaries salaries_ibfk_1 luis
3343; 2606 16666 FK CONSTRAINT employees titles titles_ibfk_1 luis
```

---

## 4.3 Resultado del respaldo

La verificacion del respaldo demuestra que el archivo contiene:

- Base `pdb_employees`.
- Esquema `employees`.
- Seis tablas.
- Datos de las seis tablas.
- Dos vistas:
  - `dept_emp_latest_date`
  - `current_dept_emp`
- Claves primarias.
- Indices.
- Seis claves foraneas.

El respaldo final fue validado correctamente.

---

# 5. Archivos incluidos

Los archivos principales del proyecto son:

```text
README.md
EntregableFinal_Luis_Gerardo_Portillo_Gonzales.md
ProyectoFinalTecbd1.pdf
Link_Del_GITHUB.txt

docker-compose.yml
migracion.load
employees-estructura.sql
vistas_postgresql.sql

final_conteos_mariadb.txt
final_conteos_postgresql.txt
conteos_vistas_mariadb.txt
conteos_vistas_postgresql.txt

checksums_mariadb.txt
checksums_postgresql.txt

huerfanos_mariadb.txt
huerfanos_postgresql.txt
verificar_huerfanos_mariadb.sql
verificar_huerfanos_postgresql.sql

vista_latest_mariadb.txt
vista_current_mariadb.txt
evidencia_creacion_vistas.txt
prueba_vista_latest.txt
prueba_vista_current.txt

restricciones_postgresql_final.txt
verificacion_backup.txt
```

Tambien se incluye la carpeta:

```text
archivo_actividad5/
```

con evidencias y archivos de apoyo de la actividad anterior, como el modelo de pgModeler y salidas de verificacion.

El archivo pesado `pdb_employees_final.dump` no se incluye dentro del ZIP liviano para evitar aumentar el tamano de la entrega, pero el respaldo queda documentado mediante `verificacion_backup.txt` y se encuentra referenciado en el repositorio GitHub.

---

# 6. Conclusiones

La migracion de la base `employees` desde MariaDB hacia PostgreSQL 18 fue realizada y verificada correctamente.

Las seis tablas principales fueron migradas y conservaron exactamente la misma cantidad de registros en origen y destino. El total verificado fue de `3919015` registros en ambos gestores, con una diferencia de `0`.

Las vistas `dept_emp_latest_date` y `current_dept_emp` fueron extraidas desde MariaDB, adaptadas a PostgreSQL, creadas y probadas correctamente. Ambas vistas devolvieron datos y sus conteos coincidieron entre origen y destino.

Las consultas de verificacion comprobaron que:

- Los conteos coinciden.
- Los checksums verificados coinciden.
- No existen registros huerfanos.
- PostgreSQL conserva claves primarias y claves foraneas.
- El backup final contiene tablas, datos y vistas.

Durante la verificacion de huerfanos en PostgreSQL se presento un problema de memoria compartida del contenedor. Este problema fue resuelto ajustando parametros de la sesion, sin modificar la base de datos ni sus registros.

Finalmente, el respaldo `pdb_employees_final.dump` fue validado con `pg_restore -l`, confirmando que contiene el esquema `employees`, las seis tablas, sus datos, las dos vistas, indices y claves foraneas.

Por lo tanto, el proyecto cumple con los criterios de migracion de tablas, migracion de vistas y consultas de verificacion.

---

# Referencias

- PostgreSQL Global Development Group. Documentacion oficial de PostgreSQL.
- MariaDB Foundation. Documentacion oficial de MariaDB.
- Dimitri Fontaine. Documentacion oficial de pgloader.
- Docker, Inc. Documentacion oficial de Docker.
- PostgreSQL Global Development Group. Documentacion de `pg_dump`.
- PostgreSQL Global Development Group. Documentacion de `pg_restore`.
