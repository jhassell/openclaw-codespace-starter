#!/usr/bin/env bash
# Interactively prompt for the OU LiteLLM API key, then (re)write config.
# Use this if you didn't set the LITELLM_API_KEY Codespaces secret.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Enter your OU LiteLLM API key (starts with sk-). Input is hidden."
read -rs -p "LITELLM_API_KEY: " KEY </dev/tty
echo

if [[ -z "${KEY}" ]]; then
  echo "No key entered. Aborting." >&2
  exit 1
fi
if [[ "${KEY}" != sk-* ]]; then
  read -rp "That doesn't start with 'sk-'. Use it anyway? [y/N] " yn </dev/tty
  [[ "${yn}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi

bash "${REPO_DIR}/scripts/configure.sh" "${KEY}"
echo "Saved. If the gateway is already running, restart it (scripts/start.sh) to pick up the new key."
