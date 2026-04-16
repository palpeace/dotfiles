# Repository Notes

## Repository role

- This repository is a chezmoi source directory for the user's local environment.
- Treat files in this repository as the source of truth for managed dotfiles and setup scripts.

## Managed areas

- Shell configuration: `home/dot_zshrc`, `home/dot_config/zsh-abbr/...`
- Git configuration: `home/dot_gitconfig.tmpl`
- Tmux configuration: `home/dot_tmux.conf`
- Prompt and tool configuration: `home/dot_config/starship.toml`, `home/dot_config/mise/config.toml`, `home/dot_config/sheldon/plugins.toml`
- Editor configuration: `home/dot_config/zed/settings.json.tmpl`
- Local helper scripts: `home/dot_local/bin/...`
- Setup hooks and bootstrap helpers: `home/.chezmoiscripts/...`

## Edit policy

- Before editing a dotfile or app config, first check whether a corresponding managed file exists in this repository under `home/...`.
- When changing dotfiles or app configuration, edit the chezmoi-managed source file in this repo first, not the live file under `$HOME`.
- Prefer paths in this repository such as `home/dot_config/...`, `home/dot_local/...`, and `home/.chezmoiscripts/...`.
- Only edit the live file in `$HOME` directly when the user explicitly asks for it or when the file is not managed by chezmoi.
- If both a live file and a chezmoi-managed source file exist, treat the file in this repository as the source of truth.

## Config organization

- For managed config files, prefer grouping entries by primary use rather than by installer backend or alphabetical order.
- When a file mixes sources such as `aqua:`, `npm:`, `cargo:`, or `go:`, keep the order natural for humans and use comments to explain purpose where needed.
- Keep comments short and practical. Prefer why the tool is present over repeating the tool name.
- Do not rely on config file ordering to satisfy runtime prerequisites. If `npm:` tools require Node or `cargo:` tools require Rust, make that explicit in setup scripts.

## Tool placement: global vs project-local

mise の `~/.config/mise/config.toml` (グローバル) に置くか、プロジェクトの `mise.toml` に置くかは以下で判断する。

### グローバルに置くもの

- ランタイム (rust, node, go, python): npm:/cargo:/go: バックエンドの前提になる
- シェル環境に統合されるツール (starship, sheldon, zoxide, fzf, atuin 等)
- どのディレクトリでも日常的に使う CLI (ripgrep, fd, bat, eza, jq, git 関連)
- エディタ (Zed リモート) が PATH から直接参照する LSP / formatter (pyright, gopls, taplo, marksman, prettier, markdownlint-cli2)
- パッケージマネージャ・タスクランナー (pnpm, uv, just)

### プロジェクトの mise.toml に置くもの

- 特定言語のビルド・実行ツール (bacon, cargo-make 等) — ただし cargo-nextest は `just check` で汎用的に使うためグローバル
- プロジェクト固有のツールチェイン
- チームで揃えるバージョンが重要なツール

### 判断基準

1. 「どのプロジェクトを開いても動いてほしいか？」→ Yes ならグローバル
2. 「Zed が PATH から参照するか？」→ Yes ならグローバル (LSP / formatter)
3. 「プリビルトバイナリがあるか？」→ No (cargo build 必須) なら PJ 側を優先し、グローバルには原則置かない

### ツール選定の注意

- aqua バックエンドのツールは、対象プラットフォーム向けのプリビルトバイナリが GitHub Releases に存在することを確認してから追加する。リリースからバイナリが消えるケースがある (例: tealdeer)。
- `cargo:` バックエンドはビルドが必要なため、グローバルには原則置かない。プロジェクトの `mise.toml` で管理する。

## Setup scripts の設計方針

### エラーハンドリング

- `setup-system`: ランタイム (rust, node, go, python) のインストール失敗は致命的なので即停止する。残りのツール (mise install, Claude Code, Kiro CLI) は失敗を記録して続行し、最後にまとめて報告する。
- `update-system`: `set -e` を使わない。各ステップ (apt, rustup, mise upgrade, sheldon, claude, kiro) を個別にエラーハンドリングし、失敗しても次へ進む。最後に失敗一覧を報告する。
- `bootstrap.sh`: `setup-system` が失敗した場合、dotfiles は配置済みであることを伝え、`setup-system` の再実行を案内する。

### mise のインストール順序

mise は `npm:` → `node`、`cargo:` → `rust`、`go:` → `go` のような暗黙のバックエンド依存を自動解決しない。`setup-system` ではランタイムを `--jobs=1` で先にインストールしてから、残りのツールを並列インストールする。
