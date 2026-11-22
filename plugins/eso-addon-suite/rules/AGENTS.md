# Estándares y Reglas de Compliance para Addons de ESO (ESOUI / Baertram)

Estándares obligatorios de desarrollo, localización, verificación y auditoría (`pr-reviewer`) para proyectos de addons de *The Elder Scrolls Online* (**EsoUI**), diseñados para prevenir regresiones de moderación en ESOUI.com y *Baertram Addon Check*.

## 1. Estándares de Código Lua y API EsoUI

1. **Verificación previa contra `eso-mcp-server`:**
   - Antes de usar cualquier constante, enum, evento (`EVENT_*`), sonido (`SOUNDS.*`), textura o API oficial de EsoUI (ej. `MODIFY_TEXT_TYPE_UPPERCASE`), verificar su existencia y firma exacta mediante `eso-mcp-server` (`eso_search_api`, `eso_get_function`, `eso_get_event`, `eso_get_constant`, `eso_get_enum`).
   - Al introducir un nuevo global oficial de EsoUI en el archivo principal (`<AddonName>.lua`) o en `src/*.lua`, registrarlo en `.luacheckrc` (`read_globals`, o `globals` si el addon muta sus campos).

2. **Cero guardas redundantes `if <ESO_GLOBAL> then` en producción:**
   - Prohibido agregar guardas de existencia sobre APIs o globales estándar de ESO (ej. `if GetUnitName then`, `if not GetUnitWorldPosition then`, `if zo_callLater then`, `if zo_strformat then`) en código de producción (`<AddonName>.lua` o `src/*.lua`).
   - Todos los *stubs* y *mocks* del entorno ESO para pruebas herméticas pertenecen exclusivamente a `tests/` (`tests/run.lua` y `tests/mocks/`).

3. **Referencia local al namespace en cada archivo Lua:**
   - Todo archivo `.lua` del addon (`<AddonName>.lua`, `src/*.lua` e incluidos `lang/*.lua`) debe inicializar y capturar localmente el namespace del addon al inicio:
     ```lua
     <AddonNamespace> = <AddonNamespace> or {}
     local Addon = <AddonNamespace> -- o `local <AddonNamespace> = <AddonNamespace>` en lang/*.lua
     ```

4. **Uso estricto de `pcall` / `xpcall`:**
   - Evitar envolver `string.format`, llamadas estándar de formateo o APIs de EsoUI en `pcall(` o `xpcall(`.
   - Solo se permite si existe una justificación técnica explícita documentada en la misma línea con `-- allow-pcall`.

## 2. Localización y Manifiesto (`<AddonName>.txt` / `.addon`)

- Mantener el manifiesto del addon cargando siempre el idioma base seguido del token dinámico `$(language)`:
  ```text
  lang/en.lua
  lang/$(language).lua
  ```
- Nunca hardcodear archivos de idiomas secundarios (como `lang/es.lua`, `lang/de.lua`, `lang/fr.lua`) en el manifiesto; el módulo de localización (`src/Locale.lua`) debe garantizar el *fallback* seguro al inglés.

## 3. Transparencia de IA (AI Disclosure & Credits) y Documentación de Release

- Incluir y mantener sincronizada una sección clara de **AI Disclosure & Credits** en toda la documentación principal del addon:
  - `docs/esoui-description.bbcode` (si aplica)
  - `README.md` y `README.*.md` (ej. `README.es.md`)
  - `readme.txt` (incluido en el paquete `.zip` para ESOUI)
- Si el proyecto define reglas locales de release y documentación (ej. `.agents/rules/release-and-docs.md`), respetar íntegramente sus convenciones para `docs/esoui-description.bbcode` (como conservar el bloque `[SIZE="4"][COLOR="DarkRed"][B]Notice:[/B][/COLOR]` destacado y evitar documentar slash commands en BBCode cuando se prioricen keybinds).

## 4. Checklist Obligatorio Pre-PR, Pre-Release y en `pr-reviewer`

Antes de abrir cualquier Pull Request hacia `dev`, promover una versión estable a `main` o aprobar una auditoría `pr-reviewer`:

- [ ] `luajit tests/run.lua` pasa con 0 fallos.
- [ ] Si el proyecto cuenta con script de validación/empaquetado (`./scripts/check-esoui.sh` y/o `./scripts/package.sh`), ejecutarlo y confirmar que pase todas las comprobaciones (guardas ESO, `pcall`, referencias locales al namespace, manifiesto, `AI Disclosure`, formato BBCode y generación del `.zip`).
- [ ] `luacheck .` pasa con 0 errores y 0 advertencias (verificado localmente si está instalado y/o en CI).
- [ ] `eso_validate_addon` (MCP) ejecutado sobre los archivos del addon sin nuevos errores ni APIs inexistentes.
