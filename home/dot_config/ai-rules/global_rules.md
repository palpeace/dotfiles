# グローバル指示（AI エージェント共通）

このファイルは複数の CLI から symlink で読まれる。実体は dotfiles の `home/dot_config/ai-rules/global_rules.md`。

## 1. 返答
- ユーザーへの返答は日本語で書く。コマンド、識別子、エラーメッセージは原文のまま。
- 答えを最初の1文に置く。何をしたかではなく、何が変わったか・何が分かったかを書く。

## 2. 環境（chezmoi で管理している）
- ドットファイルやツールの設定を変えるときは、`$HOME` の実ファイルではなく dotfiles の `home/...` を編集し、`chezmoi diff` → `chezmoi apply` する。
- 手でツールをインストールしない。mise のツールは `~/.config/mise/config.toml`（dotfiles 側）に、OS のパッケージは `bootstrap.sh` に書いてから apply する。
- 開発は Docker に寄せる。言語ランタイム（node / python / rust など）はホストのグローバルに置かず、プロジェクトのコンテナか `mise.toml` に置く。
- シェルの TUI や CLI（starship、zoxide、fzf、eza、bat、delta、yazi、gitui、micro、herdr など）は、人が AI を監督するための道具。不要と判断して削除を提案しない。
- 自己更新する AI エージェント CLI（`claude` / `codex` / `agy`）は mise に載せず `~/.local/bin` に置き、各 CLI の `update` に任せる。

## 3. 秘密情報
- API キーやトークンは `~/.config/zsh/secrets.zsh` か環境変数から読む。リポジトリや設定ファイルに書かない。

## 4. 実装とデバッグ
- エラーやビルド失敗は、推測で直さずにフルログやスタックトレースを見てから診断する。
- テストの削除、例外の握り潰し、ダミー値の返却でごまかさない。根本原因を直す。
- ファイルを編集しただけで完了にしない。ビルド・テスト・実行で確かめる。

## 5. WSL2 と Git
- 作業は Windows 側（`/mnt/c/`）ではなく WSL2 側（`~/repos/`）で行う。
- コミットメッセージは Prefix 形式（`feat:` `fix:` `docs:` `refactor:` `test:`）で簡潔に書く。
