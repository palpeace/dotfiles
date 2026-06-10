#!/usr/bin/env bash
# headroom を venv に明示インストール（chezmoi apply では走らせない＝この repo の流儀に合わせ手動実行）。
# 使い方: ~/.local/headroom-experiment/install.sh
# 撤去: rm -rf ~/.local/headroom-experiment/venv ~/.local/headroom-experiment/state
set -euo pipefail
ROOT="$HOME/.local/headroom-experiment"
if [ ! -x "$ROOT/venv/bin/headroom" ]; then
  echo "creating venv at $ROOT/venv ..."
  python3 -m venv "$ROOT/venv"
  "$ROOT/venv/bin/pip" -q install --upgrade pip
  # [proxy,code] のみ。[ml](torch/散文モデル)は CPU 機では入れない。
  "$ROOT/venv/bin/pip" install "headroom-ai[proxy,code]"
else
  echo "venv already present; upgrading headroom-ai ..."
  "$ROOT/venv/bin/pip" install -U "headroom-ai[proxy,code]"
fi
mkdir -p "$ROOT/state"
"$ROOT/venv/bin/headroom" --version
echo "done. add alias (already via chezmoi dot_zshrc): claude-hr"
