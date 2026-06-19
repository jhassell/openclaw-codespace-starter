#!/usr/bin/env bash
# Start OpenClaw. The Gateway + Control UI come up on port 18789
# (forwarded by the Codespace). Open the forwarded URL to use the web UI.
set -euo pipefail

export PATH="${HOME}/.local/bin:${HOME}/.npm-global/bin:/usr/local/share/npm-global/bin:${PATH}"

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw not found on PATH. Run: bash .devcontainer/setup.sh" >&2
  exit 1
fi

echo "Starting OpenClaw — Control UI will be at http://127.0.0.1:18789"
exec openclaw
