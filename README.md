# dotfiles
**WSL2 (Ubuntu) 向け開発環境セットアップ**

このリポジトリは `Justfile` と `GNU Stow` を使って、WSL2 上の開発環境を一括構築します。

## Features
- `just setup` で主要ツールを一括導入
- Stow による dotfiles のリンク管理
- Rust / Node (Volta) / Python (uv) の導入
- Neovim 最新版を `~/.local/opt/nvim` に配置
- Lazygit + delta で side-by-side diff
- pre-commit + gitleaks で秘密情報検出
- GitHub (gh) と GitBucket (libsecret) をホストで切替
- 端末固有設定は `.local` ファイルへ分離（競合ゼロ運用）

## Directory Structure
```text
~/dotfiles/
├── bash/       -> ~/.bashrc
├── zsh/        -> ~/.zshrc
├── tmux/       -> ~/.tmux.conf
├── shell/      -> ~/.config/shell/env
├── git/        -> ~/.gitconfig
├── lazygit/    -> ~/.config/lazygit/
├── nvim/       -> ~/.config/nvim/
├── Justfile
├── pkglist.txt
└── README.md
```

## Commands (Justfile)
- `just default` — `just --list` を表示
- `just setup` — 主要インストール工程を実行（初期専用）
- `just link` — dotfiles のリンクを再接続
- `just sync` — `git pull --rebase` + 更新時のみ `just link`
- `just setup-projects` — `~/projects/personal` / `~/projects/company` を作成
- `just setup-personal-git` — 個人用の Git 設定ファイルを作成
- `just setup-company-git` — 会社用の Git 設定ファイルを作成
- `just update-system` — `apt update & upgrade` を実行
- `just install-gh` — GitHub CLI を導入
- `just install-apt` — `pkglist.txt` のパッケージを導入
- `just setup-pre-commit` — pre-commit フックを有効化
- `just gh-personal-login` — GitHub 個人アカウント認証
- `just gh-company-login` — GitHub 会社アカウント認証
- `just gh-switch-personal` — GitHub アカウントを個人に切替
- `just gh-switch-company` — GitHub アカウントを会社に切替
- `just install-git-credential-libsecret` — libsecret helper を導入
- `just gitbucket-login` — GitBucket 認証情報を登録
- `just start-keyring` — keyring 起動コマンド断片を出力
- `just setup-fd` — `fd` シンボリックリンクを作成
- `just setup-locale` — 日本語ロケールを生成
- `just install-rust` — rustup を導入/更新
- `just install-python` — uv / Python 3.11 を導入
- `just install-node` — Volta / Node / npm / pnpm を導入
- `just install-ai` — Copilot / Codex / Kiro を導入
- `just install-nvim` — Neovim を導入
- `just install-clipboard` — win32yank を導入
- `just install-gitleaks` — gitleaks を導入
- `just install-lazygit` — Lazygit を導入
- `just setup-zsh` — Zsh + oh-my-zsh + powerlevel10k を導入

## Daily Flow (Zero Conflicts)
1. `just sync`（pull + 更新時のみ link）

編集ルール:
- 端末Aで編集 → commit/push → 端末Bで pull
- 両端末同時編集は避ける

## Local Files (Not Tracked)
- `~/.bashrc.local` — bash の端末固有設定（`just setup` で雛形作成）
- `~/.zshrc.local` — zsh の端末固有設定（`just setup` で雛形作成）
- `~/.config/nvim/lua/config/local.lua` — Neovim 端末固有設定（`just setup` で雛形作成）

## Shared Env
- `~/.config/shell/env` — bash/zsh 共通の環境変数（dotfiles 管理）
  - 秘密情報はここに書かず、`.bashrc.local` / `.zshrc.local` に置く

## Link Behavior
- `just link` はバックアップを作成しない
- 既存の通常ファイルがある場合は安全のため中断（手動で退避してから実行）

## Volta Notes
- Volta が `.bashrc` を書き換える可能性があるため、共通 env への集約で依存しない運用にする
- 追記が入った場合は一度だけ手動で削除する

## Git Bucket Notes
- keyring はこのセッションで起動する必要あり

```bash
eval "$(just start-keyring)"
```

- 認証登録は `just gitbucket-login`
- helper 設定は `~/.config/git/config` に保存（dotfiles には含めない）

## Zsh Notes
- `~/.zshrc` は dotfiles で管理
- 端末固有の設定は `~/.zshrc.local` に記載する
- 初回のみ `p10k configure` を実行してテーマを調整する

## Bash Notes
- 端末固有の設定は `~/.bashrc.local` に記載する

## Neovim Notes
- `lazy-lock.json` はローカル管理（端末ごとに最新追随）

## Tmux Notes
- copy-mode は vi 操作に設定
