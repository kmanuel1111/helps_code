# update_flyway.bash

Script para actualizar el **motor de Flyway** en cualquier carpeta de proyecto existente, sin tocar tu configuración ni tus scripts SQL.

---

## ¿Qué hace?

Reemplaza únicamente los archivos del **motor de Flyway** (binarios, Java, librerías) con los de la nueva versión descargada. Tu proyecto queda intacto.

| Elemento | Acción |
|---|---|
| `flyway` / `flyway.cmd` | 🔄 Reemplazado |
| `jre/` | 🔄 Reemplazado |
| `lib/` | 🔄 Reemplazado |
| `licenses/` | 🔄 Reemplazado |
| `rules/` | 🔄 Reemplazado |
| `drivers/postgresql-*.jar` | 🔄 Actualizado automáticamente |
| `conf/flyway.conf` | ✅ **INTACTO** — tu URL, usuario y password |
| `sql/` | ✅ **INTACTO** — tus scripts de migración |

---

## ¿Qué es el `NEW`?

Es la **carpeta de la nueva versión de Flyway descargada**, definida dentro del script:

```bash
NEW="/home/kzambrano/Documents/1_documentos_chinchinn/FlywayDesktopLinuxX64_9.5.6.0/flyway"
```

> Si descargas una versión más nueva en el futuro, solo actualiza esta ruta dentro del script.

---

## Cómo llamarlo

```bash
bash update_flyway.bash <RUTA_DE_TU_PROYECTO_FLYWAY>
```

### Ejemplos

```bash
# Ambiente developer
bash update_flyway.bash /home/kzambrano/Documents/database/flyway/local/developer/chinchin__db_cc_main_fintech_dev

# Ambiente QA
bash update_flyway.bash /home/kzambrano/Documents/database/flyway/local/qa/chinchin__db_cc_main_fintech_qa

# Ambiente sandbox
bash update_flyway.bash /home/kzambrano/Documents/database/flyway/local/sb/chinchin__db_cc_main_fintech_sb
```

---

## Lo necesario antes de correrlo

1. La carpeta `NEW` debe existir y ser la nueva versión de Flyway descomprimida.
2. La carpeta destino debe existir y tener la estructura estándar de Flyway (`conf/`, `sql/`, `drivers/`).
3. No requiere instalar nada adicional.
