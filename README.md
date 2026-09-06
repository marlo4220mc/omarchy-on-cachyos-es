# Omarchy en Español para CachyOS

Instalador de **Omarchy** sobre **CachyOS** que además aplica la capa de idioma **"Omarchy en Español"** (`omarchy-es`).

Basado en el flujo de `omarchy-on-cachyos` (compatibilidad con CachyOS + parches de seguridad y arranque), a lo que se le agregó la traducción completa de la interfaz al español.

Omarchy es un escritorio "opinionated" basado en Hyprland que prioriza simplicidad y productividad; CachyOS es una distribución Arch Linux optimizada para rendimiento.

---

## ¿Qué instala?

1. **Omarchy** (v3.x desde fuente o v4.x desde los paquetes `omarchy`, `omarchy-settings`, `omarchy-nvim`).
2. **La capa en español `omarchy-es`**: los **22 plugins** de la barra y el menú traducidos al español (`marlo4220.*`), la **extensión del menú** (`omarchy-menu.jsonc`) y `shell.json` con la barra en español.
3. Los **guardias de arranque** (mkinitcpio + limine) para no romper el arrancador de CachyOS.
4. **SDDM** con autologin hacia la sesión `omarchy.desktop`.
5. Configuración de **NVIDIA** respetuosa con el driver que ya tenga CachyOS (no fuerza ni pinnea ninguna versión).

---

## ¿Qué hace el script?

- Detecta y soporta **Omarchy v3** (instalación desde fuente) y **v4** (paquetes pacman).
- Aplica las correcciones de compatibilidad con CachyOS:
  - no pisa `/etc/pacman.conf` ni el mirrorlist (evita el riesgo de `partial upgrade`),
  - no toca el arrancador de CachyOS (limine-snapper-sync) ni recompila el initramfs,
  - reemplaza la lógica de NVIDIA por una versión que **respeta el driver existente**,
  - configura NetworkManager con backend `iwd`,
  - pinnea `walker` al repo de omarchy.
- Instala los **guardias de arranque** antes de cualquier paquete `omarchy-settings`.
- Configura **SDDM** (autologin + `omarchy.desktop`), sin romper la sesión UWSM.
- Al final aplica la **capa en español** sobre el usuario de escritorio:
  plugins `marlo4220.*`, menú y `shell.json`.

### Seguridad

- El script auxiliar de sistema usa `mktemp` + `chmod 600` y se elimina al terminar: **no** se ejecuta con `sudo bash` ningún archivo en una ruta predecible de `/tmp`.
- Los archivos de la capa en español quedan con propietario el usuario de escritorio (aunque el instalador corra como root).

---

## Prerrequisitos

Instalar primero **CachyOS**, con estas opciones:

1. **Sistema de archivos**: `BTRFS` + **Snapper** (requerido para que Omarchy funcione).
2. **Shell**: `Fish` (por defecto en CachyOS).
3. **Escritorio**: mínimo sin entorno, o el *Hyprland Desktop Environment* de CachyOS. **No** instalar GNOME ni KDE.
4. Driver gráfico: en equipos NVIDIA que CachyOS ya maneja el driver; en equipos con gráficos integrados (p. ej. AMD) el instalador lo detecta y salta la parte NVIDIA automáticamente.

---

## Instalación

```bash
# Cloná este repositorio
git clone https://github.com/marlo4220mc/omarchy-on-cachyos-es.git

# Entrá a la carpeta
cd omarchy-on-cachyos-es/bin

# Hacé ejecutable el instalador
chmod +x install-omarchy-on-cachyos.sh

# Ejecutalo
./install-omarchy-on-cachyos.sh
```

> **Nota:** revisá el contenido del script antes de ejecutarlo para entender qué cambios hará en tu sistema.

El instalador pedirá tu **nombre de usuario** y tu **email** para configurar la instalación y la capa en español.

---

## La capa Omarchy en Español

Todo el idioma vive en el repo [`marlo4220mc/omarchy-es`](https://github.com/marlo4220mc/omarchy-es) y se copia a `~/.config/omarchy/` de tu usuario:

| Componente | Descripción |
| --- | --- |
| `plugins/marlo4220.*` (22) | Plugins de la barra/menú traducidos: audio, bluetooth, monitor, alimentación, clima, reloj, red, bandeja, indicadores, actualización del sistema, agentes, menú, notificaciones, recordatorios, bloqueo, polkit, portapapeles, selector de imágenes, emojis, speedtest, disk-speedtest y OSD. |
| `extensions/omarchy-menu.jsonc` | Menú principal del launcher (Super+Espacio) en español, con los campos completos para conservar iconos y acciones. |
| `shell.json` | Configuración de la barra (arriba, anclada al reloj `omarchy.clock`, layout con los plugins en español) y de bloqueo/descanso de pantalla. |

Podés volver a aplicar esta capa manualmente en cualquier momento:

```bash
git clone https://github.com/marlo4220mc/omarchy-es.git
cd omarchy-es
./bootstrap.sh          # copia la capa a ~/.config/omarchy y reinicia el shell
```

---

## Repositorios involucrados

- [basecamp/omarchy](https://github.com/basecamp/omarchy) — Omarchy original (se instala como base).
- [`omarchy-on-cachyos-es`](https://github.com/marlo4220mc/omarchy-on-cachyos-es) — **este** instalador.
- [marlo4220mc/omarchy-es](https://github.com/marlo4220mc/omarchy-es) — capa de idioma en español.

---

## Notas sobre NVIDIA

El instalador **no** degrada ni pinnea ninguna versión de driver: detecta el que CachyOS ya tenga instalado y lo respeta. Solo si no hay ningún driver NVIDIA presente instala uno a través de la herramienta `chwd` de CachyOS.

Para aceleración de hardware (NVDEC) en navegadores:

**Chromium** — agregá a `~/.config/chromium-flags.conf`:

```
--enable-features=VaapiOnNvidiaGPUs
```

E instalá [enhanced-h264ify](https://chromewebstore.google.com/detail/enhanced-h264ify/omkfmpieigblcllmkgbflkikinpkodlk) desactivando los codecs **VP8** y **AV1**.

**Firefox** — instalá [enhanced-h264ify](https://addons.mozilla.org/en-US/firefox/addon/enhanced-h264ify/) desactivando **VP8** y **AV1**, y forzá la aceleración en `user.js`:

```js
user_pref("media.hardware-video-decoding.force-enabled", true);
user_pref("media.hardware-video-encoding.force-enabled", true);
user_pref("layers.acceleration.force-enabled", true);
user_pref("webgl.force-enabled", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.rdd-ffmpeg.enabled", true);
user_pref("media.av1.enabled", true);
user_pref("widget.dmabuf.force-enabled", true);
user_pref("gfx.x11-egl.force-enabled", true);
```

---

## Solución de problemas

- **La interfaz sigue en inglés después de instalar**: la capa se aplicó sobre el usuario de la instalación. Verificá que `~/.config/omarchy/plugins/marlo4220.*` existan y reiniciá el shell con `omarchy restart shell` (con la sesión desbloqueada).
- **La instalación corrió como v4 pero la barra no cambia**: confirmá que las variables de NVIDIA (si aplica) fueron escritas en `~/.config/uwsm/env` del *usuario* de escritorio y no en `/root`.
- Si corregiste los plugins a mano, borrá `~/.config/omarchy/plugins/marlo4220.*` o los `*.bak` antes de volver a aplicar la capa.

---

## Sin garantía

ESTE SOFTWARE SE PROPORCIONA "TAL CUAL", SIN GARANTÍA DE NINGÚN TIPO. Úsalo bajo tu propia responsabilidad; hacé siempre copia de seguridad de tu sistema y de tus datos antes de ejecutar scripts de instalación.

---

## Cómo contribuir

1. **Forkeá** este repositorio.
2. Creá un branch: `git checkout -b feature/mi-mejora`.
3. Hacé tus cambios y probálos en CachyOS.
4. Commit: `git commit -m "Descripción del cambio"`.
5. Push al fork: `git push origin feature/mi-mejora`.
6. Abrí un **Pull Request** con una descripción clara.

### Guías
- Probá los cambios sobre CachyOS antes de enviarlos.
- Seguí el estilo de código existente.
- Actualizá la documentación si agregás funcionalidad.
- Reportá bugs con GitHub Issues.