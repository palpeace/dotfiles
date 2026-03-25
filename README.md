# 🚀 dotfiles

Modern, minimal, and AI-native development environment optimized for WSL2.

---

## 🛠 Features

- **Dotfiles Management**: [chezmoi](https://www.chezmoi.io/) - 冪等性を保った環境構築
- **Tool Management**: [mise](https://mise.jdx.dev/) - 言語・CLIツールのバージョン管理
- **Shell**: [Zsh](https://www.zsh.org/) + [Sheldon](https://sheldon.cli.rs/) (Plugin Manager)
- **Prompt**: [Starship](https://starship.rs/) - 2行構成 & 視認性重視の独自スタイル
- **AI Native**: Claude Code, GitHub Copilot, Gemini CLI, Kiro (Amazon Q) をプリインストール

## 📦 Quick Start (Restore)

新しい環境では、まず以下のコマンドでセットアップを開始します。初回セットアップでは、Git のユーザー情報などローカル専用の値を確認する対話入力があります。

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/palpeace/dotfiles/main/scripts/bootstrap.sh)"
```

この流れでは次を順に行います。

- `chezmoi apply` で dotfiles を配置
- `setup-system` で OS 依存と `mise` 管理ツールを導入
- ローカル専用の Git 設定と SSH 設定を対話形式で作成

## 🔒 Identity and SSH

公開リポジトリには個人情報を残さず、必要な値だけ初回セットアップで対話入力します。

- `~/.gitconfig.local`: self 用の既定アカウント
- `~/.gitconfig-work.local`: `~/work/` 配下のリポジトリ用の work アカウント
- `~/.ssh/config.local`: 必要に応じて追加するローカル SSH 設定
- SSH 秘密鍵はローカルマシンにのみ置く
- 初回セットアップでは不足している値だけを確認し、既存のローカルファイルは上書きしない

## 📋 Prerequisites

インストール前に、Windows側に以下のフォントを導入してください。これがないとアイコンが化けます。

- **Font**: [PlemolJP Nerd Font](https://github.com/yuru7/PlemolJP/releases) (NFM)
- **Terminal**: [Windows Terminal](https://aka.ms/terminal) 

## 🧰 Included Tools

| Category | Tools |
| :--- | :--- |
| **AI Agents** | Claude Code, Copilot, Gemini CLI, Kiro |
| **Editor** | Helix (hx) |
| **CLI Essentials** | fzf, ripgrep (rg), fd, eza, bat, zoxide (z) |
| **Modern Ops** | lazygit (lg), bottom (btm), xh, jq, dust |

## 📝 Maintenance

日々の運用は「dotfiles の同期」と「システム更新」を分けて扱います。

### Dotfiles を同期する

差分を確認してから反映する運用を基本にします。

```zsh
chezmoi diff
chezmoi apply
```

または helper を使います。

```zsh
sync-dotfiles
```

`sync-dotfiles` は dotfiles の差分確認と反映だけを行い、OS パッケージやツールの導入・更新は行いません。

別 PC で変更した dotfiles を取り込むときは次です。

```zsh
chezmoi update
chezmoi diff
```

`~/.zshrc` など managed file をローカルで直接編集した場合だけ `chezmoi re-add` を使います。

```zsh
chezmoi re-add ~/.zshrc
chezmoi cd
git add .
git commit -m "update: something"
git push
```

### 日々の開発コマンド

Zed のターミナルからは、まず次の 2 つを入口に使う想定です。

```zsh
# 今いるプロジェクトに応じて開発を開始
dev

# 今いるプロジェクトに応じて確認系コマンドをまとめて実行
check
```

挙動の優先順は次です。

- `Justfile` / `justfile` があり、対応する recipe がある: `just dev` / `just check`
- `package.json` / `pnpm-lock.yaml` / `turbo.json` がある: `pnpm dev`、`pnpm lint`、`pnpm typecheck`、`pnpm test`
- `Cargo.toml` / `Cargo.lock` がある: `bacon` または `cargo run`、`cargo fmt` / `clippy` / `cargo nextest`
- Markdown 中心のディレクトリ: `prettier` と `markdownlint-cli2`

シェル操作も次を前提に整えています。

- `Ctrl-R`: `fzf` ベースの履歴検索
- `Ctrl-J`: ディレクトリ候補からの移動
- `Tab`: 色付きの補完候補

### システム導入と更新

`chezmoi apply/update` では OS パッケージや `mise` ツールの導入は行いません。明示コマンドで実行します。
これらのコマンドは `sudo` とネットワーク接続を使います。

```zsh
# 新規導入・不足分のインストール
setup-system

# OS / mise 管理ツールの更新
update-system
```

必要なら従来どおりまとめて実行できます。

```zsh
# dotfiles の更新と system update をまとめて行うフル更新
update-dev
```

### Windows 側の Zed 設定

Windows 版 Zed を WSL からリモート利用する前提では、UI 設定の本体は Windows 側にあります。
この repo では source-of-truth を保持し、必要なときだけ明示的に Windows 側へ反映します。

```zsh
# dotfiles -> Windows
apply-zed-windows-settings

# Windows -> dotfiles
pull-zed-windows-settings
```

既存の `settings.json` / `keymap.json` がある場合は、反映前に `.bak.<timestamp>` を作成します。
WSL のユーザー名と Windows のユーザー名が異なる場合は、`WINDOWS_USER=<name>` を付けて実行します。

WSL 側の remote server 設定は `~/.config/zed/settings.json` を `chezmoi` で管理します。
ここには LSP の binary path や、remote 側で効かせたい言語設定だけを置きます。
このファイルは通常の `chezmoi apply` で反映されます。

LSP / formatter / lint は基本的に WSL 側の実行環境を使います。VS Code のように Windows 側へ拡張を追加する前提ではありません。
必要なツールは主に `mise` で管理し、Zed から見えない場合はまず `mise install` と `command -v <tool>` を確認します。
ただし `rust-analyzer` だけは Rust の標準運用に寄せて `rustup` / `cargo` 側に任せます。

Markdown は Zed の標準では LSP 前提ではありません。基本は `prettier` による format と tree-sitter ベースの編集支援で扱います。
そのため、Markdown で Language Server が `No item` でも不自然ではありません。

### Local-only ファイル

次のファイルは `chezmoi` で管理せず、各マシンにだけ置きます。

- `~/.gitconfig.local`
- `~/.gitconfig-work.local`
- `~/.ssh/config.local`
- `~/.ssh/id_ed25519_github_self`
- `~/.ssh/id_ed25519_github_work`

これらを変更したいときは local file を直接編集します。`chezmoi apply` では上書きしません。
