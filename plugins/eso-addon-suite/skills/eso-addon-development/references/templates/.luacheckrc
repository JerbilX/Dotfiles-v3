-- Luacheck configuration for <ADDON_NAME> (ESO Lua 5.1 / LuaJIT)
-- Replace <ADDON_NAME> with your addon's global namespace.
std = "luajit"
max_line_length = false
self = false

exclude_files = {
    "tests/**",
}

-- Addon global namespace and EsoUI tables mutated by addon registration
globals = {
    "<ADDON_NAME>",
    "ESO_Dialogs",
    "ZO_MapPin",
}

-- Official Elder Scrolls Online (EsoUI) read-only globals
read_globals = {
    -- Core & Debug
    "d",
    "zo_callLater",
    "zo_strformat",

    -- EsoUI Singletons & Managers
    "ANIMATION_MANAGER",
    "CALLBACK_MANAGER",
    "CENTER_SCREEN_ANNOUNCE",
    "CHAT_SYSTEM",
    "EVENT_MANAGER",
    "GuiRoot",
    "InformationTooltip",
    "KEYBIND_STRIP",
    "MAIN_MENU_KEYBOARD",
    "SCENE_MANAGER",
    "SLASH_COMMANDS",
    "SOUNDS",
    "SYSTEMS",
    "WINDOW_MANAGER",
    "WORLD_MAP_MANAGER",
    "WORLD_MAP_SCENE",
    "ZO_SavedVars",
    "ZO_SimpleSceneFragment",
    "ZO_FadeSceneFragment",

    -- Common EsoUI Global Functions
    "ApplyTemplateToControl",
    "GetClientLanguage",
    "GetCurrentCharacterId",
    "GetCurrentMapId",
    "GetDisplayName",
    "GetInterfaceColor",
    "GetMapName",
    "GetMapPlayerPosition",
    "GetString",
    "GetTimeStamp",
    "GetUnitDisplayName",
    "GetUnitName",
    "GetZoneId",
    "IsInGamepadPreferredMode",
    "IsShiftKeyDown",
    "IsUnitInCombat",
    "PlaySound",
    "ZO_Alert",
    "ZO_CheckButton_SetCheckState",
    "ZO_CheckButton_SetEnableState",
    "ZO_CheckButton_SetLabelText",
    "ZO_CheckButton_SetToggleFunction",
    "ZO_ComboBox_ObjectFromContainer",
    "ZO_CreateStringId",
    "ZO_Dialogs_ShowDialog",
    "ZO_PostHook",
    "ZO_PreHook",
    "ZO_Tooltips_HideTextTooltip",
    "ZO_Tooltips_ShowTextTooltip",

    -- Common EsoUI Events & Constants
    "BOTTOMLEFT",
    "BOTTOMRIGHT",
    "CT_BACKDROP",
    "CT_BUTTON",
    "CT_CONTROL",
    "CT_EDITBOX",
    "CT_LABEL",
    "CT_SCROLL",
    "CT_TEXTURE",
    "CT_TOPLEVELCONTROL",
    "DL_OVERLAY",
    "EVENT_ADD_ON_LOADED",
    "EVENT_PLAYER_ACTIVATED",
    "EVENT_ZONE_CHANGED",
    "KEYBIND_STRIP_ALIGN_CENTER",
    "LEFT",
    "RIGHT",
    "SCENE_HIDDEN",
    "SCENE_SHOWING",
    "SCENE_SHOWN",
    "TEXT_ALIGN_CENTER",
    "TEXT_ALIGN_LEFT",
    "TEXT_ALIGN_RIGHT",
    "TEXT_ALIGN_TOP",
    "TOP",
    "TOPLEFT",
    "TOPRIGHT",
    "UI_ALERT_CATEGORY_ALERT",
    "UI_ALERT_CATEGORY_ERROR",
}
