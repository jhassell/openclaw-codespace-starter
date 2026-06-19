#!/usr/bin/env bash
# Terminal 2: wait for the gateway to be healthy, then launch the OpenClaw TUI.
# Aborts (without starting the TUI) if the gateway pre-flight failed.
set -uo pipefail
export PATH="${HOME}/.local/bin:${HOME}/.npm-global/bin:/usr/local/share/npm-global/bin:${PATH}"

STATUS="${HOME}/.openclaw/.preflight"
HEALTH="http://127.0.0.1:18789/healthz"
TIMEOUT="${OPENCLAW_TUI_WAIT:-120}"

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
    exec openclaw tui
  fi
  sleep 1
done

echo "⏱️   Timed out after ${TIMEOUT}s waiting for the gateway."
echo "    Check the 'OpenClaw: Gateway' terminal; once it's healthy, run:  openclaw tui"
exit 1
