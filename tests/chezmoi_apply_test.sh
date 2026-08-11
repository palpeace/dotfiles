#!/usr/bin/env bash
# 実際に chezmoi apply を一時ディレクトリへ流し、まっさらな WSL でも
# 全ターゲットが配置されることを検証する。
# grep ベースの他テストと違い、ここだけが「実際に動くか」を見ている。
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

chezmoi_bin="$(command -v chezmoi 2>/dev/null || true)"
if [ -z "$chezmoi_bin" ]; then
    printf 'chezmoi apply checks skipped (chezmoi not installed)\n'
    exit 0
fi

# --- 静的チェック: テンプレート化の作法 ---------------------------------

# `# chezmoi:template` は存在しない指示子。これに頼るとハッシュが固定化し
# run_onchange が二度と発火しなくなる。
while IFS= read -r script; do
    if grep -q '{{' "$script" && [[ "$script" != *.tmpl ]]; then
        printf 'template syntax in a non-.tmpl script (will NOT be expanded): %s\n' "$script" >&2
        exit 1
    fi
done < <(find home/.chezmoiscripts -type f)

# --- 動的チェック: jq 不在のまっさらな環境で apply が通るか -------------

test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
mkdir -p "$test_root/dest" "$test_root/cfg" "$test_root/slim"

# 新規 WSL 相当の最小 PATH を作る。jq は mise 経由 (= setup-system 内) でしか
# 入らないため、apply 時点では存在しない状況を再現する。
for b in bash sh cat sed grep ls uname git curl mkdir chmod ln rm cp mv tr head tail awk find sort; do
    p="$(command -v "$b" 2>/dev/null)" && ln -sf "$p" "$test_root/slim/$b"
done

if env PATH="$test_root/slim" sh -c 'command -v jq' >/dev/null 2>&1; then
    printf 'test setup error: jq leaked into the minimal PATH\n' >&2
    exit 1
fi

# scripts は除外する (setup-system を実際に走らせないため)。
if ! env -i HOME="$test_root/dest" PATH="$test_root/slim" "$chezmoi_bin" \
    --source "$repo_root" \
    --destination "$test_root/dest" \
    --config "$test_root/cfg/none.toml" \
    --persistent-state "$test_root/cfg/state.boltdb" \
    apply --force --exclude=scripts; then
    printf 'chezmoi apply failed on a jq-less (freshly installed) environment\n' >&2
    exit 1
fi

# apply は最初の失敗ターゲットで中断するため、辞書順で後ろにあるものほど
# 「配置されたこと」の証拠価値が高い。
expected_targets=(
    .claude/settings.json
    .config/mise/config.toml
    .config/sheldon/plugins.toml
    .config/starship.toml
    .gitconfig
    .local/bin/setup-system
    .local/bin/claude-statusline
    .zshenv
    .zshrc
)

for target in "${expected_targets[@]}"; do
    if [ ! -f "$test_root/dest/$target" ]; then
        printf 'expected target was not applied: ~/%s\n' "$target" >&2
        exit 1
    fi
done

# symlink_ ターゲットは参照先まで配置されて初めて意味を持つ。
for link in .claude/CLAUDE.md .config/antigravity/instructions.md; do
    if [ ! -e "$test_root/dest/$link" ]; then
        printf 'symlink target is dangling: ~/%s -> %s\n' \
            "$link" "$(readlink "$test_root/dest/$link" 2>/dev/null)" >&2
        exit 1
    fi
done

# 実行権限が落ちていると setup-system を呼ぶ after スクリプトが黙って何もしない。
for bin in setup-system update-system configure-machine setup-optional \
    setup-docker-engine claude-statusline; do
    if [ ! -x "$test_root/dest/.local/bin/$bin" ]; then
        printf 'helper script is not executable: ~/.local/bin/%s\n' "$bin" >&2
        exit 1
    fi
done

printf 'chezmoi apply checks passed\n'
