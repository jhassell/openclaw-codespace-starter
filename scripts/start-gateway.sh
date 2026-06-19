#!/usr/bin/env bash
# Terminal 1: validate the key, then run the OpenClaw gateway in the foreground.
# If the key check fails, the gateway is NOT started.
set -uo pipefail
export PATH="${HOME}/.local/bin:${HOME}/.npm-global/bin:/usr/local/share/npm-global/bin:${PATH}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "════════════════════════════════════════════════════"
echo "  OpenClaw Gateway  (OU LiteLLM)"
echo "════════════════════════════════════════════════════"

if ! bash "${REPO_DIR}/scripts/preflight.sh"; then
  echo "⛔  Gateway aborted — key pre-flight failed (see message above)."
  exit 1
fi

if ! command -v openclaw >/dev/null 2>&1; then
  echo "fail" > "${HOME}/.openclaw/.preflight"
  echo "openclaw not found on PATH. Run: bash .devcontainer/setup.sh"
  exit 1
fi

echo "🚀  Starting gateway on http://127.0.0.1:18789  (Ctrl-C to stop) ..."
exec openclaw gateway run
