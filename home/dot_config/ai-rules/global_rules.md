# Global AI Agent Rules & Engineering Principles

## 1. ツール配置の判断ポリシー (Tool Placement Policy)
新規ツールの追加や設定変更を行う場合、以下の基準で配置場所を決定すること：
- **グローバル (~/.config/mise/config.toml)**:
  - どのプロジェクトでも日常的に使う汎用 CLI (`rg`, `fd`, `bat`, `eza`, `jq`, `just`, `git` 関連)
  - AIへの指示作成やレビューに使うエディタ・TUI (`micro`, `gitui`, `oxker`, `yazi`)
  - AIが利用したりCLIから叩くフォーマッター (`prettier`, `markdownlint-cli2`)
  - シェル統合ツール・言語ランタイム (`starship`, `atuin`, `zoxide`, `node`, `rust`, `python`, `go`)
- **プロジェクトローカル (プロジェクト直下の mise.toml / Cargo.toml / package.json)**:
  - 言語・フレームワーク固有のビルド/テストツール (`bacon`, `cargo-make` 等)
  - チームで特定バージョンを固定したいツールや、ビルド処理 (`cargo build` 等) が必要なツール

## 2. ドットファイル・環境設定の原則 (Chezmoi & Environment)
- 本環境は `chezmoi` で管理されている。設定ファイルやドットファイルを変更する際は、`$HOME` 直下のライブファイルではなく、リポジトリ内の `home/...` 配下のソースファイルを一次情報源として優先編集すること。
- 秘密情報（APIキー、トークン）は `~/.config/zsh/secrets.zsh` または環境変数から読み込み、リポジトリや設定ファイル内に絶対に直接記述・露出させないこと。

## 3. 実装・デバッグの品質ガードレール (Quality & Safety Principles)
- **ログ優先主義**: エラーやビルド失敗が発生した場合、推測で修正せず、必ずフルログやスタックトレースを確認してから診断すること。
- **表面的な誤魔化しの禁止**: テストの削除、例外の空キャッチ（try-except pass）、ダミー値の返却による修正は厳禁。根本原因を特定して解消すること。
- **検証の徹底**: ファイル編集のみで完了とせず、必ずビルド・テスト・実行コマンドを動かして成功を確認すること。

## 4. WSL2 & Git 運用標準 (WSL2 & Git Conventions)
- ソースコードやプロジェクトの作業領域は、Windows 領域 (`/mnt/c/`) ではなく、高速かつパーミッション事故のない WSL2 Linux 領域 (`~/src/`) を優先使用すること。
- Git コミットメッセージは Prefix 形式 (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`) を採用し、簡潔かつ明確に記述すること。

## 5. Web開発・UIデザイン標準 (Web Application Defaults)
- 新規 Web アプリケーション開発時は Vanilla CSS とモダンなデザインシステム（グラデーション、アニメーション、ダークモード、モダンフォント）を採用し、品質の高い UI を構築すること。

## 6. グローバルスキルの参照指針 (Agentic Skills Usage)
- 環境共通の拡張スキルは `~/.agents/skills/` 配下に自動配備されています。
- マルチエージェントオーケストレーション、Computer Use（GUI/画面操作）、および特定の専門的タスクの実行時は、`~/.agents/skills/<skill-name>/SKILL.md` に定義された仕様・スクリプトを参照して実行すること。
