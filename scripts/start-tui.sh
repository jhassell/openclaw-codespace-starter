#!/usr/bin/env bash
# Terminal 2: wait for the gateway to be healthy, then launch the OpenClaw TUI.
# Aborts (without starting the TUI) if the gateway pre-flight failed.
# Put OpenClaw + node on PATH FIRST — VS Code task shells don't load ~/.bashrc/nvm.
export PATH="/usr/local/share/npm-global/bin:/usr/local/share/nvm/current/bin:${HOME:-/home/node}/.local/bin:${HOME:-/home/node}/.npm-global/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"
set -uo pipefail
# Extra, image-agnostic resolution (best effort; never fatal).
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_env.sh" 2>/dev/null || true

STATUS="${HOME}/.openclaw/.preflight"
HEALTH="http://127.0.0.1:18789/healthz"
TIMEOUT="${OPENCLAW_TUI_WAIT:-120}"

# Load the gateway token so the TUI can authenticate to the gateway.
if [[ -f "${HOME}/.openclaw/.env" ]]; then set -a; . "${HOME}/.openclaw/.env"; set +a; fi

echo "⏳  Waiting for the OpenClaw gateway to come up ..."
for ((i=0; i<TIMEOUT; i++)); do
  if [[ "$(cat "${STATUS}" 2>/dev/null)" == "fail" ]]; then
    echo
    echo "⛔  Gateway did not start (key pre-flight failed)."
    echo "    Fix your key:  bash scripts/set-key.sh"
    echo "    Then rebuild the Codespace, or re-run the 'OpenClaw: Gateway' task."
    exit 1
  fi
  if curl -fsS -m 2 -o /dev/null "${HEALTH}" 2>/dev/null \
     || timeout 1 bash -c ':</dev/tcp/127.0.0.1/18789' 2>/dev/null; then
    echo "✅  Gateway is up — launching the TUI ..."
    sleep 1
    # Re-read the token now — the gateway may have just generated/persisted it.
    TUI_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-}"
    [[ -z "${TUI_TOKEN}" && -f "${HOME}/.openclaw/.env" ]] && \
      TUI_TOKEN="$(grep -E '^OPENCLAW_GATEWAY_TOKEN=' "${HOME}/.openclaw/.env" | tail -n1 | cut -d= -f2- || true)"
    if [[ -n "${TUI_TOKEN}" ]]; then exec openclaw tui --token "${TUI_TOKEN}"; else exec openclaw tui; fi
  fi
  sleep 1
done

echo "⏱️   Timed out after ${TIMEOUT}s waiting for the gateway."
echo "    Check the 'OpenClaw: Gateway' terminal; once it's healthy, run:  openclaw tui"
exit 1
