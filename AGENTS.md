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

## 構成の要点

- `chezmoi apply` の中で入れるもの: mise のツール（`run_onchange_before_10`）、AI エージェント CLI（`run_onchange_after_10`）、補完（`20`）、yazi のプラグイン（`21`）、Docker と SSH サーバ（`30`、sudo が要る）。
- 更新は `update-system` にまとめる（dotfiles・apt・mise・sheldon・claude / codex / agy）。
- AI エージェントのグローバル指示は `home/dot_config/ai-rules/global_rules.md` の1本で、各 CLI の読む場所へ symlink する（Claude Code: `~/.claude/CLAUDE.md`、codex: `~/.codex/AGENTS.md`、agy: `~/.gemini/config/AGENTS.md`）。Claude Code が CLAUDE.md の代わりに AGENTS.md を読むのはプロジェクトの階層だけで、`~/.claude/AGENTS.md` は読まない。CLI を足すときは symlink も足す。

## 落とし穴

- スクリプトでテンプレート（`{{ }}`）が展開されるのは `.tmpl` 拡張子のときだけ。`run_onchange_` にハッシュを埋めるなら必ず `.tmpl` にする。
- `chezmoi apply` は最初に失敗したところで全体が止まる。`modify_` スクリプトは失敗しても入力をそのまま返し、apply を止めない。
- `~/.claude.json` は Claude Code が実行時に書く大きなファイルなので、`modify_` で書かない。MCP やプラグインは公式 CLI（`claude mcp add` / `claude plugin install`）で入れる。
- 公式インストーラはシェルの設定ファイルに PATH を書き足すことがある（agy は PATH が通っていても4ファイルに足す）。インストールと更新の前後で退避して戻す。
- 標準コマンド（`ls` `cat` `rm` `cd`）を alias で上書きしない。Claude Code はシェルの alias を引き継いでコマンドを実行する。
