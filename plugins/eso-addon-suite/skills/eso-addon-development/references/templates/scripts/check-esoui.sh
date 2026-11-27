#!/usr/bin/env bash
set -euo pipefail

# Placeholders to replace:
#   <ADDON_NAME>   - Addon name matching <ADDON_NAME>.txt / <ADDON_NAME>.addon
#   <ADDON_SUBDIR> - "." for root layout, or "Addon/<ADDON_NAME>" for Addon/<Name>/ layout

ADDON_NAME="<ADDON_NAME>"
ADDON_SUBDIR="<ADDON_SUBDIR>"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -z "$ADDON_SUBDIR" || "$ADDON_SUBDIR" == "." ]]; then
  ADDON_DIR="$ROOT_DIR"
  ADDON_REL="."
else
  ADDON_DIR="${ROOT_DIR}/${ADDON_SUBDIR}"
  ADDON_REL="$ADDON_SUBDIR"
fi

if [[ -f "${ADDON_DIR}/${ADDON_NAME}.txt" ]]; then
  MANIFEST_FILE="${ADDON_DIR}/${ADDON_NAME}.txt"
elif [[ -f "${ADDON_DIR}/${ADDON_NAME}.addon" ]]; then
  MANIFEST_FILE="${ADDON_DIR}/${ADDON_NAME}.addon"
else
  echo "FAIL: Manifest ${ADDON_NAME}.txt or ${ADDON_NAME}.addon not found in ${ADDON_REL}" >&2
  exit 1
fi

SKIP_PACKAGE=0
if [[ "${1:-}" == "--skip-package" ]]; then
  SKIP_PACKAGE=1
fi

ERRORS=0

fail() {
  echo "FAIL: $1" >&2
  ERRORS=$((ERRORS + 1))
}

pass() {
  echo "OK:   $1"
}

mapfile -t LUA_PROD_FILES < <(find "$ADDON_DIR" -maxdepth 3 -name '*.lua' -not -path '*/tests/*' -not -path '*/lang/*' | sort)
mapfile -t LUA_ALL_FILES < <(find "$ADDON_DIR" -maxdepth 3 -name '*.lua' -not -path '*/tests/*' | sort)

# 1. No redundant ESO global existence guards in production Lua files
if [[ "${#LUA_PROD_FILES[@]}" -gt 0 ]]; then
  ESO_GLOBAL_IDENT='(ZO_[A-Za-z0-9_]+|EVENT_[A-Za-z0-9_]+|SI_[A-Za-z0-9_]+|ACTION_RESULT_[A-Za-z0-9_]+|TEXT_ALIGN_[A-Z]+|KEYBIND_STRIP_ALIGN_[A-Z]+|Get[A-Z][A-Za-z0-9_]+|Set[A-Z][A-Za-z0-9_]+|Is[A-Z][A-Za-z0-9_]+|Does[A-Z][A-Za-z0-9_]+|PlaySound|SLASH_COMMANDS|WINDOW_MANAGER|SCENE_MANAGER|CALLBACK_MANAGER|CENTER_SCREEN_ANNOUNCE|MAIN_MENU_KEYBOARD|WORLD_MAP_SCENE|GAMEPAD_WORLD_MAP_SCENE|WORLD_MAP_MANAGER|MAIL_INBOX|MAIL_SEND|CHAT_SYSTEM|KEYBIND_STRIP|SOUNDS|SYSTEMS|GuiRoot|InformationTooltip|zo_strformat|zo_callLater|SendMail|DeleteMail|ReadMail|RequestOpenMailbox|CloseMailbox|RequestReadMail|GetNextMailId|GetMailItemInfo)'
  ESO_GUARD_REGEX="^[[:space:]]*if[[:space:]]+(not[[:space:]]+)?${ESO_GLOBAL_IDENT}[[:space:]]+then([[:space:]]|\$)"
  ESO_INLINE_AND_LEFT_REGEX="(^|[^A-Za-z0-9_.:])${ESO_GLOBAL_IDENT}[[:space:]]+and([[:space:]]|\$)"
  ESO_INLINE_AND_RIGHT_REGEX="\\band[[:space:]]+${ESO_GLOBAL_IDENT}([[:space:]]|\\)|\$)"
  ESO_INLINE_NOT_REGEX="\\bnot[[:space:]]+${ESO_GLOBAL_IDENT}([[:space:]]|\\)|\$)"
  if grep -rnE "$ESO_GUARD_REGEX" "${LUA_PROD_FILES[@]}" \
    || grep -rnE "$ESO_INLINE_AND_LEFT_REGEX" "${LUA_PROD_FILES[@]}" \
    || grep -rnE "$ESO_INLINE_AND_RIGHT_REGEX" "${LUA_PROD_FILES[@]}" \
    || grep -rnE "$ESO_INLINE_NOT_REGEX" "${LUA_PROD_FILES[@]}"; then
    fail "Redundant ESO global existence guard found in production Lua code."
  else
    pass "No redundant ESO global existence guards in production Lua code."
  fi

  # 2. No unjustified pcall( / xpcall( in production Lua files
  PCALL_HITS="$(grep -rnE '\b(x?pcall)[[:space:]]*\(' "${LUA_PROD_FILES[@]}" | grep -v -- '--[[:space:]]*allow-pcall' || true)"
  if [[ -n "$PCALL_HITS" ]]; then
    echo "$PCALL_HITS" >&2
    fail "Unjustified pcall/xpcall found in production Lua code (add '-- allow-pcall' only if strictly justified)."
  else
    pass "No unjustified pcall/xpcall in production Lua code."
  fi
fi

# 3. Every addon Lua file must declare `local Addon = <ADDON_NAME>` or `local <ADDON_NAME> = <ADDON_NAME>`
if [[ "${#LUA_ALL_FILES[@]}" -gt 0 ]]; then
  MISSING_LOCAL_REF=0
  for lua_file in "${LUA_ALL_FILES[@]}"; do
    if ! grep -qE "^[[:space:]]*local[[:space:]]+(Addon|${ADDON_NAME})[[:space:]]*=[[:space:]]*${ADDON_NAME}\\b" "$lua_file"; then
      echo "Missing local ${ADDON_NAME} reference in: $lua_file" >&2
      MISSING_LOCAL_REF=1
    fi
  done
  if [[ "$MISSING_LOCAL_REF" -ne 0 ]]; then
    fail "One or more Lua files are missing 'local Addon = ${ADDON_NAME}' or 'local ${ADDON_NAME} = ${ADDON_NAME}'."
  else
    pass "All addon Lua files declare a local ${ADDON_NAME} reference."
  fi
fi

# 4. Manifest must use lang/en.lua + lang/$(language).lua when lang/ exists (no hardcoded secondary languages)
if [[ -d "${ADDON_DIR}/lang" ]]; then
  if ! grep -qE '^lang/en\.lua[[:space:]]*$' "$MANIFEST_FILE" || ! grep -qE '^lang/\$\(language\)\.lua[[:space:]]*$' "$MANIFEST_FILE"; then
    fail "$(basename "$MANIFEST_FILE") must include both 'lang/en.lua' and 'lang/\$(language).lua'."
  elif grep -E '^lang/[a-z]{2}\.lua[[:space:]]*$' "$MANIFEST_FILE" | grep -qv '^lang/en\.lua'; then
    fail "$(basename "$MANIFEST_FILE") contains hardcoded secondary language file(s)."
  else
    pass "$(basename "$MANIFEST_FILE") uses lang/en.lua + lang/\$(language).lua without hardcoded secondary languages."
  fi
fi

# 5. AI Disclosure presence in all required documentation files
README_TXT="${ADDON_DIR}/readme.txt"
if [[ ! -f "$README_TXT" && -f "${ROOT_DIR}/readme.txt" ]]; then
  README_TXT="${ROOT_DIR}/readme.txt"
fi

AI_DOCS=(docs/esoui-description.bbcode README.md "$README_TXT")
MISSING_AI=0
for doc_file in "${AI_DOCS[@]}"; do
  if [[ ! -f "$doc_file" ]] || ! grep -qi "AI Disclosure" "$doc_file"; then
    echo "Missing 'AI Disclosure' in: $doc_file" >&2
    MISSING_AI=1
  fi
done
if [[ "$MISSING_AI" -ne 0 ]]; then
  fail "AI Disclosure missing from one or more documentation files."
else
  pass "AI Disclosure present in all required documentation files."
fi

# 6. Prominent Notice block in BBCode
BBCODE_FILE="docs/esoui-description.bbcode"
if [[ -f "$BBCODE_FILE" ]]; then
  if ! grep -qF '[SIZE="4"][COLOR="DarkRed"][B]Notice:[/B][/COLOR]' "$BBCODE_FILE"; then
    fail "$BBCODE_FILE is missing the prominent [SIZE=\"4\"][COLOR=\"DarkRed\"][B]Notice:[/B][/COLOR] block."
  else
    pass "$BBCODE_FILE preserves the prominent Notice block."
  fi
fi

# 7. Package build must succeed cleanly (unless --skip-package is passed, e.g. in CI)
if [[ "$SKIP_PACKAGE" -eq 0 ]]; then
  if ./scripts/package.sh >/dev/null; then
    pass "./scripts/package.sh built cleanly."
  else
    fail "./scripts/package.sh failed."
  fi
fi

if [[ "$ERRORS" -gt 0 ]]; then
  echo "ESOUI compliance check failed with $ERRORS error(s)." >&2
  exit 1
fi

echo "All ESOUI compliance checks passed."
