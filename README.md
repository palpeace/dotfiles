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

新しい環境では、まず以下のコマンドでセットアップを開始します。初回 bootstrap では、必要な local identity の値を確認する対話入力があります。

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/palpeace/dotfiles/main/scripts/bootstrap.sh)"
```

## 🔒 Identity and SSH

公開リポジトリには個人情報を残さず、必要な値だけ初回 bootstrap で対話入力します。

- `~/.gitconfig.local`: self 用の既定アカウント
- `~/.gitconfig-work.local`: `~/work/` 配下のリポジトリ用の work アカウント
- `~/.ssh/config.local`: 必要に応じて追加するローカル SSH 設定
- SSH private keys はローカルマシンにのみ置く
- first bootstrap は不足値を確認し、既存の local files は上書きしない

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

設定を更新した際の基本フロー：

```zsh
# 変更を反映
chezmoi re-add ~/.zshrc

# GitHubに保存
chezmoi cd
git add .
git commit -m "update: something"
git push
```

環境の更新コマンドの役割分担:

```zsh
# 開発環境をまとめて更新
update-dev

# chezmoi 本体を更新
chezmoi upgrade

# dotfiles を pull して apply
chezmoi update

# mise 管理のツールを最新化
mise upgrade
```

`run_onchange_after_00-setup-system.sh` では Ubuntu のシステムパッケージと `mise install -y` を実行します。
そのため dotfiles 側の変更反映は `chezmoi update` / `chezmoi apply`、ツールの最新版化は `mise upgrade` を使う運用です。

`update-dev` は次の順で実行されます。

```zsh
chezmoi update
sudo apt update
sudo apt upgrade -y
mise upgrade
```
