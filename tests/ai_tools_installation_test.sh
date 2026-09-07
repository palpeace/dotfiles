#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

assert_contains() {
    local path="$1"
    local pattern="$2"
    grep -Fq "$pattern" "$path" || {
        printf 'expected %s to contain: %s\n' "$path" "$pattern" >&2
        exit 1
    }
}

assert_not_contains() {
    local path="$1"
    local pattern="$2"
    ! grep -Fq "$pattern" "$path" || {
        printf 'expected %s not to contain: %s\n' "$path" "$pattern" >&2
        exit 1
    }
}

# Ensure AI CLI tools are NOT managed via mise's config.toml (since they are custom-installed/updated)
assert_not_contains "home/dot_config/mise/config.toml" '"npm:@anthropic-ai/claude-code" = "latest"'
assert_not_contains "home/dot_config/mise/config.toml" '"npm:@google/gemini-cli" = "latest"'
# codex は npm 版 (@openai/codex) も実在するが、`codex update` が自分の入れ方を
# 検出して更新するので mise のピンと二重になる。標準インストーラ側に寄せる。
assert_not_contains "home/dot_config/mise/config.toml" '@openai/codex'

# --- Claude Code Checks ---
assert_contains "home/dot_local/bin/executable_setup-system" 'https://claude.ai/install.sh'
assert_contains "home/dot_local/bin/executable_setup-system" 'if ! command -v claude >/dev/null 2>&1; then'

assert_contains "home/dot_local/bin/executable_update-system" 'if command -v claude >/dev/null 2>&1; then'
assert_contains "home/dot_local/bin/executable_update-system" 'claude update'
assert_not_contains "home/dot_local/bin/executable_update-system" 'https://claude.ai/install.sh'

# --- Antigravity CLI Checks ---
assert_contains "home/dot_local/bin/executable_setup-system" 'https://antigravity.google/cli/install.sh'
assert_contains "home/dot_local/bin/executable_setup-system" 'if ! command -v agy >/dev/null 2>&1; then'

assert_contains "home/dot_local/bin/executable_update-system" 'if command -v agy >/dev/null 2>&1; then'
assert_contains "home/dot_local/bin/executable_update-system" 'agy update'
assert_not_contains "home/dot_local/bin/executable_update-system" 'https://antigravity.google/cli/install.sh'

# --- Codex CLI Checks ---
assert_contains "home/dot_local/bin/executable_setup-system" 'https://chatgpt.com/codex/install.sh'
assert_contains "home/dot_local/bin/executable_setup-system" 'if ! command -v codex >/dev/null 2>&1; then'

assert_contains "home/dot_local/bin/executable_update-system" 'if command -v codex >/dev/null 2>&1; then'
assert_contains "home/dot_local/bin/executable_update-system" 'codex update'
assert_not_contains "home/dot_local/bin/executable_update-system" 'https://chatgpt.com/codex/install.sh'

# --- グローバル指示が3本すべてに届くか ---
# 実体は1つ (home/dot_config/ai-rules/global_rules.md) で、CLIごとに symlink が要る。
# CLIを足したのに symlink を忘れると、そのCLIだけ規範なしで動く（エラーは出ない）。
for link_src in home/dot_claude/symlink_CLAUDE.md \
    home/dot_codex/symlink_AGENTS.md \
    home/dot_config/antigravity/symlink_instructions.md; do
    assert_contains "$link_src" 'ai-rules/global_rules.md'
done

# --- PATH ブロックの追記を招かない前提 ---
# codex の公式インストーラは $HOME/.local/bin が PATH に無いと ~/.zshrc へ
# `# >>> Codex installer >>>` を書き足す。~/.zshrc は chezmoi 管理下なので、
# setup-system が先頭で PATH を通していることが「書かれない」条件になる。
assert_contains "home/dot_local/bin/executable_setup-system" 'PATH="$HOME/.local/bin:${PATH:-'
assert_not_contains "home/dot_zshrc" 'Codex installer'




printf 'AI tools installation checks passed\n'
