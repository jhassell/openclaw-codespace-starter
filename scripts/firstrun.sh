#!/usr/bin/env bash
# First-run onboarding for the OpenClaw Codespace. Triggered once from ~/.bashrc
# in interactive terminals. Honors the "onboarding wizard on first launch" flow.
set -uo pipefail

SENTINEL="${HOME}/.openclaw/.firstrun-done"
ENV_FILE="${HOME}/.openclaw/.env"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Run once, and only when we truly have a terminal to talk to.
[[ -f "${SENTINEL}" ]] && exit 0
[[ -t 0 && -t 1 ]] || exit 0

# Mark first-run done UP FRONT so this never re-fires — even if the wizard is
# interrupted (Ctrl-C) or you open another terminal before finishing setup.
mkdir -p "${HOME}/.openclaw"
touch "${SENTINEL}"

cat <<'BANNER'
────────────────────────────────────────────────────────
 🦞  OpenClaw Codespace — first-run setup
 Model: gemma4 via OU LiteLLM (https://litellm.lib.ou.edu)
────────────────────────────────────────────────────────
BANNER

KEY=""
[[ -f "${ENV_FILE}" ]] && KEY="$(grep -E '^LITELLM_API_KEY=' "${ENV_FILE}" | tail -n1 | cut -d= -f2- || true)"

if [[ -z "${KEY}" || "${KEY}" == "sk-REPLACE_ME" ]]; then
  echo "No API key set yet — let's add it now."
  bash "${REPO_DIR}/scripts/set-key.sh" || true
else
  echo "✅ API key detected — you're configured for gemma4."
fi

echo
read -rp "Launch the OpenClaw onboarding wizard now (channels, etc.)? [y/N] " yn </dev/tty || yn=""
if [[ "${yn}" =~ ^[Yy]$ ]]; then
  openclaw onboard || true
else
  echo "Skipped."
fi

echo "This first-run prompt won't appear again. Re-run onboarding anytime with:"
echo "    openclaw onboard        (or ./scripts/start.sh to launch OpenClaw)"
