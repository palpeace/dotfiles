#!/bin/bash
# =================================================================               
# bootstrap.sh - The ultimate entry point for my dotfiles
# =================================================================
set -eu

echo "⚙️  1. 最小限の基盤ツールを準備中..."
echo "🔐 システムパッケージ（git, curl）をインストールするため、sudo 権限を使用します..."
sudo apt update && sudo apt install -y git curl

echo "📦 2. mise と GitHub CLI を導入中..."
# mise 本体のインストール
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

# gh を 有効化
mise install github-cli@latest

echo "🔐 3. GitHub にログインしてください (API制限解除とCopilotのため)"
# これにより API制限が 60回/時 -> 5,000回/時 に緩和されます
mise exec github-cli@latest -- gh auth login

# 🚀 4. chezmoi を起動し、全ての環境を展開します
echo "🚀 4. Initializing chezmoi..."

# 【重要】まずは chezmoi 本体をダウンロードするだけ（-b で場所を指定）
echo "📥 Downloading chezmoi binary..."
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

# 初期化のみ実行
$HOME/.local/bin/chezmoi init --prompt palpeace

echo "📦 Applying configurations..."
$HOME/.local/bin/chezmoi apply --force

echo "✅ 全てのセットアップが完了しました！"
echo "新しいシェル（zsh）を立ち上げて、最強の環境を楽しんでください。"
