#!/usr/bin/env bash
# postCreateCommand: install OpenClaw and configure it for the OU LiteLLM gateway.
# No onboarding wizard — the gateway + TUI auto-start via .vscode/tasks.json.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Installing OpenClaw (this can take a few minutes)…"
export OPENCLAW_NO_ONBOARD=1
export OPENCLAW_NO_PROMPT=1
if ! curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-onboard --no-prompt; then
  echo "!! OpenClaw install failed. Retry later with: bash .devcontainer/setup.sh" >&2
fi

export PATH="${HOME}/.local/bin:${HOME}/.npm-global/bin:/usr/local/share/npm-global/bin:${PATH}"

echo "==> Writing OpenClaw config for OU LiteLLM…"
bash "${REPO_DIR}/scripts/configure.sh" || true

# Make sure 'openclaw' is on PATH in every future terminal.
MARKER="# >>> openclaw-codespace path >>>"
if ! grep -qF "${MARKER}" "${HOME}/.bashrc" 2>/dev/null; then
  cat >> "${HOME}/.bashrc" <<EOF

${MARKER}
export PATH="\${HOME}/.local/bin:\${HOME}/.npm-global/bin:/usr/local/share/npm-global/bin:\${PATH}"
# <<< openclaw-codespace path <<<
EOF
fi

echo "==> Setup complete. The Gateway and TUI start automatically when the Codespace opens."
