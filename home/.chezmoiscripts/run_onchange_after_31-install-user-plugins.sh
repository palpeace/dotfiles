#!/usr/bin/env bash
# user スコープの Claude Code プラグインを、宣言（このファイル）から復元する。
#
# ## MCP（30番）とは受け皿が違う
#
# プラグインの登録は **`~/.claude/settings.json`** に落ちる —— marketplace は
# `extraKnownMarketplaces`、有効化は `enabledPlugins`（2026-09-08 実測）。
# **このファイルは chezmoi が modify_settings.json で管理している**ので、
# apply でキーが消えることは無い（管理キーを重ねるだけで既存キーを保つ）。
#
# **それでも宣言がここに要る。** 新しいマシンでは settings.json が空から始まり、
# modify_ の重ね合わせは管理キーしか書かないので、`extraKnownMarketplaces` も
# `enabledPlugins` も生まれない。**プラグインの実体（clone とキャッシュ）も
# CLI でしか入らない**ので、状態を作る側の手順がどこかに要る。
#
# ## この対策が効かない範囲
#
# - **無効化を上書きしない。** POが `claude plugin disable` したものは、
#   `plugin list --json` に残る（`enabled:false`）ので**再インストールされない**。
#   逆に言うと「入っているが無効」の状態はこのスクリプトでは直らない。
# - **版は固定していない。** `claude plugin install` は marketplace の最新を取る。
#   固定する口が CLI に無いため、**更新は `claude plugin update` を人が叩く**。
# - **入ったことと、使えることは別。** codex プラグインは `codex login` を要求する
#   （ChatGPT のサブスクが要る）。入っていても未ログインなら各コマンドは落ちる。
set -euo pipefail
PATH="$HOME/.local/bin:$PATH"

if ! command -v claude >/dev/null 2>&1; then
    echo "⏭️  claude が無いので user スコープのプラグイン導入を飛ばす"
    exit 0
fi

add_marketplace() {
    local name="$1" source="$2"
    if claude plugin marketplace list 2>/dev/null | grep -qE "^[[:space:]]*❯[[:space:]]+${name}$"; then
        echo "⏭️  marketplace '$name' は登録済み"
        return 0
    fi
    echo "🧩 marketplace を足す: $name（$source）"
    claude plugin marketplace add "$source" || echo "⚠️  marketplace '$name' の登録に失敗した" >&2
}

install_plugin() {
    local id="$1"
    if claude plugin list --json 2>/dev/null | jq -e --arg id "$id" 'any(.[]?; .id == $id)' >/dev/null 2>&1; then
        echo "⏭️  プラグイン '$id' は導入済み"
        return 0
    fi
    echo "🧩 プラグインを user スコープへ導入: $id"
    # -y: stdin/stdout が TTY でない時に必須。--scope の既定は user
    claude plugin install "$id" -y || echo "⚠️  プラグイン '$id' の導入に失敗した" >&2
}

# --- codex（OpenAI 公式。Claude Code から codex を呼ぶ）---
#
# **MCP ではない。** `codex mcp-server` は非推奨で、公式ドキュメントが名指しする
# Claude Code 向けの経路がこのプラグイン（`@openai/codex-mcp` という npm パッケージは
# 存在しない。2026-09-08 実測）。**MCPサーバを足さない**ので、道具の面は増えず、
# 入るのはスラッシュコマンドとスキルとサブエージェント。
# 常時の文脈コストは `claude plugin details codex@openai-codex` が出す（1.0.6 で ~449 tok）。
add_marketplace "openai-codex" "openai/codex-plugin-cc"
install_plugin "codex@openai-codex"
