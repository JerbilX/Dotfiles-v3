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
else
  ADDON_DIR="${ROOT_DIR}/${ADDON_SUBDIR}"
fi

if [[ -f "${ADDON_DIR}/${ADDON_NAME}.txt" ]]; then
  MANIFEST_NAME="${ADDON_NAME}.txt"
elif [[ -f "${ADDON_DIR}/${ADDON_NAME}.addon" ]]; then
  MANIFEST_NAME="${ADDON_NAME}.addon"
else
  echo "Error: ${ADDON_NAME}.txt or ${ADDON_NAME}.addon not found in ${ADDON_DIR}" >&2
  exit 1
fi

MANIFEST_FILE="${ADDON_DIR}/${MANIFEST_NAME}"
DIST_DIR="${ROOT_DIR}/dist"

# Auto-compute AddOnVersion (monotonically increasing integer from git commit count)
# and Version from exact SemVer tag (e.g. v1.0.0 -> 1.0.0) on releases,
# falling back to manifest Version on dev/working branches.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ADDON_VERSION="$(git rev-list --count HEAD)"
  EXACT_TAG="$(git describe --tags --exact-match 2>/dev/null || true)"
  if [[ -n "$EXACT_TAG" ]]; then
    DISPLAY_VERSION="${EXACT_TAG#v}"
  else
    DISPLAY_VERSION="$(awk -F': *' '/^## Version:/{print $2; exit}' "$MANIFEST_FILE" | tr -d '\r')"
  fi
else
  ADDON_VERSION="$(awk -F': *' '/^## AddOnVersion:/{print $2; exit}' "$MANIFEST_FILE" | tr -d '\r')"
  DISPLAY_VERSION="$(awk -F': *' '/^## Version:/{print $2; exit}' "$MANIFEST_FILE" | tr -d '\r')"
fi

STAGE_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGE_DIR"' EXIT

TARGET_DIR="${STAGE_DIR}/${ADDON_NAME}"
mkdir -p "$TARGET_DIR"

# Copy every runtime file referenced in the manifest (preserving relative paths)
while IFS= read -r line; do
  line="${line%$'\r'}"
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  if [[ "$line" == *'$(language)'* ]]; then
    pattern="${ADDON_DIR}/${line//\$(language)/*}"
    shopt -s nullglob
    matched_files=($pattern)
    shopt -u nullglob
    if [[ "${#matched_files[@]}" -eq 0 ]]; then
      echo "Error: manifest pattern '$line' matched no files in ${ADDON_DIR}" >&2
      exit 1
    fi
    for src_file in "${matched_files[@]}"; do
      rel_path="${src_file#"${ADDON_DIR}/"}"
      mkdir -p "${TARGET_DIR}/$(dirname "$rel_path")"
      cp "$src_file" "${TARGET_DIR}/${rel_path}"
    done
    continue
  fi
  if [[ ! -f "${ADDON_DIR}/${line}" ]]; then
    echo "Error: manifest entry '$line' not found in ${ADDON_DIR}" >&2
    exit 1
  fi
  mkdir -p "${TARGET_DIR}/$(dirname "$line")"
  cp "${ADDON_DIR}/${line}" "${TARGET_DIR}/${line}"
done < "$MANIFEST_FILE"

# Include readme.txt, README.md, and LICENSE when available
for extra_file in readme.txt README.md LICENSE; do
  if [[ -f "${ADDON_DIR}/${extra_file}" ]]; then
    cp "${ADDON_DIR}/${extra_file}" "${TARGET_DIR}/${extra_file}"
  elif [[ -f "${ROOT_DIR}/${extra_file}" ]]; then
    cp "${ROOT_DIR}/${extra_file}" "${TARGET_DIR}/${extra_file}"
  fi
done

# Stamp auto-computed Version, AddOnVersion, and Description version tag into staged manifest
awk -v ver="$DISPLAY_VERSION" -v aver="$ADDON_VERSION" '
  /^## Version:/      { print "## Version: " ver; next }
  /^## AddOnVersion:/ { print "## AddOnVersion: " aver; next }
  /^## Description:/  {
    if ($0 ~ /\(v[0-9]+\.[0-9]+\.[0-9]+[^)]*\)/) {
      sub(/\(v[0-9]+\.[0-9]+\.[0-9]+[^)]*\)/, "(v" ver ")")
    } else {
      $0 = $0 " (v" ver ")"
    }
    print; next
  }
  { print }
' "$MANIFEST_FILE" > "${TARGET_DIR}/${MANIFEST_NAME}"

# Verify every file referenced in the manifest exists in the staged addon
while IFS= read -r line; do
  line="${line%$'\r'}"
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  if [[ "$line" == *'$(language)'* ]]; then
    pattern="${TARGET_DIR}/${line//\$(language)/*}"
    if ! compgen -G "$pattern" >/dev/null; then
      echo "Error: manifest pattern '$line' matched no files in staged package" >&2
      exit 1
    fi
    continue
  fi
  if [[ ! -f "${TARGET_DIR}/${line}" ]]; then
    echo "Error: manifest entry '$line' missing from staged package" >&2
    exit 1
  fi
done < "${TARGET_DIR}/${MANIFEST_NAME}"

OUT_ZIP="${DIST_DIR}/${ADDON_NAME}-${DISPLAY_VERSION}.zip"

mkdir -p "$DIST_DIR"
rm -f "${DIST_DIR}/${ADDON_NAME}"*.zip

(
  cd "$STAGE_DIR"
  zip -rq "$OUT_ZIP" "$ADDON_NAME" -x "*/.DS_Store" "*/Thumbs.db" "*~"
)

SIZE_BYTES="$(wc -c < "$OUT_ZIP" | tr -d ' ')"
echo "Packaged: $OUT_ZIP"
echo "Version:  $DISPLAY_VERSION (AddOnVersion: $ADDON_VERSION)"
echo "Size:     ${SIZE_BYTES} bytes"
