# Guía: Actualización de PostgreSQL y Gestión de Clusters Paralelos

> **Aplica a:** Cualquier actualización de versión PostgreSQL en sistemas Debian/Ubuntu  
> **Ejemplo documentado:** Actualización local de PG16 → PG18 (2026-06-11)  
> **Contexto del ejemplo:** El backup generado en el servidor (PG18) no podía restaurarse localmente porque el `pg_restore` local era versión 16. Se actualizó la instalación local a PG18 manteniendo PG16 activo en paralelo (mirror de producción).

---

## 🔍 Diagnóstico: incompatibilidad de versiones en backups

Al intentar restaurar un backup generado en una versión más nueva de PostgreSQL, el error es:

```
pg_restore: error: versión no soportada (X.XX) en el encabezado del archivo
```

**Regla:** Las herramientas cliente de PostgreSQL **no son retrocompatibles hacia atrás**. Un `pg_restore` de versión N no puede leer backups generados con `pg_dump` de versión N+1 o superior.

**Solución:** Instalar las herramientas cliente (`postgresql-client-<nueva_version>`) de la misma versión o superior al servidor que generó el backup.

### Identificar la versión del backup

```bash
# Ver metadatos del archivo de backup
pg_restore --list tu_backup.backup | head -5

# O con strings (más directo)
strings tu_backup.backup | head -3
# "PGDMP" seguido de bytes que indican la versión del formato
```

### Verificar versión de las herramientas locales

```bash
psql --version
pg_restore --version
pg_dump --version
```

---

## 📦 Verificar disponibilidad de la nueva versión

```bash
apt-cache policy postgresql-<nueva_version>
```

**Qué hace:** Consulta los repositorios APT y muestra las versiones disponibles, la instalada y la candidata.

**Ejemplo (PG18):**
```bash
apt-cache policy postgresql-18
# Candidato: 18.4-1.pgdg24.04+1
```

**Prerequisito:** Tener el repositorio oficial PGDG configurado. Verificar con:

```bash
cat /etc/apt/sources.list.d/*.list | grep postgresql
# Debe aparecer: https://apt.postgresql.org/pub/repos/apt <distro>-pgdg main
```

Si no está configurado, agregarlo:
```bash
# Agregar repositorio PGDG oficial
sudo apt install -y curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt update
```

---

## 🚀 Instalación de la nueva versión

```bash
sudo apt install -y postgresql-<nueva_version> postgresql-client-<nueva_version>
```

| Paquete                   | Descripción                                                     |
| ------------------------- | --------------------------------------------------------------- |
| `postgresql-<ver>`        | El servidor de base de datos                                    |
| `postgresql-client-<ver>` | Herramientas cliente: `psql`, `pg_dump`, `pg_restore`           |
| `postgresql-<ver>-jit`    | Compilación JIT para queries complejas (dependencia automática) |

**Ejemplo (PG18):**
```bash
sudo apt install -y postgresql-18 postgresql-client-18
```

> **Nota:** En sistemas con otro cluster PostgreSQL ya activo, el instalador **no crea el cluster automáticamente** para evitar conflicto de puertos. Hay que crearlo manualmente.

---

## 🗂️ Gestión de Clusters

### Ver todos los clusters instalados

```bash
pg_lsclusters
```

**Qué muestra:**
```
Ver  Cluster  Port   Status   Owner    Data directory
16   main     5432   online   postgres /var/lib/postgresql/16/main
18   main     5433   down     postgres /var/lib/postgresql/18/main
```

- **Ver:** Versión de PostgreSQL del cluster
- **Cluster:** Nombre lógico (puede haber múltiples por versión, ej: `main`, `replica`)
- **Port:** Puerto TCP en que escucha
- **Status:** `online` = activo, `down` = detenido
- **Data directory:** Directorio físico de los datos

---

### Crear un cluster manualmente

```bash
sudo pg_createcluster <version> <nombre>
```

**Qué hace:** Inicializa el directorio de datos, crea los archivos de configuración (`postgresql.conf`, `pg_hba.conf`) y registra el cluster. **No lo inicia.**

**Ejemplo:**
```bash
sudo pg_createcluster 18 main
```

---

### Iniciar / Detener un cluster específico

```bash
sudo pg_ctlcluster <version> <nombre> start
sudo pg_ctlcluster <version> <nombre> stop
sudo pg_ctlcluster <version> <nombre> restart
sudo pg_ctlcluster <version> <nombre> status
```

**Ejemplos:**
```bash
sudo pg_ctlcluster 18 main start
sudo pg_ctlcluster 16 main stop
```

---

## 🔄 Configurar dos clusters en paralelo (versión antigua + nueva)

### Caso de uso típico
- **Nueva versión** en puerto `5432` → entorno dev / nuevo default
- **Versión anterior** en puerto `5433` → mirror de producción / compatibilidad

### Procedimiento A: Intercambio de puertos (cuando los clusters ya existen invertidos)

Útil cuando el cluster nuevo fue creado automáticamente en el puerto secundario y el antiguo sigue en 5432.

```bash
# 1. Detener ambos clusters
sudo pg_ctlcluster <ver_antigua> main stop
sudo pg_ctlcluster <ver_nueva> main stop

# 2. Cambiar versión antigua → puerto 5433
sudo sed -i 's/port = 5432/port = 5433/' /etc/postgresql/<ver_antigua>/main/postgresql.conf

# 3. Cambiar versión nueva → puerto 5432
sudo sed -i 's/port = 5433/port = 5432/' /etc/postgresql/<ver_nueva>/main/postgresql.conf

# 4. Levantar ambos
sudo pg_ctlcluster <ver_nueva> main start
sudo pg_ctlcluster <ver_antigua> main start

# 5. Verificar
pg_lsclusters
```

**Ejemplo (PG16 → PG18):**
```bash
sudo pg_ctlcluster 16 main stop
sudo pg_ctlcluster 18 main stop
sudo sed -i 's/port = 5432/port = 5433/' /etc/postgresql/16/main/postgresql.conf
sudo sed -i 's/port = 5433/port = 5432/' /etc/postgresql/18/main/postgresql.conf
sudo pg_ctlcluster 18 main start
sudo pg_ctlcluster 16 main start
pg_lsclusters
```

**Resultado esperado:**
```
Ver  Cluster  Port   Status
16   main     5433   online   ← mirror producción
18   main     5432   online   ← dev (default)
```

---

### Procedimiento B: Migración completa con `pg_upgradecluster`

Migra todos los datos del cluster antiguo al nuevo y hace el swap de puertos automáticamente.

```bash
sudo pg_upgradecluster <ver_antigua> main
```

> **Requisito:** El cluster de la versión nueva **no debe existir aún** (`pg_lsclusters` no debe mostrar la versión nueva). Si ya existe, usar el Procedimiento A.

**Resultado:** Versión nueva en 5432 (con datos migrados), versión antigua en 5433 (detenida, datos intactos).

---

## 🔐 Configurar usuarios y autenticación en el nuevo cluster

Un cluster recién creado solo tiene el superusuario `postgres` (sin contraseña, acceso por `peer`). Los usuarios del cluster antiguo **no se copian automáticamente** al cluster nuevo en el Procedimiento A.

### Acceder al nuevo cluster por primera vez

```bash
# Entrar como superusuario del sistema operativo (peer auth)
sudo -u postgres psql -p 5432
```

### Crear usuario de trabajo en el nuevo cluster

```sql
-- Dentro de psql
CREATE USER <tu_usuario> WITH SUPERUSER PASSWORD '<tu_password>';

-- Ejemplo
CREATE USER kzambrano WITH SUPERUSER PASSWORD 'soylaclave';
```

---

## 🔌 Conectarse a cada cluster

```bash
# Cluster nuevo (nueva versión, puerto 5432 - default)
psql -U <usuario> -h localhost

# Cluster nuevo explícito
psql -U <usuario> -h localhost -p 5432

# Cluster antiguo (mirror producción)
psql -U <usuario> -h localhost -p 5433
```

En scripts bash, especificar el puerto:
```bash
# Flag -p
pg_restore -U $USER -p 5432 -d mi_base mi_backup.backup

# Variable de entorno
PGPORT=5432 pg_restore -U $USER -d mi_base mi_backup.backup
```

---

## EXTRA: 🐛 Fix del script de restauración: bug con `$?` en pipes

### El problema

```bash
# ❌ INCORRECTO: $? captura el exit code de grep, no de pg_restore
pg_restore -U $USER -d $DB_NAME "$BACKUP_FILE" 2>&1 | grep "ERROR"
if [ $? -ne 0 ]; then
    # Esto se ejecuta si grep NO encontró "ERROR" (exit code 1)
    # = falso positivo cuando la restauración es exitosa
    echo "Error al restaurar..."
fi
```

### La solución

```bash
# ✅ CORRECTO: PIPESTATUS[0] captura el exit code de pg_restore
pg_restore -U $USER -d $DB_NAME --no-owner --no-privileges "$BACKUP_FILE" 2>&1 | grep "ERROR"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "Error al restaurar..."
fi
```

**`PIPESTATUS`:** Array de bash con los exit codes de cada proceso en el pipe.
- `${PIPESTATUS[0]}` → exit code del primer comando del pipe
- `${PIPESTATUS[1]}` → exit code del segundo comando del pipe

### Flags recomendados para `pg_restore` en entornos dev

| Flag              | Descripción                                                                                      |
| ----------------- | ------------------------------------------------------------------------------------------------ |
| `--no-owner`      | No restaura el propietario original. Evita errores si el usuario del backup no existe localmente |
| `--no-privileges` | No restaura GRANTs/REVOKEs. Evita errores de permisos en entornos locales                        |

---

## 📋 Referencia rápida de comandos

```bash
# Ver todos los clusters y su estado
pg_lsclusters

# Iniciar / detener cluster específico
sudo pg_ctlcluster <ver> <cluster> start|stop|restart|reload|status

# Crear nuevo cluster vacío
sudo pg_createcluster <ver> <nombre>

# Migrar datos entre versiones (swap de puertos automático)
sudo pg_upgradecluster <ver_origen> <cluster>

# Eliminar cluster (¡destructivo! detiene y borra datos)
sudo pg_dropcluster <ver> <cluster> --stop

# Verificar versión de herramientas cliente
psql --version
pg_restore --version
pg_dump --version

# Acceder como superusuario del sistema (peer auth)
sudo -u postgres psql -p <puerto>

# Recargar config sin reiniciar el cluster
sudo pg_ctlcluster <ver> <cluster> reload
```
