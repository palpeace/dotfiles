# =============================================================================
# My Dotfiles Justfile (Volta Edition)
# =============================================================================

set shell := ["bash", "-c"]
home := env_var('HOME')

default:
    @just --list

# 🚀 Setup Everything
setup: update-system install-gh install-apt install-git-credential-libsecret setup-pre-commit link setup-fd setup-locale install-rust install-python install-node install-ai install-nvim install-clipboard install-gitleaks install-lazygit setup-projects
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
    stow -v -R -t {{home}} bash nvim git lazygit
    source ~/.bashrc

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
    grep -vE '^\s*(#|$)' pkglist.txt | xargs -r sudo apt install -y

setup-pre-commit:
    @if ! command -v pre-commit >/dev/null; then \
        echo "pre-commit not found. Run: just install-apt"; \
        exit 1; \
    fi
    pre-commit install

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

install-git-credential-libsecret:
    @echo "🔐 Installing git-credential-libsecret..."
    @if ! command -v git >/dev/null; then \
        echo "git not found. Install git first."; \
        exit 1; \
    fi
    @if command -v git-credential-libsecret >/dev/null; then \
        echo "✅ git-credential-libsecret already installed."; \
        exit 0; \
    fi
    @sudo apt update
    @sudo apt install -y git-credential-libsecret 2>/dev/null || \
      sudo apt install -y libsecret-1-0 libsecret-1-dev build-essential pkg-config
    @if command -v git-credential-libsecret >/dev/null; then \
        echo "✅ git-credential-libsecret installed."; \
        exit 0; \
    fi
    @if [ -f /usr/share/doc/git/contrib/credential/libsecret/Makefile ]; then \
        sudo make -C /usr/share/doc/git/contrib/credential/libsecret; \
        sudo install -m 0755 /usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret /usr/local/bin/; \
        echo "✅ git-credential-libsecret installed to /usr/local/bin."; \
    else \
        echo "libsecret helper source not found. Install git contrib or check distro package."; \
        exit 1; \
    fi


gitbucket-login:
    @if ! command -v git-credential-libsecret >/dev/null; then \
        echo "git-credential-libsecret not found. Run: just install-git-credential-libsecret"; \
        exit 1; \
    fi
    @if [ ! -f {{home}}/.gitconfig-company ]; then \
        echo "{{home}}/.gitconfig-company not found. Run: just setup-company-git"; \
        echo "Continuing and creating an empty file..."; \
        touch {{home}}/.gitconfig-company; \
    fi
    @if [ -z "$$DBUS_SESSION_BUS_ADDRESS" ]; then \
        echo "DBus session not found. Run: eval \"\\$$(just start-keyring)\""; \
        exit 1; \
    fi
    @read -r -p "GitBucket URL (e.g. https://git.example.com/gitbucket): " GITBUCKET_URL </dev/tty; \
    read -r -p "GitBucket username: " GITBUCKET_USER </dev/tty; \
    read -r -s -p "GitBucket PAT: " GITBUCKET_PAT </dev/tty; \
    echo >/dev/tty; \
    if [ -z "$GITBUCKET_URL" ] || [ -z "$GITBUCKET_USER" ] || [ -z "$GITBUCKET_PAT" ]; then \
        echo "Host/username/PAT are required."; \
        exit 1; \
    fi; \
    URL_NO_SCHEME=${GITBUCKET_URL#http://}; \
    URL_NO_SCHEME=${URL_NO_SCHEME#https://}; \
    URL_NO_SCHEME=${URL_NO_SCHEME%/}; \
    GITBUCKET_HOST=${URL_NO_SCHEME%%/*}; \
    GITBUCKET_PATH=${URL_NO_SCHEME#*/}; \
    if [ "$GITBUCKET_HOST" = "$URL_NO_SCHEME" ]; then \
        GITBUCKET_PATH=""; \
    fi; \
    KEY_URL="https://$GITBUCKET_HOST"; \
    mkdir -p {{home}}/.config/git; \
    git config --file {{home}}/.config/git/config credential.$KEY_URL.helper libsecret; \
    git config --file {{home}}/.config/git/config credential.$KEY_URL.username "$GITBUCKET_USER"; \
    git config --file {{home}}/.config/git/config credential.$KEY_URL.useHttpPath false; \
    printf "protocol=https\nhost=%s\nusername=%s\npassword=%s\n\n" "$GITBUCKET_HOST" "$GITBUCKET_USER" "$GITBUCKET_PAT" | git credential approve

start-keyring:
    @if [ -z "$$DBUS_SESSION_BUS_ADDRESS" ]; then \
        if command -v dbus-launch >/dev/null; then \
            dbus-launch --sh-syntax; \
        else \
            echo "dbus-launch not found. Install: sudo apt install -y dbus-x11"; \
            exit 1; \
        fi; \
    fi; \
    if command -v gnome-keyring-daemon >/dev/null; then \
        gnome-keyring-daemon --start --components=secrets 2>/dev/null; \
    else \
        echo "gnome-keyring-daemon not found. Run: just install-gnome-keyring"; \
        exit 1; \
    fi

setup-fd:
    @if ! command -v fd >/dev/null; then \
        mkdir -p {{home}}/.local/bin; \
        ln -sf $(which fdfind) {{home}}/.local/bin/fd; \
    fi

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
    @NVIM_HOME="{{home}}/.local/opt/nvim"; \
    if [ ! -x "$$NVIM_HOME/bin/nvim" ]; then \
        echo "Clean install needed. Running..."; \
        rm -rf "$$NVIM_HOME"; \
        mkdir -p {{home}}/.local/opt; \
        curl -fL --retry 3 --retry-delay 1 -o nvim-linux64.tar.gz \
          https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz; \
        tar -tzf nvim-linux64.tar.gz >/dev/null; \
        tar -C {{home}}/.local/opt -xzf nvim-linux64.tar.gz; \
        mv {{home}}/.local/opt/nvim-linux-x86_64 "$$NVIM_HOME"; \
        mkdir -p {{home}}/.local/bin; \
        ln -sf "$$NVIM_HOME/bin/nvim" {{home}}/.local/bin/nvim; \
        rm -f nvim-linux64.tar.gz; \
    else \
        echo "✅ Neovim is already installed correctly."; \
    fi

install-clipboard:
    @if ! command -v win32yank.exe >/dev/null; then \
        mkdir -p {{home}}/.local/bin; \
        curl -L --fail -o win32yank.zip https://github.com/equalsraf/win32yank/releases/download/v0.0.4/win32yank-x64.zip; \
        unzip -p win32yank.zip win32yank.exe > win32yank.exe; \
        chmod +x win32yank.exe; \
        mv win32yank.exe {{home}}/.local/bin/; \
        rm win32yank.zip; \
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
    {{home}}/.local/bin/gitleaks protect --staged

install-lazygit:
    @echo "🦥 Installing Lazygit (Latest)..."
    @VERSION="${LAZYGIT_VERSION:-}"; \
    if [ -z "$VERSION" ]; then \
        LATEST_URL=$(curl -sL -o /dev/null -w '%{url_effective}' https://github.com/jesseduffield/lazygit/releases/latest); \
        VERSION=${LATEST_URL##*/tag/v}; \
        VERSION=${VERSION%%/*}; \
    fi; \
    if [ -z "$VERSION" ]; then \
        echo "Failed to determine lazygit version."; \
        echo "Latest URL: ${LATEST_URL:-<empty>}"; \
        exit 1; \
    fi; \
    VERSION=${VERSION#v}; \
    TAG="v${VERSION}"; \
    OS=Linux; \
    ARCH=$(uname -m); \
    case "$ARCH" in \
        x86_64) ARCH=x86_64 ;; \
        aarch64|arm64) ARCH=arm64 ;; \
        *) echo "Unsupported arch: $ARCH"; exit 1 ;; \
    esac; \
    mkdir -p {{home}}/.local/bin; \
    curl -sSfL -o lazygit.tar.gz \
        "https://github.com/jesseduffield/lazygit/releases/download/${TAG}/lazygit_${VERSION}_${OS}_${ARCH}.tar.gz"; \
    tar -xf lazygit.tar.gz lazygit; \
    install -m 0755 lazygit {{home}}/.local/bin/lazygit; \
    rm -f lazygit lazygit.tar.gz
