#!/bin/bash
# apply-es-layer.sh — Aplica la capa "Omarchy en Español" (omarchy-es) a un usuario.
#
# Uso:
#   apply-es-layer.sh <URL-de-omarchy-es> <usuario-destino> [--restart-shell]
#
# Clona el repo de la capa de idioma, copia los 22 plugins traducidos
# (marlo4220.*), la extensión del menú y shell.json a
# "$HOME/.config/omarchy" del usuario destino, y opcionalmente reinicia el
# shell si la sesión es interactiva y pertenece a ese usuario.

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

OMARCHY_PRESENT=0
if command -v omarchy >/dev/null 2>&1; then
    OMARCHY_PRESENT=1
fi

AS_ROOT=0
if [ "$(id -u)" -eq 0 ]; then
    AS_ROOT=1
elif [ "$(id -un)" != "$TARGET_USER" ]; then
    echo "Aviso: aplicando la capa en español a la home de '$TARGET_USER'"
    echo "       sin privilegios root; los archivos podrían quedar con" >&2
    echo "       propietario incorrecto." >&2
fi

TMP="$(mktemp -d /tmp/omarchy-es.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

echo "→ Clonando la capa en español ($ES_REPO_URL)…"
git clone -q --depth 1 "$ES_REPO_URL" "$TMP/omarchy-es"

DEST="$TARGET_HOME/.config/omarchy"
mkdir -p "$DEST/plugins" "$DEST/extensions"

echo "→ Copiando el menú en español…"
cp "$TMP/omarchy-es/extensions/omarchy-menu.jsonc" "$DEST/extensions/omarchy-menu.jsonc"

echo "→ Copiando los plugins traducidos (marlo4220.*)…"
for plugin in "$TMP"/omarchy-es/plugins/marlo4220.*; do
    [ -d "$plugin" ] || continue
    name="$(basename "$plugin")"
    rm -rf "$DEST/plugins/$name"
    cp -r "$plugin" "$DEST/plugins/$name"
done

if [ -f "$TMP/omarchy-es/shell.json" ]; then
    if [ -f "$DEST/shell.json" ]; then
        cp "$DEST/shell.json" "$DEST/shell.json.bak.$(date +%s)"
    fi
    echo "→ Copiando shell.json…"
    cp "$TMP/omarchy-es/shell.json" "$DEST/shell.json"
fi

if [ "$AS_ROOT" -eq 1 ]; then
    echo "→ Corrigiendo la propiedad de los archivos…"
    chown -R "$TARGET_USER":"$TARGET_USER" "$DEST/plugins" "$DEST/extensions" 2>/dev/null || true
    chown "$TARGET_USER":"$TARGET_USER" "$DEST/shell.json" "$DEST"/shell.json.bak.* 2>/dev/null || true
fi

echo ""
echo "Listo. Capa omarchy-es aplicada en $DEST"

if [ "$RESTART_SHELL" -eq 1 ] && [ "$OMARCHY_PRESENT" -eq 1 ] \
    && [ "$(id -un)" = "$TARGET_USER" ]; then
    echo "→ Reiniciando el shell de Omarchy…"
    omarchy restart shell 2>/dev/null \
        || echo "No se pudo reiniciar el shell (¿sesión con pantalla bloqueada?). Reintentá con: omarchy restart shell"
elif [ "$RESTART_SHELL" -eq 1 ]; then
    echo "Nota: reiniciá el shell con: omarchy restart shell"
fi