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



