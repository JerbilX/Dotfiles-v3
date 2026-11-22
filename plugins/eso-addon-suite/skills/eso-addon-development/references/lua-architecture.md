# Referencia: Arquitectura y Principios de Diseño en Lua para EsoUI

Guía técnica de runtime y estándares de ingeniería para el desarrollo de addons en Lua y XML bajo el motor de interfaz de ZeniMax Online Studios (**EsoUI**).

---

## 1. Aislamiento de Namespace (Zero Global Pollution)

Todo addon debe encapsular su estado interno, funciones y configuraciones en una única tabla global identificada con el nombre canónico del proyecto:

```lua
MyAddonName = MyAddonName or {}
local MyAddon = MyAddonName
```

* **Prohibición de Polución Global:** Queda prohibido declarar variables, tablas o funciones fuera del namespace del addon sin el calificador `local`.
* **Exportación Controlada:** Solo la tabla raíz del addon (y los controles XML de nivel superior que requieran nombre global) deben exponerse en `_G`.
* **Verificación:** Ejecuta `eso_validate_addon` pasando `addon_namespace="MyAddonName"` para detectar cualquier asignación global accidental.

---

## 2. Ciclo de Vida y Carga (`EVENT_ADD_ON_LOADED`)

El evento `EVENT_ADD_ON_LOADED` se dispara secuencialmente para cada addon cargado durante el inicio de sesión y en cada `/reloadui`:

```lua
local function OnAddOnLoaded(eventCode, addOnName)
    if addOnName ~= MyAddon.name then return end
    EVENT_MANAGER:UnregisterForEvent(MyAddon.name, EVENT_ADD_ON_LOADED)
    MyAddon:Initialize()
end

EVENT_MANAGER:RegisterForEvent(MyAddon.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)
```

* **Validación de Identidad Obligatoria:** Todo callback de `EVENT_ADD_ON_LOADED` debe verificar que `addOnName == MyAddon.name` antes de inicializar.
* **Desregistro Inmediato:** Invoca `EVENT_MANAGER:UnregisterForEvent(MyAddon.name, EVENT_ADD_ON_LOADED)` inmediatamente tras confirmar la coincidencia para liberar el listener.

---

## 3. Persistencia de Datos (`SavedVariables`)

La persistencia de datos entre sesiones o recargas de interfaz (`/reloadui`) se implementa a través de `ZO_SavedVars`:

* **Configuraciones por Cuenta (Account-Wide):**
  ```lua
  MyAddon.savedVars = ZO_SavedVars:NewAccountWide(
      "MyAddon_SavedVariables", -- Debe coincidir con ## SavedVariables: en el manifiesto
      1,                        -- Versión del esquema de datos
      nil,                      -- Namespace/perfil opcional
      defaultSavedVars          -- Tabla con valores por defecto
  )
  ```
* **Configuraciones por Personaje (Character-Specific):**
  ```lua
  MyAddon.savedVars = ZO_SavedVars:NewCharacterIdSettings(
      "MyAddon_SavedVariables",
      1,
      nil,
      defaultSavedVars
  )
  ```
* **Tabla de Valores por Defecto (`defaultSavedVars`):** Define siempre una tabla de valores iniciales para garantizar un fallback determinista ante claves nuevas.
* **Inspección de `SavedVariables` Reales:** Para auditar archivos `SavedVariables.lua` generados por el cliente de ESO, utiliza las herramientas de solo lectura del MCP (`eso_savedvars_inspect`, `eso_savedvars_get_account_wide`, `eso_savedvars_get_character`, `eso_savedvars_query`).

---

## 4. Hooking No Destructivo

Para interceptar funciones nativas del motor o de managers de EsoUI sin romper otros addons:

* **Pre-Hooking (`ZO_PreHook`):**
  * Úsalo para validaciones previas o para cancelar condicionalmente la acción original.
  * Si el callback retorna `true`, la ejecución de la función original se aborta; si retorna `false` o `nil`, la función original continúa normalmente.
* **Post-Hooking (`ZO_PostHook`):**
  * Úsalo para reaccionar o actualizar tu UI después de que la función original haya terminado.
* **Prohibición de Sobrescritura Destructiva:** Evita reasignar funciones globales (`TargetFunction = MyCustomFunction`) cuando `ZO_PreHook` o `ZO_PostHook` resuelvan el caso.

---

## 5. Rendimiento y Recolección de Basura (GC)

El recolector de basura de Lua puede causar micro-cortes (*frame drops*) si se instancian tablas o strings masivamente en eventos de alta frecuencia:

* **Eventos Críticos:** En eventos frecuentes (`EVENT_RETICLE_TARGET_CHANGED`, `EVENT_COMBAT_EVENT`, `OnUpdate`), evita crear tablas temporales `{}` o closures anónimas en cada disparo.
* **Filtros de Eventos a Nivel Motor:** Cuando registres eventos que soporten filtrado nativo (ej. `EVENT_COMBAT_EVENT`, `EVENT_INVENTORY_SINGLE_SLOT_UPDATE`, `EVENT_EFFECT_CHANGED`), utiliza `EVENT_MANAGER:AddFilterForEvent(...)` para que el filtro ocurra en C++ antes de invocar Lua.
* **Reutilización de Controles (`ZO_ObjectPool`):** Para listas dinámicas de elementos UI (misiones, objetivos, marcadores, diálogos), reutiliza controles mediante `ZO_ControlPool` / `ZO_ObjectPool` o `ZO_ScrollList` en lugar de crear controles nuevos indefinidamente.

---

## 6. Abstracción por Tipos Nativos vs. Hardcoding de IDs

* **Enums Tipados Oficiales:** Clasifica ítems, misiones, pasos y estados usando las constantes oficiales del motor (`ItemType`, `SpecializedItemType`, `QuestType`, `QuestStepVisibility`, etc.), verificándolas con `eso_get_enum` o `eso_search_api`.
* **Evita Listas Quemadas de IDs:** No mantengas listas manuales de IDs numéricos cuando la API provea funciones o enums semánticos.

---

## 7. Organización Modular y Centralización de Constantes

En addons de múltiples archivos, centraliza los metadatos y constantes en un módulo dedicado cargado al inicio del manifiesto (`.txt` / `.addon`):

### 7.1 Orden de Carga en el Manifiesto
```txt
## Title: RPQuest
## APIVersion: 101051
## Version: 1.0.0
## AddOnVersion: 1
## Author: JerbilX
## SavedVariables: RPQuest_SavedVariables

src/Constants.lua
src/Init.lua
src/UI.lua
```

### 7.2 Encapsulamiento en Namespace
```lua
-- src/Constants.lua
RPQuest = RPQuest or {}

RPQuest.Constants = {
    METADATA = {
        NAME = "RPQuest",
        TITLE = "RPQuest",
        VERSION = "@BUILD_VERSION@",
        AUTHOR = "JerbilX",
    },
    SAVED_VARS = {
        NAME = "RPQuest_SavedVariables",
        VERSION = 1,
    },
    UI = {
        CHAT_PREFIX = "|cFFD700[RPQuest]|r ",
    },
}
```

---

## 8. Jerarquía y Creación de Controles UI (`EsoUI Controls`)

* **Ventanas de Nivel Superior (`CT_TOPLEVELCONTROL`):**
  * Vía recomendada en Lua:
    ```lua
    local myWindow = WINDOW_MANAGER:CreateTopLevelWindow("MyAddonTopLevelWindow")
    ```
  * Si usas `WINDOW_MANAGER:CreateControl("...", GuiRoot, CT_TOPLEVELCONTROL)`, el `parent` **debe** ser `GuiRoot`.
* **Anclaje Espacial (`SetAnchor`):**
  * Para alinear tu ventana con paneles nativos (ej. `ZO_SharedRightPanelBackground`), mantén el `TopLevelControl` bajo `GuiRoot` y vincúlalo mediante `:ClearAnchors()` y `:SetAnchor(...)`.
* **Controles Secundarios (`CT_CONTROL`, `CT_LABEL`, `CT_BUTTON`, `CT_TEXTURE`, `CT_BACKDROP`):**
  * Anídalos asignando como `parent` la ventana o contenedor correspondiente.
* **Validación de Layouts XML (`GuiXml`):**
  * Antes de escribir atributos o nodos hijos en un `.xml`, consulta `eso_get_ui_control` si tienes dudas sobre los atributos heredados, y valida el archivo con `eso_lint_xml`.
