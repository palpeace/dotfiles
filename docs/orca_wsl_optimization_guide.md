# Orca IDE + WSL2 + chezmoi 完全統合＆オートスケール最適化ガイド

本ドキュメントは、Windows 上の超高速 GUI IDE **Orca** と WSL2 (Linux) 環境、および `chezmoi` / `mise` で構成された開発環境を密連携させ、**マルチエージェントの自動リソース縮小・オートスケール (Auto-Scaling & Reclaim)** とスクラップ＆ビルド（ゼロからの環境完全復元）を最大限に引き出すための全設計書です。

---

## 1. アーキテクチャと基本概念

```text
+-------------------------------------------------------------------+
|                        Windows 11                                 |
|  +-------------------------------------------------------------+  |
|  |                        Orca IDE                             |  |
|  |  - Multi-Agent Orchestrator (Parallel Worktrees)            |  |
|  |  - Settings (%APPDATA%\Orca\settings.json)                  |  |
|  +------------------------------|------------------------------+  |
|  |  WSL2 Auto-Scaling Engine   | (.wslconfig)                  |  |
|  |  - autoMemoryReclaim (キャッシュメモリの即時全自動返却)       |  |
|  |  - sparseVhd (VHD容量のオートスケーリング自動回収)            |  |
|  +------------------------------|------------------------------+  |
+---------------------------------|---------------------------------+
                                  | Remote Server Connection
+---------------------------------v---------------------------------+
|                        WSL2 (Ubuntu/Linux)                        |
|  +-------------------------------------------------------------+  |
|  |  chezmoi Source (~/.local/share/chezmoi)                    |  |
|  |   ├── home/dot_config/orca/settings.json.tmpl               |  |
|  |   ├── assets/wslconfig/.wslconfig (オートスケール設定)       |  |
|  |   └── assets/orca/ (Windows用設定)                          |  |
|  +-------------------------------------------------------------+  |
|  |  mise Runtime & Tools (~/.local/share/mise/shims)           |  |
|  |   ├── gopls (Go LSP) / pyright (Python LSP)                 |  |
|  |   ├── taplo (TOML) / marksman (Markdown)                    |  |
|  |   └── prettier / markdownlint-cli2                          |  |
|  +-------------------------------------------------------------+  |
+-------------------------------------------------------------------+
```

---

## 2. WSL2 リソースのオートスケール (Auto-Scaling & Reclaim) 設定

Orca は複数の AI エージェント（Worktree やサブプロセス）を並列動作させるため、過剰なメモリ・ディスク・プロセスリソースを一時的に消費します。
本構成では、Windows 側の `.wslconfig` を全自動セットアップし、以下の**オートスケーリング機能**を有効化します。

### 1. `autoMemoryReclaim=dropcache` (メモリの全自動スケール返却)
- エージェントのタスク完了後、WSL2 内の未使用キャッシュメモリを **Windows ホストへ自動返却 (Reclaim)** します。
- メモリ不足による WSL や Windows 全体の低下を完全に回避します。

### 2. `sparseVhd=true` (仮想ディスク領域のオートスケール縮小)
- ディスク使用量が減少した際、WSL2 の VHDX ファイルサイズを **全自動で縮小・オートリサイクル** します。

### 3. `networkingMode=mirrored` & `autoProxy=true` (通信オートチューニング)
- ホストと WSL2 間のネットワーク・ポート通信をミラー化し、通信オーバーヘッドをゼロにします。

---

## 3. Orca のポテンシャルを最大限に発揮する 5 大設定

### ① LSP / Formatter の完全統合 (Auto-Format on Save)
WSL 側に `mise` でインストールした LSP ランタイム（`gopls`, `pyright`, `taplo`, `marksman`, `prettier`）のパスを Orca 設定に登録し、ファイル保存時に自動フォーマットと静的解析を有効化します。

### ② 超高速ターミナル統合 (Integrated Terminal)
Orca 内の統合ターミナルで `zsh` と `mise` shims を瞬時に読み込ませるため、`~/.zshenv` に以下を定義します。
```zsh
export PATH="$HOME/.local/share/mise/shims:$PATH"
```

### ③ インライン Git 視視性と Gutter 統合
Orca のインライン Diff や Git Gutter (行単位の変更履歴) を有効にし、即座に `lazygit` や差分確認ができるようにします。

### ④ Inlay Hints (型ヒント・引数名表示)
Rust, Go, Python, TypeScript 開発時に、変数型や関数引数名をコード上にリアルタイム表示します。

---

## 4. Windows ↔ WSL 設定同期コマンド

`chezmoi` 管理下から Windows 側の Orca 設定および `.wslconfig` を一発適用・バックアップできます。

```bash
apply-orca-windows-settings
```

**自動反映される項目**:
- `%APPDATA%\Orca\settings.json` (Orca GUI設定)
- `%APPDATA%\Orca\keymap.json` (キーバインド設定)
- `%USERPROFILE%\.wslconfig` (WSL2 オートスケール＆メモリ回収設定)

---

## 5. スクラップ＆ビルドの手順

新しい環境（新規PCやWSLの再構築時）では、以下の 1 コマンドで全環境が復元されます。

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/palpeace/dotfiles/main/scripts/bootstrap.sh)"
```
