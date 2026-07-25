# Orca IDE + WSL2 + chezmoi 完全統合＆最適化ガイド

本ドキュメントは、Windows 上の超高速 GUI IDE **Orca** と WSL2 (Linux) 環境、および `chezmoi` / `mise` で構成された開発環境を密連携させ、スクラップ＆ビルド（ゼロからの環境完全復元）と開発体験（DX）を最大限に引き出すための実践ガイドです。

---

## 1. アーキテクチャと基本概念

```text
+-------------------------------------------------------------+
|                      Windows 11                             |
|  +-------------------------------------------------------+  |
|  |                      Orca IDE                         |  |
|  |  - GUI Rendering (GPU Accelerated)                    |  |
|  |  - Windows Settings (%APPDATA%\Orca\settings.json)   |  |
|  +---------------------------+---------------------------+  |
+------------------------------|------------------------------+
                               | Remote Server Connection
+------------------------------v------------------------------+
|                     WSL2 (Ubuntu/Linux)                     |
|  +-------------------------------------------------------+  |
|  |  chezmoi Source (~/.local/share/chezmoi)              |  |
|  |   ├── home/dot_config/orca/settings.json.tmpl         |  |
|  |   ├── home/dot_config/mise/config.toml               |  |
|  |   └── assets/orca/ (Windows用設定)                    |  |
|  +-------------------------------------------------------+  |
|  |  mise Runtime & Tools (~/.local/share/mise/shims)     |  |
|  |   ├── gopls (Go LSP)                                  |  |
|  |   ├── pyright (Python LSP)                            |  |
|  |   ├── taplo (TOML LSP/Formatter)                      |  |
|  |   ├── marksman (Markdown LSP)                         |  |
|  |   └── prettier / markdownlint-cli2                    |  |
|  +-------------------------------------------------------+  |
+-------------------------------------------------------------+
```

---

## 2. Orca のポテンシャルを最大限に発揮する 5 大設定

### ① LSP / Formatter の完全統合 (Auto-Format on Save)
WSL 側に `mise` でインストールした LSP ランタイム（`gopls`, `pyright`, `taplo`, `marksman`, `prettier`）のパスを Orca 設定に登録し、ファイル保存時に自動フォーマットと静的解析を有効化します。

### ② 超高速ターミナル統合 (Integrated Terminal)
Orca 内の統合ターミナルで `zsh` と `mise` shims を瞬時に読み込ませるため、`~/.zshenv` に以下を定義します。
```zsh
export PATH="$HOME/.local/share/mise/shims:$PATH"
```
これにより、Orca 内部のターミナルやタスクランナーでも `gh`, `pnpm`, `uv`, `just` などの CLI ツールが完全に機能します。

### ③ インライン Git 視認性と Gutter 統合
Orca のインライン Diff や Git Gutter (行単位の変更履歴) を有効にし、キーバインドで即座に `lazygit` や差分確認ができるようにします。

### ④ Inlay Hints (型ヒント・引数名表示)
Rust, Go, Python, TypeScript 開発時に、変数型や関数引数名をコード上にリアルタイム表示する Inlay Hints を有効化します。

### ⑤ AI アシスタント（GitHub Copilot 等）の透過連携
`mise` で導入済みの `@github/copilot` や Orca 内蔵 AI アシスタント機能をシームレスに動作させます。

---

## 3. `mise` 管理ツールの最適化構成

| カテゴリ | ツール | 役割・Orcaとの連携効果 |
| :--- | :--- | :--- |
| **LSP / Language** | `go:gopls` | Go 言語の型チェック、定義ジャンプ、自動補完 |
| | `npm:pyright` | Python の型解析・補完 |
| | `aqua:taplo` | TOML (Cargo.toml, mise.toml等) のフォーマット＆検証 |
| | `aqua:marksman` | Markdown のリンク検証・見出し補完 |
| | `rust-analyzer` | Rust 高速言語サーバー |
| **Formatter** | `npm:prettier` | Markdown / JSON / JS / TS 自動整形 |
| | `npm:markdownlint-cli2` | Markdown 規約チェック |
| **Task / CLI** | `just` | プロジェクト定型コマンド実行 (Orca taskから呼び出し) |
| | `uv` / `npm:pnpm` | 超高速 Python / Node パッケージ管理 |
| | `ripgrep` / `fd` | Orca 内ファイル・テキスト高速検索 |
| | `github-cli` (gh) | GitHub PR / Issue 連携 |

---

## 4. Windows ↔ WSL 設定同期コマンド

`chezmoi` 管理下から Windows 側の Orca 設定を一発適用・バックアップできるスクリプトを提供します。

- **適用コマンド**: `apply-orca-windows-settings`
  - `assets/orca/settings.json` および `keymap.json` を `%APPDATA%\Orca\` へコピー。
- **吸い上げコマンド**: `pull-orca-windows-settings`
  - Windows 側で変更した Orca 設定を `assets/orca/` へ逆同期。

---

## 5. スクラップ＆ビルドの手順

新しい環境（新規PCやWSLの再構築時）では、以下の 1 コマンドで全環境が復元されます。

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/palpeace/dotfiles/main/scripts/bootstrap.sh)"
```

**復元に含まれるもの**:
1. Ubuntu パッケージ (`zsh`, `build-essential` 等)
2. `mise` および全言語ランタイム (Rust, Go, Node, Python) + 全 LSP / ツール
3. Orca 用 WSL 設定 (`~/.config/orca/settings.json`)
4. Windows 側 Orca 設定の自動反映 (`%APPDATA%\Orca\settings.json`)
