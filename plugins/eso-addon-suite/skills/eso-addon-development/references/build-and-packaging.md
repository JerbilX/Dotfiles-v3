# Referencia: Testing, Build y Empaquetado de Addons EsoUI

Guía operativa para el arnés de pruebas unitarias, sincronización de metadatos y empaquetado de distribución mediante `eso-mcp-server`.

---

## 1. Layouts de Repositorio Soportados

El ecosistema soporta dos layouts de repositorio. Ajusta `addon_path` al invocar `eso_validate_addon`, `eso_package_addon` o `eso_scaffold_test_harness` según el layout del proyecto:

1. **Layout `root` (ej. `RPQuest`):**
   * El manifiesto (`<AddonName>.txt` o `<AddonName>.addon`), `<AddonName>.lua`, `src/`, `lang/` y `readme.txt` viven directamente en la raíz del repositorio (`.`).
   * `addon_path`: `.` (raíz del repositorio).
2. **Layout `Addon/<Name>/` (ej. `MasterWritsManager`, `MasterWritsAtHome`, `ESOInventoryHelper`):**
   * Los archivos distribuibles del addon viven en `Addon/<AddonName>/` (manifiesto, código Lua/XML, `lang/`, `readme.txt`), mientras que `README.md`, `docs/`, `tests/`, `scripts/` y `.luacheckrc` permanecen en la raíz del repositorio.
   * `addon_path`: `Addon/<AddonName>` (para `eso_validate_addon` y `eso_package_addon`). Las pruebas (`luajit tests/run.lua`) y `luacheck .` se ejecutan desde la raíz del repositorio.
   * Independientemente del layout en Git, el `.zip` distribuible debe exponer siempre `<AddonName>/` en su raíz interna (nunca `Addon/<AddonName>/`).

---

## 2. Sincronización de Manifiesto y Documentación (`README.md` y BBCode)

1. **Comandos Slash (`SLASH_COMMANDS`) vs. Keybinds:**
   * **Si el addon expone comandos slash propios** (`SLASH_COMMANDS["/comando"] = ...`), documéntalos en `README.md` (y en `docs/esoui-description.bbcode` si aplica) indicando su sintaxis y argumentos. No listes comandos nativos de EsoUI (`/reloadui`, `/script`) como propios del addon.
   * **Si el addon prioriza keybinds** (o define en `.agents/rules/release-and-docs.md` omitir comandos slash), documenta únicamente los keybinds y omite slash commands en `README.md` y `docs/esoui-description.bbcode`.
2. **Dependencias (`## DependsOn:` y `## OptionalDependsOn:`):**
   * El archivo manifiesto (`.txt` o `.addon`) es la fuente de verdad técnica para el cliente de ESO.
   * Mantén sincronizada la sección de requisitos/dependencias del `README.md` y `readme.txt` con las directivas del manifiesto.
   * Si en un proyecto existente detectas una discrepancia previa entre el manifiesto y el `README.md`, consulta al usuario antes de eliminar o agregar una dependencia.

---

## 3. Estándares de Publicación en ESOUI.com / Minion

Todo paquete distribuible destinado a **ESOUI.com** y **Minion** debe cumplir estos requisitos formales:

* **Carpeta raíz `<AddonName>/` en el `.zip`:** El archivo `.zip` debe contener un único directorio raíz llamado exactamente `<AddonName>/` (coincidente con `<AddonName>.txt` / `<AddonName>.addon`), sin incluir rutas padre como `Addon/<AddonName>/` ni artefactos de desarrollo (`.git`, `.agents`, `.claude`, `.gemini`, `tests/`, `scripts/`, archivos Python, etc.).
* **`## AddOnVersion:` en el manifiesto:** Entero positivo incremental (`## AddOnVersion: 1`, `2`, ...) distinto de la versión semántica (`## Version: 1.0.0`). Minion utiliza `AddOnVersion` para detectar actualizaciones.
* **`compatible.json`:** Mantener sincronizado el archivo `compatible.json` con la `APIVersion` soportada en el manifiesto cuando el repositorio o el flujo de ESOUI/Minion lo requiera.
* **Descripción en BBCode (`docs/esoui-description.bbcode`):** La ficha pública de ESOUI.com utiliza BBCode válido (no Markdown crudo). Respeta las convenciones locales de `.agents/rules/release-and-docs.md` si existen (por ejemplo, conservar el bloque destacado `[SIZE="4"][COLOR="DarkRed"][B]Notice:[/B][/COLOR]`).
* **`readme.txt` dentro del `.zip`:** Incluir un `readme.txt` en texto plano dentro de `<AddonName>/` con descripción breve, instalación/uso, dependencias y la sección `AI Disclosure & Credits`.
* **Transparencia de IA (`AI Disclosure`):** Mantener sincronizada una sección clara de **AI Disclosure & Credits** en `README.md`, `README.*.md`, `readme.txt` y `docs/esoui-description.bbcode`.
* **No empaquetar dependencias:** Prohibido incluir librerías de terceros (`LibAddonMenu-2.0`, `LibMapPins`, `LibChatMessage`, etc.) dentro del `.zip` del addon. Decláralas únicamente en `## DependsOn:` o `## OptionalDependsOn:` para que el usuario o Minion las instalen por separado.

---

## 4. Versionado y Empaquetado Distribuible

* **Manifiesto como Fuente de Verdad:** La versión pública y la versión entera para Minion/ESOUI se definen en el manifiesto:
  ```txt
  ## Version: 1.0.0
  ## AddOnVersion: 1
  ```
* **Token `@BUILD_VERSION@`:** El código Lua generado por `eso_scaffold_addon` utiliza `@BUILD_VERSION@` (o la constante centralizada del namespace) para evitar desincronizaciones manuales.
* **Empaquetado con `eso_package_addon`:**
  * Para generar el archivo `.zip` de distribución compatible con Minion y ESOUI.com, utiliza `eso_package_addon(addon_path, output_dir=..., validate_first=True)` pasando `addon_path="."` (layout `root`) o `addon_path="Addon/<AddonName>"` (layout `Addon/<Name>/`).
  * El empaquetador valida que todos los archivos listados en el manifiesto existan en disco, estandariza la carpeta raíz `<AddonName>/` dentro del `.zip` y excluye artefactos de desarrollo.

---

## 5. Prevalencia del Motor EsoUI sobre los Mocks (Anti-Test-Induced Damage)

* **La API de EsoUI manda sobre el Mock:** La fuente de verdad técnica es la API oficial indexada en `eso-mcp-server`.
* **Qué hacer cuando falla un test por falta de soporte en el mock:**
  * Si tu código de producción usa una función, método de control, filtro (`EVENT_MANAGER:AddFilterForEvent`) o constante real de EsoUI (verificada con `eso_get_function` / `eso_get_event` / `eso_get_constant`) y el test falla porque el mock local no lo implementa, **actualiza el mock en `tests/mocks/eso_ui_mock.lua`**.
  * **Prohibido ensuciar el código de producción:** Nunca agregues comprobaciones defensivas innecesarias en el addon (como `if EVENT_MANAGER.AddFilterForEvent then`) solo para pasar un mock incompleto.

---

## 6. Estándares del Arnés de Pruebas (`tests/run.lua`)

Para mantener ejecuciones rápidas, deterministas y amigables con la ventana de contexto y el sandbox:

1. **Inicialización con `eso_scaffold_test_harness`:**
   * Usa `eso_scaffold_test_harness(addon_path)` para aprovisionar el mock base (`tests/mocks/eso_ui_mock.lua`), que ya emula `GuiRoot`, `WINDOW_MANAGER`, `EVENT_MANAGER`, `SCENE_MANAGER`, `ZO_Scene`, `ZO_FadeSceneFragment` y `ZO_SavedVars`.
2. **Salida Concisa (<50 líneas en éxito):**
   * Al pasar las pruebas, `tests/run.lua` debe imprimir un resumen compacto (ej. `OK: N tests passed, 0 failed`) sin logs verbosos por cada aserción exitosa.
3. **Sin Volcados Masivos (`Anti-Table-Dumps`):**
   * Ante una falla, reporta archivo, línea, nombre del test y valor esperado vs. recibido, sin volcar tablas globales (`_G`) completas a stdout.
4. **Ejecución Atómica en Terminal:**
   * Ejecuta siempre las pruebas con un comando directo y auto-aprobable en el sandbox:
     * `luajit tests/run.lua` (o `lua tests/run.lua`)
   * Evita bucles complejos en bash (`for f in ...; do ...; done`) o subshells innecesarias.
