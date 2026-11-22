#!/usr/bin/env bash
# Ref: docs/adr/0001-arquitectura-declarativa-multi-dominio.md
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${GEMINI_CONFIG_DIR:-$HOME/.gemini/config}"

mkdir -p "$CONFIG_DIR"

# 1. Clean legacy embedded Git repository in ~/.gemini/config (if present)
if [ -d "$CONFIG_DIR/.git" ] || [ -f "$CONFIG_DIR/.gitignore" ]; then
    rm -rf "$CONFIG_DIR/.git" "$CONFIG_DIR/.gitignore"
    echo "[bootstrap] Cleaned legacy .git / .gitignore from $CONFIG_DIR"
fi

# 2. Remove legacy ~/.gemini/config/skills directory (symlinks and duplicated copies)
#    so ~/.gemini/config/skills.json is the single declarative source of truth.
if [ -d "$CONFIG_DIR/skills" ] || [ -L "$CONFIG_DIR/skills" ]; then
    rm -rf "$CONFIG_DIR/skills"
    echo "[bootstrap] Cleaned legacy $CONFIG_DIR/skills directory (zero symlinks)"
fi

# 3. Install declarative global configuration files
#    Note: Antigravity's Language Server (fs.ParseAbsolutePath) does not expand
#    tilde (~/) in JSON config paths, so we keep ~/ portable in Git and expand
#    it to $HOME/ when provisioning ~/.gemini/config/skills.json.
install -m 0644 "$REPO_ROOT/config/GEMINI.md" "$CONFIG_DIR/GEMINI.md"
sed "s|\"~/|\"$HOME/|g" "$REPO_ROOT/config/skills.json" > "$CONFIG_DIR/skills.json"
chmod 0644 "$CONFIG_DIR/skills.json"

echo "[bootstrap] Installed $CONFIG_DIR/GEMINI.md"
echo "[bootstrap] Installed $CONFIG_DIR/skills.json"
echo "[bootstrap] Done."
