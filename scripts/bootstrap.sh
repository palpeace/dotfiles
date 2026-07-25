#!/bin/bash
# =================================================================               
# bootstrap.sh - The ultimate zero-touch entry point for dotfiles
# =================================================================
set -euo pipefail

CHEZMOI_REPO="${CHEZMOI_REPO:-palpeace}"
NONINTERACTIVE="${NONINTERACTIVE:-0}"

echo "⚙️  1. WSLシステム設定と基本ライブラリの事前チェック..."

# 1. WSL /etc/wsl.conf の準備
if [ -w /etc/wsl.conf ] || command -v sudo >/dev/null 2>&1; then
    if [ ! -f /etc/wsl.conf ] || ! grep -q "systemd=true" /etc/wsl.conf 2>/dev/null; then
        echo "🔧 /etc/wsl.conf に systemd 有効化設定を追加中..."
        sudo bash -c 'cat >> /etc/wsl.conf <<EOF
[boot]
systemd=true
[interop]
appendWindowsPath=false
EOF' 2>/dev/null || true
    fi
fi

# 2. パッケージ更新と基本ツールの確保
echo "📦 パッケージリストを更新し git / curl を確認中..."
export DEBIAN_FRONTEND=noninteractive
sudo -E apt update -qq && sudo -E apt install -y git curl

# 3. mise のセットアップ
echo "📦 2. mise を導入中..."
if ! command -v mise >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/mise" ]; then
    curl -fsSL https://mise.run | sh
fi
export PATH="$HOME/.local/bin:$PATH"

# 4. chezmoi のダウンロードと一括反映
echo "🚀 3. chezmoi の初期化と全設定の一括適用 (chezmoi init --apply)..."
if ! command -v chezmoi >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/chezmoi" ]; then
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

"$HOME/.local/bin/chezmoi" init --apply --force "$CHEZMOI_REPO"

echo ""
echo "✅ スクラップ＆ビルド（環境復元）が完了しました！"
echo "🪟 Windows 版 Orca IDE の設定を反映する場合は: apply-orca-windows-settings"
echo "🐳 Docker / GPU を使うマシンでは: configure-machine && setup-optional"

