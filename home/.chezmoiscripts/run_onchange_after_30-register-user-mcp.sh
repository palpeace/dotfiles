#!/usr/bin/env bash
# user スコープの MCP サーバを、宣言（このファイル）から復元する。
#
# ## なぜ dotfiles が持つのか
#
# **user スコープの登録は `~/.claude.json` にしか書かれず、そこは chezmoi 管理外**なので
# WSL を作り直すと消える。project スコープ（repo 直下の `.mcp.json`）は clone で戻るが、
# **「どのプロジェクトでも同じ意味を持つ道具」は repo に紐づけられない**ので、ここが唯一の
# 置き場になる。判断の軸（実体 / 登録 / 前提の3つ）は agex の
# bundles/meta/environment.md「MCPサーバの置き場は3つの軸で決まる」。
#
# ## ファイルを直接書かない
#
# `~/.claude.json` は CC が実行時に書く 60KB のファイルで、キャッシュとプロジェクト履歴が
# 混ざる。`modify_` で書く方式（~/.claude/settings.json と同じ）は理屈上できるが、
# 壊した時に失うものが大きい。**公式CLI経由にして、形式が変わっても追随する。**
# `claude mcp add` に `--force` 相当は無い（実測）ので、`claude mcp get` の存在確認と組にする。
#
# ## この対策が効かない範囲
#
# - **`claude mcp get` は project スコープの同名も見つける。** 同じ名前が repo 側の
#   `.mcp.json` にあると、user へは登録されないまま「登録済み」と出る。名前を衝突させない。
# - **並行セッションと競合しうる。** `claude mcp add` は `~/.claude.json` を
#   read-modify-write するので、CC が動いている最中に走ると取りこぼしうる。
#   run_onchange なので**このファイルを変えた時しか走らない**が、ゼロではない。
# - **登録できたことと、サーバが動くことは別。** 確認は `claude mcp list`（健全性まで見る）。
set -euo pipefail
PATH="$HOME/.local/bin:$PATH"

if ! command -v claude >/dev/null 2>&1; then
    echo "⏭️  claude が無いので user スコープの MCP 登録を飛ばす"
    exit 0
fi

# **失敗したら非ゼロで落ちる。** run_onchange は実行された時点で「済み」として
# 記録されるので、ここで握り潰すと**初回に失敗した登録が二度と再試行されない**
# （型 silent-success）。落とせば apply が失敗として報告し、次の apply で再実行される。
failures=()

register() {
    local name="$1"
    shift
    if claude mcp get "$name" >/dev/null 2>&1; then
        echo "⏭️  MCP '$name' は登録済み"
        return 0
    fi
    echo "🔌 MCP を user スコープへ登録: $name"
    if ! claude mcp add --scope user "$name" -- "$@"; then
        echo "⚠️  MCP '$name' の登録に失敗した" >&2
        failures+=("mcp:$name")
    fi
}

# --- Playwright（ブラウザ操作。どのプロジェクトでも意味を持つので user）---
#
# **手元のブラウザを --executable-path で指すので、MCP 側にダウンロードさせない。**
# akm-viewer が playwright-core 1.62.0 で使っている build をそのまま共有する
# （MCP が要求する版とずれていても executable-path が優先される。2026-09-08 実測）。
# 無ければ指定を省く —— その場合 MCP が初回に自分で取りに行く。
playwright_chromium="$(ls -d "$HOME"/.cache/ms-playwright/chromium-*/chrome-linux64/chrome 2>/dev/null | sort -V | tail -1 || true)"
playwright_args=(npx -y "@playwright/mcp@0.0.80" --headless --isolated)
if [ -n "$playwright_chromium" ]; then
    playwright_args+=(--executable-path "$playwright_chromium")
else
    echo "ℹ️  ms-playwright のブラウザが無いので --executable-path を省く（初回に MCP が取得する）"
fi

# **--allow-unrestricted-file-access は付けない。** 既定では file:// が
# ワークスペース（CC が渡す root）の中に制限される。安全側の既定なので崩さない
# —— 付けないと外の file:// が開けないことは実測済みで、それは仕様どおりの挙動。
register playwright "${playwright_args[@]}"

# --- 入れていないもの（判断を残す）---
#
# **codex**: **MCP では入れない。** `codex mcp-server` は動く（ツールは `codex` /
#   `codex-reply` の2本）が非推奨で、**公式の後継は MCP ではなく Claude Code の
#   プラグイン** `openai/codex-plugin-cc`（`@openai/codex-mcp` という npm パッケージは
#   存在しない。2026-09-08 実測）。**受け皿はこのファイルではなく
#   `~/.claude/settings.json` の `enabledPlugins`** で、そちらは modify_settings.json が
#   既に管理している。**引き金**: ChatGPT のサブスクが開通したら入れる
#   （`/codex:setup` が `codex login` を要求する）。
# **agy**: **MCPサーバにならない。** `agy mcp` はサーバを"使う"側の管理
#   （add/remove/list/enable/disable）で、agy 自身を出す口は無い（`--help` に
#   serve / stdio / mcp-server が無く、あるのは `mic-serve` だけ。実測）。

if [ ${#failures[@]} -gt 0 ]; then
    echo "⚠️  user スコープの MCP 登録に失敗が残った: ${failures[*]}" >&2
    exit 1
fi
