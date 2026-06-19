#!/usr/bin/env bash
# Terminal 1: validate the key, then run the OpenClaw gateway in the foreground.
# If the key check fails, the gateway is NOT started.
# Put OpenClaw + node on PATH FIRST — VS Code task shells don't load ~/.bashrc/nvm.
export PATH="/usr/local/share/npm-global/bin:/usr/local/share/nvm/current/bin:${HOME:-/home/node}/.local/bin:${HOME:-/home/node}/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"
set -uo pipefail
# Extra, image-agnostic resolution (best effort; never fatal).
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_env.sh" 2>/dev/null || true
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
  echo "❌ openclaw not found on PATH."
  echo "   PATH=${PATH}"
  echo "   probe: $(ls -l /usr/local/share/npm-global/bin/openclaw 2>&1)"
  echo "   Fix: bash .devcontainer/setup.sh"
  exit 1
fi

# Ensure a startable config exists. Render defaults if missing, and always make
# sure the container-critical keys are set. These are surgical — they do NOT
# touch any model selection you made with select-model.sh.
if [[ ! -f "${HOME}/.openclaw/openclaw.json" ]]; then
  echo "No config found — rendering defaults…"
  bash "${REPO_DIR}/scripts/configure.sh" || true
fi
# Load persisted secrets (LiteLLM key + gateway token) into this process.
mkdir -p "${HOME}/.openclaw"
if [[ -f "${HOME}/.openclaw/.env" ]]; then set -a; . "${HOME}/.openclaw/.env"; set +a; fi

# Guarantee a stable gateway client token exists (older configs predate it).
if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
  OPENCLAW_GATEWAY_TOKEN="$(openssl rand -hex 24 2>/dev/null || (head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n'))"
  export OPENCLAW_GATEWAY_TOKEN
  printf 'OPENCLAW_GATEWAY_TOKEN=%s\n' "${OPENCLAW_GATEWAY_TOKEN}" >> "${HOME}/.openclaw/.env"
fi

openclaw config set gateway.mode local                            >/dev/null 2>&1 || true
openclaw config set gateway.bind loopback                         >/dev/null 2>&1 || true
openclaw config set gateway.auth.mode token                       >/dev/null 2>&1 || true
openclaw config set gateway.auth.token "${OPENCLAW_GATEWAY_TOKEN}" >/dev/null 2>&1 || true

echo "🚀  Starting gateway on http://127.0.0.1:18789  (Ctrl-C to stop) ..."
exec openclaw gateway run
