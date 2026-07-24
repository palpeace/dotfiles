# 🚀 dotfiles

[MIT License](./LICENSE) © 2026 palpeace

Modern, minimal, zero-touch, and AI-native development environment optimized for WSL2.

---

## 🛠 Features

- **Dotfiles Management**: [chezmoi](https://www.chezmoi.io/) - 冪等性を保ったワンライナー環境復元
- **Tool Management**: [mise](https://mise.jdx.dev/) - 言語・CLIツールのバージョン管理
- **Shell & Prompt**: [Zsh](https://www.zsh.org/) + [Sheldon](https://sheldon.cli.rs/) + [Starship](https://starship.rs/)
- **AI Native Core**: Claude Code, Copilot, Antigravity CLI, Kiro CLI
- **WSL Zero-Touch**: `/etc/wsl.conf` (systemd / interop) の全自動セットアップ対応

---

## 📦 Quick Start (Scrap & Build)

新しい WSL インスタンス（`wsl --install` 直後）で以下の 1 コマンドを実行するだけで、全自動で完全復元します。

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/palpeace/dotfiles/main/scripts/bootstrap.sh)"
```

このワンライナーにより、以下が全自動で完了します。
- `/etc/wsl.conf` の最適化 (`systemd=true`, `appendWindowsPath=false`)
- `chezmoi init --apply` による設定ファイルの配置
- Git の基本情報 (`~/.gitconfig.local`) の対話生成・設定
- OS 依存パッケージと `mise` / AI ツールの自動導入

---

## 🎯 ツール管理方針 (グローバル vs プロジェクトローカル)

本環境では、グローバル環境 (`~/.config/mise/config.toml`) とプロジェクトローカル (`mise.toml`) の役割を明確に分類・分離しています。

### 📌 判断基準 3 原則

1. **どのプロジェクトを開いても常用したいか？**
   → **Yes:** グローバル (`~/.config/mise/config.toml`) に配置
2. **エディタ (Zed等) が PATH から直接参照する LSP / Formatter か？**
   → **Yes:** グローバルに配置 (`pyright`, `gopls`, `prettier`, `taplo` 等)
3. **ビルド処理 (`cargo build` 等) が必要か？**
   → **Yes:** プロジェクトローカル (`mise.toml`) を優先し、グローバルには原則置かない

### ⚖️ 配置先の比較

| 分類 | 配置場所 | 対象ツール例 |
| :--- | :--- | :--- |
| **グローバル** | `~/.config/mise/config.toml` | ランタイム (Rust, Node, Go, Python)、シェル統合 (starship, sheldon, zoxide, fzf)、日常CLI (ripgrep, fd, bat, eza, jq)、LSP/Formatter |
| **PJローカル** | プロジェクト直下の `mise.toml` | 言語固有ビルド・テストツール (`bacon`, `cargo-make`)、PJ限定ツールチェーン (`decktape`)、チーム統一バージョン |

---

## 🧰 Included Base Tools

| Category | Tools |
| :--- | :--- |
| **AI Agents (Core)** | Claude Code (`claude`), Copilot, Antigravity CLI (`agy`), Kiro CLI |
| **Editor** | Helix (`hx`) |
| **CLI Essentials** | fzf, ripgrep (`rg`), fd, eza, bat, zoxide (`z`), jq, trash-cli, tldr |
| **Modern Ops** | lazygit (`lg`), lazydocker (`ld`), bottom (`btm`), xh, dust, tmux |
| **Formatters / LSP** | Prettier, Markdownlint, Taplo, Marksman, Pyright, Gopls |

---

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

### 🔒 Identity & Security

- Git の個人情報（`user.name`, `user.email`）は管理外の `~/.gitconfig.local` に分離され、chezmoi リポジトリには露出されません。
- 秘密情報（API キー等）は `~/.config/zsh/secrets.zsh` に分離して管理されます。
