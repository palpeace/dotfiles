# AGENTS.md

このリポジトリは chezmoi のソース（Public）。`.chezmoiroot` により `home/` 以下がホームディレクトリに展開される。

## ルール

- **Public に置くのは「組み方」だけ。** 認証情報、実行時の状態、ログ、固有名詞（社名・顧客名・社内ホスト名など）は置かない。
  - 秘密や固有の値はリポジトリ外のファイルに置き、ここからは読み込むだけにする（例: `~/.gitconfig.work`、`~/.config/zsh/secrets.zsh`）。
- **ユーザースコープ（`~/.claude`、`~/.codex`、`~/.gemini`）に入るものは、すべてこのリポジトリで宣言する。**
  - 既存キーを残したい JSON などは `modify_` スクリプトで必要なキーだけを書き換える。
- **ブートストラップが終わったら、手で何もインストールしない。** 必要なものはここに書いてから `chezmoi apply` する。
  - OS の土台（ログインシェルの zsh、git、curl など）は apt で入れ、`bootstrap.sh` に書く。
  - ユーザーのツール（chezmoi、gh、gitleaks など）は mise で入れ、`home/dot_config/mise/config.toml` に書く。
  - ログインシェルは mise で入れない（バージョン更新でパスが変わるとログインできなくなるため）。
- **GitHub Actions は利用しない。** 検査はローカルの pre-push フック（gitleaks）で行う。

## 変更の手順

1. `home/` 以下を編集する
2. `chezmoi diff` で差分を確認する
3. `chezmoi apply` する
4. コミットする（push 時に gitleaks が自動で走る）
