#!/usr/bin/env bash
# Discover the models the OU LiteLLM gateway offers, then set a primary and
# optional secondary (fallback) model. The gateway hot-reloads — no restart.
set -uo pipefail
# Make 'openclaw' findable in non-interactive task shells.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_env.sh"

LITELLM_BASE_URL="${LITELLM_BASE_URL:-https://litellm.lib.ou.edu}"
ENV_FILE="${HOME}/.openclaw/.env"
base="${LITELLM_BASE_URL%/}"

KEY="${LITELLM_API_KEY:-}"
[[ -z "${KEY}" && -f "${ENV_FILE}" ]] && KEY="$(grep -E '^LITELLM_API_KEY=' "${ENV_FILE}" | tail -n1 | cut -d= -f2- || true)"
[[ -z "${KEY}" || "${KEY}" == "sk-REPLACE_ME" ]] && { echo "No API key set. Run: bash scripts/set-key.sh"; exit 1; }

echo "Fetching available models from ${base} ..."
http=000
for url in "${base}/v1/models" "${base}/models"; do
  http="$(curl -s -m 20 -o /tmp/oc_models.json -w '%{http_code}' -H "Authorization: Bearer ${KEY}" "${url}" || echo 000)"
  [[ "${http}" == "200" ]] && break
done
[[ "${http}" == "200" ]] || { echo "Could not list models (HTTP ${http})."; exit 1; }

mapfile -t MODELS < <(python3 -c 'import json
for m in json.load(open("/tmp/oc_models.json")).get("data",[]): print(m["id"])' 2>/dev/null | sort -u)
((${#MODELS[@]})) || { echo "No models returned by the gateway."; exit 1; }

echo
echo "Available models:"
for i in "${!MODELS[@]}"; do printf "  %2d) %s\n" "$((i+1))" "${MODELS[$i]}"; done
echo

read -rp "Primary model number [default 1]: " p </dev/tty; p="${p:-1}"
PRIMARY="${MODELS[$((p-1))]:-}"
[[ -z "${PRIMARY}" ]] && { echo "Invalid choice."; exit 1; }

read -rp "Secondary/fallback model number(s), comma-separated (blank = none): " s </dev/tty

echo "→ primary: litellm/${PRIMARY}"
openclaw models set "litellm/${PRIMARY}"

openclaw models fallbacks clear >/dev/null 2>&1 || true
if [[ -n "${s// /}" ]]; then
  IFS=',' read -ra IDX <<< "${s}"
  for n in "${IDX[@]}"; do
    n="${n// /}"; m="${MODELS[$((n-1))]:-}"
    [[ -n "${m}" ]] && { echo "→ fallback: litellm/${m}"; openclaw models fallbacks add "litellm/${m}"; }
  done
fi

echo
echo "Current model configuration:"
openclaw models status 2>/dev/null || true
echo "(Hot-reloaded — your next message uses the new model.)"
