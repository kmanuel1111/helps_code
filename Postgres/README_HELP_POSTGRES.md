# 📘 Carpeta de Ayuda PostgreSQL

Este documento en formato **Markdown (.md)** funciona como una guía rápida y práctica para trabajar con PostgreSQL.  
La idea es que sea **transferible, autoexplicativa y modular**, con ejemplos claros que van desde consultas básicas (`SELECT`) hasta operaciones avanzadas como backups y upgrades de versión.  

---

## 🧭 Navegación Básica

- [🚀 Instalación y Configuración](#-instalación-de-postgresql-en-linux-debianubuntu)
- [💾 Backup y Restauración](#-backup-y-restauración-en-postgresql)
  - [1. Backup (`pg_dump`)](#1-backup-con-pg_dump)
  - [2. Backup de Tabla](#2-backup-de-tabla-específica)
  - [3. Backup Completo (`pg_dumpall`)](#3-backup-completo-del-servidor-con-pg_dumpall)
  - [4. Restauración (`pg_restore`)](#4-restauración-con-pg_restore)
- [🐚 Comandos Básicos (PSQL)](#-comandos-básicos-psql)

---

## 🚀 Instalación de PostgreSQL en Linux (Debian/Ubuntu)

### 1. Instalación desde repositorio automático
```bash
sudo apt install -y postgresql-common
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh

# Instalar la última versión disponible
sudo apt-get -y install postgresql postgresql-contrib
```

### 2. Instalación con configuración manual (recomendado si no se desea la última versión)
```bash
# Importar la llave de firma del repositorio
sudo apt install curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

# Crear archivo de configuración del repositorio
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Actualizar lista de paquetes
sudo apt update

# Instalar PostgreSQL (última versión o específica)
sudo apt -y install postgresql
# Ejemplo: sudo apt -y install postgresql-16
```
### 3. Configuración inicial de usuario
```bash
# Ingresar como usuario postgres
sudo su - postgres
psql

# Crear usuario y contraseña
create user kzambrano with password '123456';

# Dar permisos de superusuario
alter user kzambrano with superuser;
```

### 4. Upgrade de versión de PostgreSQL

```bash
# Instalar la nueva versión (ejemplo: PostgreSQL 16)
sudo apt -y install postgresql-16

# Ajustar binarios para apuntar a la nueva versión
pg_dumpall --version
sudo ln -s /usr/lib/postgresql/14/bin/pg_dumpall /usr/bin/pg_dumpall --force

pg_restore --version
sudo ln -s /usr/lib/postgresql/14/bin/pg_restore /usr/bin/pg_restore --force

pg_dump --version
sudo ln -s /usr/lib/postgresql/14/bin/pg_dump /usr/bin/pg_dump --force
```

### 5. Conexión local a PostgreSQL 16
```bash
# Revisar puerto en archivo de configuración
nano /etc/postgresql/16/main/postgresql.conf

# Conexión indicando puerto
psql -p 5433

# Verificar versión dentro de la base de datos
SELECT VERSION();

# Crear usuario en PostgreSQL 16
create user kzambrano with password '123456';
alter user kzambrano with superuser;
```

# 💾 Backup y Restauración en PostgreSQL

Esta sección explica cómo realizar **copias de seguridad (backups)** y cómo **restaurarlas** en PostgreSQL.  
Incluye ejemplos básicos y avanzados con parámetros detallados para distintos escenarios.

---

## 1. Backup con `pg_dump`

`pg_dump` permite exportar una sola base de datos o incluso tablas específicas.  
Ejemplo con parámetros completos:

```bash
# Parámetros explicados:
# --file: Nombre del archivo de salida
# --host: Host del servidor (generalmente localhost)
# --port: Puerto de conexión (por defecto 5432)
# --username: Usuario con permisos para realizar el backup
# --format=c: Formato custom (comprimido, permite restore selectivo)
# --blobs: Incluye objetos binarios (BLOBs)
# --verbose: Muestra detalle del proceso en pantalla

pg_dump \
  --file="nombre_del_backup.backup" \
  --host="localhost" \
  --port="5432" \
  --username="kzambrano" \
  --format=c \
  --blobs \
  --verbose \
  nombre_base_de_datos
```

### Ejemplo práctico 

```bash
pg_dump \
  --file="cc-productiondb_2025-10-21-0000.backup" \
  --host="localhost" \
  --port="5432" \
  --username="kzambrano" \
  --format=c \
  --blobs \
  --verbose \
  production_cc
```

## 2. Backup de tabla específica

También puedes respaldar solo una tabla dentro de una base de datos:

```bash
pg_dump \
  --file="tabla_especifica.backup" \
  --host="localhost" \
  --port="5432" \
  --username="kzambrano" \
  --format=c \
  --blobs \
  --verbose \
  --table="nombre_tabla_para_backup" \
  nombre_base_de_datos
```

## 3. Backup completo del servidor con pg_dumpall

`pg_dumpall` permite respaldar todo el servidor PostgreSQL, incluyendo roles y esquemas.

```bash
pg_dumpall \
  --file="nombre_del_backup.backup" \
  --host="localhost" \
  --port="5432" \
  --username="kzambrano" \
  --verbose
```

### Ejemplo práctico

```bash
pg_dumpall \
  --file="cc-productiondb_2025-10-21-0000.backup" \
  --host="localhost" \
  --port="5432" \
  --username="kzambrano" \
  --verbose
```

## 4. Restauración con `pg_restore`

`pg_restore` se utiliza para restaurar backups creados con `pg_dump` en formato **custom (`-F c`)**.  
Permite restaurar en una base de datos existente o crear una nueva.

---

## Restaurar en una base de datos existente

Ejemplo con parámetros completos:

```bash
# Parámetros explicados:
# --verbose: Muestra detalle del proceso
# --host: Host del servidor
# --username: Usuario de conexión
# --port: Puerto de conexión
# --format=c: Debe coincidir con el formato del backup (custom)
# --dbname: Base de datos donde se restaurará la información

pg_restore \
  --verbose \
  --host=localhost \
  --username=kzambrano \
  --port=5432 \
  --format=c \
  --dbname=cc_development \
  "/home/jsalge@chinchin.int/produccion_borrado.backup"
```

## Restaurar en una base de datos específica con nombre detallado

```bash
pg_restore \
  --verbose \
  --host=localhost \
  --username=kzambrano \
  --port=5432 \
  --format=c \
  --dbname=cc-productiondb_2025-10-21 \
  "/Backup/db_cc-productiondb_2025-10-21-0000/cc-productiondb_2025-10-21-0000.backup"
```
## Restaurar creando la base de datos desde el dump

Si el backup fue generado con --create, se puede restaurar directamente:

```bash
pg_restore \
  --verbose \
  --host=localhost \
  --username=kzambrano \
  --port=5432 \
  --format=c \
  --create \
  -d postgres \
  "/backups/produccion.backup"
```
👉 Aquí -d postgres indica que la conexión inicial se hace a la base principal, y desde allí se ejecuta la creación de la nueva base

---

## 🐚 Comandos Básicos (PSQL)

Esta sección es una **guía de supervivencia** para quienes están empezando a usar la terminal de PostgreSQL (`psql`). Aquí encontrarás los comandos que usarás el 90% del tiempo.

### ℹ️ Ayuda y Versión

Antes de intentar cualquier operación, es útil verificar la versión y las opciones disponibles:

```bash
# Ver la versión del cliente psql
psql --version

# Ver ayuda completa de argumentos de línea de comandos
psql --help
```
### 🔌 Conexión Detallada

Para conectarte a una base de datos específica con todos los parámetros controlados, usa la siguiente estructura:

```bash
# Parámetros explicados:
# --host | -h: Host del servidor (IP o dominio)
# --port | -p: Puerto de conexión (5432 es el default)
# --username | -U: Usuario de conexión
# --dbname | -d: Nombre de la base de datos a conectar
# --password | -W:  Solicita la contraseña explícitamente (opcional)

psql \
  --host=localhost \
  --port=5432 \
  --username=kzambrano \
  --dbname=cc_development
```

### 📜 Ejecución de Scripts (.sql)

Para ejecutar un archivo de comandos SQL desde la terminal (sin entrar a la consola interactiva), usa el flag `-f`:

```bash
# Ejecutar un archivo SQL en una base de datos específica
psql \
  --host=localhost \
  --username=kzambrano \
  --dbname=cc_development \
  -f archivo_script.sql
```

### 🧭 Navegación y Control

| Comando        | Descripción                                    | Ejemplo / Notas                                   |
| :------------- | :--------------------------------------------- | :------------------------------------------------ |
| `\l`           | **Listar** todas las bases de datos.           | Muestra nombres, dueños y codificación.           |
| `\c nombre_db` | **Conectarse** a una base de datos específica. | `\c mi_tienda` (Cambia el prompt a `mi_tienda=>`) |
| `\dt`          | **Listar tablas** de la base de datos actual.  | Solo muestra tablas públicas.                     |
| `\du`          | **Listar usuarios** (roles) y sus permisos.    | Útil para ver quién es superusuario.              |
| `\dn`          | **Listar esquemas** del sistema.               |                                                   |
| `\q`           | **Salir** de la consola psql.                  | Vuelve a la terminal de Linux.                    |

### 🧐 Inspección de Objetos

- **`\d nombre_tabla`**: Muestra la estructura básica de una tabla (columnas, tipos de dato).
- **`\d+ nombre_tabla`**: Muestra información detallada (comentarios, tamaño en disco, índices).

### 📝 Consultas SQL "De Bolsillo"

Una vez dentro de una base de datos, usas SQL estándar. **Nota importante:** Todas las sentencias SQL deben terminar con punto y coma (`;`).

#### Consultas de Datos
```sql
-- Ver todo el contenido de una tabla
SELECT * FROM usuarios;

-- Ver solo columnas específicas
SELECT nombre, email FROM usuarios;

-- Filtrar datos (Clause WHERE)
SELECT * FROM usuarios WHERE activo = true;

-- Ordenar resultados
SELECT * FROM productos ORDER BY precio DESC;
```

#### Gestión de Datos (DML)
```sql
-- Insertar un nuevo registro
INSERT INTO usuarios (nombre, email) VALUES ('Juan Perez', 'juan@example.com');

-- Actualizar un registro existente
UPDATE usuarios SET activo = false WHERE id = 5;

-- Eliminar un registro (¡Cuidado! Siempre usa WHERE)
DELETE FROM usuarios WHERE id = 10;
```

#### Gestión de Estructura (DDL)
```sql
-- Crear una base de datos nueva
CREATE DATABASE mi_nueva_db;

-- Crear una tabla simple
CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    precio DECIMAL(10,2)
);
```

### 🆘 Ayuda y Tips

- **`\?`**: Muestra la lista completa de comandos `\` (barra invertida) de psql.
- **`\h`**: Muestra ayuda sobre comandos SQL. Ejemplo: `\h SELECT` te explica cómo usar `SELECT`.
- **Limpiar pantalla**: En Linux, puedes usar `Ctrl + L` para limpiar la terminal de psql.
- **Historial**: Usa las flechas `Arriba` y `Abajo` para navegar por comandos anteriores.