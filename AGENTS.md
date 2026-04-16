# Repository Notes

## Repository role

- This repository is a chezmoi source directory for the user's local environment.
- Treat files in this repository as the source of truth for managed dotfiles and setup scripts.

## Managed areas

- Shell configuration: `home/dot_zshrc`, `home/dot_config/zsh-abbr/...`
- Git configuration: `home/dot_gitconfig.tmpl`
- Tmux configuration: `home/dot_tmux.conf`
- Prompt and tool configuration: `home/dot_config/starship.toml`, `home/dot_config/mise/config.toml`, `home/dot_config/sheldon/plugins.toml`
- Editor configuration: `home/dot_config/zed/settings.json.tmpl`
- Local helper scripts: `home/dot_local/bin/...`
- Setup hooks and bootstrap helpers: `home/.chezmoiscripts/...`

## Edit policy

- Before editing a dotfile or app config, first check whether a corresponding managed file exists in this repository under `home/...`.
- When changing dotfiles or app configuration, edit the chezmoi-managed source file in this repo first, not the live file under `$HOME`.
- Prefer paths in this repository such as `home/dot_config/...`, `home/dot_local/...`, and `home/.chezmoiscripts/...`.
- Only edit the live file in `$HOME` directly when the user explicitly asks for it or when the file is not managed by chezmoi.
- If both a live file and a chezmoi-managed source file exist, treat the file in this repository as the source of truth.

## Config organization

- For managed config files, prefer grouping entries by primary use rather than by installer backend or alphabetical order.
- When a file mixes sources such as `aqua:`, `npm:`, `cargo:`, or `go:`, keep the order natural for humans and use comments to explain purpose where needed.
- Keep comments short and practical. Prefer why the tool is present over repeating the tool name.
- Do not rely on config file ordering to satisfy runtime prerequisites. If `npm:` tools require Node or `cargo:` tools require Rust, make that explicit in setup scripts.
