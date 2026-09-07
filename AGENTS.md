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

- ランタイム (rust, node, python): npm:/cargo:/pipx: バックエンドの前提になる（`go` は 2026-09-07 に落とした。下の「ランタイムは使うバックエンドがあるものだけ」を見る）
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

- `setup-system`: ランタイム (rust, node, python) のインストール失敗は致命的なので即停止する。残りのツール (mise install, Claude Code, Codex CLI, Antigravity CLI) は失敗を記録して続行し、最後にまとめて報告する。
- `update-system`: `set -e` を使わない。各ステップ (apt, rustup, mise self-update, mise upgrade, sheldon, claude, codex, agy) を個別にエラーハンドリングし、失敗しても次へ進む。最後に失敗一覧を報告する。
- **`mise prune` は「消したと言わずに消さない」**(2026-09-07、mise 2026.8.5 実測)。`--dry-run` は uninstall を予告するのに素の実行は終了0で何もしない。`update-system` は prune の後に `mise ls --prunable` の残りを警告として出すだけにして、削除 (`mise uninstall <tool>@<version>`) は人の操作に残している。mise を上げたら再測する。
- `bootstrap.sh`: `setup-system` が失敗した場合、dotfiles は配置済みであることを伝え、`setup-system` の再実行を案内する。

### mise のインストール順序

mise は `npm:` → `node`、`cargo:` → `rust`、`go:` → `go` のような暗黙のバックエンド依存を自動解決しない。`setup-system` ではランタイムを `--jobs=1` で先にインストールしてから、残りのツールを並列インストールする。

**ランタイムは「使うバックエンドがあるものだけ」置く。** 2026-09-07 に `go` を落とした —— `go:` のツールも `go.mod` を持つプロジェクトも1つも無いのに 287MB を占めていた。`go:` のツールを足す時は `config.toml` と `setup-system` のランタイム列の**両方**に戻す（片方だけだと `mise install go` が版を解決できずに落ちる）。

## AI エージェント CLI の置き場

`claude` / `codex` / `agy` の3本は **mise に載せず `~/.local/bin` に置き、自己更新に任せる**（判断基準は `home/dot_config/ai-rules/global_rules.md` の「例外（自己更新型のAIエージェントCLI）」）。`setup-system` が公式インストーラで入れ、`update-system` が各CLIの `update` サブコマンドを叩く。

- **公式インストーラが `~/.zshrc` を書き換えうる。** codex のインストーラは `$HOME/.local/bin` が PATH に無いと判断すると、Linux + zsh では `~/.zshrc` に `# >>> Codex installer >>>` の PATH ブロックを追記する（`install.sh` の `pick_profile` / `add_to_path`）。`~/.zshrc` は chezmoi 管理下なので、**追記されると次の apply で消えて毎回書き戻るドリフト源になる**。`setup-system` は先頭で PATH に `$HOME/.local/bin` を入れているため `already on PATH` で何も書かない（2026-09-07 実測）。**この前提を崩さない。**
- **グローバル指示は1本を3箇所から symlink する。** 実体は `home/dot_config/ai-rules/global_rules.md` で、`home/dot_claude/symlink_CLAUDE.md` / `home/dot_codex/symlink_AGENTS.md` / `home/dot_config/antigravity/symlink_instructions.md` が同じファイルを指す。**CLIを足す時はこの symlink も足す** —— 無いとそのCLIだけ規範が届かない。
- **資格情報と実行時状態は `.chezmoiignore` で塞ぐ**（`**/.codex/auth.json` 等）。

## MCP サーバの登録

**`user` スコープのものだけ dotfiles が持つ。** `home/.chezmoiscripts/run_onchange_after_30-register-user-mcp.sh` が唯一の宣言で、他の3つの登録先には手を出さない。

| 登録先                     | 実体                                             | 誰が持つか                                    |
| -------------------------- | ------------------------------------------------ | --------------------------------------------- |
| `project`                  | リポジトリ直下の `.mcp.json`                     | **その repo**（コミットされるので clone で戻る） |
| **`user`**                 | `~/.claude.json` の `mcpServers`                 | **dotfiles**（chezmoi 管理外なので作り直すと消える） |
| `local`                    | `~/.claude.json` の `projects.<パス>.mcpServers` | 使わない                                      |
| アカウント側のコネクタ     | ローカルに無い                                   | claude.ai 側。**管理対象が存在しない**        |

- **判定は「そのプロジェクトの外で意味を持つか」。** repo の面やデータを触るもの（TickTick の特定リスト、部署DB）は `project`。ブラウザのような汎用の道具が `user`。
- **`~/.claude.json` を `modify_` で書かない。** CC が実行時に書く 60KB のファイルで、キャッシュとプロジェクト履歴が混ざる。公式CLI（`claude mcp add --scope user`）経由にして、形式が変わっても追随させる。`--force` 相当が無いので `claude mcp get` の存在確認と組で冪等にする。
- **ビルドが要るサーバ本体は dotfiles に置かない。** `~/repos/mcp/<name>` に clone し、`.mcp.json` から絶対パスで指す（`dist` を版管理しない repo なら、clone 後に build が要ることを agex 側に記録する）。
- 確認は `claude mcp list`（健全性まで見る）。
