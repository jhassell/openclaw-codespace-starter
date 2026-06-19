#!/usr/bin/env bash
# Pre-flight: verify the OU LiteLLM key actually works BEFORE starting the gateway.
# Writes ~/.openclaw/.preflight = ok|fail (read by the TUI launcher) and exits 0/1.
set -uo pipefail

LITELLM_BASE_URL="${LITELLM_BASE_URL:-https://litellm.lib.ou.edu}"
ENV_FILE="${HOME}/.openclaw/.env"
STATUS="${HOME}/.openclaw/.preflight"
base="${LITELLM_BASE_URL%/}"
mkdir -p "${HOME}/.openclaw"

KEY="${LITELLM_API_KEY:-}"
if [[ -z "${KEY}" && -f "${ENV_FILE}" ]]; then
  KEY="$(grep -E '^LITELLM_API_KEY=' "${ENV_FILE}" | tail -n1 | cut -d= -f2- || true)"
fi

fail() { echo "fail" > "${STATUS}"; echo; echo "❌ $1"; echo; exit 1; }

[[ -z "${KEY}" || "${KEY}" == "sk-REPLACE_ME" ]] && \
  fail "No OU LiteLLM API key set. Run 'bash scripts/set-key.sh' (or set the LITELLM_API_KEY Codespaces secret), then reopen."

echo "🔑 Verifying OU LiteLLM key against ${base} ..."
code=000
for url in "${base}/v1/models" "${base}/models"; do
  code="$(curl -s -m 20 -o /tmp/oc_models.json -w '%{http_code}' -H "Authorization: Bearer ${KEY}" "${url}" || echo 000)"
  [[ "${code}" == "200" ]] && { endpoint="${url}"; break; }
done

if [[ "${code}" != "200" ]]; then
  case "${code}" in
    401|403) fail "Key rejected (HTTP ${code}) — your OU LiteLLM key is invalid or expired. Fix: bash scripts/set-key.sh" ;;
    000)     fail "Could not reach ${base} (network/endpoint issue). Check the gateway URL." ;;
    *)       fail "Unexpected response (HTTP ${code}) from ${base}. Details: /tmp/oc_models.json" ;;
  esac
fi

count="$(python3 -c 'import json;print(len(json.load(open("/tmp/oc_models.json")).get("data",[])))' 2>/dev/null || echo "?")"
echo "ok" > "${STATUS}"
echo "✅ Key valid — ${count} model(s) available."
