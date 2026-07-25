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
        if sudo -n true 2>/dev/null; then
            SUDO_CMD="sudo -n"
        elif [ "${NONINTERACTIVE:-0}" != "1" ] && [ -t 0 ]; then
            echo "🔐 sudo requires a password. Please authenticate:" >&2
            sudo -v
            SUDO_CMD="sudo"
        else
            echo "❌ ERROR: sudo password required but running in non-interactive mode." >&2
            exit 1
        fi
    else
        echo "❌ ERROR: Root access or functional sudo is required." >&2
        exit 1
    fi
fi

wait_for_apt() {
    while :; do
        local locked=0
        for lock in /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock; do
            if command -v fuser >/dev/null 2>&1; then
                if $SUDO_CMD fuser "$lock" >/dev/null 2>&1; then locked=1; break; fi
            elif command -v lsof >/dev/null 2>&1; then
                if $SUDO_CMD lsof "$lock" >/dev/null 2>&1; then locked=1; break; fi
            else
                # fuserもlsofもない場合はロックファイルを直接検証（不完全だがハングは防げる）
                if $SUDO_CMD test -f "$lock" && [ "$($SUDO_CMD stat -c %s "$lock" 2>/dev/null || echo 0)" -gt 0 ]; then locked=1; break; fi
            fi
        done
        [ "$locked" -eq 0 ] && break
        echo "⏳ Waiting for apt lock to be released (unattended-upgrades might be running)..."
        sleep 5
    done
}

echo "⚙️  1. WSLシステム設定と基本ライブラリの事前チェック..."

# 1. WSL /etc/wsl.conf の準備
if [ ! -f /etc/wsl.conf ] || ! grep -q "^systemd=true" /etc/wsl.conf 2>/dev/null || ! grep -q "^appendWindowsPath=false" /etc/wsl.conf 2>/dev/null; then
    echo "🔧 /etc/wsl.conf の冪等な構成変更を実行中..."
    # [boot] ブロックの追加と systemd=true
    $SUDO_CMD bash -c 'grep -q "^\[boot\]" /etc/wsl.conf 2>/dev/null || echo -e "\n[boot]" >> /etc/wsl.conf'
    $SUDO_CMD bash -c 'grep -q "^systemd=true" /etc/wsl.conf 2>/dev/null || awk "/^\[boot\]/ && !x {print; print \"systemd=true\"; x=1; next} 1" /etc/wsl.conf > /etc/wsl.conf.tmp && mv /etc/wsl.conf.tmp /etc/wsl.conf'
    # [interop] ブロックの追加と appendWindowsPath=false
    $SUDO_CMD bash -c 'grep -q "^\[interop\]" /etc/wsl.conf 2>/dev/null || echo -e "\n[interop]" >> /etc/wsl.conf'
    $SUDO_CMD bash -c 'grep -q "^appendWindowsPath=false" /etc/wsl.conf 2>/dev/null || awk "/^\[interop\]/ && !x {print; print \"appendWindowsPath=false\"; x=1; next} 1" /etc/wsl.conf > /etc/wsl.conf.tmp && mv /etc/wsl.conf.tmp /etc/wsl.conf'
fi

# 2. パッケージ更新と基本ツールの確保
echo "📦 パッケージリストを更新し git / curl を確認中..."
export DEBIAN_FRONTEND=noninteractive
APT_OPTS=(-o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold")
wait_for_apt
$SUDO_CMD apt update -qq && wait_for_apt && $SUDO_CMD apt install -y "${APT_OPTS[@]}" git curl

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
