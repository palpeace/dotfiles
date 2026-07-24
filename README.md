# 🚀 dotfiles

[MIT License](./LICENSE) © 2026 palpeace

Modern, minimal, zero-touch, and AI-native development environment optimized for WSL2.

---

## 🛠 Features

- **Dotfiles Management**: [chezmoi](https://www.chezmoi.io/) - 冪等性を保ったワンライナー環境復元
- **Tool Management**: [mise](https://mise.jdx.dev/) - 言語・CLIツールのバージョン管理
- **Shell**: [Zsh](https://www.zsh.org/) + [Sheldon](https://sheldon.cli.rs/) (Plugin Manager)
- **Prompt**: [Starship](https://starship.rs/) - 2行構成 & 視認性重視の独自スタイル
- **AI Native Core**: Claude Code, GitHub Copilot, Antigravity CLI, Kiro CLI
- **WSL Zero-Touch**: `/etc/wsl.conf` (systemd / interop) の全自動セットアップ対応

## 📦 Quick Start (Scrap & Build)

新しい WSL インスタンス（`wsl --install` 直後）で、以下の 1 コマンドを実行するだけで環境が全自動で完全復元します。

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/palpeace/dotfiles/main/scripts/bootstrap.sh)"
```

このワンライナーにより、以下が全自動で完了します。

- `/etc/wsl.conf` の最適化 (`systemd=true`, `appendWindowsPath=false`)
- `chezmoi init --apply` による設定ファイルの配置
- Git の基本情報 (`~/.gitconfig.local`) の作成
- OS 依存パッケージと `mise` / AI ツールの自動導入

Docker Engine や headroom (Claude Code トークン圧縮) が必要なマシンでは、`bootstrap` の後に次を実行します。

```zsh
configure-machine
setup-optional
```

## 🔒 Identity & Security

- Git の個人情報（`user.name`, `user.email`）は管理外の `~/.gitconfig.local` に分離され、chezmoi リポジトリには一切露出されません。
- 秘密情報（API キー等）は `~/.config/zsh/secrets.zsh` に分離して管理されます。

## 🧰 Included Base Tools

| Category | Tools |
| :--- | :--- |
| **AI Agents (Core)** | Claude Code (`claude`), Copilot, Antigravity CLI (`agy`), Kiro CLI |
| **AI Agents (Optional)** | headroom (Claude Code トークン圧縮プロキシ) |
| **Editor** | Helix (`hx`) |
| **CLI Essentials** | fzf, ripgrep (`rg`), fd, eza, bat, zoxide (`z`), jq, trash-cli |
| **Modern Ops** | lazygit (`lg`), lazydocker (`ld`), bottom (`btm`), xh, dust, tmux |

> 💡 **プロジェクト固有のツール管理**:
> スライド作成ツール（`decktape`）や特定の検証ツール等は、ベース環境を汚さず、プロジェクト側の `mise.toml` または `package.json` で個別管理します。

## 📝 Maintenance

### 運用早見表

```zsh
# 1. dotfiles を GitHub から取り込んで反映
chezmoi update

# 2. 今の PC で変更したファイルを dotfiles リポジトリに戻す
chezmoi re-add ~/.zshrc
chezmoi cd && git add . && git commit -m "update: config" && git push

# 3. システムパッケージ & mise 管理ツールの最新更新
update-system
```

### Windows 側の Zed 設定同期

```zsh
# dotfiles -> Windows Zed
apply-zed-windows-settings

# Windows Zed -> dotfiles
pull-zed-windows-settings
```

