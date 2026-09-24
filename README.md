# dotfiles

WSL2（Ubuntu 24.04）の環境を [chezmoi](https://www.chezmoi.io/) で宣言し、新しい WSL をワンライナーで復元するためのリポジトリ。
ここに置くのは「組み方」だけで、認証情報・実行時の状態・ログは置かない。ルールと構成の詳細は [AGENTS.md](AGENTS.md)。

## 復元

### 1. Windows 側（初回だけ・手作業）

`.wslconfig` と Windows Terminal の設定は Windows 側のファイルなので、このリポジトリでは管理しない。

`%USERPROFILE%\.wslconfig`（`wsl --install` の前に作る）:

```ini
# memory / swap は既定（ホスト RAM の 50% / その 25%）のまま。絞ると OOM を招く
[experimental]
autoMemoryReclaim=gradual   # 解放したメモリを段階的に Windows へ返す
sparseVhd=true              # 新しく作る VHD を使用量に応じて縮める
```

- `autoMemoryReclaim` と `sparseVhd` は `[wsl2]` ではなく `[experimental]` に書く（`[wsl2]` では無視される）。
- 不正な値が1つでもあると、ファイル全体が無視される（例: `memory=50%`）。

Windows Terminal の `settings.json` に足すもの:

```jsonc
{
  "profiles": {
    "defaults": {
      "bellStyle": ["window", "taskbar"], // Claude Code の入力待ちでタスクバーを点滅させる
      "historySize": 50000                // AI の長い出力を遡れるようにする
    }
  }
}
```

フォントは Nerd Font（starship・eza のアイコン用）にする。

### 2. WSL の中

```sh
curl -fsSL https://raw.githubusercontent.com/palpeace/dotfiles/main/bootstrap.sh | sh
```

zsh・mise・chezmoi を入れて dotfiles を展開し、`chezmoi apply` の中で残りを入れる
（mise のツール、claude / codex / agy、Claude Code のプラグイン、Docker Engine、SSH サーバ、Google Chrome）。
途中で sudo のパスワードを聞かれる。

### 3. 認証（手作業）

1. 新しい端末を開く（zsh で起動する）
2. `gh auth login`
3. `claude` / `codex` / `agy` をそれぞれ一度起動してログインする
4. 仕事用の git 設定が要るなら `~/.gitconfig.work` を作る（リポジトリには入れない）
5. SSH で入るなら `~/.ssh/authorized_keys` に公開鍵を置く（リポジトリには入れない）

## 日常の操作

| やりたいこと | コマンド |
|---|---|
| 設定を変える | `home/` を編集 → `chezmoi diff` → `chezmoi apply` → コミット |
| すべて更新する | `update-system`（dotfiles・apt・mise・zsh プラグイン・AI の CLI） |
| Claude Code をモデル指定で起動 | `opus` / `sonnet` / `fable` / `haiku`（例: `opus xhigh "..."`） |

push の前に gitleaks が秘密を検査する（`.githooks/pre-push`）。

## 検証が必要な項目

まだ実機で確かめていないもの。確かめたら、この一覧から消す。

- [ ] **bootstrap を新しい WSL で通しで実行する**（Docker・SSH サーバ・Chrome を足した後の版）。
      1段目の sudo の後、`chezmoi apply` の中の sudo が止まらずに進むこと。
- [ ] **NVIDIA の GPU がある端末**で `docker run --rm --gpus all ubuntu nvidia-smi` が GPU を表示すること。
      NVIDIA の無い端末では Toolkit を入れずに終わること。
- [ ] **ブラウザ操作**: Claude Code から browse プラグインのスキルが使われること
      （CLI の `browse open --local`・`snapshot`・`screenshot` は確認済み）。
- [ ] **`update-system` の初回実行**: すべての段が成功すること。`agy update` が `~/.bashrc` などを書き換えないこと。
- [ ] **codex と agy がグローバル指示を読むこと**（ログイン後）。`~/.codex/AGENTS.md` と `~/.gemini/config/AGENTS.md`。
- [ ] **codex プラグイン**: `codex login` の後、Claude Code から codex を呼べること。
- [ ] **SSH サーバ**: 別の PC から鍵で入れること。
      WSL2 では同じ PC のディストリビューションが 22 番を共有するので、SSH サーバを持てるのは1つだけ。
- [ ] **docker を sudo なしで使えること**（WSL を開き直した後）。
- [ ] **Windows 側の PATH が混ざらないこと**（`wsl --shutdown` の後）。`echo $PATH` に `/mnt/c` が無く、
      `gh auth login` などが wslview で Windows のブラウザを開けること。
