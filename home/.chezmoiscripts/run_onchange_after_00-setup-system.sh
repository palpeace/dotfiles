#!/bin/bash
set -eufo pipefail

echo "🚀 システム構成を同期中..."
export PATH="$HOME/.local/bin:$PATH"

# 1. OSパッケージ
sudo apt update
sudo apt install -y zsh build-essential pkg-config libssl-dev unzip xz-utils bubblewrap

# 2. シェル切り替え
if [ "$SHELL" != "$(which zsh)" ]; then
    sudo chsh -s $(which zsh) $(whoami)
fi

# 3. mise ツールの一括インストール (GitHub Token を活用)
if command -v gh &> /dev/null; then
    export GITHUB_TOKEN=$(gh auth token 2>/dev/null || echo "")
fi

eval "$($HOME/.local/bin/mise activate bash)"
$HOME/.local/bin/mise install -y

# 4. Kiro CLI
if ! command -v kiro-cli &> /dev/null; then
    curl -fsSL https://cli.kiro.dev/install | bash
fi
