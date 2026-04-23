# 📘 Configurar Single-Node Replica Set (rs0) con Seguridad en MongoDB
### *Para habilitar Transacciones Multi-Documento en entornos locales o de un solo servidor*

**Tags:** `MongoDB` `ReplicaSet` `Transactions` `Security` `KeyFile` `rs0`

---

## 📋 Índice
1. [¿Por qué necesito un Replica Set?](#por-qué-necesito-un-replica-set)
2. [Paso 1: Generar el KeyFile](#paso-1-generar-el-keyfile)
3. [Paso 2: Configurar mongod.conf](#paso-2-configurar-mongodconf)
4. [Paso 3: Reiniciar el servicio](#paso-3-reiniciar-el-servicio)
5. [Paso 4: Inicializar el Replica Set](#paso-4-inicializar-el-replica-set)
6. [Verificación](#verificación)
7. [Error Común y Solución](#error-común-y-solución)
8. [Usando Transacciones en tus Scripts JS](#usando-transacciones-en-tus-scripts-js)

---

## 🎯 ¿Por qué necesito un Replica Set?

MongoDB solo permite las **Transacciones Multi-Documento** (el equivalente al `BEGIN / COMMIT / ROLLBACK` de SQL) cuando el servidor está configurado como un **Replica Set**.

Sin Replica Set, si tienes un script que hace operaciones en varias colecciones y algo falla a mitad del proceso, los cambios anteriores **no se revierten**, dejando tu base de datos en un estado inconsistente.

```
// Sin RS: si esto falla...
deleteMany(...)  ✅ Se ejecuta
insertMany(...)  ❌ Falla  →  El delete ya ocurrió. Sin vuelta atrás.

// Con RS y Transacción: si esto falla...
deleteMany(...)  ✅ Se ejecuta
insertMany(...)  ❌ Falla  →  Se hace ROLLBACK de TODO automáticamente. ✅
```

---

## 🔑 Paso 1: Generar el KeyFile

El KeyFile es obligatorio cuando `security.authorization: enabled` está activo en tu `mongod.conf`. Sin él, MongoDB rechaza arrancar con Replica Set + seguridad simultáneamente.

Ejecuta estos **3 comandos en orden** en tu terminal:

```bash
# 1. Generar el archivo con una clave aleatoria de 756 bytes en Base64
openssl rand -base64 756 | sudo tee /var/lib/mongodb/mongodb.key > /dev/null

# 2. Asignar el propietario correcto (usuario del proceso mongod)
sudo chown mongodb:mongodb /var/lib/mongodb/mongodb.key

# 3. Asignar permisos de solo lectura para el dueño (MongoDB lo exige, si el archivo tiene más permisos rechaza arrancar)
sudo chmod 400 /var/lib/mongodb/mongodb.key
```

> ⚠️ **Importante:** Los 3 comandos son obligatorios. Si el achivo tiene permisos `644` o `600`, MongoDB se **negará a arrancar** por razones de seguridad.

---

## ⚙️ Paso 2: Configurar mongod.conf

Edita el archivo de configuración de MongoDB:

```bash
sudo nano /etc/mongod.conf
```

Localiza la sección `replication` y la sección `security` y déjalas exactamente así:

```yaml
security:
  authorization: enabled
  keyFile: /var/lib/mongodb/mongodb.key

replication:
  replSetName: rs0
```

### ✅ Checklist del archivo de configuración

| Sección | Clave | Valor correcto |
| :--- | :--- | :--- |
| `security` | `authorization` | `enabled` |
| `security` | `keyFile` | `/var/lib/mongodb/mongodb.key` |
| `replication` | `replSetName` | `rs0` |

> ⚠️ **YAML es sensible a la indentación.** Usa **espacios**, nunca la tecla TAB. Cada subclave debe tener exactamente **2 espacios** de sangría.

---

## 🔃 Paso 3: Reiniciar el servicio

```bash
sudo systemctl restart mongod
```

Verifica que arrancó correctamente:

```bash
sudo systemctl status mongod
```

Deberías ver `Active: active (running)`. Si ves `status=2/INVALIDARGUMENT` o similar, revisa la indentación del `mongod.conf`.

---

## 🚀 Paso 4: Inicializar el Replica Set

Este paso se realiza **una sola vez**. Conéctate a `mongosh` con tu usuario:

```bash
mongosh "mongodb://tu_usuario:tu_password@localhost:27017/?authSource=admin"
```

Y dentro de la consola, ejecuta:

```javascript
rs.initiate()
```

### ✅ Confirmación de éxito

Si todo salió bien, el **prompt de tu consola cambiará** de:
```
test>
```
a:
```
rs0 [direct: primary] test>
```

La presencia de **`rs0 [direct: primary]`** confirma que el Replica Set está activo y tu nodo es el servidor primario.

---

## 🔎 Verificación

Puedes confirmar el estado del Replica Set en cualquier momento con:

```javascript
// Ver estado completo de todos los miembros
rs.status()

// Ver la configuración actual del Replica Set
rs.conf()

// Confirmar que este nodo es el primario y acepta escrituras
db.hello().isWritablePrimary
// → Debe devolver: true
```

---

## 🆘 Error Común y Solución

### `MongoServerError: Transaction numbers are only allowed on a replica set member or mongos`

**Causa:** Estás intentando usar Transacciones en una instancia **Standalone** (sin Replica Set configurado).

**Solución:** Seguir los pasos de esta guía. El servidor debe ser un Replica Set para poder usar transacciones.

---

### `status=2/INVALIDARGUMENT` al reiniciar mongod

**Causa:** Error de sintaxis o indentación en `/etc/mongod.conf`.

**Posibles razones:**
- Se usó TAB en lugar de espacios.
- Falta la sección `keyFile` en `security` (MongoDB rechaza arrancar con `authorization: enabled` + `replSetName` sin `keyFile`).
- El bloque `replication:` está repetido en el archivo.

---

## 💻 Usando Transacciones en tus Scripts JS

Una vez configurado el Replica Set, puedes envolver tus operaciones en una transacción de la siguiente manera:

```javascript
// 1. Iniciar la sesión
const session = db.getMongo().startSession();
session.startTransaction();

try {
    // 2. Obtener la base de datos a través de la sesión (obligatorio para que las operaciones formen parte de la transacción)
    const mi_db = session.getDatabase('nombre_de_tu_bd');

    print("=== Iniciando Transacción ===");

    // 3. Tus operaciones (deleteMany, insertMany, updateMany, etc.)
    mi_db.mi_coleccion.deleteMany({ _id: { $in: [ObjectId("...")] } });
    mi_db.mi_coleccion.insertMany([{ ... }]);

    // 4. Si todo salió bien, se confirman los cambios
    session.commitTransaction();
    print("✅ Transacción completada con éxito.");

} catch (error) {
    // 5. Si algo falló, se deshace TODO automáticamente (rollback)
    session.abortTransaction();
    print("❌ ERROR detectado: Se cancelaron todos los cambios.");
    print("Detalle: " + error);
} finally {
    // 6. Siempre cerrar la sesión
    session.endSession();
    print("=== Sesión finalizada ===");
}
```

### 📌 Ejecutar el script apuntando a una base de datos específica

Incluye el nombre de la BD **en la URI de conexión** (antes del `?`), sin modificar el archivo `.js`:

```bash
mongosh "mongodb://usuario:password@localhost:27017/nombre_de_tu_bd?authSource=admin" \
--file tu_script.js
```

---

## 🎓 Resumen de Comandos

| Tarea | Comando |
| :--- | :--- |
| Generar keyFile | `openssl rand -base64 756 \| sudo tee /var/lib/mongodb/mongodb.key > /dev/null` |
| Asignar propietario | `sudo chown mongodb:mongodb /var/lib/mongodb/mongodb.key` |
| Asignar permisos | `sudo chmod 400 /var/lib/mongodb/mongodb.key` |
| Reiniciar MongoDB | `sudo systemctl restart mongod` |
| Estado del servicio | `sudo systemctl status mongod` |
| Inicializar RS | `rs.initiate()` (desde mongosh, solo una vez) |
| Verificar RS activo | `db.hello().isWritablePrimary` |
| Ver estado del RS | `rs.status()` |

---

> 💡 **Recuerda:** El `rs.initiate()` solo se ejecuta **una vez** en la vida del servidor. Una vez inicializado el Replica Set, cada vez que reinicies `mongod` se levantará automáticamente en modo `rs0:PRIMARY`.

---

## 🌐 BONUS: Replica Set Multi-Nodo en un Ambiente Real

> 🧪 **Esta sección es teórica / para ambiente controlado.** Aplica cuando tienes **3 servidores reales** (o VMs) y quieres configurar una réplica de producción con alta disponibilidad.

### 🏗️ Arquitectura típica (1 Primario + 2 Secundarios)

```
┌─────────────────────────────────────────────────────┐
│                  Replica Set: rs0                   │
│                                                     │
│  ┌──────────────┐   ┌──────────────┐   ┌─────────┐ │
│  │   PRIMARY    │──▶│  SECONDARY 1 │   │SECONDARY│ │
│  │ 192.168.1.10 │   │ 192.168.1.11 │   │  2      │ │
│  │  :27017      │   │   :27017     │   │.1.12    │ │
│  └──────────────┘   └──────────────┘   └─────────┘ │
│         │                  │                 │      │
│         └──────── Oplog replication ─────────┘      │
└─────────────────────────────────────────────────────┘
```

| Nodo | IP (ejemplo) | Rol inicial | Puerto |
| :--- | :--- | :--- | :--- |
| Servidor A | `192.168.1.10` | PRIMARY | 27017 |
| Servidor B | `192.168.1.11` | SECONDARY | 27017 |
| Servidor C | `192.168.1.12` | SECONDARY | 27017 |

> **¿Por qué 3 nodos?** MongoDB usa votación para elegir un nuevo PRIMARY si el actual cae. Con 3 nodos hay siempre mayoría (2 de 3). Con 2 nodos, si uno cae, no hay mayoría y el RS se bloquea.

---

### 📋 Pre-requisitos en TODOS los servidores

Antes de empezar, en cada uno de los 3 servidores:

```bash
# 1. MongoDB instalado y funcionando
sudo systemctl status mongod

# 2. Los 3 servidores deben poder comunicarse entre sí por el puerto 27017
# Probar desde cada servidor hacia los otros dos:
ping 192.168.1.11
ping 192.168.1.12

# 3. El firewall debe permitir el puerto 27017
sudo ufw allow 27017
# o en sistemas con firewalld:
sudo firewall-cmd --permanent --add-port=27017/tcp && sudo firewall-cmd --reload
```

---

### 🔑 Paso 1: Generar el KeyFile (solo en un servidor, se copia a los demás)

El KeyFile debe ser **idéntico** en los 3 nodos. Se genera en uno y se copia a los otros.

**En el Servidor A (futuro PRIMARY):**

```bash
# Generar la clave
openssl rand -base64 756 | sudo tee /var/lib/mongodb/mongodb.key > /dev/null
sudo chown mongodb:mongodb /var/lib/mongodb/mongodb.key
sudo chmod 400 /var/lib/mongodb/mongodb.key

# Copiar el archivo a los otros dos servidores
# (necesitas acceso SSH a los otros servidores)
sudo scp /var/lib/mongodb/mongodb.key usuario@192.168.1.11:/tmp/mongodb.key
sudo scp /var/lib/mongodb/mongodb.key usuario@192.168.1.12:/tmp/mongodb.key
```

**En el Servidor B y C** (para mover el keyfile al lugar correcto):

```bash
sudo mv /tmp/mongodb.key /var/lib/mongodb/mongodb.key
sudo chown mongodb:mongodb /var/lib/mongodb/mongodb.key
sudo chmod 400 /var/lib/mongodb/mongodb.key
```

---

### ⚙️ Paso 2: Configurar `mongod.conf` en los 3 servidores

El archivo de configuración es **igual en los 3 nodos**, solo cambia el `bindIp` si aplica:

```yaml
# /etc/mongod.conf

storage:
  dbPath: /var/lib/mongodb

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0        # Escuchar en todas las interfaces de red

processManagement:
  timeZoneInfo: /usr/share/zoneinfo

security:
  authorization: enabled
  keyFile: /var/lib/mongodb/mongodb.key

replication:
  replSetName: rs0        # El mismo nombre en los 3 servidores ← CLAVE
```

Reiniciar en cada servidor:

```bash
sudo systemctl restart mongod
```

---

### 🚀 Paso 3: Inicializar el Replica Set (solo desde el futuro PRIMARY)

Conéctate al **Servidor A** (el que será el PRIMARY):

```bash
mongosh "mongodb://admin:password@192.168.1.10:27017/?authSource=admin"
```

Y ejecuta la inicialización con la configuración completa de los 3 miembros:

```javascript
rs.initiate({
  _id: "rs0",                         // Debe coincidir con replSetName del mongod.conf
  members: [
    { _id: 0, host: "192.168.1.10:27017" },   // Servidor A → será el PRIMARY
    { _id: 1, host: "192.168.1.11:27017" },   // Servidor B → SECONDARY
    { _id: 2, host: "192.168.1.12:27017" }    // Servidor C → SECONDARY
  ]
})
```

Respuesta esperada:

```json
{ "ok": 1 }
```

Espera unos segundos y verifica:

```javascript
rs.status()
```

Deberías ver los 3 miembros: uno en `PRIMARY` y dos en `SECONDARY`.

---

### 🔁 Paso 4: Agregar un miembro después (si ya tienes el RS funcionando)

Si en el futuro quieres **agregar un cuarto nodo** al Replica Set ya existente, desde el PRIMARY:

```javascript
// Agregar un nuevo miembro
rs.add("192.168.1.13:27017")

// Si quieres que sea solo árbitro (vota pero no guarda datos, más liviano)
rs.addArb("192.168.1.14:27017")
```

---

### 💣 Paso 5: Simular una falla (para probar la alta disponibilidad)

Esto es lo que deberías probar en tu ambiente controlado:

```bash
# En el Servidor A (PRIMARY), detén MongoDB
sudo systemctl stop mongod
```

Conéctate a cualquiera de los secundarios y observa:

```javascript
// Desde el Servidor B o C
rs.status()
// → Verás que uno de los SECONDARY se convirtió automáticamente en PRIMARY
// → El Servidor A aparecerá como DOWN
```

Cuando vuelves a levantar el Servidor A:

```bash
sudo systemctl start mongod
```

Automáticamente se reconecta al RS y vuelve como **SECONDARY** (el nuevo PRIMARY ya fue elegido mientras estaba caído).

---

### 📊 Tabla Resumen: Single-Node vs Multi-Nodo

| Característica | Single-Node RS (lo que hicimos) | Multi-Nodo RS (3 nodos) |
| :--- | :---: | :---: |
| Soporte de Transacciones | ✅ | ✅ |
| Alta Disponibilidad | ❌ | ✅ |
| Failover automático | ❌ | ✅ |
| Recomendado para Producción | ❌ | ✅ |
| Recomendado para Desarrollo | ✅ | 🤷 (overkill) |
| Servidores necesarios | 1 | Mínimo 3 |

---

> 🎓 **Conclusión:** Con lo que aprendiste hoy ya tienes la base para montar un RS de producción. La diferencia con el single-node es solo en el `rs.initiate()` donde declaras los 3 miembros, y el paso de distribuir el KeyFile entre servidores. ¡Todo lo demás es exactamente lo mismo!
