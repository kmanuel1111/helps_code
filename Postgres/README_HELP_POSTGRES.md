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
- [⚙️ Gestión del Servicio (pg_ctl)](#-gestión-del-servicio-pg_ctl)
- [🏛️ Jerarquía de Objetos](#-jerarquía-de-objetos-en-postgresql)
- [🗄️ Tablespaces](#-tablespaces-en-postgresql)
- [🛢️ Bases de Datos (Databases)](#-bases-de-datos-databases)
- [🛡️ Gestión de Permisos (GRANT)](#-gestión-de-permisos-grant)
- [🛑 Revocar Permisos (REVOKE)](#-revocar-permisos-revoke)
- [🔍 Search Path (Ruta de Búsqueda)](#-que-es-el-search_path)
- [👮‍♂️ Seguridad: Autenticación (pg_hba.conf)](#-seguridad-autenticación-pg_hba-conf)
- [🛡️ Seguridad: Políticas de Fila (RLS)](#-seguridad-row-level-security-rls-policies)
- [🖥️ pgAdmin 4: Interfaz Gráfica](#-pgadmin-4-interfaz-gráfica-para-postgresql)
- [📚 Introducción a SQL](#-introducción-a-sql)
  - [🔢 Tipos de Datos](#-tipos-de-datos-en-postgresql)
  - [🏗️ Estructura del Lenguaje SQL (DDL, DML, DCL, TCL)](#-estructura-del-lenguaje-sql)
  - [📋 Tablas](#-tablas-tables)
  - [🔒 Tipos de Constraints](#-tipos-de-constraints-restricciones)
  - [👁️ Vistas (Views)](#-vistas-views)
  - [🔢 Secuencias (Sequences)](#-secuencias-sequences)
  - [🏷️ Domains](#-domains-dominios)
  - [🔗 Tipos de JOINs](#-tipos-de-joins)
- [🧰 Temas Avanzados de SQL](#-temas-avanzados-de-sql)
  - [⚡ Funciones SQL Útiles](#-funciones-sql-útiles)
  - [🖨️ FORMAT() — Formateo de Texto](#-format--formateo-de-texto-en-sql)
  - [🔬 Plan de Ejecución (EXPLAIN)](#-plan-de-ejecución-explain--explain-analyze)
  - [🔤 Quoting en PostgreSQL](#-quoting-en-postgresql)
  - [📇 Índices (Indexes)](#-índices-indexes)

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

---

## ⚙️ Gestión del Servicio (pg_ctl)

`pg_ctl` es una utilidad para inicializar, iniciar, detener o controlar el servidor de PostgreSQL. A diferencia de `systemctl` (que gestiona el servicio a nivel de sistema operativo), `pg_ctl` permite un control más directo sobre un directorio de datos específico.

### Estructura Básica

```bash
pg_ctl -D /ruta/al/directorio_data [accion]
```

### Acciones Comunes

| Acción      | Descripción                                                                                   | Comando Ejemplo                              |
| :---------- | :-------------------------------------------------------------------------------------------- | :------------------------------------------- |
| **start**   | Inicia el servidor.                                                                           | `pg_ctl -D /var/lib/postgresql/data start`   |
| **stop**    | Detiene el servidor.                                                                          | `pg_ctl -D /var/lib/postgresql/data stop`    |
| **restart** | Reinicia el servidor.                                                                         | `pg_ctl -D /var/lib/postgresql/data restart` |
| **status**  | Verifica si el servidor está corriendo.                                                       | `pg_ctl -D /var/lib/postgresql/data status`  |
| **reload**  | Recarga archivos de configuración (`pg_hba.conf`, `postgresql.conf`) sin detener el servicio. | `pg_ctl -D /var/lib/postgresql/data reload`  |

### Modos de Apagado (`-m`)

Al detener el servidor (`stop` o `restart`), puedes especificar cómo tratar las conexiones activas con el flag `-m`:

- **Smart** (`-m s`): Espera a que todos los clientes se desconecten y terminen sus transacciones. (Por defecto en backups).
- **Fast** (`-m f`): Interrumpe transacciones y desconecta clientes inmediatamente. (Recomendado para reinicios rápidos).
- **Immediate** (`-m i`): Aborta el proceso sin cerrar limpiamente. **No recomendado** (puede requerir recuperación al iniciar).

### Redirección de Logs (`-l`)

Es muy recomendable guardar la salida del servidor en un archivo de log. Usa el flag `-l`:

### Ejemplo Práctico

Reiniciar el servidor de forma rápida (fast) especificando el directorio de datos y archivo de log (Local):
```bash
pg_ctl -D /var/lib/postgres/data -l /var/log/postgresql/server.log -m fast restart
```

---

## 🏛️ Jerarquía de Objetos en PostgreSQL

Para entender cómo PostgreSQL organiza los datos, es fundamental comprender su jerarquía de objetos. A diferencia de otros gestores de base de datos, PostgreSQL estructura los objetos en varios niveles lógicos y físicos.

![jerarquia_postgres](./jerarquia_postgres.png)

### Explicación de la Jerarquía

Esta estructura jerárquica permite un control granular y organizado de los datos:

1.  **Database Cluster (Clúster de Bases de Datos)**
    *   Es la instancia principal de PostgreSQL en ejecución (el servicio).
    *   No se refiere a múltiples servidores, sino a **una colección de bases de datos** gestionada por una única instancia.
    *   Administra recursos compartidos como la memoria y procesos de fondo.

2.  **Objetos Globales (Users/Groups, Tablespaces)**
    *   **Roles (Users/Groups):** Los usuarios se definen a nivel de clúster. Un mismo usuario puede tener acceso a múltiples bases de datos dentro del clúster si se le conceden los permisos.
    *   **Tablespaces:** Definen las ubicaciones físicas en el disco donde se almacenan los archivos. Son globales y pueden ser utilizados por cualquier base de datos para optimizar el almacenamiento (ej. guardar índices en un disco SSD rápido).

3.  **Database (Base de Datos)**
    *   Es un contenedor **aislado** de esquemas y datos.
    *   Los objetos de una base de datos no son visibles ni accesibles directamente desde otra base de datos.
    *   Cada base de datos tiene sus propios catálogos y configuraciones.

4.  **Objetos a Nivel de Base de Datos**
    *   **Catalogs:** Tablas del sistema que almacenan metadatos sobre la base de datos (tablas, columnas, tipos de datos).
    *   **Extensions:** Módulos que extienden la funcionalidad de PostgreSQL (como PostGIS para datos geográficos o pgcrypto).
    *   **Schema (Esquema):** Es un espacio de nombres lógico (*namespace*) dentro de la base de datos. Permite organizar objetos y evitar colisiones de nombres (ej. `ventas.usuarios` y `rrhh.usuarios`).

5.  **Objetos a Nivel de Esquema**
    *   Aquí residen los objetos que contienen o procesan los datos reales:
        *   **Table:** Almacena registros (filas).
        *   **View:** Consultas guardadas que actúan como tablas virtuales.
        *   **Sequence:** Generadores de números secuenciales (usados para IDs).
        *   **Functions:** Procedimientos almacenados y lógica de negocio.
        *   **Event Triggers:** Disparadores que reaccionan a eventos del sistema.

---

## 🗄️ Tablespaces en PostgreSQL

Un `TABLESPACE` es una ubicación en el sistema de archivos donde PostgreSQL almacena los archivos de datos que contienen las tablas e índices de la base de datos.

### ¿Para qué sirven?

1.  **Optimización de Rendimiento (I/O):** Puedes colocar tablas o índices con mucho acceso en discos SSD rápidos y datos históricos o de poco uso en discos HDD más lentos pero económicos.
2.  **Gestión de Espacio:** Si una partición de disco se llena, puedes crear un tablespace en otra partición y mover objetos allí sin detener el servicio.
3.  **Separación de Carga:** Separar índices de tablas en distintos discos físicos para reducir la contención de I/O.

### 🛠️ Pasos para crear y usar un Tablespace

#### 1. Crear el directorio físico (en el SO)

Primero, debes crear la carpeta en el sistema operativo y darle permisos al usuario `postgres`.

```bash
# Crear directorio
sudo mkdir -p /mnt/fast_ssd/pg_data

# Asignar propietario postgres
sudo chown -R postgres:postgres /mnt/fast_ssd/pg_data
```

#### 2. Crear el Tablespace (en PostgreSQL)

Conéctate a PostgreSQL y ejecuta:

```sql
CREATE TABLESPACE fast_tablespace OWNER kzambrano LOCATION '/mnt/fast_ssd/pg_data';
```

#### 3. Usar el Tablespace

**Opción A: Crear una tabla directamente en el tablespace**

```sql
CREATE TABLE pedidos_log (
    id SERIAL PRIMARY KEY,
    fecha TIMESTAMP DEFAULT NOW(),
    descripcion TEXT
) TABLESPACE fast_tablespace;
```

**Opción B: Mover una tabla existente al tablespace**

```sql
ALTER TABLE usuarios SET TABLESPACE fast_tablespace;
```

**Opción C: Mover un índice a otro tablespace**

```sql
ALTER INDEX idx_usuarios_email SET TABLESPACE fast_tablespace;
```

**Opción D: Asignar un tablespace por defecto a una base de datos**

```sql
CREATE DATABASE nueva_db TABLESPACE fast_tablespace;
```

Esto hará que todas las tablas creadas en `nueva_db` se guarden por defecto en `fast_tablespace`, a menos que se especifique lo contrario.

### 🔍 Consultar Tablespaces

Para ver los tablespaces existentes y su ubicación:
```
\db+
```
```sql
SELECT spcname, pg_tablespace_location(oid) FROM pg_tablespace;
```

### 🗑️ Eliminar un Tablespace

Para eliminar un tablespace, primero debes asegurarte de que no esté en uso. Es decir, no debe contener tablas, índices u otros objetos. Si contiene objetos, debes moverlos a otro tablespace antes de eliminarlo.

```sql
-- Eliminar un tablespace que no está en uso
DROP TABLESPACE fast_tablespace;
```

---

## 🛢️ Bases de Datos (Databases)

Una **Base de Datos** en PostgreSQL es un contenedor lógico que aísla esquemas, tablas, funciones y otros objetos.

### Características Principales

1.  **Aislamiento:** Un usuario conectado a una base de datos no puede ver ni consultar objetos de otra base de datos.
2.  **Configuración Propia:** Cada base de datos puede tener su propia configuración y dueño.
3.  **Backups Individuales:** Puedes restaurar o hacer backup de una base de datos sin afectar a las demás.

### 🛠️ Gestión de Bases de Datos

#### 1. Crear una Base de Datos

El comando básico es `CREATE DATABASE`.

```sql
-- Creación simple
CREATE DATABASE mi_tienda;

-- Creación con parámetros específicos
CREATE DATABASE mi_tienda
    WITH 
    OWNER = kzambrano
    ENCODING = 'UTF8'
    TABLESPACE = fast_tablespace
    CONNECTION LIMIT = -1;
```

Nota: Se recomienda revocar la conexión a public. De forma que solo puedan ingresar los usuarios con pirivilegios.

```sql
REVOKE CONNECT ON DATABASE mi_tienda FROM public;
```

#### 2. Modificar una Base de Datos

Puedes renombrar, cambiar el dueño o ajustar parámetros de configuración.

```sql
-- Renombrar la base de datos
ALTER DATABASE mi_tienda RENAME TO mi_tienda_v2;

-- Cambiar el propietario
ALTER DATABASE mi_tienda_v2 OWNER TO nuevo_usuario;

-- Configurar parámetros por defecto para esta base de datos
-- (Ejemplo: establecer la zona horaria por defecto)
ALTER DATABASE mi_tienda_v2 SET timezone TO 'America/Caracas';
```

#### 3. Eliminar una Base de Datos

**¡Cuidado!** Esta acción es irreversible.

```sql
DROP DATABASE mi_tienda_v2;
```

> **Nota:** No puedes borrar una base de datos si hay usuarios conectados a ella.

**Forzar desconexión y borrado (PostgreSQL 13+):**

```sql
DROP DATABASE mi_tienda_v2 WITH (FORCE); -- BETA
```

#### 4. Clonar una Base de Datos

Puedes crear una copia exacta de una base de datos existente usándola como `TEMPLATE`.

```sql
-- Crear 'tienda_test' como copia de 'tienda_prod'
-- Importante: Nadie puede estar conectado a 'tienda_prod' durante este proceso
CREATE DATABASE tienda_test TEMPLATE tienda_prod;
```

### 📏 Consultar Tamaño

Para ver cuánto espacio en disco ocupa una base de datos:

```sql
SELECT pg_size_pretty(pg_database_size('nombre_db'));
```

Ver el tamaño de todas las bases de datos:

```sql
SELECT datname, pg_size_pretty(pg_database_size(datname)) 
FROM pg_database 
ORDER BY pg_database_size(datname) DESC;
```

---

## 🛡️ Gestión de Permisos (GRANT)

En PostgreSQL, los permisos se gestionan en una jerarquía: **Instancia -> Base de Datos -> Esquema -> Objeto (Tabla, Vista, etc.)**.

Para que un usuario pueda hacer un `SELECT` en una tabla, debe tener permisos de `CONNECT` en la base de datos y `USAGE` en el esquema donde está la tabla.

### 1. Nivel Base de Datos

Permite al usuario conectarse a la base de datos.
Recuerda que, por defecto, `public` suele tener permiso de conexión, por lo que es buena práctica revocarlo si se busca seguridad estricta.

```sql
-- Permitir conexión
GRANT CONNECT ON DATABASE mi_tienda TO kzambrano;
```

### 2. Nivel Esquema

El permiso `USAGE` permite "entrar" al esquema y buscar objetos dentro de él. `CREATE` permite crear nuevos objetos (tablas, funciones, etc.).

```sql
-- Permitir uso del esquema public
GRANT USAGE ON SCHEMA public TO kzambrano;

-- Permitir crear tablas en el esquema public
GRANT CREATE ON SCHEMA public TO kzambrano;
```

### 3. Nivel Tablas y Objetos

Aquí se definen las acciones específicas sobre los datos.

```sql
-- Permiso de lectura
GRANT SELECT ON ALL TABLES IN SCHEMA public TO kzambrano;

-- Permisos de escritura (Insertar, Actualizar, Borrar)
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO kzambrano;

-- Otorgar TODOS los permisos sobre una tabla específica
GRANT ALL PRIVILEGES ON TABLE usuarios TO kzambrano;
```

> **Nota:** `ON ALL TABLES` solo afecta las tablas que existen **en ese momento**. Para tablas futuras, debes usar `ALTER DEFAULT PRIVILEGES`.

### 4. Nivel Secuencias

Si tienes columnas `SERIAL` o `BIGSERIAL`, el usuario necesita permisos para usar la secuencia asociada al insertar datos.

```sql
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO kzambrano;
```

### 🧪 Ejemplos de Roles Comunes

#### Escenario A: Usuario de Solo Lectura (Reportes)

```sql
-- 1. Conexión
GRANT CONNECT ON DATABASE mi_tienda TO usuario_reportes;

-- 2. Uso del esquema
GRANT USAGE ON SCHEMA public TO usuario_reportes;

-- 3. Lectura de datos
GRANT SELECT ON ALL TABLES IN SCHEMA public TO usuario_reportes;

-- 4. Asegurar lectura para tablas futuras
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO usuario_reportes;
```

#### Escenario B: Usuario de Aplicación (Lectura y Escritura)

```sql
-- 1. Conexión
GRANT CONNECT ON DATABASE mi_tienda TO app_user;

-- 2. Uso del esquema
GRANT USAGE ON SCHEMA public TO app_user;

-- 3. Lectura y Escritura de datos
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;

-- 4. Permisos sobre secuencias (para los IDs)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- 5. Asegurar permisos para tablas futuras
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO app_user;
```

---

## 🛑 Revocar Permisos (REVOKE)

El comando `REVOKE` es lo opuesto a `GRANT`. Se utiliza para quitar privilegios previamente otorgados a un usuario o rol.

**Sintaxis General:**
`REVOKE [PERMISO] ON [OBJETO] FROM [USUARIO];`

### 1. Nivel Base de Datos

Quitar el permiso de conexión.

```sql
-- Revocar conexión a la base de datos
REVOKE CONNECT ON DATABASE mi_tienda FROM kzambrano;

-- Revocar conexión al rol público (Buena Práctica de Seguridad)
REVOKE CONNECT ON DATABASE mi_tienda FROM public;
```

### 2. Nivel Esquema

Quitar permisos de uso o creación.

```sql
-- Revocar uso del esquema
REVOKE USAGE ON SCHEMA public FROM kzambrano;

-- Revocar permiso de creación
REVOKE CREATE ON SCHEMA public FROM kzambrano;
```

### 3. Nivel Tablas y Objetos

Quitar permisos sobre datos.

```sql
-- Revocar permisos de lectura
REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM kzambrano;

-- Revocar permisos de escritura
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM kzambrano;

-- Revocar TODOS los privilegios sobre una tabla específica
REVOKE ALL PRIVILEGES ON TABLE usuarios FROM kzambrano;
```

### ⚠️ Uso de CASCADE y RESTRICT

Por defecto, `REVOKE` usa `RESTRICT`, lo que significa que fallará si otros privilegios dependen del que estás intentando revocar.

Si deseas revocar un privilegio y todos los que dependen de él (por ejemplo, si el usuario otorgó ese permiso a otros), usa `CASCADE`.

```sql
-- Revocar permiso y sus dependientes
REVOKE SELECT ON TABLE sensitiva FROM usuario_admin CASCADE;
```




---

## 🔍 ¿Qué es el `search_path`?

Imagina que estás en una biblioteca gigante (tu base de datos) y le pides al bibliotecario (PostgreSQL) el libro "Harry Potter".  
Si no le dices explícitamente en qué sección buscar (Fantasía, Infantil, Best Sellers), el bibliotecario tiene que tener un orden predefinido para buscar.  
Ese orden o "lista de lugares donde mirar" es el **`search_path`**.

En términos técnicos, el `search_path` es una lista ordenada de **esquemas** que PostgreSQL recorre cuando haces referencia a un objeto (tabla, vista, función) sin especificar su esquema completo.

### Ejemplo visual

Supongamos que tienes:
1.  Esquema **`ventas`** con una tabla llamada **`clientes`**.
2.  Esquema **`public`** TAMBIÉN con una tabla llamada **`clientes`**.

Y tu `search_path` está configurado como: `ventas, public`.

Cuando ejecutas:
```sql
SELECT * FROM clientes;
```

PostgreSQL hace lo siguiente:
1.  ¿Existe `clientes` en el esquema `ventas`? **¡SÍ!** -> Usa esa tabla y **se detiene**.
2.  Ignora totalmente la tabla `clientes` que está en `public`.

### 🕵️‍♀️ ¿Cómo ver tu `search_path` actual?

Por defecto, PostgreSQL viene configurado así: `"$user", public`.

*   `"$user"`: Busca primero en un esquema que se llame **igual que tu usuario actual**. Si tu usuario es `kzambrano`, busca un esquema `kzambrano`.
*   `public`: Si no lo encuentra antes, busca en el esquema `public` (donde suele estar todo por defecto).

Para verlo en tu consola, ejecuta:

```sql
SHOW search_path;
```

### 🛠️ ¿Cómo cambiar el `search_path`?

Tienes 3 niveles para cambiarlo, del más temporal al más permanente:

#### 1. Solo para esta sesión (Temporal)
Si cierras la terminal o te desconectas, se pierde la configuración. Útil para pruebas rápidas.

```sql
-- Ahora buscará primero en 'ventas', luego en 'public'
SET search_path TO ventas, public;
```

#### 2. Para un usuario específico (Persistente)
Cada vez que ese usuario se conecte, tendrá ese camino de búsqueda predefinido. Ideal para usuarios de aplicaciones.

```sql
ALTER ROLE kzambrano SET search_path TO ventas, public;
```

#### 3. Para toda la base de datos (Global)
Afecta a **todos** los que se conecten a esa base de datos (a menos que tengan su propia configuración de usuario, que tiene prioridad).

```sql
ALTER DATABASE mi_tienda SET search_path TO ventas, public;
```

### 💡 ¿Por qué es esto tan útil?

1.  **Limpieza y Organización:** Puedes tener tus tablas en esquemas organizados (`facturacion`, `rrhh`, `logistica`) y solo añadir al `search_path` lo que necesites en ese momento. Te ahorras escribir `SELECT * FROM facturacion.facturas` y solo escribes `SELECT * FROM facturas`.
    
2.  **Seguridad:** Puedes "ocultar" tablas de sistemas o versiones antiguas simplemente sacándolas del path.
    
3.  **Multitenancy (SaaS):** Este es el "superpoder" del search path.
    *   Imagina que tienes una aplicación para varios clientes.
    *   Creas un esquema `cliente_A` y otro `cliente_B` con las **mismas tablas** (facturas, usuarios).
    *   Cuando se conecta el Cliente A, configuras: `SET search_path TO cliente_A`.
    *   La aplicación ejecuta `SELECT * FROM facturas` y automáticamente trae las de A.
    *   ¡El código de la aplicación es el mismo para todos! Solo cambia el `search_path`.

---

## 👮‍♂️ Seguridad: Autenticación (pg_hba.conf)

El **`pg_hba.conf`** es el "portero de la discoteca" de tu base de datos. Controla **QUIÉN** puede conectarse, **DESDE DÓNDE** y **CÓMO**.
HBA significa **Host-Based Authentication**.

### ¿Dónde encontrarlo?
Su ubicación depende de la instalación, pero puedes preguntárselo a Postgres:

```sql
SHOW hba_file;
```

### Estructura del Archivo

Cada línea es una regla. Postgres lee el archivo de arriba a abajo y **se detiene en la primera coincidencia**.

```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     peer
host    all             all             127.0.0.1/32            scram-sha-256
host    mi_app_db       app_user        192.168.1.0/24          md5
host    all             all             0.0.0.0/0               reject
```

#### Explicación de Columnas:

1.  **TYPE:**
    *   `local`: Conexiones a través de socket Unix (en la misma máquina).
    *   `host`: Conexiones TCP/IP (incluyendo localHost y remotas).
    *   `hostssl`: Solo conexiones TCP/IP encriptadas con SSL.

2.  **DATABASE:**
    *   `all`: Todas las bases de datos.
    *   `nombre_db`: Una base de datos específica.
    *   `replication`: Para conexiones de replicación.

3.  **USER:**
    *   `all`: Cualquier usuario.
    *   `nombre_usuario`: Un usuario específico.
    *   `+nombre_grupo`: Miembros de un grupo.

4.  **ADDRESS:**
    *   La IP o rango de IPs desde donde se permite la conexión (CIDR).
    *   `127.0.0.1/32`: Solo localhost IPv4.
    *   `::1/128`: Solo localhost IPv6.
    *   `0.0.0.0/0`: Desde CUALQUIER lugar (⚠️ Peligroso si es `trust`).

5.  **METHOD:**
    *   `trust`: **¡PELIGRO!** Permite entrar sin contraseña. Solo úsalo en entornos de desarrollo muy controlados.
    *   `peer`: Usa el nombre del usuario del sistema operativo (común en Linux para usuario `postgres`).
    *   `md5`: Contraseña con hash MD5 (antiguo estándar).
    *   `scram-sha-256`: Contraseña con hash SHA-256 (estándar moderno y seguro).
    *   `reject`: Rechaza la conexión explícitamente.

### 🔄 Aplicar Cambios

Después de editar el archivo, **NO necesitas reiniciar** la base de datos, solo recargar la configuración:

Desde SQL:
```sql
SELECT pg_reload_conf();
```

Desde Terminal:
```bash
pg_ctl reload
# O en sistemas systemd:
sudo systemctl reload postgresql
```

---

## 🛡️ Seguridad: Row Level Security (RLS) Policies

Los permisos normales (`GRANT SELECT`) te dejan ver **toda** la tabla o nada.
Las **Policies (RLS)** te permiten definir reglas para ver **solo ciertas filas**.

Imagina una tabla `nominas`.
*   El jefe puede ver TODAS las filas.
*   El empleado solo puede ver SU PROPIA fila.

### 1. Activar RLS en la Tabla

Por defecto, RLS está desactivado. Debes activarlo explícitamente:

```sql
ALTER TABLE nominas ENABLE ROW LEVEL SECURITY;
```

🔴 **Importante:** Una vez activado, por defecto **NADIE (excepto el dueño de la tabla y superusuarios)** puede ver nada hasta que crees una política. (Principio de "Deny by Default").

### 2. Crear una Política (POLICY)

#### Ejemplo A: El usuario solo ve sus propios datos

Asumimos que la tabla `nominas` tiene una columna `usuario` que coincide con el `current_user` de la base de datos.

```sql
CREATE POLICY ver_propia_nomina ON nominas
    FOR SELECT                           -- Solo aplica a consultas SELECT
    TO public                            -- Aplica a todos los roles
    USING (usuario = current_user);      -- Condición: columna 'usuario' == usuario conectado
```

#### Ejemplo B: El Administrador ve todo

```sql
CREATE POLICY admin_ve_todo ON nominas
    FOR ALL                              -- Aplica a SELECT, INSERT, UPDATE, DELETE
    TO rol_administrador                 -- Solo aplica a este rol
    USING (true);                        -- Siempre verdadero (ve todo)
```

### 3. Casos de Uso Comunes

*   **Multi-tenant por fila:** Varios clientes en la misma tabla, cada uno solo ve sus datos (`organization_id = current_setting('app.current_org')::int`).
*   **Soft Deletes:** Ocultar filas marcadas como borradas (`deleted_at IS NULL`) para todos los usuarios normales.

### 🔍 Verificar Políticas

Para ver qué políticas existen en una tabla:

```sql
\d nominas
```
Al final de la salida verás la sección "Policies".

---

## 🖥️ pgAdmin 4: Interfaz Gráfica para PostgreSQL

### ¿Qué es pgAdmin 4?

Hasta ahora hemos trabajado con **`psql`**, que es la terminal de línea de comandos de PostgreSQL.  
**pgAdmin 4** es la herramienta gráfica oficial y gratuita para administrar PostgreSQL.

Piénsalo así:
- `psql` es como conducir un automóvil con palanca — potente y preciso, pero requiere práctica.
- `pgAdmin 4` es como conducir un automóvil automático — más visual e intuitivo para el día a día.

> **¿Cuándo usar cada uno?**  
> Usa `psql` para automatizaciones, scripts y cuando estés en un servidor remoto sin interfaz gráfica.  
> Usa `pgAdmin 4` cuando quieras explorar datos visualmente, crear objetos con asistentes, o simplemente prefieras ver todo en pantalla.

---

### 💿 Instalación de pgAdmin 4

pgAdmin 4 puede instalarse de tres maneras según tu sistema operativo:

#### 🐧 En Linux (Debian/Ubuntu)

```bash
# 1. Instalar el repositorio de pgAdmin
curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg

sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'

# 2. Actualizar e instalar
sudo apt update

# Instalar versión de escritorio (GUI local)
sudo apt install pgadmin4-desktop

# O instalar versión web (se accede desde el navegador)
sudo apt install pgadmin4-web

# Si instalas la versión web, configúrala con:
sudo /usr/pgadmin4/bin/setup-web.sh
```

> ℹ️ **¿Cuál elegir?**  
> - `pgadmin4-desktop`: Se abre como una aplicación normal de escritorio.  
> - `pgadmin4-web`: Se accede desde tu navegador en `http://localhost/pgadmin4`. Útil en servidores.

#### 🪟 En Windows

1. Ve a la página oficial: [https://www.pgadmin.org/download/pgadmin-4-windows/](https://www.pgadmin.org/download/pgadmin-4-windows/)
2. Descarga el instalador `.exe` de la última versión.
3. Ejecútalo y sigue el asistente (Siguiente → Siguiente → Instalar).
4. Al finalizar, pgAdmin 4 aparecerá en tu menú de inicio.

> **Nota:** Si instalaste PostgreSQL desde el instalador oficial de [postgresql.org](https://www.postgresql.org/download/windows/), pgAdmin 4 probablemente ya vino incluido y ya está instalado en tu máquina.

#### 🍎 En macOS

1. Ve a: [https://www.pgadmin.org/download/pgadmin-4-macos/](https://www.pgadmin.org/download/pgadmin-4-macos/)
2. Descarga el archivo `.dmg`.
3. Arrástralo a tu carpeta de **Aplicaciones**.

---

### 🔌 Primera Conexión a un Servidor PostgreSQL

Una vez que abres pgAdmin 4 por primera vez, verás un panel en blanco. Debes **registrar un servidor** (es decir, decirle a pgAdmin a qué instancia de PostgreSQL debe conectarse).

#### Paso a Paso

**Paso 1:** En el panel izquierdo ("Browser"), haz clic derecho en **"Servers"** → **"Register"** → **"Server..."**

```
Panel izquierdo  →  Servers  →  (clic derecho)  →  Register  →  Server...
```

**Paso 2:** Se abre una ventana con dos pestañas principales. Completa la pestaña **"General"**:

| Campo    | Valor de ejemplo      | Descripción                                                    |
| :------- | :-------------------- | :------------------------------------------------------------- |
| **Name** | `Mi PostgreSQL Local` | Un alias que TÚ le pones (solo para identificarlo en pgAdmin). |

**Paso 3:** Ve a la pestaña **"Connection"** y completa los datos de conexión:

| Campo                    | Valor típico              | Descripción                                                                               |
| :----------------------- | :------------------------ | :---------------------------------------------------------------------------------------- |
| **Host name/address**    | `localhost` o `127.0.0.1` | IP del servidor. Si está en tu misma máquina, es `localhost`.                             |
| **Port**                 | `5432`                    | Puerto por defecto de PostgreSQL.                                                         |
| **Maintenance database** | `postgres`                | La base de datos a la que pgAdmin se conecta inicialmente (la `postgres` siempre existe). |
| **Username**             | `kzambrano`               | Tu usuario de PostgreSQL.                                                                 |
| **Password**             | `tu_contraseña`           | La contraseña del usuario.                                                                |

**Paso 4:** Opcionalmente, activa **"Save password"** para no tener que escribirla cada vez.

**Paso 5:** Haz clic en **"Save"**. Si los datos son correctos, verás el servidor aparecer en el árbol de la izquierda con un ícono de toma de corriente ✅.

> 🔴 **Error común:** Si ves `Connection refused` o `could not connect to server`, verifica:
> 1. Que el servicio de PostgreSQL esté corriendo: `sudo systemctl status postgresql`
> 2. Que el host y puerto sean correctos.
> 3. Que el usuario y contraseña sean válidos.

---

### 🗺️ Navegando pgAdmin 4: La Interfaz Explicada

```
📁 Servers
 └── 📡 Mi PostgreSQL Local
      └── 🗄️ Databases
           └── 📦 mi_tienda        ← aquí están tus datos
                ├── 📏 Schemas
                │    └── 🧩 public
                │         ├── 📊 Tables      ← tus tablas
                │         ├── 👁️ Views
                │         └── 🔢 Sequences
                ├── 🏛️ Extensions
                └── ⚙️ Functions
```

- **Para ver tablas:** Expande `Databases` → tu_base_de_datos → `Schemas` → `public` → `Tables`.
- **Para ver columnas de una tabla:** Haz clic en la tabla → verás su estructura en el panel derecho.

---

### 🛠️ Tips Más Útiles del Día a Día

#### 1. 📝 Query Tool: Tu consola SQL visual

El **Query Tool** es el equivalente visual al `psql`. Aquí escribes y ejecutas tus consultas SQL.

**Cómo abrirlo:**
- Haz clic derecho sobre una base de datos → **"Query Tool"**
- O usa el menú superior: `Tools` → `Query Tool`

**Atajos de teclado clave dentro del Query Tool:**

| Atajo          | Acción                                            |
| :------------- | :------------------------------------------------ |
| `F5`           | Ejecutar la consulta completa                     |
| `Shift + F5`   | Ejecutar SOLO la consulta donde está el cursor    |
| `Ctrl + /`     | Comentar/descomentar la línea seleccionada        |
| `Ctrl + Space` | Autocompletar (nombres de tablas, columnas, etc.) |
| `Ctrl + S`     | Guardar el script `.sql` en un archivo            |

> 💡 **Tip:** Si seleccionas solo una parte del SQL y presionas `F5`, ejecutará únicamente lo seleccionado. Muy útil para probar partes de una consulta larga.

#### 2. 📊 Ver el contenido de una tabla rápidamente

No necesitas escribir `SELECT * FROM tabla`. Puedes hacerlo visualmente:

1. En el árbol izquierdo, haz clic derecho en cualquier tabla.
2. Selecciona **"View/Edit Data"** → **"All Rows"**.
3. Se abrirá el Query Tool con los datos ya cargados.

#### 3. 📤 Exportar datos a CSV o Excel

¿Necesitas compartir datos con alguien que no usa PostgreSQL? pgAdmin permite exportar resultados fácilmente.

1. Ejecuta tu consulta en el Query Tool.
2. En la barra de resultados, haz clic en el ícono de **descarga** (o el botón **"Download as CSV"**).
3. Se genera un archivo `.csv` que puedes abrir en Excel o Google Sheets.

#### 4. 🔎 Inspeccionar la estructura de una tabla (DDL)

¿Quieres ver cómo fue creada una tabla? pgAdmin puede mostrarte el SQL exacto.

1. Haz clic derecho en la tabla.
2. Selecciona **"Properties..."** para ver columnas, tipos de datos, restricciones, índices, etc.
3. O selecciona **"Scripts"** → **"CREATE Script"** para ver el `CREATE TABLE` completo.

#### 5. 🔒 Verificar permisos de un usuario fácilmente

En el Query Tool, puedes ejecutar:
```sql
-- Ver todos los permisos sobre las tablas del esquema public
SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
ORDER BY grantee, table_name;
```

#### 6. 📈 Ver el tamaño de tablas y búsqueda de tablas pesadas

```sql
-- Ver las tablas más grandes de la base de datos actual
SELECT
    schemaname AS esquema,
    tablename AS tabla,
    pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS tamaño_total,
    pg_size_pretty(pg_relation_size(schemaname || '.' || tablename)) AS tamaño_datos,
    pg_size_pretty(pg_indexes_size(schemaname || '.' || tablename)) AS tamaño_indices
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname || '.' || tablename) DESC
LIMIT 20;
```

#### 7. 🐢 Identificar consultas lentas en tiempo real

```sql
-- Ver las consultas que están corriendo ahora mismo
SELECT
    pid,
    now() - pg_stat_activity.query_start AS duracion,
    query,
    state
FROM pg_stat_activity
WHERE state = 'active'
  AND query_start < now() - interval '5 seconds'
ORDER BY duracion DESC;
```

> 💡 Si ves una consulta con mucho tiempo, puedes terminarla con:
> ```sql
> SELECT pg_terminate_backend(pid);  -- Reemplaza pid con el número real
> ```

---

### ✅ Resumen: Qué Puedes Hacer con pgAdmin 4

| Tarea                   | Cómo                                         |
| :---------------------- | :------------------------------------------- |
| Ejecutar SQL            | Query Tool (`F5`)                            |
| Ver tablas y columnas   | Árbol izquierdo → Tables                     |
| Ver datos de una tabla  | Clic derecho en tabla → View/Edit Data       |
| Exportar datos a CSV    | Query Tool → botón descarga                  |
| Ver el DDL de un objeto | Clic derecho → Scripts → CREATE Script       |
| Crear una base de datos | Clic derecho en Databases → Create           |
| Crear un usuario        | Clic derecho en Login/Group Roles → Create   |
| Hacer un backup         | Clic derecho en la base de datos → Backup... |
| Ver roles y permisos    | Object → Properties → Security               |

---

# 📚 Introducción a SQL

SQL (**Structured Query Language**) es el idioma universal para comunicarse con bases de datos relacionales.  
No importa si usas PostgreSQL, MySQL, SQL Server u Oracle — el núcleo del lenguaje es el mismo.

> **¿Qué significa "relacional"?**  
> Que los datos se guardan en **tablas** (como hojas de cálculo), y esas tablas pueden estar **relacionadas** entre sí. Por ejemplo, una tabla de `pedidos` puede relacionarse con una tabla de `clientes`.

---

## 🔢 Tipos de Datos en PostgreSQL

Antes de crear cualquier tabla, necesitas saber **qué tipos de información** puede guardar PostgreSQL.  
Elegir el tipo correcto es como elegir el recipiente correcto: no pondrías agua en una bolsa de papel.

### 📐 Numéricos

| Tipo                            |  Tamaño  | Rango / Descripción             | Cuándo Usarlo                                                              |
| :------------------------------ | :------: | :------------------------------ | :------------------------------------------------------------------------- |
| `SMALLINT`                      | 2 bytes  | -32,768 a 32,767                | Contadores pequeños, códigos de estado                                     |
| `INTEGER` / `INT`               | 4 bytes  | -2,147,483,648 a 2,147,483,647  | IDs, cantidades, el más común                                              |
| `BIGINT`                        | 8 bytes  | -9.2 × 10¹⁸ a 9.2 × 10¹⁸        | IDs de sistemas con millones de registros                                  |
| `NUMERIC(p,s)` / `DECIMAL(p,s)` | Variable | Precisión exacta                | **Dinero, precios, cálculos financieros** ❗ Nunca uses `FLOAT` para dinero |
| `REAL`                          | 4 bytes  | 6 dígitos de precisión          | Datos científicos, coordenadas aproximadas                                 |
| `DOUBLE PRECISION`              | 8 bytes  | 15 dígitos de precisión         | Mediciones de mayor precisión                                              |
| `SERIAL`                        | 4 bytes  | Autoincremental (1, 2, 3...)    | IDs autogenerados (atajo para INTEGER + SEQUENCE)                          |
| `BIGSERIAL`                     | 8 bytes  | Autoincremental (entero grande) | IDs en tablas muy grandes                                                  |

```sql
-- Ejemplo: NUMERIC(10, 2) significa máximo 10 dígitos en total, 2 de ellos decimales
-- Válido: 99999999.99  → 9 enteros + 2 decimales = 11... error
-- Válido: 9999999.99   → 7 enteros + 2 decimales = 9 total ✅
precio NUMERIC(10, 2)
```

### 🔤 Cadenas de Texto (Character)

| Tipo         | Descripción                                              | Cuándo Usarlo                                                     |
| :----------- | :------------------------------------------------------- | :---------------------------------------------------------------- |
| `CHAR(n)`    | Longitud **fija**. Rellena con espacios si es más corto. | Códigos de longitud siempre igual (ej. código de país 'VE', 'US') |
| `VARCHAR(n)` | Longitud **variable**, máximo `n` caracteres.            | Nombres, emails, textos cortos con límite definido                |
| `TEXT`       | Longitud **ilimitada**.                                  | Descripciones largas, contenido de artículos, HTML                |

```sql
-- Ejemplo comparativo
codigo_pais  CHAR(2),        -- Siempre 2 letras: 'VE', 'US', 'BR'
nombre       VARCHAR(100),   -- Máximo 100 caracteres, puede ser menos
descripcion  TEXT            -- Sin límite de tamaño
```

> 💡 **Tip PostgreSQL:** En PostgreSQL, `TEXT` y `VARCHAR` tienen el mismo rendimiento. Usa `VARCHAR(n)` cuando quieras imponer un límite de negocio, y `TEXT` cuando no haya límite natural.

### 📅 Fechas y Tiempo (Temporal)

| Tipo          | Descripción                                                              | Ejemplo                         |
| :------------ | :----------------------------------------------------------------------- | :------------------------------ |
| `DATE`        | Solo la fecha (año, mes, día).                                           | `'2025-12-31'`                  |
| `TIME`        | Solo la hora (sin zona horaria).                                         | `'14:30:00'`                    |
| `TIMETZ`      | Hora con zona horaria.                                                   | `'14:30:00-04:00'`              |
| `TIMESTAMP`   | Fecha y hora combinadas (sin zona horaria).                              | `'2025-12-31 14:30:00'`         |
| `TIMESTAMPTZ` | Fecha y hora con zona horaria. **El más recomendado para aplicaciones.** | `'2025-12-31 14:30:00-04:00'`   |
| `INTERVAL`    | Una duración de tiempo.                                                  | `'3 days 4 hours'`, `'1 month'` |

```sql
-- Funciones de fecha más útiles
SELECT NOW();                          -- Fecha y hora actual con zona horaria
SELECT CURRENT_DATE;                   -- Solo la fecha de hoy
SELECT CURRENT_TIME;                   -- Solo la hora actual
SELECT NOW() - INTERVAL '7 days';     -- Hace 7 días
SELECT EXTRACT(YEAR FROM NOW());       -- Extraer el año
SELECT DATE_TRUNC('month', NOW());     -- Primer día del mes actual
```

### 🗂️ Otros Tipos Importantes

| Tipo      | Descripción                                                        | Caso de Uso                       |
| :-------- | :----------------------------------------------------------------- | :-------------------------------- |
| `BOOLEAN` | `true` / `false` / `NULL`                                          | Banderas, estados activo/inactivo |
| `UUID`    | Identificador único universal (128 bits)                           | IDs distribuidos, APIs REST       |
| `JSON`    | Texto JSON (sin validación de estructura interna)                  | Datos semiestructurados           |
| `JSONB`   | JSON binario, **indexable y eficiente**. Recomendado sobre `JSON`. | Datos dinámicos, configuraciones  |
| `ARRAY`   | Un arreglo de cualquier tipo                                       | Etiquetas, listas de opciones     |
| `INET`    | Dirección IP (IPv4 o IPv6)                                         | Logs de acceso, redes             |
| `BYTEA`   | Datos binarios (imágenes, archivos)                                | Almacenar archivos pequeños       |

```sql
-- Ejemplos de uso
activo       BOOLEAN DEFAULT true,
user_id      UUID DEFAULT gen_random_uuid(),
config       JSONB,
etiquetas    TEXT[],                     -- Array de texto
ip_origen    INET
```

---

## 🏗️ Estructura del Lenguaje SQL

SQL no es un solo tipo de comando — se divide en **4 categorías** según lo que hacen:

```
SQL
├── DDL  → Define la estructura (crea, modifica, elimina objetos)
├── DML  → Manipula los datos (inserta, actualiza, borra)
├── DCL  → Controla los accesos y permisos
└── TCL  → Gestiona las transacciones
```

### 📐 DDL — Data Definition Language

Define la **estructura** de la base de datos. Los cambios son automáticamente permanentes.

| Comando    | Qué hace                                            |
| :--------- | :-------------------------------------------------- |
| `CREATE`   | Crea un objeto (tabla, vista, índice, etc.)         |
| `ALTER`    | Modifica la estructura de un objeto                 |
| `DROP`     | Elimina un objeto **permanentemente**               |
| `TRUNCATE` | Vacía una tabla (borra todos los datos, muy rápido) |

```sql
CREATE TABLE productos (...);       -- Crear
ALTER TABLE productos ADD COLUMN descuento NUMERIC(5,2);  -- Modificar
DROP TABLE productos;               -- Eliminar
TRUNCATE TABLE logs;                -- Vaciar (más rápido que DELETE)
```

### ✏️ DML — Data Manipulation Language

Trabaja con los **datos** dentro de los objetos. Puede deshacerse con `ROLLBACK`.

| Comando  | Qué hace                      |
| :------- | :---------------------------- |
| `SELECT` | Lee/consulta datos            |
| `INSERT` | Agrega nuevos registros       |
| `UPDATE` | Modifica registros existentes |
| `DELETE` | Elimina registros específicos |

```sql
SELECT nombre FROM clientes WHERE activo = true;
INSERT INTO clientes (nombre, email) VALUES ('Ana', 'ana@mail.com');
UPDATE clientes SET activo = false WHERE id = 5;
DELETE FROM clientes WHERE id = 5;
```

### 🔑 DCL — Data Control Language

Controla **quién puede hacer qué** en la base de datos.

| Comando  | Qué hace                           |
| :------- | :--------------------------------- |
| `GRANT`  | Otorga permisos a un usuario o rol |
| `REVOKE` | Quita permisos a un usuario o rol  |

```sql
GRANT SELECT ON TABLE clientes TO usuario_reportes;
REVOKE INSERT ON TABLE clientes FROM usuario_reportes;
```

> 📖 Ver sección completa: [Gestión de Permisos (GRANT)](#-gestión-de-permisos-grant)

### 🔄 TCL — Transaction Control Language

Gestiona **transacciones**: grupos de operaciones que deben ejecutarse todas o ninguna.

> **Analogía:** Es como una transferencia bancaria. O se descuenta de tu cuenta Y se acredita en la otra, o no pasa nada. No puede pasar "a medias".

| Comando     | Qué hace                                   |
| :---------- | :----------------------------------------- |
| `BEGIN`     | Inicia una transacción                     |
| `COMMIT`    | Confirma y guarda todos los cambios        |
| `ROLLBACK`  | Deshace todos los cambios desde el `BEGIN` |
| `SAVEPOINT` | Crea un punto de restauración intermedio   |

```sql
BEGIN;
    UPDATE cuentas SET saldo = saldo - 500 WHERE id = 1;  -- Débito
    UPDATE cuentas SET saldo = saldo + 500 WHERE id = 2;  -- Crédito
COMMIT;  -- Solo se guarda si ambos UPDATE fueron exitosos
```

```sql
-- Ejemplo con ROLLBACK ante un error
BEGIN;
    DELETE FROM pedidos WHERE cliente_id = 99;
    -- ¡Ups! Me equivoqué, no era ese cliente
ROLLBACK;  -- Deshace el DELETE, los datos están intactos
```

---

## 📋 Tablas (Tables)

Una **tabla** es la unidad básica de almacenamiento en SQL. Piénsala como una hoja de cálculo donde:
- Las **columnas** definen qué datos se guardan (nombre, precio, fecha...).
- Las **filas** son los registros individuales (cada producto, cada cliente...).

### Crear una Tabla

```sql
CREATE TABLE productos (
    -- Columna       Tipo de Dato      Restricción
    id               SERIAL            PRIMARY KEY,
    nombre           VARCHAR(150)      NOT NULL,
    descripcion      TEXT,
    precio           NUMERIC(10, 2)    NOT NULL DEFAULT 0.00,
    stock            INTEGER           NOT NULL DEFAULT 0,
    activo           BOOLEAN           NOT NULL DEFAULT true,
    creado_en        TIMESTAMPTZ       NOT NULL DEFAULT NOW()
);
```

### Modificar una Tabla (ALTER TABLE)

```sql
-- Agregar una columna nueva
ALTER TABLE productos ADD COLUMN categoria VARCHAR(50);

-- Eliminar una columna
ALTER TABLE productos DROP COLUMN categoria;

-- Cambiar el tipo de dato de una columna
ALTER TABLE productos ALTER COLUMN descripcion TYPE VARCHAR(500);

-- Renombrar una columna
ALTER TABLE productos RENAME COLUMN nombre TO nombre_producto;

-- Renombrar la tabla
ALTER TABLE productos RENAME TO catalogo_productos;

-- Agregar un valor por defecto a una columna existente
ALTER TABLE productos ALTER COLUMN activo SET DEFAULT true;
```

### Eliminar una Tabla

```sql
-- Eliminar una tabla (¡Irreversible!)
DROP TABLE productos;

-- Eliminar solo si existe (evita errores si no existe)
DROP TABLE IF EXISTS productos;

-- Eliminar aunque otras tablas dependan de ella (¡Peligroso!)
DROP TABLE productos CASCADE;
```

### Vaciar una tabla (TRUNCATE)

```sql
-- Borra TODOS los datos pero conserva la estructura
-- Mucho más rápido que DELETE sin WHERE en tablas grandes
TRUNCATE TABLE logs;

-- Vaciar y reiniciar los contadores SERIAL/SEQUENCE
TRUNCATE TABLE pedidos RESTART IDENTITY;
```

> ⚠️ **TRUNCATE vs DELETE:**  
> - `TRUNCATE` elimina TODOS los registros de golpe, no se puede filtrar con `WHERE`, y no activa triggers de fila.  
> - `DELETE` puede tener `WHERE`, activa triggers, y puede deshacerse con `ROLLBACK`.

---

## 🔒 Tipos de Constraints (Restricciones)

Los **constraints** son reglas que PostgreSQL aplica automáticamente para garantizar la integridad de los datos.  
Son como los validadores de un formulario, pero a nivel de base de datos — **irrompibles**.

### PRIMARY KEY — La Llave Única

Identifica **inequívocamente** cada fila de la tabla. No puede ser `NULL` ni repetirse.

```sql
-- Forma 1: Inline (en la definición de la columna)
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100)
);

-- Forma 2: Al final de la tabla
CREATE TABLE usuarios (
    id SERIAL,
    nombre VARCHAR(100),
    CONSTRAINT pk_usuarios PRIMARY KEY (id)
);

-- PRIMARY KEY compuesta (cuando la combinación de columnas es la clave)
CREATE TABLE orden_producto (
    orden_id   INTEGER,
    producto_id INTEGER,
    cantidad   INTEGER,
    PRIMARY KEY (orden_id, producto_id)  -- La combinación debe ser única
);
```

### NOT NULL — Campo Obligatorio

Impide que una columna quede en blanco.

```sql
CREATE TABLE clientes (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,   -- Obligatorio
    email  VARCHAR(200) NOT NULL,   -- Obligatorio
    telefono VARCHAR(20)            -- Opcional (puede ser NULL)
);
```

### UNIQUE — Sin Duplicados

Garantiza que no haya dos filas con el mismo valor en esa columna.

```sql
CREATE TABLE usuarios (
    id    SERIAL PRIMARY KEY,
    email VARCHAR(200) NOT NULL UNIQUE,   -- No pueden repetirse emails
    dni   VARCHAR(20)  UNIQUE            -- Tampoco el DNI
);

-- UNIQUE compuesto (la COMBINACIÓN debe ser única)
CREATE TABLE inscripciones (
    usuario_id INTEGER,
    curso_id   INTEGER,
    UNIQUE (usuario_id, curso_id)  -- Un usuario no puede inscribirse dos veces al mismo curso
);
```

### FOREIGN KEY — Relación Entre Tablas

Garantiza que un valor en una columna **exista** en otra tabla. Es la base de las relaciones.

```sql
CREATE TABLE pedidos (
    id          SERIAL PRIMARY KEY,
    cliente_id  INTEGER NOT NULL,
    total       NUMERIC(12, 2),
    
    -- La clave foránea: cliente_id debe existir en la tabla clientes
    CONSTRAINT fk_pedidos_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES clientes(id)
        ON DELETE RESTRICT   -- No permite borrar un cliente si tiene pedidos
        ON UPDATE CASCADE    -- Si cambia el ID del cliente, actualiza aquí también
);
```

**Opciones para `ON DELETE` / `ON UPDATE`:**

| Opción        | Comportamiento                                                    |
| :------------ | :---------------------------------------------------------------- |
| `RESTRICT`    | Bloquea la operación si hay registros dependientes.               |
| `CASCADE`     | Propaga el cambio automáticamente (borra/actualiza los hijos).    |
| `SET NULL`    | Pone `NULL` en la columna de la tabla hija.                       |
| `SET DEFAULT` | Restaura el valor por defecto de la columna hija.                 |
| `NO ACTION`   | Igual que `RESTRICT`, pero verificado al final de la transacción. |

### CHECK — Validación de Rango o Lógica

Valida que el valor cumpla una condición personalizada.

```sql
CREATE TABLE productos (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    precio NUMERIC(10, 2) CHECK (precio >= 0),               -- No puede ser negativo
    stock  INTEGER        CHECK (stock >= 0),                 -- Tampoco el stock
    rating NUMERIC(2,1)   CHECK (rating BETWEEN 0.0 AND 5.0) -- Rating de 0 a 5
);

-- CHECK con nombre (más descriptivo en los errores)
CREATE TABLE empleados (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    salario NUMERIC(10,2),
    CONSTRAINT chk_salario_positivo CHECK (salario > 0)
);
```

### DEFAULT — Valor por Defecto

Establece un valor automático cuando no se especifica uno al insertar.

```sql
CREATE TABLE articulos (
    id         SERIAL PRIMARY KEY,
    titulo     VARCHAR(200) NOT NULL,
    publicado  BOOLEAN      DEFAULT false,         -- Por defecto no publicado
    vistas     INTEGER      DEFAULT 0,             -- Inicia en cero
    creado_en  TIMESTAMPTZ  DEFAULT NOW(),         -- Fecha actual automática
    region     VARCHAR(20)  DEFAULT 'LATAM'
);
```

### Agregar y Quitar Constraints Posteriormente

```sql
-- Agregar un NOT NULL después de crear la tabla
ALTER TABLE productos ALTER COLUMN precio SET NOT NULL;

-- Agregar un UNIQUE
ALTER TABLE usuarios ADD CONSTRAINT uq_email UNIQUE (email);

-- Agregar un CHECK
ALTER TABLE productos ADD CONSTRAINT chk_precio CHECK (precio >= 0);

-- Eliminar un constraint por su nombre
ALTER TABLE productos DROP CONSTRAINT chk_precio;

-- Ver constraints de una tabla
SELECT conname, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'productos'::regclass;
```

---

## 👁️ Vistas (Views)

Una **vista** es una consulta SQL guardada con un nombre. Desde afuera, se comporta exactamente como una tabla, pero **no almacena datos propios** — los lee de las tablas originales cada vez que la consultas.

> **Analogía:** Una vista es como un "acceso directo" que cuando lo abres, ejecuta la consulta y te muestra el resultado actualizado.

### ¿Para qué sirven?

1. **Simplificar consultas complejas** — Guardas un `SELECT` complicado con múltiples JOINs y lo usas como si fuera una tabla simple.
2. **Seguridad** — Das acceso a una vista (que muestra solo ciertas columnas) sin exponer la tabla completa.
3. **Abstracción** — Si cambias la estructura interna, la vista sigue funcionando igual.

### Crear una Vista

```sql
-- Vista simple
CREATE VIEW vista_clientes_activos AS
    SELECT id, nombre, email
    FROM clientes
    WHERE activo = true;

-- Usarla como si fuera una tabla
SELECT * FROM vista_clientes_activos;
SELECT nombre FROM vista_clientes_activos WHERE email LIKE '%@gmail.com';
```

```sql
-- Vista con JOIN: resume información de varias tablas
CREATE VIEW vista_resumen_pedidos AS
    SELECT
        p.id           AS pedido_id,
        c.nombre       AS cliente,
        p.total,
        p.creado_en    AS fecha
    FROM pedidos p
    JOIN clientes c ON p.cliente_id = c.id;
```

### Reemplazar o Eliminar una Vista

```sql
-- Reemplazar (actualizar) una vista existente
CREATE OR REPLACE VIEW vista_clientes_activos AS
    SELECT id, nombre, email, telefono  -- Ahora también incluimos teléfono
    FROM clientes
    WHERE activo = true;

-- Eliminar una vista
DROP VIEW IF EXISTS vista_clientes_activos;
```

### Vista Materializada (MATERIALIZED VIEW)

Una vista materializada **sí almacena los datos** físicamente. Esto la hace muy rápida para consultar, pero sus datos se "congelan" hasta que la refrescas manualmente.

```sql
-- Crear vista materializada (guarda los datos en disco)
CREATE MATERIALIZED VIEW resumen_ventas_mensual AS
    SELECT
        DATE_TRUNC('month', creado_en) AS mes,
        COUNT(*)                        AS total_pedidos,
        SUM(total)                      AS ingresos
    FROM pedidos
    GROUP BY 1
    ORDER BY 1;

-- Actualizar sus datos cuando lo necesites
REFRESH MATERIALIZED VIEW resumen_ventas_mensual;

-- Usarla
SELECT * FROM resumen_ventas_mensual;
```

> **¿Cuándo usar cuál?**
> - **Vista normal:** datos siempre actualizados, consultas simples o medianas.
> - **Vista materializada:** reportes/dashboards pesados que se consultan mucho pero los datos no cambian a cada segundo.

---

## 🔢 Secuencias (Sequences)

Una **secuencia** es un generador de números únicos y consecutivos. Es lo que hay "detrás" de los tipos `SERIAL` y `BIGSERIAL`.

> **Analogía:** Es como un ticket de turno en un banco — cada vez que pides uno, te da el siguiente número disponible, sin repetirse nunca.

### Crear y Usar una Secuencia

```sql
-- Crear una secuencia manualmente
CREATE SEQUENCE seq_numero_factura
    START WITH 1000     -- Empieza en 1000
    INCREMENT BY 1      -- Sube de uno en uno
    MINVALUE 1000
    MAXVALUE 9999999
    NO CYCLE;           -- Lanza error cuando llega al máximo (no reinicia)

-- Obtener el próximo número
SELECT NEXTVAL('seq_numero_factura');   -- Resultado: 1000

-- Ver el valor actual (sin avanzar)
SELECT CURRVAL('seq_numero_factura');   -- Resultado: 1000

-- Usar en un INSERT
INSERT INTO facturas (numero, cliente_id)
VALUES (NEXTVAL('seq_numero_factura'), 5);
```

### Conectar una Secuencia a una Tabla

```sql
-- Crear tabla usando la secuencia como valor por defecto
CREATE TABLE facturas (
    id        INTEGER    DEFAULT NEXTVAL('seq_numero_factura') PRIMARY KEY,
    cliente_id INTEGER   NOT NULL,
    total      NUMERIC(12,2)
);
```

### Lo que hace SERIAL "por dentro"

Cuando escribes `SERIAL`, PostgreSQL hace exactamente esto:

```sql
-- Esto:
CREATE TABLE usuarios (id SERIAL PRIMARY KEY);

-- Es equivalente a esto:
CREATE SEQUENCE usuarios_id_seq;
CREATE TABLE usuarios (
    id INTEGER DEFAULT NEXTVAL('usuarios_id_seq') NOT NULL
);
ALTER SEQUENCE usuarios_id_seq OWNED BY usuarios.id;
```

### Operaciones Útiles

```sql
-- Ver todas las secuencias en la base de datos
SELECT * FROM information_schema.sequences;

-- Reiniciar una secuencia a un valor específico (útil tras truncar una tabla)
ALTER SEQUENCE seq_numero_factura RESTART WITH 1000;

-- Eliminar una secuencia
DROP SEQUENCE IF EXISTS seq_numero_factura;
```

---

## 🏷️ Domains (Dominios)

Un **Domain** es un tipo de dato personalizado con reglas adicionales integradas.  
Es como crear tu propio tipo de dato que lleva sus restricciones incluidas — defines las reglas una vez y las reutilizas en muchas tablas.

> **Analogía:** Imagina que en tu empresa usas siempre el mismo formato de código de producto: "Letras mayúsculas + 4 números" (ej. `PROD1234`). En lugar de repetir el `CHECK` en cada tabla, creas un tipo `codigo_producto` con esa regla, y lo usas donde quieras.

### Crear un Domain

```sql
-- Domain para correos electrónicos (con validación de formato)
CREATE DOMAIN email_valido AS TEXT
    CHECK (VALUE ~ '^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');

-- Domain para precios (nunca negativos)
CREATE DOMAIN precio_positivo AS NUMERIC(12, 2)
    NOT NULL
    DEFAULT 0.00
    CHECK (VALUE >= 0);

-- Domain para porcentajes (entre 0 y 100)
CREATE DOMAIN porcentaje AS NUMERIC(5, 2)
    CHECK (VALUE BETWEEN 0 AND 100);

-- Domain para estado de un registro (enum-like)
CREATE DOMAIN estado_registro AS SMALLINT
    NOT NULL
    DEFAULT 1
    CHECK (VALUE IN (0, 1, 2));  -- 0=inactivo, 1=activo, 2=suspendido
```

### Usar un Domain en una Tabla

```sql
-- Ahora el tipo de la columna es el domain, con todas sus reglas incluidas
CREATE TABLE empleados (
    id         SERIAL           PRIMARY KEY,
    email      email_valido     NOT NULL UNIQUE,  -- Valida formato automáticamente
    salario    precio_positivo,                   -- Nunca negativo
    comision   porcentaje,                        -- Entre 0 y 100
    estado     estado_registro                    -- Solo 0, 1 o 2
);

-- Si intentas insertar un email inválido, PostgreSQL lo rechaza:
INSERT INTO empleados (email, salario) VALUES ('no-es-un-email', 5000.00);
-- ERROR: value for domain email_valido violates check constraint
```

### Modificar y Eliminar Domains

```sql
-- Agregar una restricción a un domain existente
ALTER DOMAIN precio_positivo ADD CONSTRAINT precio_max CHECK (VALUE <= 999999.99);

-- Eliminar una restricción del domain
ALTER DOMAIN precio_positivo DROP CONSTRAINT precio_max;

-- Eliminar el domain (solo si no está en uso)
DROP DOMAIN IF EXISTS estado_registro;
```

### Ver los Domains Existentes

```sql
SELECT typname, typtype
FROM pg_type
WHERE typtype = 'd';   -- 'd' = domain
```

---

## 🔗 Tipos de JOINs

Los **JOINs** son la operación más poderosa de SQL: combinan filas de dos o más tablas basándose en una condición.

Para todos los ejemplos, usamos estas dos tablas:

```sql
-- Tabla A: clientes
| id  | nombre  |
| --- | ------- |
| 1   | Ana     |
| 2   | Carlos  |
| 3   | Beatriz |

-- Tabla B: pedidos (algunos clientes no tienen pedidos, hay pedidos sin cliente válido)
| id  | cliente_id | total  |
| --- | ---------- | ------ |
| 1   | 1          | 200.00 |
| 2   | 1          | 350.00 |
| 3   | 2          | 80.00  |
| 4   | 99         | 500.00 | ← cliente_id 99 no existe en clientes |
```

### INNER JOIN — Solo los que coinciden en ambas tablas

El más común. Retorna filas que tienen **coincidencia en ambos lados**.

```
Resultado: filas de A ∩ B
```

```sql
SELECT c.nombre, p.total
FROM clientes c
INNER JOIN pedidos p ON c.id = p.cliente_id;

-- Resultado:
| --  | nombre | total  |
| --- | ------ | ------ |
| --  | Ana    | 200.00 |
| --  | Ana    | 350.00 |
| --  | Carlos | 80.00  |
-- Beatriz no aparece (no tiene pedidos)
-- El pedido 4 no aparece (su cliente_id 99 no existe)
```

### LEFT JOIN — Todos los de la izquierda, aunque no tengan pareja

Retorna **todas las filas de la tabla izquierda** y las coincidencias de la derecha (si no hay, pone `NULL`).

```
Resultado: todo A + lo que coincida de B
```

```sql
SELECT c.nombre, p.total
FROM clientes c
LEFT JOIN pedidos p ON c.id = p.cliente_id;

-- Resultado:
| --  | nombre  | total  |
| --- | ------- | ------ |
| --  | Ana     | 200.00 |
| --  | Ana     | 350.00 |
| --  | Carlos  | 80.00  |
| --  | Beatriz | NULL   | ← Beatriz aparece, pero sin pedidos (NULL) |
```

> **Caso de uso típico:** Listar todos los clientes, incluyendo los que aún no han comprado.

### RIGHT JOIN — Todos los de la derecha, aunque no tengan pareja

Opuesto al `LEFT JOIN`. En la práctica, es raramente usado porque siempre puedes reescribirlo como un `LEFT JOIN` invirtiendo el orden de las tablas.

```sql
SELECT c.nombre, p.total
FROM clientes c
RIGHT JOIN pedidos p ON c.id = p.cliente_id;

-- Resultado:
| --  | nombre | total  |
| --- | ------ | ------ |
| --  | Ana    | 200.00 |
| --  | Ana    | 350.00 |
| --  | Carlos | 80.00  |
| --  | NULL   | 500.00 | ← Pedido huérfano (cliente_id 99 no existe) |
```

### FULL OUTER JOIN — Todo, sin excepción

Combina `LEFT` y `RIGHT` JOIN. Devuelve **todas las filas de ambas tablas**, con `NULL` donde no hay coincidencia.

```sql
SELECT c.nombre, p.total
FROM clientes c
FULL OUTER JOIN pedidos p ON c.id = p.cliente_id;

-- Resultado:
| --  | nombre  | total  |
| --- | ------- | ------ |
| --  | Ana     | 200.00 |
| --  | Ana     | 350.00 |
| --  | Carlos  | 80.00  |
| --  | Beatriz | NULL   | ← Cliente sin pedidos       |
| --  | NULL    | 500.00 | ← Pedido sin cliente válido |
```

> **Caso de uso:** Auditoría para encontrar registros huérfanos en cualquier dirección.

### CROSS JOIN — El producto cartesiano

Combina **cada fila de A con cada fila de B**. Raramente útil en producción, pero tiene casos específicos.

```sql
-- Con 3 clientes y 4 pedidos → resultado: 3 × 4 = 12 filas
SELECT c.nombre, p.total
FROM clientes c
CROSS JOIN pedidos p;
```

> **Caso de uso:** Generar combinaciones de tallas × colores para un catálogo de productos.

### SELF JOIN — Una tabla unida consigo misma

Se usa cuando una tabla tiene una relación jerárquica **consigo misma** (ej. empleados y su jefe directo).

```sql
-- Tabla empleados con columna jefe_id que apunta al mismo id
SELECT
    e.nombre     AS empleado,
    j.nombre     AS jefe
FROM empleados e
LEFT JOIN empleados j ON e.jefe_id = j.id;

-- Resultado:
| --  | empleado | jefe |
| --- | -------- | ---- |
| --  | Carlos   | Ana  |
| --  | Beatriz  | Ana  |
| --  | Ana      | NULL | ← Ana no tiene jefe (es la directora) |
```

### Resumen Visual de los JOINs

```
CLIENTES (A)    PEDIDOS (B)

INNER JOIN:        A ∩ B         (solo los que coinciden)
LEFT JOIN:         A + (A ∩ B)   (todos de A)
RIGHT JOIN:        (A ∩ B) + B   (todos de B)
FULL OUTER JOIN:   A + (A ∩ B) + B (todos de ambos)
CROSS JOIN:        A × B         (todas las combinaciones posibles)
```

```sql
-- Tip: Cuando necesitas múltiples JOINs, siempre alinea las condiciones ON
SELECT
    o.id          AS orden,
    c.nombre      AS cliente,
    p.nombre      AS producto,
    op.cantidad,
    op.cantidad * p.precio AS subtotal
FROM ordenes o
JOIN clientes  c  ON o.cliente_id  = c.id
JOIN orden_producto op ON o.id = op.orden_id
JOIN productos p  ON op.producto_id = p.id
WHERE o.creado_en >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY o.id;
```

---

# 🧰 Temas Avanzados de SQL

---

## ⚡ Funciones SQL Útiles

PostgreSQL incluye cientos de funciones incorporadas. Aquí están las más usadas en el día a día, agrupadas por categoría.

---

### 📊 Funciones de Agregación

Las funciones de agregación **resumen** muchas filas en un solo valor. Se usan casi siempre con `GROUP BY`.

| Función      | Descripción                              | Ejemplo                              |
| :----------- | :--------------------------------------- | :----------------------------------- |
| `COUNT(*)`   | Cuenta todas las filas                   | `SELECT COUNT(*) FROM pedidos;`      |
| `COUNT(col)` | Cuenta filas donde la columna NO es NULL | `SELECT COUNT(email) FROM clientes;` |
| `SUM(col)`   | Suma los valores                         | `SELECT SUM(total) FROM pedidos;`    |
| `AVG(col)`   | Promedio de los valores                  | `SELECT AVG(precio) FROM productos;` |
| `MIN(col)`   | El valor más pequeño                     | `SELECT MIN(precio) FROM productos;` |
| `MAX(col)`   | El valor más grande                      | `SELECT MAX(created_at) FROM logs;`  |

```sql
-- Ejemplo completo con GROUP BY
-- "¿Cuántos pedidos y cuánto facturó cada cliente?"
SELECT
    c.nombre,
    COUNT(p.id)    AS total_pedidos,
    SUM(p.total)   AS facturado,
    AVG(p.total)   AS ticket_promedio,
    MAX(p.total)   AS pedido_mas_grande
FROM clientes c
LEFT JOIN pedidos p ON c.id = p.cliente_id
GROUP BY c.id, c.nombre
ORDER BY facturado DESC NULLS LAST;
```

> 💡 **HAVING vs WHERE:** `WHERE` filtra **antes** de agrupar, `HAVING` filtra **después** de agrupar.

```sql
-- Solo clientes que han gastado más de $1000 en total
SELECT c.nombre, SUM(p.total) AS total_gastado
FROM clientes c
JOIN pedidos p ON c.id = p.cliente_id
GROUP BY c.nombre
HAVING SUM(p.total) > 1000;
```

---

### 🔤 Funciones de Texto (String)

| Función                  | Descripción                                             | Ejemplo                                 | Resultado                    |
| :----------------------- | :------------------------------------------------------ | :-------------------------------------- | :--------------------------- |
| `UPPER(s)`               | Convierte a mayúsculas                                  | `UPPER('hola')`                         | `'HOLA'`                     |
| `LOWER(s)`               | Convierte a minúsculas                                  | `LOWER('HOLA')`                         | `'hola'`                     |
| `INITCAP`                | Convierte la primera letra de cada palabra en mayúscula | `INITCAP('ana garzon')`                 | `'Ana Garzon'`               |
| `LENGTH(s)`              | Número de caracteres                                    | `LENGTH('hola')`                        | `4`                          |
| `TRIM(s)`                | Elimina espacios al inicio y final                      | `TRIM('  hola  ')`                      | `'hola'`                     |
| `LTRIM(s)` / `RTRIM(s)`  | Elimina espacios solo a la izquierda/derecha            | `LTRIM('  hola')`                       | `'hola'`                     |
| `SUBSTRING(s, ini, len)` | Extrae una parte del texto                              | `SUBSTRING('hola mundo', 1, 4)`         | `'hola'`                     |
| `POSITION(sub IN s)`     | Posición de una subcadena                               | `POSITION('mundo' IN 'hola mundo')`     | `6`                          |
| `REPLACE(s, old, new)`   | Reemplaza texto                                         | `REPLACE('hola mundo', 'mundo', 'SQL')` | `'hola SQL'`                 |
| `CONCAT(s1, s2, ...)`    | Une cadenas                                             | `CONCAT('hola', ' ', 'mundo')`          | `'hola mundo'`               |
| `\|\|`                   | Operador de concatenación                               | `'hola' \|\| ' mundo'`                  | `'hola mundo'`               |
| `SPLIT_PART(s, sep, n)`  | Divide por separador y toma la n-ésima parte            | `SPLIT_PART('a,b,c', ',', 2)`           | `'b'`                        |
| `LIKE`                   | Búsqueda por patrón (`%` = cualquier cosa)              | `WHERE nombre LIKE 'Ana%'`              | Nombres que empiezan con Ana |
| `ILIKE`                  | Igual que LIKE pero sin distinción mayúsculas           | `WHERE email ILIKE '%@GMAIL%'`          | Insensible a mayúsculas      |


```sql
-- Ejemplo práctico: normalizar un nombre al guardarlo
INSERT INTO clientes (nombre, email)
VALUES (
    TRIM(INITCAP('  ana GARZon  ')),    -- 'Ana Garzon'
    LOWER(TRIM('  ANA@GMAIL.COM  '))    -- 'ana@gmail.com'
);
```

---

### 📅 Funciones de Fecha y Tiempo

```sql
-- Fecha y hora actual
SELECT NOW();                           -- 2025-10-21 14:30:00.123456-04

-- Solo fecha / solo hora
SELECT CURRENT_DATE;                    -- 2025-10-21
SELECT CURRENT_TIME;                    -- 14:30:00.123456-04

-- Aritmética con fechas
SELECT NOW() + INTERVAL '30 days';     -- 30 días en el futuro
SELECT NOW() - INTERVAL '1 year';      -- Hace un año
SELECT '2025-12-31'::DATE - CURRENT_DATE AS dias_para_fin_de_anio;

-- Extraer partes de una fecha
SELECT EXTRACT(YEAR  FROM NOW());       -- 2025
SELECT EXTRACT(MONTH FROM NOW());       -- 10
SELECT EXTRACT(DOW   FROM NOW());       -- 2  (0=Dom, 1=Lun, ... 6=Sáb)

-- Truncar a una unidad (devuelve el inicio del período)
SELECT DATE_TRUNC('month', NOW());      -- 2025-10-01 00:00:00
SELECT DATE_TRUNC('year',  NOW());      -- 2025-01-01 00:00:00
SELECT DATE_TRUNC('week',  NOW());      -- Lunes de la semana actual

-- Diferencia entre dos fechas
SELECT AGE('2025-12-31', '1990-06-15');  -- 35 years 6 months 16 days

-- Convertir zona horaria
SELECT NOW() AT TIME ZONE 'America/New_York';
SELECT NOW() AT TIME ZONE 'UTC';

-- Formatear una fecha como texto
SELECT TO_CHAR(NOW(), 'DD/MM/YYYY HH24:MI');     -- '21/10/2025 14:30'
SELECT TO_CHAR(NOW(), 'Day, DD "de" Month YYYY'); -- 'Tuesday, 21 de October  2025'
```

---

### 🤔 Funciones Condicionales

#### CASE WHEN — El "if/else" de SQL

```sql
-- Forma 1: CASE buscado (condiciones independientes)
SELECT
    nombre,
    precio,
    CASE
        WHEN precio < 10    THEN 'Económico'
        WHEN precio < 50    THEN 'Moderado'
        WHEN precio < 200   THEN 'Premium'
        ELSE                     'Lujo'
    END AS categoria_precio
FROM productos;

-- Forma 2: CASE simple (comparar una sola columna)
SELECT
    nombre,
    estado,
    CASE estado
        WHEN 1 THEN 'Activo'
        WHEN 0 THEN 'Inactivo'
        WHEN 2 THEN 'Suspendido'
        ELSE 'Desconocido'
    END AS estado_texto
FROM empleados;
```

#### COALESCE — El primer valor no-NULL

```sql
-- Devuelve el primer valor que NO sea NULL
SELECT COALESCE(telefono, celular, 'Sin contacto') AS contacto
FROM clientes;
-- Si telefono es NULL y celular tiene valor → devuelve celular
-- Si ambos son NULL → devuelve 'Sin contacto'
```

#### NULLIF — Convierte un valor en NULL

```sql
-- Devuelve NULL si los dos argumentos son iguales
-- Evita divisiones por cero:
SELECT total / NULLIF(cantidad, 0) AS precio_unitario
FROM pedidos;
-- Si cantidad = 0 → NULLIF devuelve NULL → división devuelve NULL (no error)
```

#### GREATEST / LEAST

```sql
-- Devuelve el mayor/menor entre una lista de valores
SELECT GREATEST(precio, precio_especial, precio_minimo) AS precio_final;
SELECT LEAST(10, 5, 8, 3, 12);   -- Resultado: 3
```

---

### 🪟 Funciones de Ventana (Window Functions)

Las funciones de ventana calculan un resultado sobre un **conjunto de filas relacionadas** sin colapsar el resultado (a diferencia de `GROUP BY`).

```sql
-- ROW_NUMBER: asigna un número de fila dentro de cada grupo
SELECT
    nombre,
    departamento,
    salario,
    ROW_NUMBER() OVER (PARTITION BY departamento ORDER BY salario DESC) AS ranking
FROM empleados;
-- Cada empleado tiene su puesto de ranking dentro de su departamento

-- RANK: como ROW_NUMBER pero empata y salta números
-- DENSE_RANK: empata pero NO salta números

-- LAG / LEAD: acceder a la fila anterior o siguiente
SELECT
    mes,
    ventas,
    LAG(ventas, 1) OVER (ORDER BY mes)  AS ventas_mes_anterior,
    ventas - LAG(ventas, 1) OVER (ORDER BY mes)  AS diferencia
FROM ventas_mensuales;

-- SUM acumulado (running total)
SELECT
    fecha,
    monto,
    SUM(monto) OVER (ORDER BY fecha) AS total_acumulado
FROM transacciones;
```

---

## 🖨️ FORMAT() — Formateo de Texto en SQL

`FORMAT()` es la función de PostgreSQL para construir cadenas de texto con **placeholders**, similar al `printf` de C o f-strings de Python. Muy útil para construir mensajes dinámicos o SQL dinámico con `EXECUTE`.

### Sintaxis

```sql
FORMAT(cadena_formato, argumento1, argumento2, ...)
```

### Especificadores de Formato

| Especificador | Descripción                                              | Ejemplo                                                                  |
| :------------ | :------------------------------------------------------- | :----------------------------------------------------------------------- |
| `%s`          | Texto (string) simple                                    | `FORMAT('Hola %s', 'mundo')` → `'Hola mundo'`                            |
| `%I`          | **Identificador** con comillas (nombre de tabla/columna) | `FORMAT('SELECT * FROM %I', 'mi tabla')` → `SELECT * FROM "mi tabla"`    |
| `%L`          | **Literal** con comillas (valor de dato)                 | `FORMAT('WHERE nombre = %L', "O'Reilly")` → `WHERE nombre = 'O''Reilly'` |
| `%%`          | El carácter literal `%`                                  | `FORMAT('100%%')` → `'100%'`                                             |

> 🔐 **¿Por qué `%I` y `%L` son importantes?**  
> Protegen contra **SQL Injection** al escapar automáticamente los valores. Siempre úsalos al construir SQL dinámico.

### Ejemplos Prácticos

```sql
-- Mensaje simple
SELECT FORMAT('Bienvenido, %s. Tienes %s pedidos pendientes.', nombre, pendientes)
FROM clientes;

-- Construir SQL dinámico de forma segura en una función
DO $$
DECLARE
    tabla_nombre TEXT := 'ventas 2025';  -- Tiene un espacio → necesita comillas
    columna TEXT := 'total';
    valor_buscar TEXT := "O'Brien";       -- Tiene comilla simple → necesita escape
    sql_query TEXT;
BEGIN
    -- %I maneja el espacio en el nombre de tabla
    -- %L maneja la comilla simple en el valor
    sql_query := FORMAT(
        'SELECT %I FROM %I WHERE vendedor = %L',
        columna,
        tabla_nombre,
        valor_buscar
    );
    -- Resultado: SELECT "total" FROM "ventas 2025" WHERE vendedor = 'O''Brien'
    RAISE NOTICE '%', sql_query;
END;
$$;
```

```sql
-- Uso en generación de mensajes de log
INSERT INTO audit_log (mensaje, creado_en)
VALUES (
    FORMAT(
        'Usuario %L eliminó el registro #%s de la tabla %I a las %s',
        current_user,
        42,
        'pedidos',
        TO_CHAR(NOW(), 'HH24:MI:SS')
    ),
    NOW()
);
```

---

## 🔬 Plan de Ejecución (EXPLAIN / EXPLAIN ANALYZE)

Cuando ejecutas una consulta, PostgreSQL genera un **plan de ejecución**: una serie de pasos que decide seguir para obtener el resultado de la manera más eficiente posible.

`EXPLAIN` te permite ver ese plan **sin ejecutar** la consulta.  
`EXPLAIN ANALYZE` lo muestra **ejecutándola de verdad** y midiendo los tiempos reales.

> **Analogía:** Es como el GPS de tu consulta. Te dice qué camino va a tomar, por qué eligió ese camino, y si usas `ANALYZE`, también te dice cuánto tardó cada tramo.

### Uso Básico

```sql
-- Ver el plan estimado (sin ejecutar la consulta)
EXPLAIN
SELECT * FROM pedidos WHERE cliente_id = 5;

-- Ver el plan REAL con tiempos reales (SÍ ejecuta la consulta)
EXPLAIN ANALYZE
SELECT * FROM pedidos WHERE cliente_id = 5;

-- Formato más legible y detallado (recomendado)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT p.id, c.nombre, p.total
FROM pedidos p
JOIN clientes c ON p.cliente_id = c.id
WHERE p.total > 1000;
```

### Cómo Leer la Salida

La salida es un árbol que se lee **de adentro hacia afuera** (el nodo más indentado se ejecuta primero):

```
Nested Loop  (cost=0.43..16.48 rows=1 width=36) (actual time=0.021..0.023 rows=1 loops=1)
  ->  Index Scan using pedidos_pkey on pedidos p
        (cost=0.29..8.31 rows=1 width=20) (actual time=0.012..0.013 rows=1 loops=1)
        Index Cond: (id = 42)
  ->  Index Scan using clientes_pkey on clientes c
        (cost=0.14..8.16 rows=1 width=20) (actual time=0.007..0.008 rows=1 loops=1)
        Index Cond: (id = p.cliente_id)
Planning Time: 0.3 ms
Execution Time: 0.05 ms
```

#### Glosario de la Salida

| Término                | Significado                                                                                                                                            |
| :--------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cost=inicio..total`   | Costo estimado por el planificador. `inicio` = costo hasta devolver la primera fila. `total` = costo total. No son segundos, son unidades arbitrarias. |
| `rows=N`               | Filas estimadas que devolverá este nodo.                                                                                                               |
| `actual time=ini..fin` | Tiempo real en milisegundos (solo con `ANALYZE`).                                                                                                      |
| `loops=N`              | Cuántas veces se ejecutó este nodo.                                                                                                                    |
| `width=N`              | Tamaño estimado en bytes de cada fila.                                                                                                                 |

#### Tipos de Nodos Comunes

| Nodo               | Qué hace                                                   | Señal                                                           |
| :----------------- | :--------------------------------------------------------- | :-------------------------------------------------------------- |
| `Seq Scan`         | Lee toda la tabla de principio a fin.                      | ⚠️ Lento en tablas grandes si hay un filtro. Considerar índice.  |
| `Index Scan`       | Usa un índice para acceder a filas específicas.            | ✅ Eficiente para pocos resultados.                              |
| `Index Only Scan`  | Lee todo desde el índice, sin tocar la tabla.              | ✅✅ Muy eficiente.                                               |
| `Bitmap Heap Scan` | Usa el índice para crear un mapa de filas y luego las lee. | ✅ Para rangos o múltiples condiciones.                          |
| `Hash Join`        | Une dos tablas usando una tabla hash en memoria.           | ✅ Bueno para tablas grandes sin índice en la columna de join.   |
| `Nested Loop`      | Une tablas iterando fila por fila.                         | ✅ Excelente cuando la tabla interior es pequeña o tiene índice. |
| `Merge Join`       | Une tablas ordenadas.                                      | ✅ Eficiente cuando ambos lados están ordenados.                 |
| `Sort`             | Ordena las filas.                                          | ⚠️ Caro. Si aparece y hay `ORDER BY`, considera un índice.       |

### Casos Comunes y Cómo Interpretarlos

```sql
-- CASO 1: Seq Scan en tabla grande → Candidato para índice
EXPLAIN SELECT * FROM logs WHERE nivel = 'ERROR';
-- Si muestra: Seq Scan on logs  (rows=1000000)
-- → Crear índice: CREATE INDEX idx_logs_nivel ON logs(nivel);

-- CASO 2: Verificar que se usa un índice existente
EXPLAIN SELECT * FROM pedidos WHERE id = 42;
-- Debe mostrar: Index Scan using pedidos_pkey on pedidos
-- Si no lo muestra, el planificador decidió que no valía la pena (tabla muy pequeña)

-- CASO 3: Ver uso de buffers (hits en caché vs lecturas en disco)
EXPLAIN (ANALYZE, BUFFERS)
SELECT SUM(total) FROM pedidos WHERE creado_en > NOW() - INTERVAL '7 days';
-- Buffers: shared hit=N   → N páginas leídas desde caché (rápido)
-- Buffers: shared read=N  → N páginas leídas desde disco (lento)
```

> 💡 **Tip:** Puedes usar la extensión `pg_stat_statements` para encontrar las consultas más lentas de todo el sistema sin tener que hacer `EXPLAIN` una por una.

---

## 🔤 Quoting en PostgreSQL

El **quoting** (uso de comillas) es una fuente frecuente de confusión. PostgreSQL usa diferentes tipos de comillas con significados completamente distintos.

### 1. Comillas Simples `'texto'` — Para Valores de Datos (Literales)

Se usan para encerrar **valores de texto, fechas**, etc. que son datos.

```sql
-- ✅ Correcto: texto es un valor, va entre comillas simples
SELECT * FROM clientes WHERE nombre = 'Ana García';
INSERT INTO logs (nivel) VALUES ('ERROR');
SELECT '2025-10-21'::DATE;
```

**Escapar una comilla simple dentro del texto:** duplicarla (`''`)

```sql
-- El apellido O'Brien tiene comilla simple
SELECT * FROM clientes WHERE apellido = 'O''Brien';
--                                          ↑↑ dos comillas simples = una literal

-- También puedes usar dollar quoting (ver más abajo)
SELECT * FROM clientes WHERE apellido = $$ O'Brien $$;
```

### 2. Comillas Dobles `"nombre"` — Para Identificadores

Se usan para encerrar **nombres de objetos** (tablas, columnas, esquemas) cuando:
- El nombre tiene espacios o caracteres especiales.
- El nombre es una palabra reservada de SQL.
- Quieres preservar mayúsculas/minúsculas exactas.

```sql
-- ✅ Necesarias cuando hay espacios en el nombre
CREATE TABLE "mi tabla con espacios" (id SERIAL);
SELECT * FROM "mi tabla con espacios";

-- ✅ Necesarias para nombres con mayúsculas exactas
CREATE TABLE "ClientesPremium" (id SERIAL);  -- SIN comillas, PostgreSQL lo guarda en minúsculas
SELECT * FROM "ClientesPremium";             -- Con comillas, busca el nombre exacto

-- ⚠️ Sin comillas dobles, PostgreSQL convierte TODO a minúsculas
CREATE TABLE MiTabla (id SERIAL);    -- Se guarda como 'mitable'
SELECT * FROM mitable;               -- ✅ Funciona
SELECT * FROM MiTabla;               -- ✅ También funciona (convierte a minúsculas)
SELECT * FROM "MiTabla";             -- ❌ ERROR: "MiTabla" no existe
```

> 💡 **Mejor práctica:** Usa siempre nombres en **minúsculas con guiones bajos** (`mi_tabla`, `nombre_cliente`) para evitar lidiar con comillas dobles.

### 3. Dollar Quoting `$$texto$$` — Para Cuerpos de Funciones

Se usa principalmente para escribir el cuerpo de **funciones, procedimientos y bloques `DO`**. Evita el infierno de escapar comillas simples dentro del código.

```sql
-- SIN dollar quoting: hay que escapar cada comilla simple
CREATE FUNCTION saludo() RETURNS TEXT AS
'SELECT ''Hola, '' || nombre || ''!'';'
LANGUAGE SQL;
-- Muy difícil de leer ↑

-- CON dollar quoting: mucho más legible
CREATE FUNCTION saludo(p_nombre TEXT) RETURNS TEXT AS $$
    SELECT 'Hola, ' || p_nombre || '!';
$$
LANGUAGE SQL;
```

**Dollar quoting con etiqueta** (para bloques anidados):

```sql
-- Cuando el cuerpo interno también usa $$, usas una etiqueta diferente
CREATE FUNCTION ejemplo() RETURNS VOID AS $outer$
DECLARE
    sql TEXT := $inner$SELECT 'hola'$inner$;  -- Block interno usa $inner$
BEGIN
    EXECUTE sql;
END;
$outer$
LANGUAGE plpgsql;
```

### Tabla Resumen de Quoting

| Tipo                    | Sintaxis        | Uso                                                                       | Ejemplo                  |
| :---------------------- | :-------------- | :------------------------------------------------------------------------ | :----------------------- |
| Comilla simple          | `'valor'`       | Valores de datos (strings, fechas, números)                               | `WHERE nombre = 'Ana'`   |
| Comilla simple escapada | `'O''Brien'`    | Comilla simple dentro de un valor                                         | `'it''s a test'`         |
| Comilla doble           | `"nombre"`      | Identificadores (tablas, columnas) con caracteres especiales o mayúsculas | `"Mi Tabla"`, `"userId"` |
| Dollar quoting          | `$$...$$`       | Cuerpo de funciones / PL/pgSQL                                            | `AS $$ SELECT 1 $$`      |
| Dollar con etiqueta     | `$tag$...$tag$` | Bloques anidados                                                          | `$body$ ... $body$`      |

---

## 📇 Índices (Indexes)

Un **índice** es una estructura de datos separada que PostgreSQL mantiene actualizada para acelerar la búsqueda de filas. Es exactamente como el índice al final de un libro — en lugar de leer todo el libro para encontrar "variable", vas al índice y saltas directo a la página.

> **¿Cuándo PostgreSQL usa un índice?**  
> Automáticamente decide si usar el índice o hacer un Seq Scan (leer toda la tabla). Si la tabla es pequeña, el Seq Scan puede ser más rápido. El índice brilla cuando la consulta filtra una fracción pequeña de las filas.

### Crear y Eliminar Índices

```sql
-- Índice básico en una columna
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);

-- Índice único (como UNIQUE constraint pero explícito)
CREATE UNIQUE INDEX idx_usuarios_email ON usuarios(email);

-- Índice en múltiples columnas (compuesto)
-- Útil cuando siempre filtras por la combinación de ambas columnas
CREATE INDEX idx_pedidos_cliente_fecha ON pedidos(cliente_id, creado_en);

-- Índice parcial (solo sobre un subconjunto de filas)
-- Ahorra espacio cuando solo consultas ciertos registros
CREATE INDEX idx_pedidos_activos ON pedidos(creado_en)
WHERE estado = 'pendiente';

-- Crear índice sin bloquear la tabla (recomendado en producción)
CREATE INDEX CONCURRENTLY idx_pedidos_total ON pedidos(total);

-- Eliminar índice
DROP INDEX IF EXISTS idx_pedidos_cliente;

-- Ver índices de una tabla
\d pedidos         -- En psql
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'pedidos';
```

---

### 🌲 BTREE — El Índice por Defecto

**B-Tree** (Árbol B balanceado) es el tipo de índice usado por defecto en PostgreSQL cuando no especificas otro.

**Soporta:**
- Comparaciones exactas: `=`, `<>`, `!=`
- Rangos: `<`, `>`, `<=`, `>=`, `BETWEEN`
- Ordenamiento: `ORDER BY`, `MIN()`, `MAX()`
- `IS NULL` / `IS NOT NULL`

```sql
-- Estos índices son BTREE por defecto
CREATE INDEX idx_precio ON productos(precio);
CREATE INDEX idx_nombre ON clientes(nombre);

-- Útil para:
SELECT * FROM productos WHERE precio BETWEEN 10 AND 50;    -- Rango ✅
SELECT * FROM clientes WHERE nombre = 'Ana';               -- Igualdad ✅
SELECT * FROM pedidos ORDER BY creado_en DESC LIMIT 10;    -- Ordenamiento ✅

-- Especificarlo explícitamente (equivalente al anterior)
CREATE INDEX idx_precio ON productos USING BTREE (precio);
```

---

### #️⃣ HASH — Solo para Igualdad Exacta

El índice **HASH** almacena una función hash de los valores. Es más rápido que BTREE para búsquedas de **igualdad exacta**, pero **no soporta rangos ni ordenamiento**.

```sql
CREATE INDEX idx_hash_email ON usuarios USING HASH (email);

-- Eficiente SOLO para:
SELECT * FROM usuarios WHERE email = 'ana@gmail.com';     -- ✅ Igualdad exacta

-- NO funciona (no soporta rangos):
SELECT * FROM productos WHERE precio > 50;                 -- ❌ No usa HASH
SELECT * FROM clientes ORDER BY nombre;                    -- ❌ No usa HASH
```

> ⚠️ En la práctica, BTREE es casi siempre mejor que HASH porque soporta más operaciones con velocidad similar. Usa HASH solo si tienes un caso de uso muy específico de igualdad con valores muy largos.

---

### 🔍 GIN — Para Contenido Compuesto (Arrays, JSONB, Full Text)

**GIN** (Generalized Inverted Index) — Índice invertido generalizado. Ideal para columnas que contienen **múltiples valores** en una sola celda.

**Ideal para:**
- `JSONB` — buscar dentro de documentos JSON
- `ARRAY` — buscar elementos dentro de arrays
- `tsvector` / `tsquery` — búsqueda de texto completo (Full Text Search)
- `hstore` — tipo clave-valor

```sql
-- Índice GIN para una columna JSONB
CREATE INDEX idx_gin_config ON productos USING GIN (config);

-- Permite búsquedas eficientes dentro del JSON:
SELECT * FROM productos WHERE config @> '{"color": "rojo"}';
SELECT * FROM productos WHERE config ? 'talla';        -- ¿Tiene la clave 'talla'?

-- Índice GIN para arrays
CREATE INDEX idx_gin_etiquetas ON articulos USING GIN (etiquetas);

SELECT * FROM articulos WHERE etiquetas @> ARRAY['sql', 'postgres'];

-- Índice GIN para búsqueda de texto completo
ALTER TABLE articulos ADD COLUMN busqueda_ts tsvector;
CREATE INDEX idx_gin_fts ON articulos USING GIN (busqueda_ts);

SELECT * FROM articulos
WHERE busqueda_ts @@ to_tsquery('spanish', 'postgres & indice');
```

---

### 🗺️ GIST — Para Datos Geométricos y Rangos

**GIST** (Generalized Search Tree) — Árbol de búsqueda generalizado. Soporta tipos de datos complejos como geometrías, rangos y texto aproximado.

**Ideal para:**
- Tipos geométricos (`POINT`, `POLYGON`, `LINE`) — con extensión PostGIS
- Tipos de rango (`DATERANGE`, `NUMRANGE`, `TSTZRANGE`)
- Búsqueda de texto aproximado (`pg_trgm`)

```sql
-- Índice GIST para rangos de fechas
CREATE INDEX idx_gist_periodo ON reservas USING GIST (periodo);
-- donde "periodo" es de tipo DATERANGE

-- Buscar reservas que se solapan con el período requerido
SELECT * FROM reservas
WHERE periodo && '[2025-12-20, 2025-12-27)'::DATERANGE;  -- && = se solapan

-- Índice GIST para búsqueda aproximada de texto (con extensión pg_trgm)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_gist_nombre ON clientes USING GIST (nombre gist_trgm_ops);

-- Búsqueda aproximada (similaridad)
SELECT nombre FROM clientes WHERE nombre % 'Gonzalez';
SELECT nombre FROM clientes WHERE nombre ILIKE '%gonzal%';  -- Aprovecha el índice
```

---

### 📏 BRIN — Para Tablas Enormes con Datos Ordenados

**BRIN** (Block Range INdex) — Índice de rango de bloques. Es el índice más pequeño en tamaño. Funciona guardando el **rango de valores mínimo y máximo** de cada bloque físico del disco.

**Solo funciona bien cuando existe correlación física-lógica:** los datos en disco están naturalmente ordenados por la columna indexada (ej: columnas de fecha donde siempre se insertan datos recientes al final).

```sql
-- Índice BRIN para una columna de fecha de creación
-- (Los registros más nuevos siempre se insertan al final → correlación natural)
CREATE INDEX idx_brin_creado ON logs USING BRIN (creado_en);

-- También útil en tablas de series de tiempo, IoT, eventos de auditoría
CREATE INDEX idx_brin_timestamp ON sensor_data USING BRIN (recorded_at);

-- Muy eficiente en espacio y para rangos temporales:
SELECT * FROM logs WHERE creado_en BETWEEN '2025-01-01' AND '2025-03-31';
```

> **Ventaja:** Un BRIN puede ser 1000x más pequeño que un BTREE equivalente.  
> **Desventaja:** Solo es útil si los datos están físicamente ordenados por esa columna.

---

### 📊 Resumen Comparativo de Tipos de Índices

| Tipo      | Operaciones Soportadas               | Caso de Uso Ideal                                  |
| :-------- | :----------------------------------- | :------------------------------------------------- |
| **BTREE** | `=`, `<`, `>`, `BETWEEN`, `ORDER BY` | **Uso general. El 90% de los casos.**              |
| **HASH**  | Solo `=`                             | Búsquedas de igualdad exacta en claves muy largas  |
| **GIN**   | `@>`, `?`, `@@`, `&&`                | JSONB, Arrays, Full Text Search                    |
| **GIST**  | Solapamiento, contención, distancia  | Geometrías, Rangos, texto aproximado               |
| **BRIN**  | Rangos en datos correlacionados      | Tablas de logs/eventos enormes (millones de filas) |

### Consejos sobre Índices

```sql
-- ✅ Ver qué índices están siendo usados y cuántas veces
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan    AS veces_usado,
    idx_tup_read AS filas_leidas
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- ⚠️ Encontrar índices que NUNCA se usan (candidatos para eliminar)
SELECT schemaname, tablename, indexname
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND schemaname NOT IN ('pg_catalog')
ORDER BY tablename;
```

> 🏁 **Reglas de Oro para Índices:**
> 1. **No indexes everywhere** — Cada índice ralentiza los `INSERT`, `UPDATE` y `DELETE`.
> 2. **Indexa las columnas de JOIN y WHERE más frecuentes.**
> 3. **Usa `EXPLAIN ANALYZE` para confirmar que el índice se está usando.**
> 4. **Usa `CREATE INDEX CONCURRENTLY` en producción** para no bloquear la tabla.
> 5. **Índices compuestos:** el orden importa. `(a, b)` ayuda en `WHERE a=1`, `WHERE a=1 AND b=2`, pero NO en `WHERE b=2` solo.
