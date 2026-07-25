# 🚀 dotfiles

[MIT License](./LICENSE) © 2026 palpeace

Modern, minimal, zero-touch, and AI-native development environment optimized for WSL2 & Orca ADE.

---

## 🛠 Features

- **Dotfiles Management**: [chezmoi](https://www.chezmoi.io/) - 冪等性を保ったワンライナー環境復元
- **Tool Management**: [mise](https://mise.jdx.dev/) - 言語・CLIツールのバージョン管理
- **Shell & Prompt**: [Zsh](https://www.zsh.org/) + [Sheldon](https://sheldon.cli.rs/) + [Starship](https://starship.rs/)
- **AI Native Core**: Claude Code, Copilot, Antigravity CLI (`agy`), Kiro CLI
- **Orca ADE & WSL2 Direct Integration**: `%APPDATA%\Orca` 設定の自動展開と `.wslconfig` リソース最適化 (`autoMemoryReclaim`, `sparseVhd`, `dnsTunneling`)
- **WSL Zero-Touch**: `/etc/wsl.conf` (`systemd=true`, `appendWindowsPath=false`) の全自動セットアップ対応

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
- 自動ヘルスチェック（Smoke Tests）の実行

---

## 🪟 Windows Orca IDE & WSL2 連携設定

Windows 側の Orca ADE および `.wslconfig` へ設定を一括適用・同期するための専用ヘルパーが用意されています。

```zsh
# 1. chezmoi の設定を Windows 側 Orca (%APPDATA%\Orca) および %USERPROFILE%\.wslconfig に反映
apply-orca-windows-settings

# 2. Windows 側で変更した Orca 設定を dotfiles リポジトリの assets/orca へ取り込み
pull-orca-windows-settings
```

詳しいアーキテクチャや連動設計については [Orca ADE Optimization Guide](./docs/orca_wsl_optimization_guide.md) を参照してください。

---

## 🧩 マシン個別オプショナル設定 (Docker / GPU / headroom)

マシンごとに Docker Engine や GPU アクセラレーション、Claude Code 用トークンプロキシの有無を設定できます。

```zsh
# 対話形式でマシン構成を選択 (成果物は ~/.config/dotfiles/machine.env に保存)
configure-machine

# 選択された設定に基づいてオプショナルコンポーネントをセットアップ
setup-optional
```

---

## ⚡ 日常のシェルヘルパー機能

本環境には、ワークスペースに応じて最適なタスクを実行するヘルパー関数が `.zshrc` に組み込まれています。

```zsh
# 1. 開発サーバー / タスクの起動 (Justfile, package.json, Cargo.toml を自動判定)
dev

# 2. コード品質・テストの一括検証 (Justfile, Cargo clippy/nextest, pnpm/prettier/markdownlint)
check

# 3. chezmoi の変更を安全にドライラン確認して適用
sync-dotfiles
```

---

## 🎯 ツール管理方針 (グローバル vs プロジェクトローカル)

本環境では、グローバル環境 (`~/.config/mise/config.toml`) とプロジェクトローカル (`mise.toml`) の役割を明確に分類・分離しています。

### 📌 判断基準 3 原則

1. **どのプロジェクトを開いても常用したいか？**
   → **Yes:** グローバル (`~/.config/mise/config.toml`) に配置
2. **エディタ (Orca ADE / Zed等) が PATH から直接参照する LSP / Formatter か？**
   → **Yes:** グローバルに配置 (`pyright`, `gopls`, `prettier`, `taplo`, `marksman`, `rust-analyzer` 等)
3. **ビルド処理 (`cargo build` 等) が必要か？**
   → **Yes:** プロジェクトローカル (`mise.toml`) を優先し、グローバルには原則置かない

### ⚖️ 配置先の比較

| 分類 | 配置場所 | 対象ツール例 |
| :--- | :--- | :--- |
| **グローバル** | `~/.config/mise/config.toml` | ランタイム (Rust, Node, Go, Python)、シェル統合 (starship, sheldon, zoxide, fzf, atuin)、日常CLI (ripgrep, fd, bat, eza, jq)、LSP/Formatter |
| **PJローカル** | プロジェクト直下の `mise.toml` | 言語固有ビルド・テストツール (`bacon`, `cargo-make`)、PJ限定ツールチェーン (`decktape`)、チーム統一バージョン |

---

## 🧰 Included Base Tools

| Category | Tools |
| :--- | :--- |
| **AI Agents (Core)** | Claude Code (`claude`), Copilot, Antigravity CLI (`agy` / `agy-skip`), Kiro CLI |
| **Editor** | Helix (`hx`), Orca ADE (`orca` / `oc`), Zed (`ze`) 連携 |
| **CLI Essentials** | fzf, ripgrep (`rg`), fd, eza, bat, zoxide (`z`), jq, trash-cli, tldr (`tlrc`) |
| **Modern Ops** | lazygit (`lg`), lazydocker (`ld`), bottom (`btm`), xh, dust, tmux |
| **Formatters / LSP** | Prettier, Markdownlint, Taplo, Marksman, Pyright, Gopls, rust-analyzer |

---

## 📝 Maintenance

### 運用早見表

```zsh
# 1. dotfiles を GitHub から取り込んで反映
chezmoi update

# 2. 今の PC で変更したファイルを dotfiles リポジトリに戻す
chezmoi re-add ~/.zshrc
chezmoi cd && git add . && git commit -m "update: config" && git push

# 3. システムパッケージ & mise 管理ツール・AI ツールの最新一括更新
update-system
```

### 🔒 Identity & Security

- Git の個人情報（`user.name`, `user.email`）は管理外の `~/.gitconfig.local` に分離され、chezmoi リポジトリには露出されません。
- 秘密情報（API キー等）は `~/.config/zsh/secrets.zsh` に分離して管理されます。

