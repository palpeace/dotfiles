#!/bin/bash

# ==============================================================================
# Bootstrap Script for Palpeace's Dotfiles
# ==============================================================================

# エラーハンドリングの強化
# -e: コマンドが失敗したら即終了
# -u: 未定義変数を使用したらエラー
# -o pipefail: パイプの途中でエラーがあれば検知
set -euo pipefail

# --- ログ出力用関数 ---
function log_info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}

function log_success() {
  echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

function log_warn() {
  echo -e "\033[1;33m[WARN]\033[0m $1"
}

# --- 1. 最小限の依存確認 ---
log_info "🚀 Starting bootstrap process..."

# cumkdir -prlはJustのインストーラー取得に必須
if ! command -v curl &>/dev/null; then
  log_warn "'curl' not found. Installing..."
  sudo apt update && sudo apt install -y curl
fi

# --- 2. Just (Task Runner) のインストール ---
# Rust環境には依存せず、公式のバイナリを直接配置する
if ! command -v just &>/dev/null; then
  log_info "Installing 'just' binary (to /usr/local/bin)..."

  # 公式スクリプトを使用
  # sudoを使用してシステム全体で使える場所 (/usr/local/bin) に配置
  curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin

  log_success "'just' installed successfully."
else
  log_info "'just' is already installed. Skipping."
fi

# --- 3. Justへのバトンタッチ ---
log_info "Handing over to Just..."

# スクリプトのあるディレクトリ（リポジトリルート）へ移動
# これにより、どこから実行しても正しくJustfileを読み込める
cd "$(dirname "$0")"

# Justを実行して本格的な環境構築を開始
# (Justfile内の 'setup' レシピが実行されます)
just setup

# ここで現在のシェルプロセスを新しいシェルに置き換える
# -l: ログインシェルとして起動し、確実に設定ファイルを読み込ませる
if command -v zsh >/dev/null; then
  exec zsh -l
fi
exec bash -l

# --- 完了 ---
# ここまで到達すれば成功
log_success "🎉 Bootstrap finished! Please restart your shell to apply changes."
