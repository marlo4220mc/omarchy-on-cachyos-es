#!/bin/bash
# apply-es-layer.sh — Aplica la capa "Omarchy en Español" (omarchy-es) a un usuario.
#
# Uso:
#   apply-es-layer.sh <URL-de-omarchy-es> <usuario-destino> [--restart-shell]
#
# Clona el repo de la capa de idioma, copia los plugins traducidos
# (marlo4220.*), la extensión del menú, shell.json, el catálogo de atajos y
# escribe ~/.config/omarchy/language, y opcionalmente reinicia el shell si la
# sesión es interactiva y pertenece a ese usuario.
#
# Cada pieza es opcional: si una no existe en el repo, se avisa y se sigue, para
# que un cambio en omarchy-es no rompa la instalación completa.

set -euo pipefail

ES_REPO_URL="${1:?Uso: apply-es-layer.sh <URL-de-omarchy-es> <usuario-destino> [--restart-shell]}"
TARGET_USER="${2:?Uso: apply-es-layer.sh <URL-de-omarchy-es> <usuario-destino> [--restart-shell]}"
RESTART_SHELL="0"
if [ "${3:-}" = "--restart-shell" ]; then
    RESTART_SHELL="1"
fi

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6 || true)"
if [ -z "$TARGET_HOME" ]; then
    echo "Error: no se pudo resolver la home de '$TARGET_USER'." >&2
    exit 1
fi

AS_ROOT=0
if [ "$(id -u)" -eq 0 ]; then
    AS_ROOT=1
elif [ "$(id -un)" != "$TARGET_USER" ]; then
    echo "Aviso: aplicando la capa en español a la home de '$TARGET_USER'" >&2
    echo "       sin privilegios root; los archivos podrían quedar con" >&2
    echo "       propietario incorrecto." >&2
fi

TMP="$(mktemp -d /tmp/omarchy-es.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

echo "→ Clonando la capa en español ($ES_REPO_URL)…"
if ! git clone --depth 1 "$ES_REPO_URL" "$TMP/omarchy-es"; then
    echo "Error: no se pudo clonar $ES_REPO_URL (¿red?)." >&2
    exit 1
fi

SRC="$TMP/omarchy-es"
DEST="$TARGET_HOME/.config/omarchy"
mkdir -p "$DEST/plugins" "$DEST/extensions"

# Omarchy 4.5+ trae i18n nativo: el shell lee ~/.config/omarchy/language y
# superpone default/i18n/<código>/shell.json sobre el catálogo inglés.
ES_LANG="${OMARCHY_ES_LANG:-es-MX}"
echo "→ Configurando idioma nativo ($ES_LANG)…"
printf '%s\n' "$ES_LANG" > "$DEST/language"

# omarchy.indicators ya tiene i18n nativo y permisos de sistema en 4.5+; un
# clon viejo bloquea DND/NightLight/StayAwake, así que se retira.
if [ -d "$DEST/plugins/marlo4220.indicators" ]; then
    echo "→ Retirando el clon marlo4220.indicators (se usa el nativo)…"
    rm -rf "$DEST/plugins/marlo4220.indicators"
fi

if [ -f "$SRC/extensions/omarchy-menu.jsonc" ]; then
    echo "→ Copiando el menú en español…"
    cp "$SRC/extensions/omarchy-menu.jsonc" "$DEST/extensions/omarchy-menu.jsonc"
else
    echo "  [aviso] el repo no trae extensions/omarchy-menu.jsonc (se conserva el actual)" >&2
fi

echo "→ Copiando los plugins traducidos (marlo4220.*)…"
COPIED=0
for plugin in "$SRC"/plugins/marlo4220.*; do
    [ -d "$plugin" ] || continue
    name="$(basename "$plugin")"
    rm -rf "$DEST/plugins/$name"
    cp -r "$plugin" "$DEST/plugins/$name"
    COPIED=$((COPIED + 1))
done
echo "  [ok]    $COPIED plugins copiados"

if [ -f "$SRC/shell.json" ]; then
    if [ -f "$DEST/shell.json" ]; then
        cp "$DEST/shell.json" "$DEST/shell.json.bak.$(date +%s)"
    fi
    echo "→ Copiando shell.json…"
    cp "$SRC/shell.json" "$DEST/shell.json"
else
    echo "  [aviso] el repo no trae shell.json (se conserva el actual)" >&2
fi

# Atajos de teclado en español: catálogo que re-registra todos los bindings con
# la misma tecla/modificador/dispatcher y solo cambia la descripción. El menú
# Super+K lo lee de hyprctl binds, así que sale traducido sin perder atajos.
HYPR_DIR="$TARGET_HOME/.config/hypr"
if [ -f "$SRC/hypr/bindings.lua" ]; then
    mkdir -p "$HYPR_DIR"
    echo "→ Instalando el catálogo de atajos en español ($HYPR_DIR/bindings.lua)…"
    if [ -f "$HYPR_DIR/bindings.lua" ] && ! grep -q "Capa omarchy-es" "$HYPR_DIR/bindings.lua" 2>/dev/null; then
        cp "$HYPR_DIR/bindings.lua" "$HYPR_DIR/bindings.lua.bak.$(date +%s)"
    fi
    cp "$SRC/hypr/bindings.lua" "$HYPR_DIR/bindings.lua"

    if [ -f "$HYPR_DIR/hyprland.lua" ] \
        && ! grep -q '^omarchy_default_bindings = false' "$HYPR_DIR/hyprland.lua" 2>/dev/null; then
        echo "→ Activando omarchy_default_bindings = false…"
        sed -i '1i\omarchy_default_bindings = false' "$HYPR_DIR/hyprland.lua"
    fi
else
    echo "  [aviso] el repo no trae hypr/bindings.lua (los atajos quedan en inglés)" >&2
fi

if [ "$AS_ROOT" -eq 1 ]; then
    echo "→ Corrigiendo la propiedad de los archivos…"
    chown -R "$TARGET_USER":"$TARGET_USER" "$DEST/plugins" "$DEST/extensions" 2>/dev/null || true
    chown "$TARGET_USER":"$TARGET_USER" "$DEST/language" 2>/dev/null || true
    chown "$TARGET_USER":"$TARGET_USER" "$DEST/shell.json" "$DEST"/shell.json.bak.* 2>/dev/null || true
    chown "$TARGET_USER":"$TARGET_USER" "$HYPR_DIR/bindings.lua" "$HYPR_DIR"/bindings.lua.bak.* 2>/dev/null || true
fi

echo ""
echo "Listo. Capa omarchy-es aplicada en $DEST"

if [ "$RESTART_SHELL" -eq 1 ] && command -v omarchy >/dev/null 2>&1 \
    && [ "$(id -un)" = "$TARGET_USER" ]; then
    echo "→ Reiniciando el shell de Omarchy…"
    omarchy restart shell 2>/dev/null \
        || echo "No se pudo reiniciar el shell (¿sesión con pantalla bloqueada?). Reintentá con: omarchy restart shell"
elif [ "$RESTART_SHELL" -eq 1 ]; then
    echo "Nota: reiniciá el shell con: omarchy restart shell"
fi
