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

新しい環境で以下のコマンドを叩くだけで、OSの依存関係からAIツールまで全てが整います。

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/palpeace/dotfiles/main/scripts/bootstrap.sh)"
```

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
# chezmoi 本体を更新
chezmoi upgrade

# dotfiles を pull して apply
chezmoi update

# mise 管理のツールを最新化
mise upgrade
```

`run_onchange_after_00-setup-system.sh` では Ubuntu のシステムパッケージと `mise install -y` を実行します。
そのため dotfiles 側の変更反映は `chezmoi update` / `chezmoi apply`、ツールの最新版化は `mise upgrade` を使う運用です。
