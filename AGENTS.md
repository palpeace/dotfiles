# Repository Notes

## Repository role

- This repository is a chezmoi source directory for the user's local environment.
- Treat files in this repository as the source of truth for managed dotfiles and setup scripts.

## Managed areas

- Shell configuration: `home/dot_zshrc`
- Git configuration: `home/dot_gitconfig.tmpl`
- Prompt and tool configuration: `home/dot_config/starship.toml`, `home/dot_config/mise/config.toml`, `home/dot_config/sheldon/plugins.toml`
- Editor configuration: `home/dot_config/micro/settings.json`
- Local helper scripts: `home/dot_local/bin/...`
- Setup hooks and bootstrap helpers: `home/.chezmoiscripts/...`

## Edit policy

- Before editing a dotfile or app config, first check whether a corresponding managed file exists in this repository under `home/...`.
- When changing dotfiles or app configuration, edit the chezmoi-managed source file in this repo first, not the live file under `$HOME`.
- Prefer paths in this repository such as `home/dot_config/...`, `home/dot_local/...`, and `home/.chezmoiscripts/...`.
- Only edit the live file in `$HOME` directly when the user explicitly asks for it or when the file is not managed by chezmoi.
- If both a live file and a chezmoi-managed source file exist, treat the file in this repository as the source of truth.

## 管理対象外 (このリポジトリに置かないもの)

- `.wslconfig`: Windows 側 (`%USERPROFILE%`) のファイルで、WSL 内の chezmoi からは配置経路が無い。
  過去に `assets/wslconfig/` へ置いていたが、配置されないまま Windows 側の実物とドリフトしたため削除した。
  設定内容は README の Quick Start Step 0 に手順として記載する。
- Windows Terminal の `settings.json`: 同上。実体は
  `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`。
  `/mnt/c/...` 経由で書けはするが、`.wslconfig` と同じくドリフトするので管理対象にしない。
  設定内容は README の Quick Start Step 0 に手順として記載する。

## chezmoi の落とし穴

- スクリプトをテンプレート化できるのは **`.tmpl` 拡張子のみ**。`# chezmoi:template` のような
  コメント指示子は存在せず、書いても `{{ }}` は展開されない。`run_onchange_` でこれをやると
  ハッシュが永久に固定され、初回 apply 以降二度と再実行されなくなる。
- `chezmoi execute-template` は拡張子に関係なく強制展開するため、この誤りの検証には使えない。
- apply は最初に失敗したターゲットで**全体が中断**する。辞書順で早い `.claude/` 配下が失敗すると
  `.config/` 以降が一切配置されない。`modify_` スクリプトの外部コマンド依存は特に危険。

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
  - *※ 人間はコードを書かない「企画者」ですが、AIエージェントの監督やターミナル操作において「状況認識能力と機動力」は必須です。そのため、ターミナルUXを向上させるこれらのモダンCLI群は「IDE等のプログラミング肥大化ツール」とは明確に区別し、積極的にグローバルに配置します。*
- AIネイティブ環境でのレビュー・指示用ツール (micro, gitui, oxker, yazi, prettier, markdownlint-cli2)
- パッケージマネージャ・タスクランナー (pnpm, uv, just)

### プロジェクトの mise.toml に置くもの

- 特定言語のビルド・実行ツール (bacon, cargo-make, cargo-nextest 等)
- プロジェクト固有のツールチェイン
- チームで揃えるバージョンが重要なツール

### 判断基準

1. 「どのプロジェクトを開いても動いてほしいか？」→ Yes ならグローバル
2. 「AIへの指示（micro）やレビュー（gitui, oxker, yazi）に必要か？」→ Yes ならグローバル
3. 「プリビルトバイナリがあるか？」→ No (cargo build 必須) なら PJ 側を優先し、グローバルには原則置かない

### ツール選定の注意

- aqua バックエンドのツールは、対象プラットフォーム向けのプリビルトバイナリが GitHub Releases に存在することを確認してから追加する。リリースからバイナリが消えるケースがあるため注意。
- `cargo:` バックエンドはビルドが必要なため、グローバルには原則置かない。プロジェクトの `mise.toml` で管理する。

## Setup scripts の設計方針

### エラーハンドリング

- `setup-system`: ランタイム (rust, node, go, python) のインストール失敗は致命的なので即停止する。残りのツール (mise install, Claude Code, Antigravity CLI) は失敗を記録して続行し、最後にまとめて報告する。
- `update-system`: `set -e` を使わない。各ステップ (apt, rustup, mise upgrade, sheldon, claude, agy) を個別にエラーハンドリングし、失敗しても次へ進む。最後に失敗一覧を報告する。
- `bootstrap.sh`: `setup-system` が失敗した場合、dotfiles は配置済みであることを伝え、`setup-system` の再実行を案内する。

### mise のインストール順序

mise は `npm:` → `node`、`cargo:` → `rust`、`go:` → `go` のような暗黙のバックエンド依存を自動解決しない。`setup-system` ではランタイムを `--jobs=1` で先にインストールしてから、残りのツールを並列インストールする。
