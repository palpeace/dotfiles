# Orca ADE (Agent Development Environment) + WSL2 + chezmoi 完全統合ガイド

本ドキュメントは、AI 時代における最先端 Agent IDE **Orca (Orca ADE)** と WSL2 (Linux) 環境、および `chezmoi` / `mise` で構成された開発環境を密連携させ、**マルチエージェントオーケストレーション・Git Worktree 独立実行・WSL2 オートスケール** までのポテンシャルを 100% 引き出すための全設計書です。

---

## 1. アーキテクチャと基本概念

```text
+-------------------------------------------------------------------+
|                        Windows 11                                 |
|  +-------------------------------------------------------------+  |
|  |                    Orca ADE (GUI Host)                      |  |
|  |  - Multi-Agent Parallel Orchestration                       |  |
|  |  - Built-in Diff & Merge Engine (Hunk/Line level)           |  |
|  |  - Design Mode (Embedded Chromium for UI Preview)           |  |
|  |  - Settings (%APPDATA%\Orca\settings.json)                  |  |
|  +------------------------------|------------------------------+  |
|  |  WSL2 Auto-Scaling Engine   | (.wslconfig)                  |  |
|  |  - autoMemoryReclaim (キャッシュメモリの全自動スケール返却)   |  |
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
|  |  AI Agents & Tools (~/.local/bin / mise shims)             |  |
|  |   ├── Claude Code / Antigravity CLI (agy) / Kiro CLI        |  |
|  |   ├── gopls (Go) / pyright (Python) / rust-analyzer (Rust)   |  |
|  |   └── taplo (TOML) / marksman (MD) / prettier               |  |
|  +-------------------------------------------------------------+  |
+-------------------------------------------------------------------+
```

---

## 2. Orca ADE のポテンシャルを最大限に発揮する 7 大統合ポイント

### ① マルチAIエージェントの直接連携 (Agents Menu & Launchers)
Orca ADE から WSL 内にインストールされた AI エージェント（**Claude Code**, **Antigravity CLI (agy)**, **Kiro CLI**, **GitHub Copilot**）をシームレスに直接起動・監視できます。
- 本 dotfiles の `setup-system` により、これらの CLI ツールが全自動で配備され、Orca の Agents 設定でそのまま認識されます。

### ② Parallel Worktree Management (マルチタスク独立実行)
Orca ADE は `git worktree` をネイティブ活用し、複数の AI エージェントが異なるブランチ・タスクで同時にコードを生成しても衝突しません。
- 本 dotfiles では、単一の作業ディレクトリ `~/src` を基点として、Orca が安全に Worktrees を自動生成・管理できるよう統合されています。

### ③ Advanced Diff & Merge Engine (AI生成コード視認性)
AI が提案・生成したコードの行単位・ハンク単位のステージングや三方マージ (3-way merge) 視認性を向上させます。
- `git_gutter` および `inline_blame` を有効化。

### ④ WSL2 リソースのオートスケール (Auto-Scaling & Reclaim)
エージェント並行動作時のリソース圧迫を防止するため、Windows 側 `.wslconfig` を自動構成します。
- `autoMemoryReclaim=dropcache`: キャッシュメモリを Windows ホストへ即座に全自動返却。
- `sparseVhd=true`: VHD ディスク領域の自動スケーリング・回収。
- `networkingMode=mirrored`: 通信オーバーヘッドをゼロに最適化。

### ⑤ Design Mode 連携 (ブラウザ依存ライブラリの配備)
Orca ADE 内蔵の内蔵 Chromium プレビュー（Design Mode）や Playwright 動作に必要な Ubuntu ライブラリ（`libnss3`, `libnspr4`, `wslu`, `libwebkit2gtk` 等）が `setup-system` で完備されています。

### ⑥ LSP / Formatter 完全自動化 (Auto-Format on Save)
`mise` で導入済みの全 LSP（`gopls`, `pyright`, `taplo`, `marksman`, `prettier`）を Orca が自動使用し、ファイル保存時にリアルタイム静的解析とフォーマットを適用します。

### ⑦ 統合ターミナル (Integrated Terminal) のシームレス化
Orca の統合ターミナル起動時に `.zshenv` が読まれ、`~/.local/share/mise/shims` と `$HOME/.local/bin` に即座にパスが通ります。

---

## 3. Windows ↔ WSL 設定同期コマンド

`chezmoi` 管理下から Windows 側の Orca 設定および `.wslconfig` を一発適用・バックアップできます。

```bash
apply-orca-windows-settings
```

**自動反映される項目**:
- `%APPDATA%\Orca\settings.json` (Orca GUI / Agents / Git 設定)
- `%APPDATA%\Orca\keymap.json` (キーバインド設定)
- `%USERPROFILE%\.wslconfig` (WSL2 オートスケール＆メモリ回収設定)

---

## 4. スクラップ＆ビルドの手順

新しい環境（新規PCやWSLの再構築時）では、以下の 1 コマンドで全環境が復元されます。

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/palpeace/dotfiles/main/scripts/bootstrap.sh)"
```
