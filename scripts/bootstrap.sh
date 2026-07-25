#!/bin/bash
# =================================================================
# bootstrap.sh - The ultimate zero-touch entry point for dotfiles
# =================================================================
set -euo pipefail

CHEZMOI_REPO="${CHEZMOI_REPO:-palpeace}"
export NONINTERACTIVE="${NONINTERACTIVE:-0}"

# 0. 非対話環境における sudo 可否チェック
SUDO_CMD=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO_CMD="sudo -n"
        $SUDO_CMD true 2>/dev/null || { echo "❌ ERROR: sudo password required or non-interactive sudo failed." >&2; exit 1; }
    else
        echo "❌ ERROR: Root access or functional sudo is required." >&2
        exit 1
    fi
fi

echo "⚙️  1. WSLシステム設定と基本ライブラリの事前チェック..."

# 1. WSL /etc/wsl.conf の準備
if [ ! -f /etc/wsl.conf ] || ! grep -q "systemd=true" /etc/wsl.conf 2>/dev/null; then
    echo "🔧 /etc/wsl.conf に systemd 有効化設定を追加中..."
    $SUDO_CMD bash -c 'cat >> /etc/wsl.conf <<EOF
[boot]
systemd=true
[interop]
appendWindowsPath=false
EOF' 2>/dev/null || true
fi

# 2. パッケージ更新と基本ツールの確保
echo "📦 パッケージリストを更新し git / curl を確認中..."
export DEBIAN_FRONTEND=noninteractive
$SUDO_CMD -E apt update -qq && $SUDO_CMD -E apt install -y git curl

# 3. mise のセットアップ
echo "📦 2. mise を導入中..."
mkdir -p "$HOME/.local/bin"
if ! command -v mise >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/mise" ]; then
    tmp_mise="$(mktemp)"
    curl -fsSL https://mise.run -o "$tmp_mise"
    sh "$tmp_mise"
    rm -f "$tmp_mise"
fi
export PATH="$HOME/.local/bin:$PATH"

# 4. chezmoi のダウンロードと一括反映
echo "🚀 3. chezmoi の初期化と全設定の一括適用 (chezmoi init --apply)..."
if ! command -v chezmoi >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/chezmoi" ]; then
    tmp_chezmoi="$(mktemp)"
    curl -fsSL get.chezmoi.io -o "$tmp_chezmoi"
    sh "$tmp_chezmoi" -- -b "$HOME/.local/bin"
    rm -f "$tmp_chezmoi"
fi

"$HOME/.local/bin/chezmoi" init --apply --force "$CHEZMOI_REPO"

echo ""
echo "🔬 4. 構築完了後の自動テスト (Smoke Tests) を実行中..."
test_dir="$HOME/.local/share/chezmoi/tests"
if [ -d "$test_dir" ]; then
    (
        cd "$HOME/.local/share/chezmoi"
        failed_tests=0
        for test_script in tests/*.sh; do
            if [ -f "$test_script" ]; then
                echo "▶️  Running test: $test_script"
                if ! bash "$test_script"; then
                    echo "❌ Test failed: $test_script"
                    failed_tests=$((failed_tests + 1))
                fi
            fi
        done
        
        if [ "$failed_tests" -gt 0 ]; then
            echo "🚨 $failed_tests 個のテストが失敗しました。環境構築は不完全です。" >&2
            exit 1
        else
            echo "✅ すべてのテストがパスしました。環境は完全に健全です。"
        fi
    ) || exit 1
else
    echo "⚠️ テストディレクトリが見つかりません。テストをスキップします。"
fi

echo ""
echo "✅ スクラップ＆ビルド（環境復元）がすべて完了しました！"
echo "🪟 Windows 版 Orca IDE の設定を反映する場合は: apply-orca-windows-settings"
echo "🐳 Docker / GPU を使うマシンでは: configure-machine && setup-optional"
