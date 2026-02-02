# =============================================================================
# My Dotfiles Justfile (Volta Edition)
# =============================================================================

set shell := ["bash", "-c"]
home := env_var('HOME')

default:
    @just --list

# 🚀 Setup Everything
setup: update-system install-gh install-apt link setup-fd setup-locale install-rust install-python install-node install-ai install-nvim install-clipboard install-gitleaks setup-projects
    @echo "🎉 All Setup Complete! Please restart your shell."

# -----------------------------------------------------------------------------
# 🔗 Configuration
# -----------------------------------------------------------------------------

link:
    @echo "🔗 Linking dotfiles via Stow..."
    mkdir -p {{home}}/.config
    @if [ -f {{home}}/.bashrc ] && [ ! -L {{home}}/.bashrc ]; then \
        echo "Backing up existing .bashrc..."; \
        mv {{home}}/.bashrc {{home}}/.bashrc.backup.$(date +%s); \
    fi
    @if [ -f {{home}}/.gitconfig ] && [ ! -L {{home}}/.gitconfig ]; then \
        echo "Backing up existing .gitconfig..."; \
        mv {{home}}/.gitconfig {{home}}/.gitconfig.backup.$(date +%s); \
    fi
    stow -v -R -t {{home}} bash nvim git

# -----------------------------------------------------------------------------
# 📁 Projects & Git Identity
# -----------------------------------------------------------------------------

setup-projects:
    @echo "📁 Creating project directories..."
    mkdir -p {{home}}/projects/personal
    mkdir -p {{home}}/projects/company

setup-personal-git:
    @if [ -f {{home}}/.gitconfig-personal ]; then \
        echo "Found {{home}}/.gitconfig-personal. Skipping."; \
        exit 0; \
    fi
    @read -r -p "Personal git name: " PERSONAL_NAME </dev/tty; \
    read -r -p "Personal git email: " PERSONAL_EMAIL </dev/tty; \
    read -r -p "Personal GitHub username: " PERSONAL_GH </dev/tty; \
    printf "%s\n" \
        "[user]" \
        "    name = $PERSONAL_NAME" \
        "    email = $PERSONAL_EMAIL" \
        "[credential]" \
        "    username = $PERSONAL_GH" \
        "    useHttpPath = true" \
        > {{home}}/.gitconfig-personal; \
    mkdir -p {{home}}/.config/git

setup-company-git:
    @if [ -f {{home}}/.gitconfig-company ]; then \
        echo "Found {{home}}/.gitconfig-company. Skipping."; \
        exit 0; \
    fi
    @read -r -p "Company git name: " COMPANY_NAME </dev/tty; \
    read -r -p "Company git email: " COMPANY_EMAIL </dev/tty; \
    read -r -p "Company GitHub username: " COMPANY_GH </dev/tty; \
    printf "%s\n" \
        "[user]" \
        "    name = $COMPANY_NAME" \
        "    email = $COMPANY_EMAIL" \
        "[credential]" \
        "    username = $COMPANY_GH" \
        "    useHttpPath = true" \
        > {{home}}/.gitconfig-company; \
    mkdir -p {{home}}/.config/git

# -----------------------------------------------------------------------------
# 📦 System & Basic Tools
# -----------------------------------------------------------------------------

update-system:
    @echo "🔄 Updating system..."
    sudo apt update && sudo apt upgrade -y
    # 不要なパッケージの削除 (autoremove)
    sudo apt autoremove -y

install-gh:
    @echo "🐙 Checking GitHub CLI..."
    @if ! command -v gh >/dev/null; then \
        echo "Installing gh..."; \
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg; \
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg; \
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null; \
        sudo apt update && sudo apt install -y gh; \
    fi

install-apt:
    @echo "📦 Installing APT packages..."
    sudo apt update
    sudo apt install -y $(cat pkglist.txt | grep -v "^#" | tr '\n' ' ')

gh-personal-login:
    @if ! command -v gh >/dev/null; then \
        echo "gh not found. Run: just install-gh"; \
        exit 1; \
    fi
    @PERSONAL_GH=$(git config --file {{home}}/.gitconfig-personal credential.username 2>/dev/null); \
    if [ -z "$PERSONAL_GH" ]; then \
        read -r -p "Personal GitHub username: " PERSONAL_GH </dev/tty; \
    fi; \
    if [ -z "$PERSONAL_GH" ]; then \
        echo "Personal GitHub username is required."; \
        exit 1; \
    fi; \
    if ! gh auth status -h github.com -u "$PERSONAL_GH" >/dev/null 2>&1; then \
        gh auth login -h github.com -p https; \
    fi; \
    gh auth switch -h github.com -u "$PERSONAL_GH"; \
    gh auth setup-git

gh-company-login:
    @if ! command -v gh >/dev/null; then \
        echo "gh not found. Run: just install-gh"; \
        exit 1; \
    fi
    @COMPANY_GH=$(git config --file {{home}}/.gitconfig-company credential.username 2>/dev/null); \
    if [ -z "$COMPANY_GH" ]; then \
        read -r -p "Company GitHub username: " COMPANY_GH </dev/tty; \
    fi; \
    if [ -z "$COMPANY_GH" ]; then \
        echo "Company GitHub username is required."; \
        exit 1; \
    fi; \
    if ! gh auth status -h github.com -u "$COMPANY_GH" >/dev/null 2>&1; then \
        gh auth login -h github.com -p https; \
    fi; \
    gh auth switch -h github.com -u "$COMPANY_GH"; \
    gh auth setup-git

gh-switch-personal:
    @if ! command -v gh >/dev/null; then \
        echo "gh not found. Run: just install-gh"; \
        exit 1; \
    fi
    @PERSONAL_GH=$(git config --file {{home}}/.gitconfig-personal credential.username 2>/dev/null); \
    if [ -z "$PERSONAL_GH" ]; then \
        read -r -p "Personal GitHub username: " PERSONAL_GH </dev/tty; \
    fi; \
    if [ -z "$PERSONAL_GH" ]; then \
        echo "Personal GitHub username is required."; \
        exit 1; \
    fi; \
    gh auth switch -h github.com -u "$PERSONAL_GH"

gh-switch-company:
    @if ! command -v gh >/dev/null; then \
        echo "gh not found. Run: just install-gh"; \
        exit 1; \
    fi
    @COMPANY_GH=$(git config --file {{home}}/.gitconfig-company credential.username 2>/dev/null); \
    if [ -z "$COMPANY_GH" ]; then \
        read -r -p "Company GitHub username: " COMPANY_GH </dev/tty; \
    fi; \
    if [ -z "$COMPANY_GH" ]; then \
        echo "Company GitHub username is required."; \
        exit 1; \
    fi; \
    gh auth switch -h github.com -u "$COMPANY_GH"

setup-fd:
    @if ! command -v fd >/dev/null; then sudo ln -s $(which fdfind) /usr/local/bin/fd; fi

setup-locale:
    @echo "🇯🇵 Generating Japanese locale..."
    sudo locale-gen ja_JP.UTF-8
    sudo update-locale LANG=ja_JP.UTF-8

# -----------------------------------------------------------------------------
# 🦀 Rust (rustup)
# -----------------------------------------------------------------------------

install-rust:
    @echo "🦀 Checking Rust..."
    @if ! command -v rustup >/dev/null; then \
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
    else rustup update; fi

# -----------------------------------------------------------------------------
# 🐍 Python (uv) 
# -----------------------------------------------------------------------------

install-python:
    @echo "🐍 Checking uv & Python..."
    @if ! command -v uv >/dev/null; then \
        curl -LsSf https://astral.sh/uv/install.sh | sh; \
    fi
    # Python 3.11 のインストール
    {{home}}/.local/bin/uv python install 3.11 || true

# -----------------------------------------------------------------------------
# 🟢 Node.js (Volta) 
# -----------------------------------------------------------------------------

install-node:
    @echo "🟢 Checking Volta & Node..."
    # 1. Volta インストール
    @if ! command -v volta >/dev/null; then \
        curl https://get.volta.sh | bash; \
    fi
    
    # 2. node & npm & pnpm
    {{home}}/.volta/bin/volta install node
    {{home}}/.volta/bin/volta install npm@latest
    {{home}}/.volta/bin/volta install pnpm

# -----------------------------------------------------------------------------
# 🤖 AI Tools
# -----------------------------------------------------------------------------

install-ai:
    @echo "🤖 Installing AI tools..."
    # Kiro CLI
    @if [ ! -d "{{home}}/.kiro" ]; then \
        curl -fsSL https://cli.kiro.dev/install | bash; \
    fi
    
    # Codex & Copilot
    {{home}}/.volta/bin/volta install @github/copilot
    {{home}}/.volta/bin/volta install @openai/codex

# -----------------------------------------------------------------------------
# 📝 Editors (Neovim) & Misc
# -----------------------------------------------------------------------------

install-nvim:
    @echo "📝 Installing Neovim (Latest)..."
    @if [ ! -f "/opt/nvim/bin/nvim" ]; then \
        echo "Clean install needed. Running..."; \
        sudo rm -rf /opt/nvim; \
        curl -fL --retry 3 --retry-delay 1 -o nvim-linux64.tar.gz \
          https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz; \
        tar -tzf nvim-linux64.tar.gz >/dev/null; \
        sudo tar -C /opt -xzf nvim-linux64.tar.gz; \
        sudo mv /opt/nvim-linux-x86_64 /opt/nvim; \
        rm -f nvim-linux64.tar.gz; \
    else \
        echo "✅ Neovim is already installed correctly."; \
    fi

install-clipboard:
    @if ! command -v win32yank.exe >/dev/null; then \
        curl -L --fail -o win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip; \
        unzip -p win32yank.zip win32yank.exe > win32yank.exe; chmod +x win32yank.exe; sudo mv win32yank.exe /usr/local/bin/; rm win32yank.zip; \
    fi

install-gitleaks:
    @VERSION="${GITLEAKS_VERSION:-}"; \
    if [ -z "$VERSION" ]; then \
        LATEST_URL=$(curl -sL -o /dev/null -w '%{url_effective}' https://github.com/gitleaks/gitleaks/releases/latest); \
        VERSION=${LATEST_URL##*/tag/v}; \
        VERSION=${VERSION%%/*}; \
    fi; \
    if [ -z "$VERSION" ]; then \
        echo "Failed to determine gitleaks version."; \
        echo "Latest URL: ${LATEST_URL:-<empty>}"; \
        exit 1; \
    fi; \
    VERSION=${VERSION#v}; \
    TAG="v${VERSION}"; \
    OS=linux; \
    ARCH=$(uname -m); \
    case "$ARCH" in \
        x86_64) ARCH=x64 ;; \
        aarch64|arm64) ARCH=arm64 ;; \
        *) echo "Unsupported arch: $ARCH"; exit 1 ;; \
    esac; \
    mkdir -p {{home}}/.local/bin; \
    curl -sSfL \
        "https://github.com/gitleaks/gitleaks/releases/download/${TAG}/gitleaks_${VERSION}_${OS}_${ARCH}.tar.gz" \
        | tar -xz -C {{home}}/.local/bin gitleaks; \
    gitleaks protect --staged
