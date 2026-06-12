#!/bin/bash
# =============================================================================
# update_flyway.bash
# Actualiza el motor de Flyway en una carpeta de proyecto existente,
# preservando conf/flyway.conf y la carpeta sql/ intactos.
#
# USO:
#   ./update_flyway.bash <RUTA_DESTINO>
#
# EJEMPLO:
#   ./update_flyway.bash /home/kzambrano/Documents/database/flyway/local/developer/chinchin__db_cc_main_fintech_dev
#   ./update_flyway.bash /home/kzambrano/Documents/database/flyway/local/qa/chinchin__db_cc_main_fintech_qa
# =============================================================================

set -e  # Detener si hay error

# --- Fuente del nuevo Flyway (motor descargado) ---
NEW="/home/kzambrano/Documents/1_documentos_chinchinn/FlywayDesktopLinuxX64_9.5.6.0/flyway"

# --- Validar argumento ---
if [ -z "$1" ]; then
    echo "❌ ERROR: Debes indicar la carpeta destino."
    echo ""
    echo "USO: $0 <RUTA_DESTINO>"
    echo ""
    echo "EJEMPLO:"
    echo "  $0 /home/kzambrano/Documents/database/flyway/local/developer/chinchin__db_cc_main_fintech_dev"
    exit 1
fi

DEST="$1"

# --- Validar que el destino existe ---
if [ ! -d "$DEST" ]; then
    echo "❌ ERROR: La carpeta destino no existe: $DEST"
    exit 1
fi

# --- Validar que la fuente existe ---
if [ ! -d "$NEW" ]; then
    echo "❌ ERROR: La carpeta de la nueva versión de Flyway no existe: $NEW"
    exit 1
fi

echo "=============================================="
echo "  🚀 Actualizando Flyway"
echo "  📁 Destino : $DEST"
echo "  🆕 Fuente  : $NEW"
echo "=============================================="
echo ""

# 1. Backup del conf
echo "📦 [1/5] Creando backup de flyway.conf..."
if [ -f "$DEST/conf/flyway.conf" ]; then
    cp "$DEST/conf/flyway.conf" "$DEST/conf/flyway.conf.backup_$(date +%Y%m%d_%H%M%S)"
    echo "    ✅ Backup creado"
else
    echo "    ⚠️  No se encontró flyway.conf — se omite backup"
fi

# 2. Reemplazar binarios ejecutables
echo ""
echo "🔧 [2/5] Reemplazando binarios (flyway, flyway.cmd)..."
cp "$NEW/flyway"     "$DEST/flyway"
cp "$NEW/flyway.cmd" "$DEST/flyway.cmd"
chmod +x "$DEST/flyway"
echo "    ✅ Binarios actualizados"

# 3. Reemplazar motor Java y librerías
echo ""
echo "⚙️  [3/5] Reemplazando motor (jre, lib, licenses, rules)..."
rm -rf "$DEST/jre"      && cp -r "$NEW/jre"      "$DEST/jre"
rm -rf "$DEST/lib"      && cp -r "$NEW/lib"       "$DEST/lib"
rm -rf "$DEST/licenses" && cp -r "$NEW/licenses"  "$DEST/licenses"
rm -rf "$DEST/rules"    && cp -r "$NEW/rules"     "$DEST/rules"
echo "    ✅ Motor actualizado"

# 4. Actualizar driver PostgreSQL (auto-detecta versión vieja)
echo ""
echo "🐘 [4/5] Actualizando driver PostgreSQL..."
OLD_PG_DRIVER=$(ls "$DEST/drivers/postgresql-"*.jar 2>/dev/null | head -n 1)
NEW_PG_DRIVER=$(ls "$NEW/drivers/postgresql-"*.jar 2>/dev/null | head -n 1)

if [ -n "$OLD_PG_DRIVER" ] && [ -n "$NEW_PG_DRIVER" ]; then
    OLD_NAME=$(basename "$OLD_PG_DRIVER")
    NEW_NAME=$(basename "$NEW_PG_DRIVER")
    if [ "$OLD_NAME" != "$NEW_NAME" ]; then
        rm -f "$OLD_PG_DRIVER"
        cp "$NEW_PG_DRIVER" "$DEST/drivers/"
        echo "    ✅ $OLD_NAME → $NEW_NAME"
    else
        echo "    ℹ️  El driver ya está en la versión más reciente: $NEW_NAME"
    fi
elif [ -n "$NEW_PG_DRIVER" ]; then
    cp "$NEW_PG_DRIVER" "$DEST/drivers/"
    echo "    ✅ Driver instalado: $(basename $NEW_PG_DRIVER)"
else
    echo "    ⚠️  No se encontró driver PostgreSQL en la fuente — verifica manualmente"
fi

# 5. Verificación final
echo ""
echo "🔍 [5/5] Verificando instalación..."
echo ""
"$DEST/flyway" -v
echo ""
echo "=============================================="
echo "  ✅ Actualización completada exitosamente"
echo "  📝 conf/flyway.conf : INTACTO"
echo "  📂 sql/             : INTACTO"
echo "=============================================="
