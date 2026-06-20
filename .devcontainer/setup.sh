#!/usr/bin/env bash
# postCreateCommand: install OpenClaw and configure it for the OU LiteLLM gateway.
# No onboarding wizard — the gateway + TUI auto-start via .vscode/tasks.json.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Installing OpenClaw (this can take a few minutes)…"
bash "${REPO_DIR}/scripts/install-openclaw.sh" \
  || echo "!! OpenClaw install failed. Retry later with: bash .devcontainer/setup.sh" >&2

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

# Best-effort: install the model-picker keyboard shortcut (Ctrl/Cmd+Alt+M).
# USER-scoped, so only written when no keybindings.json exists yet (never clobbers yours).
SRC="${REPO_DIR}/.vscode/keybindings.sample.jsonc"
if [[ -f "${SRC}" ]]; then
  for D in "${HOME}/.vscode-remote/data/User" "${HOME}/.vscode-server/data/User" "${HOME}/.vscode-server-insiders/data/User"; do
    [[ -d "${D}" ]] || continue
    if [[ ! -e "${D}/keybindings.json" ]]; then
      cp "${SRC}" "${D}/keybindings.json" && echo "==> Installed model-picker shortcut (Ctrl/Cmd+Alt+M)."
    else
      echo "==> Existing keybindings.json found — shortcut not auto-added (see .vscode/keybindings.sample.jsonc)."
    fi
    break
  done
fi

echo "==> Setup complete. The Gateway and TUI start automatically when the Codespace opens."
