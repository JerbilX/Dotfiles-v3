# Referencia: Testing, Build y Empaquetado de Addons EsoUI

Guía operativa para el arnés de pruebas unitarias, sincronización de metadatos y empaquetado de distribución mediante `eso-mcp-server`.

---

## 1. Sincronización de Manifiesto y Documentación (`README.md`)

1. **Comandos Slash (`SLASH_COMMANDS`):**
   * Cada vez que agregues o modifiques un comando de chat propio del addon (ej. `SLASH_COMMANDS["/rpquest"] = ...`), documéntalo en el `README.md` indicando su sintaxis y argumentos.
   * No listes comandos nativos de EsoUI (`/reloadui`, `/script`) como si fueran propios del addon.
2. **Dependencias (`## DependsOn:` y `## OptionalDependsOn:`):**
   * El archivo manifiesto (`.txt` o `.addon`) es la fuente de verdad técnica para el cliente de ESO.
   * Mantén sincronizada la sección de requisitos/dependencias del `README.md` con las directivas del manifiesto.
   * Si en un proyecto existente detectas una discrepancia previa entre el manifiesto y el `README.md`, consulta al usuario antes de eliminar o agregar una dependencia.

---

## 2. Versionado y Empaquetado Distribuible

* **Manifiesto como Fuente de Verdad:** La versión pública y la versión entera para Minion/ESOUI se definen en el manifiesto:
  ```txt
  ## Version: 1.0.0
  ## AddOnVersion: 1
  ```
* **Token `@BUILD_VERSION@`:** El código Lua generado por `eso_scaffold_addon` utiliza `@BUILD_VERSION@` (o la constante centralizada del namespace) para evitar desincronizaciones manuales.
* **Empaquetado con `eso_package_addon`:**
  * Para generar el archivo `.zip` de distribución compatible con Minion y ESOUI.com, utiliza la herramienta MCP `eso_package_addon(addon_path, output_dir=..., validate_first=True)`.
  * El empaquetador valida automáticamente que todos los archivos listados en el manifiesto existan en disco, estandariza la carpeta raíz `<AddonName>/` dentro del `.zip` y excluye artefactos de desarrollo (`.git`, `.agents`, `.claude`, `.gemini`, `tests/`, archivos Python, etc.).

---

## 3. Prevalencia del Motor EsoUI sobre los Mocks (Anti-Test-Induced Damage)

* **La API de EsoUI manda sobre el Mock:** La fuente de verdad técnica es la API oficial indexada en `eso-mcp-server`.
* **Qué hacer cuando falla un test por falta de soporte en el mock:**
  * Si tu código de producción usa una función, método de control, filtro (`EVENT_MANAGER:AddFilterForEvent`) o constante real de EsoUI (verificada con `eso_get_function` / `eso_get_event` / `eso_get_constant`) y el test falla porque el mock local no lo implementa, **actualiza el mock en `tests/mocks/eso_ui_mock.lua`**.
  * **Prohibido ensuciar el código de producción:** Nunca agregues comprobaciones defensivas innecesarias en el addon (como `if EVENT_MANAGER.AddFilterForEvent then`) solo para pasar un mock incompleto.

---

## 4. Estándares del Arnés de Pruebas (`tests/run.lua`)

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
