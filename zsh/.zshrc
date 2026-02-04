# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ~/.zshrc managed by dotfiles (stow).

# ---- oh-my-zsh ----
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins (keep minimal)
plugins=(git)

if [ -f "$HOME/.config/shell/env" ]; then
  source "$HOME/.config/shell/env"
fi

if [ -d "$ZSH" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# ---- History ----
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ---- Tools ----
# Python Aliases (Safe Shim)
alias python='uv run python'
alias pip='uv run pip'

# Neovim
export EDITOR=nvim
alias v='nvim'
alias vim='nvim'

# GitBucket helper (start keyring once per session)
gbsk() {
  eval "$(just -f ~/dotfiles/Justfile start-keyring)" || return $?
  if [ "$#" -gt 0 ]; then
    "$@"
  fi
}

# Local overrides (per-machine)
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
