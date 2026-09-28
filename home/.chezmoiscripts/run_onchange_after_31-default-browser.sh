#!/bin/sh
# xdg-open が開くリンクを、WSL の Chrome ではなく Windows のブラウザ（wslview）で開く。
# xdg-open は BROWSER より先に x-scheme-handler の既定を見るので、BROWSER=wslview（~/.zshenv）
# だけでは足りない。Google Chrome（setup-chrome）を入れると、その既定が Chrome になる。
# WSL の Chrome は browse が実行ファイルを直接起動して使うので、既定を変えても影響しない。
# 書き込み先は ~/.config/mimeapps.list（Claude Code も書くので、chezmoi では管理しない）。
set -eu
command -v xdg-mime >/dev/null 2>&1 || exit 0

for type in x-scheme-handler/http x-scheme-handler/https text/html; do
  xdg-mime default wslview.desktop "$type"
done
