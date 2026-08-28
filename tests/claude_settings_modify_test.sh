#!/usr/bin/env bash
# home/dot_claude/modify_settings.json の振る舞いテスト。
#
# このスクリプトは chezmoi apply で最初に評価されるターゲット (.claude/) にあり、
# 非ゼロ終了すると apply 全体がそこで中断する = .config/ .local/bin/ .zshrc が
# 1つも配置されない。つまり「ここが落ちない」ことは環境の再現性そのもの。
# settings.json は Claude Code が実行時に書くファイルなので、クラッシュや
# 書き込み途中で壊れた JSON になることが実際にある。
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

script="home/dot_claude/modify_settings.json"
failures=0

fail() { printf '  ❌ %s\n' "$1" >&2; failures=$((failures + 1)); }

# 壊れた入力でも exit 0 で返し、入力を素通しすること (apply を止めない)。
assert_passthrough() {
    local label="$1" input="$2" out status
    out="$(printf '%s' "$input" | sh "$script" 2>/dev/null)" && status=0 || status=$?
    if [ "$status" -ne 0 ]; then
        fail "$label: exit $status で終了した (apply 全体が中断する)"
    elif [ "$out" != "$input" ]; then
        fail "$label: 入力が素通しされていない (out=${out:0:40})"
    fi
}

# 有効な JSON では管理キーが適用され、実行時キーが保持されること。
assert_merged() {
    local label="$1" input="$2" out status
    out="$(printf '%s' "$input" | sh "$script")" && status=0 || status=$?
    if [ "$status" -ne 0 ]; then
        fail "$label: exit $status"
        return
    fi
    if ! printf '%s' "$out" | jq -e '.statusLine.type == "command"' >/dev/null 2>&1; then
        fail "$label: 管理キー statusLine が適用されていない"
    fi
    if ! printf '%s' "$out" | jq -e '.disableAgentView == true' >/dev/null 2>&1; then
        fail "$label: 管理キー disableAgentView が適用されていない"
    fi
}

if ! command -v jq >/dev/null 2>&1; then
    printf 'claude settings modify checks skipped (jq not installed)\n'
    exit 0
fi

# --- 正常系 -----------------------------------------------------------
assert_merged "空オブジェクト" '{}'
assert_merged "実行時キーあり" '{"model":"opus[1m]","effortLevel":"xhigh","fastMode":true}'

# 実行時キーが消えないこと。これが消えると apply のたびにモデル選択が戻る。
out="$(printf '%s' '{"model":"opus[1m]","effortLevel":"xhigh","fastMode":true}' | sh "$script")"
for k in model effortLevel fastMode; do
    printf '%s' "$out" | jq -e "has(\"$k\")" >/dev/null 2>&1 || fail "実行時キー $k が消えた"
done

# --- 壊れた入力でも apply を止めないこと (回帰テスト) -------------------
assert_passthrough "書き込み途中で切れた JSON" '{"model": "opus",'
assert_passthrough "JSON ではない"             'not json at all'
assert_passthrough "括弧だけ"                  '{{{'
assert_passthrough "末尾にゴミ"                '{"a":1} trailing garbage'
# jq の `. * {}` はオブジェクト以外で失敗する。これらも有効な JSON なので通す。
assert_passthrough "null"                      'null'
assert_passthrough "配列"                      '[]'
assert_passthrough "数値"                      '123'
assert_passthrough "文字列"                    '"string"'

# 壊れた入力でも部分出力を書かないこと。jq は末尾ゴミの前までを stdout へ
# 吐いてから失敗するため、パイプ直結だと切り詰めた JSON を書いてしまう。
out="$(printf '%s' '{"a":1} trailing garbage' | sh "$script" 2>/dev/null)"
[ "$out" = '{"a":1} trailing garbage' ] || fail "末尾ゴミ入力で部分出力を書いた (out=${out:0:40})"

# --- 空入力 -----------------------------------------------------------
out="$(printf '' | sh "$script")"
printf '%s' "$out" | jq -e . >/dev/null 2>&1 || fail "空入力で有効な JSON を返さなかった"

# --- jq 不在の環境 (初回 bootstrap 相当) -------------------------------
slim="$(mktemp -d)"
trap 'rm -rf "$slim"' EXIT
for b in sh cat command printf; do
    p="$(command -v "$b" 2>/dev/null)" && ln -sf "$p" "$slim/$b"
done
out="$(printf '%s' '{"model":"x"}' | env PATH="$slim" sh "$script" 2>/dev/null)" && status=0 || status=$?
[ "${status:-0}" -eq 0 ] || fail "jq 不在で exit $status"
[ "$out" = '{"model":"x"}' ] || fail "jq 不在で素通しされなかった (out=$out)"

if [ "$failures" -gt 0 ]; then
    printf '%d 件の claude settings modify チェックが失敗しました\n' "$failures" >&2
    exit 1
fi
printf 'claude settings modify checks passed\n'
