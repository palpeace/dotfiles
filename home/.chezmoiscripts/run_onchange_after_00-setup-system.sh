#!/bin/bash
# chezmoi:template
# mise/config.toml hash: {{ include "dot_config/mise/config.toml" | sha256sum }}
set -euo pipefail

echo "🔄 Provisioning system dependencies and managed tools..."
if [ -x "$HOME/.local/bin/setup-system" ]; then
    "$HOME/.local/bin/setup-system"
fi

