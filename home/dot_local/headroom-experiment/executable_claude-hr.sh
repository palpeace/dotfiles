#!/usr/bin/env bash
# claude-hr: Claude Code を headroom proxy 経由で起動する。
#   使い方: claude-hr [claude への引数...] / claude-hr stats / claude-hr stop
# 既定は token モード(圧縮の恩恵を取る)。cache モード(prefix 凍結)は CLAUDE_HR_MODE=cache で切替。詳細は env.sh。
# 状態は ~/.local/headroom-experiment 配下に固定(global/chezmoi/repo を汚さない)。
set -euo pipefail
ROOT="$HOME/.local/headroom-experiment"
PORT="${HEADROOM_PORT:-8787}"
HR="$ROOT/venv/bin/headroom"
# shellcheck disable=SC1091
source "$ROOT/env.sh"

proxy_pid() { ss -ltnp 2>/dev/null | grep ":$PORT " | grep -oE 'pid=[0-9]+' | head -1 | cut -d= -f2; }
proxy_ready() { curl -fsS -o /dev/null -m 2 "http://127.0.0.1:$PORT/readyz" 2>/dev/null; }

case "${1:-}" in
  stop)
    pid="$(proxy_pid)"; [ -n "$pid" ] && kill "$pid" && echo "stopped proxy (pid $pid)" || echo "no proxy on :$PORT"
    exit 0 ;;
  stats)
    curl -fsS -m 5 "http://127.0.0.1:$PORT/stats" | python3 -m json.tool
    exit 0 ;;
esac

MODE="${HEADROOM_MODE:-token}"   # token=圧縮(既定) / cache=prefix 凍結のみ。CLAUDE_HR_MODE で切替
if ! proxy_ready; then
  ( cd "$ROOT/state" && nohup "$HR" proxy --port "$PORT" --mode "$MODE" > "$ROOT/state/proxy.log" 2>&1 & )
  for _ in $(seq 1 20); do proxy_ready && break; sleep 0.5; done
  proxy_ready || { echo "proxy failed to start; see $ROOT/state/proxy.log" >&2; exit 1; }
fi
exec env ANTHROPIC_BASE_URL="http://127.0.0.1:$PORT" claude "$@"
