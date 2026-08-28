#!/usr/bin/env bash
# =================================================================
# verify-in-docker.sh - まっさらな Ubuntu 24.04 で「環境の再現」を実証する
# =================================================================
# tests/chezmoi_apply_test.sh との違い:
#   - あちらは --source で「今の PATH のまま」apply する静的検証
#   - こちらは pristine なコンテナで git clone から chezmoi init --apply を通す
#     (= 新規 WSL でユーザーが実際に踏む経路)
#
# 検証するのは「dotfiles が配置されるか」であって、apt/mise の導入は既定では
# 走らせない (--full で走る)。ネットワークと数十分を使うため。
#
#   ./scripts/verify-in-docker.sh          # 高速レーン: 配置の再現性のみ
#   ./scripts/verify-in-docker.sh --full   # 全レーン: bootstrap.sh を丸ごと実行
#   ./scripts/verify-in-docker.sh --keep   # 失敗したコンテナを残して調査する
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FULL=0
KEEP=0
for arg in "$@"; do
    case "$arg" in
        --full) FULL=1 ;;
        --keep) KEEP=1 ;;
        -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) echo "unknown option: $arg" >&2; exit 2 ;;
    esac
done

command -v docker >/dev/null 2>&1 || { echo "docker が要る" >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "docker daemon が動いていない" >&2; exit 1; }

IMAGE="dotfiles-verify:base"

# --- ベースイメージ (初回のみビルド) -----------------------------------
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "🏗  ベースイメージを構築中 (初回のみ)..."
    docker build -q -t "$IMAGE" - >/dev/null <<'DOCKERFILE'
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
# 新規 WSL 相当の最小構成。jq は意図的に入れない (mise 経由でしか入らないため)。
RUN apt-get update -qq \
 && apt-get install -y -qq --no-install-recommends git curl ca-certificates sudo \
 && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash tester \
 && echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester
USER tester
WORKDIR /home/tester
# ホストとコンテナで UID がずれるため、検証用リポジトリの所有者チェックを免除する。
RUN git config --global --add safe.directory '*'
RUN BINDIR="$HOME/.local/bin" sh -c "$(curl -fsSL get.chezmoi.io)" >/dev/null
ENV PATH=/home/tester/.local/bin:$PATH
DOCKERFILE
fi

# --- 作業ツリーをそのまま「push 済みリポジトリ」として梱包 --------------
# HEAD ではなく現在の working tree を検証する。未コミットの修正を試すため。
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
tar -C "$repo_root" --exclude=.git -cf - . | tar -C "$stage" -xf -
git -C "$stage" init -q
git -C "$stage" add -A
git -C "$stage" -c user.email=v@example.com -c user.name=verify commit -qm "worktree snapshot"

case_index=0
run_case() {
    local name="$1"; shift
    local script="$1"; shift
    case_index=$((case_index + 1))
    printf '\n\033[1m▶ %s\033[0m\n' "$name"

    # --keep のときは終了後もコンテナを残し、中に入って調査できるようにする。
    local -a docker_args=(run -v "$stage:/srcrepo:ro")
    local container="dotfiles-verify-$$-$case_index"
    if [ "$KEEP" = 1 ]; then
        docker_args+=(--name "$container")
    else
        docker_args+=(--rm)
    fi

    if docker "${docker_args[@]}" "$IMAGE" bash -euo pipefail -c "$script"; then
        printf '\033[32m  ✅ PASS: %s\033[0m\n' "$name"
        [ "$KEEP" = 1 ] && printf '     調査: docker start -ai %s\n' "$container"
        return 0
    fi
    printf '\033[31m  ❌ FAIL: %s\033[0m\n' "$name"
    [ "$KEEP" = 1 ] && printf '     調査: docker start -ai %s\n' "$container"
    return 1
}

# 配置後に必ず揃っているべきもの。apply は最初の失敗ターゲットで中断するため、
# 「後ろのものが在る」ことが「全部通った」ことの証拠になる。
read -r -d '' ASSERT <<'ASSERT_EOF' || true
fail=0
for t in .claude/settings.json .config/mise/config.toml .config/sheldon/plugins.toml \
         .config/starship.toml .config/yazi/yazi.toml .config/herdr/config.toml \
         .gitconfig .zshenv .zshrc; do
    [ -f "$HOME/$t" ] || { echo "  未配置: ~/$t"; fail=1; }
done
for l in .claude/CLAUDE.md .config/antigravity/instructions.md; do
    [ -e "$HOME/$l" ] || { echo "  symlink が壊れている: ~/$l"; fail=1; }
done
for b in setup-system update-system configure-machine setup-optional \
         setup-docker-engine claude-statusline agy-run; do
    [ -x "$HOME/.local/bin/$b" ] || { echo "  実行権限が無い: ~/.local/bin/$b"; fail=1; }
done
[ "$fail" = 0 ] || exit 1
echo "  全ターゲット配置OK"
ASSERT_EOF

INIT='chezmoi init --apply --force --exclude=scripts file:///srcrepo'

failures=0

# --- ケース1: 完全にまっさらな新規 WSL (jq 不在) ------------------------
run_case "case1: pristine な新規環境 (jq 不在)" "
$INIT
$ASSERT
" || failures=$((failures + 1))

# --- ケース2: settings.json が壊れている (指摘#1 の回帰テスト) ----------
# Claude Code のクラッシュ / 書き込み途中 / ディスク満杯で普通に起きる状態。
# 現状はここで apply 全体が中断し、.zshrc も .config/ も一切配置されない。
run_case "case2: ~/.claude/settings.json が壊れている + jq 有り" "
sudo apt-get update -qq >/dev/null 2>&1 && sudo apt-get install -y -qq jq >/dev/null 2>&1
mkdir -p \"\$HOME/.claude\"
printf '{\"model\": \"opus\",' > \"\$HOME/.claude/settings.json\"
$INIT
$ASSERT
" || failures=$((failures + 1))

# --- ケース3: CC が実行時に書いたキーを apply が消さないこと ------------
run_case "case3: 実行時キー (model/effortLevel) が apply 後も残る" "
sudo apt-get update -qq >/dev/null 2>&1 && sudo apt-get install -y -qq jq >/dev/null 2>&1
mkdir -p \"\$HOME/.claude\"
printf '{\"model\":\"opus[1m]\",\"effortLevel\":\"xhigh\",\"fastMode\":true}' > \"\$HOME/.claude/settings.json\"
$INIT
$ASSERT
for k in model effortLevel fastMode; do
    jq -e \"has(\\\"\$k\\\")\" \"\$HOME/.claude/settings.json\" >/dev/null || { echo \"  実行時キーが消えた: \$k\"; exit 1; }
done
jq -e '.statusLine.type == \"command\"' \"\$HOME/.claude/settings.json\" >/dev/null || { echo '  管理キーが入っていない'; exit 1; }
echo '  実行時キー保持 + 管理キー適用OK'
" || failures=$((failures + 1))

# --- ケース4 (--full): bootstrap.sh を丸ごと ---------------------------
if [ "$FULL" = 1 ]; then
    echo ""
    echo "⏳ --full: apt/mise/AI CLI の実導入を含むため 15〜40 分かかる"
    run_case "case4: bootstrap.sh 全体 (apt + mise + AI CLI)" "
sudo chown -R tester /srcrepo 2>/dev/null || true
export CHEZMOI_REPO=file:///srcrepo NONINTERACTIVE=1 USE_JP_MIRROR=0
bash /srcrepo/scripts/bootstrap.sh
$ASSERT
command -v \$HOME/.local/share/mise/shims/rg >/dev/null || { echo '  mise ツールが入っていない'; exit 1; }
echo '  フルプロビジョニングOK'
" || failures=$((failures + 1))
fi

echo ""
if [ "$failures" -gt 0 ]; then
    echo "🚨 $failures 件のケースが失敗した"
    exit 1
fi
echo "✅ 全ケース PASS"
