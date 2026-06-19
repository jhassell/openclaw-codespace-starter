#!/usr/bin/env bash
# postCreateCommand: install OpenClaw and configure it for the OU LiteLLM gateway.
# Safe to re-run (idempotent).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Installing OpenClaw (this can take a few minutes)…"
# Non-interactive install: no onboarding wizard, no prompts (no TTY here).
export OPENCLAW_NO_ONBOARD=1
export OPENCLAW_NO_PROMPT=1
if ! curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-onboard --no-prompt; then
  echo "!! OpenClaw install failed. Retry later with: bash .devcontainer/setup.sh" >&2
fi

# Make sure common install locations are on PATH for the rest of this script.
export PATH="${HOME}/.local/bin:${HOME}/.npm-global/bin:/usr/local/share/npm-global/bin:${PATH}"

echo "==> Writing OpenClaw config for OU LiteLLM (gemma4)…"
bash "${REPO_DIR}/scripts/configure.sh" || true

# Install a one-time, interactive-only onboarding hook for new terminals.
HOOK_MARKER="# >>> openclaw-codespace firstrun >>>"
if ! grep -qF "${HOOK_MARKER}" "${HOME}/.bashrc" 2>/dev/null; then
  cat >> "${HOME}/.bashrc" <<EOF

${HOOK_MARKER}
export PATH="\${HOME}/.local/bin:\${HOME}/.npm-global/bin:/usr/local/share/npm-global/bin:\${PATH}"
if [[ \$- == *i* ]] && [[ -f "${REPO_DIR}/scripts/firstrun.sh" ]]; then
  bash "${REPO_DIR}/scripts/firstrun.sh"
fi
# <<< openclaw-codespace firstrun <<<
EOF
fi

echo "==> Setup complete. Open a new terminal to finish onboarding."
