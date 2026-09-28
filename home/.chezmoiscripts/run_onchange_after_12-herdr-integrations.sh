#!/bin/sh
# herdr の公式連携（エージェントの SessionStart フック）を入れる。これがあると herdr サーバを
# 再起動しても、Claude Code・Codex・agy の会話が再開される（無いと新しいシェルに戻る）。
# 書き込み先は herdr が管理する（~/.claude/hooks/、~/.claude/settings.json の hooks、
# ~/.codex/hooks.json と config.toml、~/.gemini/config/hooks/ と hooks.json）。
# modify_settings.json は hooks に触れないので apply で消えない。
# Codex は次の起動で「Hooks need review」と聞くので、信頼する（しないとフックが動かない）。
#
# Codex の TUI は既定で共有のデーモン（app-server）につなぎ、フックはデーモンの中で動く。
# デーモンは最初に起動したペインの HERDR_PANE_ID を持ち続けるので、ほかのペインの会話が
# そのペインに記録されてしまう。daemon_auto_start を切り、TUI ごとに自分の中で動かす。
# 動いているデーモンは止めない（使っている Codex を切らないため）。止めるのは
# `codex app-server daemon stop`。
#
# - herdr の更新で連携の版が上がったときの入れ直しは update-system が受け持つ。
# - 失敗したら非ゼロで終わる（run_onchange は成功するまで次の apply で再実行される）。
set -eu
PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
command -v herdr >/dev/null 2>&1 || exit 0

failures=""
status="$(herdr integration status 2>/dev/null || true)"

install_integration() { # <herdr の連携名> <エージェントのコマンド>
  command -v "$2" >/dev/null 2>&1 || return 0
  printf '%s\n' "$status" | grep -q "^$1: current " && return 0
  echo "==> herdr の連携を入れる: $1"
  herdr integration install "$1" || failures="$failures $1"
}

install_integration claude claude
install_integration codex codex
install_integration antigravity-cli agy

if command -v codex >/dev/null 2>&1 &&
  ! codex features list 2>/dev/null | grep -Eq '^daemon_auto_start +[a-z]+ +false$'; then
  echo "==> codex の daemon_auto_start を切る"
  codex features disable daemon_auto_start || failures="$failures codex:daemon_auto_start"
fi

if [ -n "$failures" ]; then
  echo "warning: 失敗:$failures" >&2
  exit 1
fi
