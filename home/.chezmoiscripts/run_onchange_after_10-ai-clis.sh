#!/bin/sh
# 自己更新する AI エージェント CLI を公式インストーラで ~/.local/bin に入れる。
# mise に載せないのは、各 CLI の update と mise のバージョン管理が二重になるため。
# 更新は update-system が各 CLI の update サブコマンドで行う。
#
# インストーラはシェルの設定ファイルに PATH の行を書き足すことがある
# （agy は PATH が通っていても ~/.bashrc ~/.profile ~/.zprofile ~/.zshrc に無条件で足す）。
# 書き足しを止める指定が無いので、前後で退避して元に戻す。
set -eu
PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
export PATH
# codex のインストーラの質問（「Start Codex now?」など）を出さない。答えはすべて「いいえ」になる
export CODEX_NON_INTERACTIVE=1

failures=""
profiles=".bashrc .profile .zprofile .zshrc"
backup="$(mktemp -d)"
trap 'rm -rf "$backup"' EXIT

install() { # <command> <installer URL> <shell>
  command -v "$1" >/dev/null 2>&1 && return 0
  echo "==> install $1"
  for f in $profiles; do
    [ -f "$HOME/$f" ] && cp -p "$HOME/$f" "$backup/$f"
  done
  if ! curl -fsSL "$2" | "$3"; then
    failures="$failures $1"
  fi
  for f in $profiles; do
    if [ -f "$backup/$f" ]; then
      cat "$backup/$f" >"$HOME/$f"
      rm -f "$backup/$f"
    else
      rm -f "$HOME/$f" # インストーラが新しく作ったもの
    fi
  done
}

install claude https://claude.ai/install.sh bash
install codex https://chatgpt.com/codex/install.sh sh
install agy https://antigravity.google/cli/install.sh bash

if [ -n "$failures" ]; then
  echo "warning: install failed:$failures（次の chezmoi apply で再試行する）" >&2
  exit 1
fi
