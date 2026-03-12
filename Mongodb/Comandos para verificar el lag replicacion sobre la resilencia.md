# 📘 MANUAL DE SUPERVIVENCIA: Diagnóstico de Replica Sets en MongoDB
### *Guía para Administradores (Incluye Casos Reales)*

**Tags:** `MongoDB` `Replication` `Troubleshooting` `Ops`

---

## 📋 Índice
1. [Introducción](#introducción)
2. [Caso 1: Lectura Avanzada de `rs.status()`](#caso-1-lectura-avanzada-de-rsstatus)
3. [Caso 2: Medición del Replication Lag](#caso-2-medición-del-replication-lag)
4. [Checklist de Diagnóstico Rápido](#checklist-de-diagnóstico-rápido)
5. [Plantilla de Reporte de Incidente](#plantilla-de-reporte-de-incidente)
6. [Anexo: Comandos de Rescate](#anexo-comandos-de-rescate)

---

## 🎯 Introducción

Cuando un Replica Set de MongoDB funciona bien, es invisible. Cuando falla, tu aplicación se ralentiza o se detiene. Este manual está diseñado para ser tu guía de cabecera cuando sospeches que un nodo está "desfasado". Aprenderás a leer las señales que MongoDB te envía y a documentarlas como un profesional.

---

## 🕵️ Caso 1: Lectura Avanzada de `rs.status()`

El comando `rs.status()` es el "electrocardiograma" de tu Replica Set. Vamos a aprender a interpretar sus latidos.

### 🔬 La Anatomía del Comando

```javascript
rs.status()
```

### 📊 Tabla de Decodificación Instantánea

| Campo Clave                    | ¿Qué te dice?                      | Semáforo 🚦                                                                    |
| :----------------------------- | :--------------------------------- | :---------------------------------------------------------------------------- |
| **`members[n].stateStr`**      | El rol del nodo                    | 🟢 `PRIMARY`/`SECONDARY` <br> 🟡 `STARTUP2` <br> 🔴 `RECOVERING`/`DOWN`          |
| **`members[n].health`**        | ¿Responde el nodo?                 | 🟢 `1` <br> 🔴 `0`                                                              |
| **`members[n].optime`**        | *Timestamp* de la última operación | 🟢 Similar en todos <br> 🟡 Diferencia de segundos <br> 🔴 Diferencia de minutos |
| **`members[n].optimeDate`**    | Fecha legible de `optime`          | 🟢 Fechas casi idénticas <br> 🔴 **Diferencia > 30 min** (¡Alerta!)             |
| **`members[n].lastHeartbeat`** | Última comunicación                | 🟢 Reciente <br> 🔴 Antiguo                                                     |
| **`members[n].pingMs`**        | Latencia de red                    | 🟢 < 50ms <br> 🟡 50-200ms <br> 🔴 > 200ms                                       |

### 🚨 Ejemplo de la Vida Real (Escenario Crítico)

Imagina que ejecutas el comando y ves esto:

```json
{
  "members": [
    {
      "name": "primary-server:27017",
      "stateStr": "PRIMARY",
      "optimeDate": "2025-04-10T15:30:00Z"  // 🟢 Actual
    },
    {
      "name": "secondary-server:27017",
      "stateStr": "SECONDARY",
      "health": 1,                          // 🟢 Vivo, pero...
      "optimeDate": "2025-04-10T15:00:00Z"  // 🔴 30 MINUTOS ATRÁS
    }
  ]
}
```

**Diagnóstico Inmediato:** El nodo `secondary-server` está **vivo pero desfasado por 30 minutos**. El problema no es de conectividad, es de rendimiento o capacidad.

---

## 📏 Caso 2: Medición del Replication Lag

Si `rs.status()` te da la sospecha, `rs.printSecondaryReplicationInfo()` te da la prueba forense.

### 🎯 El Comando Definitivo

Debes ejecutarlo **conectado al nodo PRIMARIO**.

```javascript
rs.printSecondaryReplicationInfo()
```

### 📈 Interpretación de la Salida

```text
source: secondary-server:27017
    syncedTo: Thu Apr 10 2025 15:00:00 GMT+0000 (UTC)
    1800 secs (0.5 hrs) behind the primary   // 🔴 ¡Confirmado!
```

- **`syncedTo`:** La fecha hasta donde el secundario está al día.
- **`X secs behind the primary`:** El **Replication Lag**.
    - `0 secs` = 😎 Perfecto.
    - `> 10 secs` = 🤔 Revisar.
    - `> 300 secs` (5 min) = 🚨 Critico.

### 🧠 Dato Técnico Clave
El **Replication Lag** mide el tiempo que tarda una operación de escritura en el primario en aplicarse en el secundario. 30 minutos de lag significa que hay una acumulación de operaciones que el secundario no puede procesar a tiempo.

---

## ✅ Checklist de Diagnóstico Rápido

Cuando llegues a un servidor con problemas, sigue esta lista en orden:

- [ ] **1. Conexión:** `mongo --host <nodos>`
- [ ] **2. Estado Global:** `rs.status()` (Buscar `optimeDate` dispares)
- [ ] **3. Medición Exacta:** `rs.printSecondaryReplicationInfo()` (Desde el PRIMARY)
- [ ] **4. Salud del Oplog:** `rs.printReplicationInfo()` (En cada nodo)
    - *¿El oplog es suficientemente grande para cubrir el lag?*
- [ ] **5. Logs del nodo atrasado:** `grep "repl" /var/log/mongodb/mongod.log`
    - *¿Hay errores de IO o de aplicación del oplog?*
- [ ] **6. Sistema Operativo (en el nodo atrasado):**
    - `top` o `htop` (¿CPU al 100%?)
    - `iostat -x 1` (¿%util de disco cercano al 100%?)
    - `ping <primary-host>` (¿Latencia alta?)

---

## 📝 Plantilla de Reporte de Incidente

Copia y pega este bloque en tu sistema de tickets cada vez que enfrentes un problema de replicación.

```markdown
---
### 🔴 REPORTE DE INCIDENTE: REPLICATION LAG

**Fecha:** {{YYYY-MM-DD}}
**Reportado por:** {{Tu Nombre}}
**Entorno:** [Producción/Pre-producción]

#### 1. SÍNTOMA INICIAL
> [Ej: La aplicación reporta lentitud en lecturas. Se revisa MongoDB y se encuentra un nodo atrasado.]

#### 2. EVIDENCIA TÉCNICA

**Comando:** `rs.status()`
**Hallazgo:** El nodo `{{secondary-host}}` muestra un `optimeDate` de `{{fecha_atrasada}}`, mientras el PRIMARY está en `{{fecha_actual}}`.

**Comando:** `rs.printSecondaryReplicationInfo()` (Desde PRIMARY)
**Hallazgo:**
```text
source: {{secondary-host}}
    syncedTo: {{fecha_atrasada}}
    {{X}} secs ({{Y}} hrs) behind the primary
```

#### 3. ANÁLISIS DE CAUSA RAÍZ
- [ ] **Red:** Latencia alta ({{pingMs}} ms)
- [ ] **Disco (IO):** %util alto en el secundario
- [ ] **CPU:** Proceso saturado
- [ ] **Operación bloqueante:** Indexación o consulta pesada
- [ ] **Otro:** {{especificar}}

#### 4. ACCIÓN TOMADA
> [Ej: Se reinició el servicio mongod en el secundario. / Se migró a un disco SSD. / Se mató una operación de larga duración.]

#### 5. RESOLUCIÓN
> [Ej: El nodo se puso al día y el lag volvió a 0 segundos.]

#### 6. LECCIONES APRENDIDAS
- [ ] Crear alerta en {{Herramienta}} cuando lag > 300 segundos.
- [ ] Homogeneizar hardware entre nodos del replica set.
```
---

## 🆘 Anexo: Comandos de Rescate (Cheat Sheet)

| Tarea                          | Comando                              | Dónde ejecutarlo |
| :----------------------------- | :----------------------------------- | :--------------- |
| **Ver estado completo**        | `rs.status()`                        | Cualquier nodo   |
| **Ver rol actual**             | `rs.isMaster()`                      | Cualquier nodo   |
| **Ver lag en segundos**        | `rs.printSecondaryReplicationInfo()` | **PRIMARY**      |
| **Ver tamaño del oplog**       | `rs.printReplicationInfo()`          | Cualquier nodo   |
| **Ver config del replica set** | `rs.conf()`                          | Cualquier nodo   |
| **Forzar re-sincronización**   | `rs.syncFrom("host:port")`           | Nodo atrasado    |
| **Salir de la shell**          | `exit` o `quit()`                    | -                |

---

## 🎓 Palabras del Docente

> *"Un nodo con lag no es un nodo roto, es un nodo pidiendo ayuda. Aprende a escucharlo."*

Recuerda: La diferencia de 30 minutos que encontraste no es solo un número. Es una señal de que tu sistema está desbalanceado. Ya sea por hardware, red o carga, tu trabajo como administrador es identificar la causa y equilibrar la balanza.

**¡Manos a la obra!** 🚀
```