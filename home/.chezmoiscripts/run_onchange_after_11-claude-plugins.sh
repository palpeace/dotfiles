#!/bin/sh
# Claude Code の user スコープのプラグインを、この宣言から入れる。
# 登録先は ~/.claude/settings.json（extraKnownMarketplaces / enabledPlugins）で、
# modify_settings.json は宣言したキーしか触らないので apply で消えない。
# ただし新しいマシンでは空から始まり、プラグインの実体も CLI でしか入らないので、ここで入れる。
#
# - 無効化したもの（enabled:false）は入れ直さない。
# - 版は固定できない。更新は `claude plugin update <id>`。
# - 失敗したら非ゼロで終わる（run_onchange は成功するまで次の apply で再実行される）。
set -eu
PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
command -v claude >/dev/null 2>&1 || exit 0

failures=""

add_marketplace() { # <name> <source>
  if claude plugin marketplace list --json 2>/dev/null | jq -e --arg n "$1" 'any(.[]?; .name == $n)' >/dev/null; then
    return 0
  fi
  echo "==> marketplace を追加: $1（$2）"
  claude plugin marketplace add "$2" || failures="$failures marketplace:$1"
}

install_plugin() { # <id>
  if claude plugin list --json 2>/dev/null | jq -e --arg id "$1" 'any(.[]?; .id == $id)' >/dev/null; then
    return 0
  fi
  echo "==> プラグインを入れる: $1"
  # -y は stdin/stdout が端末でないときに必要。--scope の既定は user
  claude plugin install "$1" -y || failures="$failures plugin:$1"
}

# codex（OpenAI 公式）: Claude Code から codex を呼ぶ。使うには codex login が要る
add_marketplace openai-codex openai/codex-plugin-cc
install_plugin codex@openai-codex

# browse（Browserbase 公式、Stagehand の CLI）: ブラウザ操作のスキル。
# 本体の browse CLI は mise の npm:browse、ブラウザは setup-chrome が入れる Google Chrome。
# ローカルで動かす分には API キーは不要（BROWSERBASE_API_KEY はクラウド用）
add_marketplace browserbase browserbase/browse-plugin
install_plugin browse@browserbase

if [ -n "$failures" ]; then
  echo "warning: 失敗:$failures" >&2
  exit 1
fi
