#!/bin/sh
# 新しい WSL (Ubuntu) の復元スクリプト
#   curl -fsSL https://raw.githubusercontent.com/palpeace/dotfiles/main/bootstrap.sh | sh
# 何度実行しても同じ結果になる（入っているものは飛ばす）。
set -eu

REPO="palpeace/dotfiles"
MISE="$HOME/.local/bin/mise"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# パイプ実行時に子プロセスがスクリプト本体を読み込まないよう、全体を関数にして最後に呼ぶ
main() {
  # 1. apt パッケージ（zsh と前提コマンド）
  pkgs=""
  for p in zsh git curl; do
    command -v "$p" >/dev/null 2>&1 || pkgs="$pkgs $p"
  done
  if [ -n "$pkgs" ]; then
    log "apt install:$pkgs"
    # 新しい WSL は起動直後に自動更新が apt を掴んでいることがあるので、ロックを最大5分待つ
    sudo apt-get -o DPkg::Lock::Timeout=300 update </dev/null
    # shellcheck disable=SC2086
    sudo apt-get -o DPkg::Lock::Timeout=300 install -y $pkgs </dev/null
  fi

  # 2. ログインシェルを zsh に
  zsh_path="$(command -v zsh)"
  if [ "$(getent passwd "$(id -un)" | cut -d: -f7)" != "$zsh_path" ]; then
    log "login shell -> $zsh_path"
    sudo chsh -s "$zsh_path" "$(id -un)"
  fi

  # 3. タイムゾーン（新しい WSL でも日本時間にする）
  if [ "$(readlink -f /etc/localtime)" != "/usr/share/zoneinfo/Asia/Tokyo" ]; then
    log "timezone -> Asia/Tokyo"
    sudo timedatectl set-timezone Asia/Tokyo 2>/dev/null \
      || sudo ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
  fi

  # 4. 作業場所（global_rules.md が ~/repos を指定している）
  mkdir -p "$HOME/repos"

  # 5. mise
  if [ ! -x "$MISE" ]; then
    log "install mise"
    curl -fsSL https://mise.run | sh
  fi

  # 6. chezmoi で dotfiles を展開する。
  #    mise のツール、AI エージェント CLI（claude / codex / agy）、補完なども
  #    apply の中のスクリプトが入れる（宣言を書いて apply すれば揃う形にするため）。
  log "chezmoi init --apply $REPO"
  "$MISE" exec chezmoi@latest -- chezmoi init --apply "$REPO" </dev/null

  log "done. 残りは認証だけ（手で行う）:"
  cat <<'EOF'
  1. 新しい端末を開く（zsh で起動する）
  2. gh auth login
  3. claude / codex / agy をそれぞれ一度起動してログインする
  4. 仕事用の git 設定が必要なら ~/.gitconfig.work を作る（リポジトリには入れない）
EOF
}

main "$@"
