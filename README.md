# dotfiles
**Automated Development Environment for WSL2 (Ubuntu)**
Focused on Rust, SaaS Development, and AI-Powered Workflows.

このリポジトリは、WSL2 上での開発環境を **"One Command"** で構築・管理するための設定集です。
`Just` タスクランナーと `GNU Stow` を組み合わせることで、**冪等性（何度実行しても壊れない）** と **再現性** を担保しています。

## ✨ Key Features

* **⚡ Automated Setup**: `Justfile` による一括セットアップと依存関係解決。
* **🔗 Config Management**: `GNU Stow` を使用し、ホームディレクトリを汚さずに設定をシンボリックリンクで管理。
* **🦀 Rust Ready**: `rustup`, `pkg-config`, `openssl`, `protobuf` など、開発に必要なツールチェーンを完備。
* **🐍 Python & Node**:
    * **Python**: `uv` による超高速な環境分離（システムPythonを破壊しません）。
    * **Node.js**: `Volta` によるプロジェクトごとのバージョン固定と高速な切り替え。
* **📝 Neovim (LazyVim)**: 最新の Neovim バイナリと LazyVim スターターを自動配置。
* **🤖 AI Integrated**: GitHub Copilot, OpenAI Codex, Kiro CLI を標準装備。
* **🇯🇵 WSL Optimized**: 日本語ロケール生成、Windowsクリップボード共有 (`win32yank`) 設定済み。

## 📂 Directory Structure

`GNU Stow` の仕組みにより、リポジトリ内のディレクトリ構造がそのままホームディレクトリにマッピングされます。

```text
~/dotfiles/
├── bash/
│   └── .bashrc          -> ~/.bashrc (Shell config)
├── git/
│   └── .gitconfig       -> ~/.gitconfig (Include by repo location)
├── nvim/
│   └── .config/
│       └── nvim/        -> ~/.config/nvim/ (LazyVim config)
├── Justfile             # Task runner definition (The Commander)
├── pkglist.txt          # Apt packages list
├── bootstrap.sh         # Entry point script
└── README.md            # This file
```

## 🛠️ Usage (Maintenance)

インストール後のメンテナンスは `just` コマンドで行います。
認証（GitHub/AI CLI）は `just setup` 後に個別で対応が必要です。

| Command | Description |
| :--- | :--- |
| **`just setup`** | 全インストール工程を実行（非対話でOK） |
| **`just link`** | 設定ファイル（.bashrc, nvimなど）のリンクを再接続 |
| **`just update-system`** | `apt update & upgrade` を実行 |
| **`just install-apt`** | `pkglist.txt` に追加したパッケージをインストール |
| **`just install-rust`** | Rustツールチェーン (`rustup`) の更新 |
| **`just gh-personal-login`** | 個人アカウントで GitHub 認証を設定（初回はこちら） |
| **`just gh-company-login`** | 会社アカウントで GitHub 認証を追加 |
| **`just gh-switch-personal`** | GitHub アカウントを個人に切り替え |
| **`just gh-switch-company`** | GitHub アカウントを会社に切り替え |

コマンド一覧の確認:
```bash
just --list
```

## 🔐 Git Identity Split (Personal / Company)

`~/projects/personal/**` と `~/projects/company/**` で `user.name` / `user.email` を切り替えます。

1) `just link` を実行して `~/.gitconfig` を配置  
2) `just setup-projects` を実行（ディレクトリ作成のみ）  
3) 個人/会社の Git 設定は手動で実行  
   - `just setup-personal-git`  
   - `just setup-company-git`  
   - 既存の `~/.gitconfig-personal` / `~/.gitconfig-company` がある場合は不要
4) 認証は GitHub CLI (`gh`) を使用  
   - 初回: `just gh-personal-login`  
   - 会社追加: `just gh-company-login`  
   - 切り替え: `just gh-switch-personal` / `just gh-switch-company`  
   - 認証情報は `~/.config/gh/hosts.yml` に保存され、**このリポジトリには含めない**
   - Public 運用のため、`hosts.yml` は絶対にコミットしない

## 📦 Included Tools

### Core
* **Git, curl, wget, unzip**: Essentials.
* **zsh**: (Installed for compatibility, bash is default).
* **Stow**: Dotfile manager.

### Development Runtimes
* **Rust**: `rustup`, `cargo`, `rustc`
* **Node.js**: `volta`, `node`, `npm`, `pnpm`
* **Python**: `uv` (Fastest pip alternative), Python 3.11 (User-space)

### Tools & Editors
* **Neovim**: Latest stable release (via GitHub Releases).
* **LazyVim**: Full-featured IDE layer for Neovim.
* **ripgrep (rg)**: Super fast grep replacement.
* **fd**: Simple/fast alternative to find.
* **tmux**: Terminal multiplexer.

### AI CLI Tools
* **GitHub Copilot CLI**
* **OpenAI Codex CLI**
* **Kiro CLI**
