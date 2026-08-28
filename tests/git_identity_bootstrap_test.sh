#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

identity_script="home/.chezmoiscripts/run_once_after_10-setup-identities.sh.tmpl"

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
    if grep -Fq "$pattern" "$path"; then
        printf 'did not expect %s to contain: %s\n' "$path" "$pattern" >&2
        exit 1
    fi
}

assert_contains "home/dot_gitconfig.tmpl" 'path = ~/.gitconfig.local'
assert_not_contains "home/dot_gitconfig.tmpl" '[includeIf "gitdir:~/work/"]'

assert_not_contains "home/dot_gitconfig.tmpl" 'ssh://git@github.com/'

assert_contains "home/.chezmoiscripts/run_once_after_10-setup-identities.sh.tmpl" 'prompt_value'
assert_contains "home/.chezmoiscripts/run_once_after_10-setup-identities.sh.tmpl" 'self_gitconfig_path'

assert_not_contains "home/.chezmoiscripts/run_once_after_10-setup-identities.sh.tmpl" 'ssh-keygen'

assert_contains "home/dot_local/bin/executable_setup-system" 'require_github_cli_auth'
assert_not_contains "home/dot_local/bin/executable_setup-system" 'ssh-keyscan'

# 防御に寄与せず正常な入力だけを壊していた (例: "GEOFFREY" -> "GFREY")。
# 改行除去だけで注入は成立しないため、復活させないこと。
# 経緯を説明したコメント自体はこの文字列を含むので、コード行だけを見る。
if grep -v '^[[:space:]]*#' "$identity_script" | grep -Fq "sed 's/EOF//g'"; then
    printf 'did not expect %s to reintroduce: %s\n' "$identity_script" "sed 's/EOF//g'" >&2
    exit 1
fi

# --- 振る舞いテスト: 生成される既定アドレスが常に妥当であること -----------
# ~/.gitconfig.local は run_once で作られ、一度書かれたら二度と直らない。
# 壊れた値が焼き付くと push が弾かれ、原因も分かりにくい。

failures=0
gen_identity() {
    # gen_identity <表示名> <ログイン名> -> "name|email" もしくは "" (未作成)
    local name="$1" login="$2" home
    home="$(mktemp -d)"
    (
        export HOME="$home" NONINTERACTIVE=1 USER="$login" GIT_AUTHOR_NAME="$name"
        unset GIT_AUTHOR_EMAIL
        bash "$identity_script" >/dev/null 2>&1
    )
    if [ -f "$home/.gitconfig.local" ]; then
        printf '%s|%s' \
            "$(sed -n 's/^[[:space:]]*name = //p' "$home/.gitconfig.local")" \
            "$(sed -n 's/^[[:space:]]*email = //p' "$home/.gitconfig.local")"
    fi
    rm -rf "$home"
}

assert_identity() {
    local label="$1" name="$2" login="$3" result generated_name generated_email
    result="$(gen_identity "$name" "$login")"
    if [ -z "$result" ]; then
        printf '  %s: ~/.gitconfig.local が作られませんでした\n' "$label" >&2
        failures=$((failures + 1))
        return
    fi
    generated_name="${result%%|*}"
    generated_email="${result#*|}"

    # 表示名は入力どおりに保存されること (加工して壊さない)。
    if [ "$generated_name" != "$name" ]; then
        printf '  %s: 表示名が変形された: %s -> %s\n' "$label" "$name" "$generated_name" >&2
        failures=$((failures + 1))
    fi
    # 既定アドレスは ASCII のローカルパート + @ドメイン であること。
    if ! printf '%s' "$generated_email" | grep -Eq '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'; then
        printf '  %s: 不正なメールアドレス: %s\n' "$label" "$generated_email" >&2
        failures=$((failures + 1))
    fi
}

assert_identity "複数語の表示名"     'Takumi Murai'  'tester'
assert_identity "大文字でEOFを含む"   'GEOFFREY'      'tester'
assert_identity "記号入り"           "O'Brien-Smith" 'tester'
assert_identity "非ASCIIのみ"        '山田太郎'       'tester'

# 表示名もログイン名も slug 化できないときは、壊れた値を焼き付けるより
# 「作らずに手動設定を案内する」のが正しい。
if [ -n "$(gen_identity '山田太郎' 'root')" ]; then
    printf '  非ASCII名 + root: 妥当な既定値が作れないのに書き込まれました\n' >&2
    failures=$((failures + 1))
fi

# 既に ~/.gitconfig.local がある場合は上書きしないこと (再実行時の保護)。
existing_home="$(mktemp -d)"
printf '[user]\n\tname = keep-me\n' > "$existing_home/.gitconfig.local"
HOME="$existing_home" bash "$identity_script" >/dev/null 2>&1
if ! grep -Fq 'keep-me' "$existing_home/.gitconfig.local"; then
    printf '  既存の ~/.gitconfig.local が上書きされました\n' >&2
    failures=$((failures + 1))
fi
rm -rf "$existing_home"

if [ "$failures" -gt 0 ]; then
    printf '%d 件の git identity チェックが失敗しました\n' "$failures" >&2
    exit 1
fi

printf 'git identity bootstrap checks passed\n'
