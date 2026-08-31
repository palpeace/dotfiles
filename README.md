# 🚀 dotfiles

[MIT License](./LICENSE) © 2026 palpeace

Modern, minimal, zero-touch, and AI-native development environment optimized for WSL2.

### 💡 Core Philosophy: "The Human is a Director, not a Coder"
人間の役割は「コードを書くプログラマ」から、AIへの指示とレビューを行う「企画者・監督者」へシフトしました。
そのため、LSPや重厚なIDEなど**「人間がコードを書くためのツール」は徹底的に排除（ミニマリズム）**されています。
一方で、AIの挙動を監視し、緊急時にシステムを操作するための**「ターミナル上での状況認識能力と機動力（Situational Awareness）」は必須**であるため、モダンなCLIツール群（eza, bat, starship, zsh-autosuggestions等）は**「監督者のためのコマンドセンターUX」として積極的に維持**しています。

---

## 🛠 Features

- **Dotfiles Management**: [chezmoi](https://www.chezmoi.io/) - 冪等性を保ったワンライナー環境復元
- **Tool Management**: [mise](https://mise.jdx.dev/) - 言語・CLIツールのバージョン管理
- **Shell & Prompt**: [Zsh](https://www.zsh.org/) + [Sheldon](https://sheldon.cli.rs/) + [Starship](https://starship.rs/)
- **AI Native Core**: Claude Code, Copilot, Antigravity CLI (`agy`)
- **WSL Zero-Touch**: `/etc/wsl.conf` (`systemd=true`, `appendWindowsPath=false`) の全自動セットアップ対応
- **WSL2 リソース最適化**: `.wslconfig` は Windows 側のファイルのため本リポジトリの管理外。[Quick Start の Step 0](#0-windows-側の事前設定-初回のみ) を参照

---

## 📦 Quick Start (Scrap & Build)

### 0. Windows 側の事前設定 (初回のみ)

`.wslconfig` は Windows 側のファイルで WSL 内からは管理できないため、**`wsl --install` を実行する前に**手動で作成します。
メモ帳等で `%USERPROFILE%\.wslconfig` を作成し、以下を記述してください。

```ini
# memory / swap は既定 (ホスト RAM の 50% / その 25%) が妥当なため指定しない。
# 中途半端に絞るとかえって OOM Killer を誘発する。

[experimental]
# 解放済みメモリをホストへ段階的に返す。
# 既定の dropCache はページキャッシュを即時全破棄するためビルドが遅くなる。
autoMemoryReclaim=gradual
# 新規作成される VHD を自動でスパース化し、使用量に応じて縮小させる (既定: false)
sparseVhd=true
```

> [!IMPORTANT]
>
> - `autoMemoryReclaim` と `sparseVhd` は **`[wsl2]` ではなく `[experimental]` セクション**です。
>   `[wsl2]` 配下に書いても無視されます。
> - `memory` は `size` 型 (`16GB` 等) のみで、**`50%` のようなパーセント指定は不正**です。
>   不正な値があるとファイルが malformed と判定され、**設定全体が無視されます**。
> - `sparseVhd` は**新規に作成される VHD にのみ適用**されます。既存ディストリに後から効かせるには
>   `wsl --manage <Distro> --set-sparse true` が必要です。スクラップ&ビルドはこれを効かせる好機です。
> - `dnsTunneling` / `autoProxy` は既定で `true` のため明示不要です。

#### Windows Terminal の設定

`.wslconfig` と同じく Windows 側のファイル (`%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`) のため、本リポジトリの管理外です。
「監督者のコマンドセンター」として以下を設定します。既存の JSON にマージしてください。

```jsonc
{
  // タブ / ペイン構成を再起動後に復元する
  "firstWindowPreference": "persistedWindowLayout",
  "launchMode": "maximized",

  "profiles": {
    "defaults": {
      // AI が入力待ちになった瞬間にタスクバーを点滅させる (Claude Code 側のベルと組で機能)
      "bellStyle": ["window", "taskbar"],
      // AI の長い出力を遡れるようにする。既定の 9001 行では即座に溢れる
      "historySize": 50000
    }
  },

  "actions": [
    { "command": "togglePaneZoom", "id": "User.togglePaneZoom" },
    { "command": { "action": "splitPane", "split": "right", "size": 0.28, "splitMode": "duplicate" }, "id": "User.splitPane.sidebar" }
  ],
  "keybindings": [
    { "id": "User.togglePaneZoom",    "keys": "alt+shift+z" },
    { "id": "User.splitPane.sidebar", "keys": "alt+shift+e" }
  ]
}
```

> [!NOTE]
> `alt+←/→/↑/↓` (ペイン間移動)、`alt+shift+←/→` (ペインのリサイズ)、`alt+shift+d` (分割) は
> Windows Terminal の**既定バインドなので設定不要**です。上記は既定に無い2つだけを足しています。

##### ペイン運用の指針

- **タブ = 1 プロジェクト / worktree**。ペインは 2 分割までに留める。
- Claude Code は `tui: "fullscreen"` で動くため、細いペインに入れると描画が崩れる。
  **細い側 (28%) に yazi / gitui、広い側に Claude Code** を置く。
- ペインを増やすより `alt+shift+z` (`togglePaneZoom`) で切り替える。
  普段は細いサイドバー、じっくり見たいときだけ一時的に全画面へズームして戻す。

### 1. ワンライナー実行

新しい WSL インスタンス（`wsl --install` 直後）で以下の 1 コマンドを実行するだけで、全自動で完全復元します。

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/palpeace/dotfiles/main/scripts/bootstrap.sh)"
```

このワンライナーにより、以下が全自動で完了します。
- `/etc/wsl.conf` の最適化 (`systemd=true`, `appendWindowsPath=false`)
- `chezmoi init --apply` による設定ファイルの配置
- Git の基本情報 (`~/.gitconfig.local`) の対話生成・設定
- OS 依存パッケージと `mise` / AI ツールの自動導入
- 自動ヘルスチェック（Smoke Tests）の実行

### 2. WSL の再起動 (必須)

`/etc/wsl.conf` の `systemd=true` / `appendWindowsPath=false` は**再起動後に初めて有効**になります。
Windows 側の PowerShell で以下を実行してください。

```powershell
wsl --shutdown
```

> [!TIP]
> 社内プロキシ等で apt ミラー（山形大）へ到達できない場合は、`USE_JP_MIRROR=0` を付けて実行すると
> 既定のミラーのままセットアップできます: `USE_JP_MIRROR=0 setup-system`

---



## 🧩 マシン個別オプショナル設定 (Docker / GPU)

マシンごとに Docker Engine や GPU アクセラレーションの有無を設定できます。

```zsh
# 対話形式でマシン構成を選択 (成果物は ~/.config/dotfiles/machine.env に保存)
configure-machine

# 選択された設定に基づいてオプショナルコンポーネントをセットアップ
setup-optional
```

---

## ⚡ 日常のシェルヘルパー機能

`.zshrc` に定義されているヘルパー関数です。

```zsh
# 1. chezmoi の変更を差分確認してから適用する
#    注意: mise/config.toml を変更した後は、run_onchange により setup-system
#          (apt / mise の実導入) が続けて走る。数分かかり sudo を求められる。
sync-dotfiles

# 2. dotfiles を取り込んでから、OS パッケージと管理ツールをまとめて更新する
update-all

# 3. yazi で移動し、抜けた場所へシェルも cd する (alias ではなく関数)
y
```

---

## ⌨️ Command Cheat Sheet (エイリアス・ショートカット)

ターミナルでの機動力と状況認識を高めるため、以下の短いコマンド（エイリアス）が設定されています。

| コマンド | 展開される内容 / 使うツール | 用途・説明 |
| :--- | :--- | :--- |
| **ファイル操作・移動** | | |
| `cd` | `z` (zoxide) | 過去の履歴からよしなにディレクトリを推測して高速ジャンプ |
| `ls`, `ll`, `la` | `eza --icons` | カラフルなアイコン付きでディレクトリ内容を表示 |
| `tree` | `eza --tree` | ディレクトリ構造をツリー状に可視化 |
| `cat` | `bat` | シンタックスハイライト付きでファイルの中身をプレビュー |
| `rm` | `trash-put` (trash-cli) | 完全に削除せず、システムのゴミ箱に安全に移動。一覧 `trash-list` / 復元 `trash-restore` / 即時削除は `\rm` |
| **司令塔ツール (TUI/エディタ)** | | |
| `mi` | `micro` | CLI上でサクッとファイルを修正するための超軽量エディタ |
| `y` | `yazi` | IDEのサイドバー代わりに使う超高速なTUIファイラ（**抜けた場所へシェルも `cd` する**） |
| `gu` | `gitui` | Gitの差分確認・コミットを行うTUI（レビューの要） |
| `ox` | `oxker` | Dockerコンテナの状態確認・管理を行うTUI |
| **AI エージェント** | | |
| `agy-a` | `agy --dangerously-skip-permissions` | 権限確認をスキップして Antigravity を全自動起動 |
| `cc-a` | `claude --permission-mode auto` | Claude Code を完全自動モードで起動 |
| `opus` / `sonnet` | `claude --permission-mode auto --model '<model>[1m]'` | 1M コンテキストで起動。第1引数が `low`〜`max` なら `--effort` として渡す (例: `opus xhigh`) |
| `fable` | `claude --permission-mode auto --model 'fable[1m]'` | 最難関・長時間タスク向けの Fable 5 で起動。Opus の 2 倍単価で、専用の週次上限を超えると usage credits を消費する |
| `haiku` | `claude --permission-mode auto --model haiku` | Haiku で起動 (effort 非対応) |
| `cc-p-opus` / `cc-p-fable` | `claude --permission-mode plan --model '<model>[1m]'` | Claude Code (Opus / Fable) を計画モード(Plan)で起動 |
| **その他** | | |
| `ghs` | `gh auth switch` | GitHubの認証アカウントを素早く切り替え |

---

## 👁 AI の稼働状況を把握する (Situational Awareness)

「AI が実行中か待機中か」を**確認しに行かない**のが方針です。見に行く (Pull) のをやめ、
通知させる (Push) 3 層構成にしています。設定は `home/dot_claude/modify_settings.json` で管理されます。

| 層 | 設定キー | 何が起きるか | いつ効くか |
| :--- | :--- | :--- | :--- |
| **進捗インジケータ** | `terminalProgressBarEnabled` | 長時間処理中に OSC 9;4 を出力し、Windows Terminal がタブとタスクバーに進捗を描く**はずだが、この環境では動作を確認できなかった**。WT 側は `printf '\033]9;4;3;0\007'` に反応するので受け手は対応済み。CC 側の既定は `true`、ゲート (`tengu_terminal_sidebar`) も無関係と確認済みだが、数分の処理でも描画されない。原因未特定 | （現状は効果なし） |
| **ベル** | `preferredNotifChannel: "terminal_bell"` | 入力待ちになった瞬間にベル。WT 側の `bellStyle: ["window","taskbar"]` と組でタスクバーが点滅する | 他のウィンドウで作業中 |
| **モバイル push** | `inputNeededNotifEnabled` | 権限プロンプトや質問が待っているときスマホへ通知 | 離席中 |

> [!NOTE]
> Claude Code の Agents View は「1 セッション内のサブエージェント一覧」であり、
> 複数セッションを俯瞰するダッシュボードではありません。複数プロジェクトを並列で回す場合は
> **Windows Terminal のタブ + 上記の通知**の組み合わせのほうが素直です。

---

## 🗂 yazi と Claude Code の連携

`y` (yazi) を「AI へ渡す対象を探すためのサイドバー」として使うための導線です。

- **`y` で辿り着いた場所からそのまま AI を起動できる**
  `y` は alias ではなく関数で、yazi 終了時に最後のディレクトリへシェルも `cd` します。
  そのまま `opus` / `cc-a` を叩けば、そのプロジェクトで Claude Code が起動します。
- **yazi の中から直接起動する**
  yazi 上で `C` を押すと、そのディレクトリで Claude Code (Opus / auto) が起動します
  (`home/dot_config/yazi/keymap.toml`)。
- **ファイルの指定はパスのコピーより `@` 補完が速い**
  yazi でプレビューして当たりを付け、Claude Code のプロンプトでは `@` のファジー補完で渡すのが最短です。
  なお本環境は `appendWindowsPath=false` のため `clip.exe` が `PATH` に無く、
  yazi の yank (`c` → `p`) はクリップボード連携が OSC 52 頼みになります。

---

## 🎯 ツール管理方針 (グローバル vs プロジェクトローカル)

本環境では、グローバル環境 (`~/.config/mise/config.toml`) とプロジェクトローカル (`mise.toml`) の役割を明確に分類・分離しています。

### 📌 判断基準 3 原則

1. **どのプロジェクトを開いても常用したいか？**
   → **Yes:** グローバル (`~/.config/mise/config.toml`) に配置
2. **AIへの指示（micro）やレビュー（gitui, oxker, yazi）に必要か？**
   → **Yes:** グローバルに配置
3. **ビルド処理 (`cargo build` 等) が必要か？**
   → **Yes:** プロジェクトローカル (`mise.toml`) を優先し、グローバルには原則置かない

### ⚖️ 配置先の比較

| 分類 | 配置場所 | 対象ツール例 |
| :--- | :--- | :--- |
| **グローバル** | `~/.config/mise/config.toml` | ランタイム (Rust, Node, Go, Python)、シェル統合 (starship, sheldon, zoxide, fzf, atuin)、日常CLI (ripgrep, fd, bat, eza, jq)、司令塔エディタ/TUI (micro, gitui, oxker, yazi) |
| **PJローカル** | プロジェクト直下の `mise.toml` | 言語固有ビルド・テストツール (`bacon`, `cargo-make`)、PJ限定ツールチェーン (`decktape`)、チーム統一バージョン |

---

## 🧰 Included Base Tools

| Category | Tools |
| :--- | :--- |
| **AI Agents (Core)** | Claude Code (`claude` / `cc-a`), Copilot, Antigravity CLI (`agy` / `agy-a`) |
| **Editor / TUI** | micro (`mi`), gitui (`gu`), oxker (`ox`), yazi (`y`) |
| **CLI Essentials** | fzf, ripgrep (`rg`), fd, eza, bat, zoxide (`z`), jq, trash-cli |
| **Modern Ops** | xh, dust |
| **Formatters** | Prettier, Markdownlint |

---

## 📝 Maintenance

### 運用早見表

```zsh
# 1. dotfiles を GitHub から取り込んで反映
chezmoi update

# 2. 今の PC で変更したファイルを dotfiles リポジトリに戻す
chezmoi re-add ~/.zshrc
chezmoi cd && git add . && git commit -m "update: config" && git push

# 3. システムパッケージ & mise 管理ツール・AI ツールの最新一括更新
update-system
```

### 🔒 Identity & Security

- Git の個人情報（`user.name`, `user.email`）は管理外の `~/.gitconfig.local` に分離され、chezmoi リポジトリには露出されません。
- 秘密情報（API キー等）は `~/.config/zsh/secrets.zsh` に分離して管理されます。
- 全 AI エージェント共通のグローバルエンジニアリング規則は `home/dot_config/ai-rules/global_rules.md` で一元管理され、各ツール（Claude Code, Antigravity CLI）へ自動同期されます。

