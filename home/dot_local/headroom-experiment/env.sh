# headroom 実験用 env（状態を実験ディレクトリ配下に固定＝aide repo/chezmoi を汚さない）
export HEADROOM_CONFIG_DIR="$HOME/.local/headroom-experiment/state/config"
export HEADROOM_WORKSPACE_DIR="$HOME/.local/headroom-experiment/state/workspace"
export HEADROOM_SAVINGS_PATH="$HOME/.local/headroom-experiment/state/savings.json"
export HEADROOM_SUBSCRIPTION_STATE_PATH="$HOME/.local/headroom-experiment/state/subscription.json"
# mode は用途で選ぶ（2026-06-10 A/B 実測）:
#   token = 実際に圧縮(tool 出力 ~55%・忠実度OK)。コンテキスト窓を稼ぐならこれ。ただし cache を壊す設計。
#   cache = prefix 凍結のみで圧縮 0。cache 温存だけ欲しい時。
# 既定は token（圧縮の恩恵を得るため）。CLAUDE_HR_MODE=cache で上書き可。
export HEADROOM_MODE="${CLAUDE_HR_MODE:-token}"
