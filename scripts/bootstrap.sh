#!/bin/bash
# =================================================================               
# bootstrap.sh - The ultimate entry point for my dotfiles
# =================================================================
set -euo pipefail

echo "⚙️  1. 最小限の基盤ツールを準備中..."
echo "🔐 システムパッケージ（git, curl）をインストールするため、sudo 権限を使用します..."
sudo apt update && sudo apt install -y git curl

echo "📦 2. mise と GitHub CLI を導入中..."
# mise 本体のインストール
curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

# gh を有効化
"$HOME/.local/bin/mise" install github-cli@latest

echo "🔐 3. GitHub にログインしてください (API制限解除とCopilotのため)"
# これにより API制限が 60回/時 -> 5,000回/時 に緩和されます
"$HOME/.local/bin/mise" exec github-cli@latest -- gh auth login

# 🚀 4. chezmoi を起動し、全ての環境を展開します
echo "🚀 4. Initializing chezmoi..."

# 【重要】まずは chezmoi 本体をダウンロードするだけ（-b で場所を指定）
echo "📥 Downloading chezmoi binary..."
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

# 初期化のみ実行
$HOME/.local/bin/chezmoi init --prompt palpeace

echo "📦 Applying configurations..."
$HOME/.local/bin/chezmoi apply

echo "🛠️  5. Installing system dependencies and managed tools..."
"$HOME/.local/bin/setup-system"

echo "🔐 6. Configuring local identities and SSH..."
source_path="$("$HOME/.local/bin/chezmoi" source-path)"
template_path=""

for candidate in \
    "$source_path/.chezmoiscripts/run_once_after_10-setup-ssh.sh.tmpl" \
    "$source_path/home/.chezmoiscripts/run_once_after_10-setup-ssh.sh.tmpl"
do
    if [[ -f "$candidate" ]]; then
        template_path="$candidate"
        break
    fi
done

if [[ -z "$template_path" ]]; then
    printf 'chezmoi template not found under %s\n' "$source_path" >&2
    exit 1
fi

rendered_script="$(mktemp)"
trap 'rm -f "$rendered_script"' EXIT
"$HOME/.local/bin/chezmoi" execute-template < "$template_path" > "$rendered_script"
bash "$rendered_script"

echo "🪟 7. Windows 版 Zed の設定を反映する場合は、必要に応じて次を実行してください:"
echo "   apply-zed-windows-settings"
echo "🐳 8. Docker / GPU を使うマシンでは、必要に応じて次を実行してください:"
echo "   configure-machine"
echo "   setup-optional"

echo "✅ 全てのセットアップが完了しました！"
echo "新しいシェル（zsh）を立ち上げて、最強の環境を楽しんでください。"
