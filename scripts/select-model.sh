#!/usr/bin/env bash
# Switch the OpenClaw model. Lists the OU LiteLLM catalog and — when an
# OpenRouter key is present — an OpenRouter option that browses tool-capable
# models. Sets primary + optional fallback; the gateway hot-reloads (no restart).
set -uo pipefail
# Make 'openclaw' findable in non-interactive shells.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_env.sh" 2>/dev/null || true

LITELLM_BASE_URL="${LITELLM_BASE_URL:-https://litellm.lib.ou.edu}"
ENV_FILE="${HOME}/.openclaw/.env"
oubase="${LITELLM_BASE_URL%/}"

read_env() { # read_env VAR -> value from process env or ~/.openclaw/.env
  local var="$1" val="${!1:-}"
  [[ -z "${val}" && -f "${ENV_FILE}" ]] && val="$(grep -E "^${var}=" "${ENV_FILE}" | tail -n1 | cut -d= -f2- || true)"
  printf '%s' "${val}"
}

apply_models() { # apply_models <prefix> <primary> [fallbacks...]
  local prefix="$1" primary="$2"; shift 2
  echo "→ primary: ${prefix}${primary}"
  openclaw models set "${prefix}${primary}"
  openclaw models fallbacks clear >/dev/null 2>&1 || true
  local f
  for f in "$@"; do
    [[ -n "${f}" ]] && { echo "→ fallback: ${prefix}${f}"; openclaw models fallbacks add "${prefix}${f}"; }
  done
  echo; echo "Current model configuration:"
  openclaw models status 2>/dev/null || true
  echo "(Hot-reloaded — your next message uses the new model.)"
}

# ---- OU LiteLLM catalog ---------------------------------------------------
OU_KEY="$(read_env LITELLM_API_KEY)"
[[ -z "${OU_KEY}" || "${OU_KEY}" == "sk-REPLACE_ME" ]] && { echo "No OU LiteLLM key. Run: bash scripts/set-key.sh"; exit 1; }

echo "Fetching OU models from ${oubase} ..."
http=000
for url in "${oubase}/v1/models" "${oubase}/models"; do
  http="$(curl -s -m 20 -o /tmp/ou_models.json -w '%{http_code}' -H "Authorization: Bearer ${OU_KEY}" "${url}" || echo 000)"
  [[ "${http}" == "200" ]] && break
done
[[ "${http}" == "200" ]] || { echo "Could not list OU models (HTTP ${http})."; exit 1; }
mapfile -t OU < <(python3 -c 'import json
for m in json.load(open("/tmp/ou_models.json")).get("data",[]): print(m["id"])' 2>/dev/null | sort -u)
((${#OU[@]})) || { echo "No OU models returned."; exit 1; }
N=${#OU[@]}

# ---- list OU models + OpenRouter option (key-gated) -----------------------
OR_KEY="$(read_env OPENROUTER_API_KEY)"
OR_OPTION=0
echo
echo "Available models (OU LiteLLM):"
for i in "${!OU[@]}"; do printf "  %2d) %s\n" "$((i+1))" "${OU[$i]}"; done
if [[ -n "${OR_KEY}" ]]; then
  OR_OPTION=$((N+1))
  printf "  %2d) %s\n" "${OR_OPTION}" "OpenRouter → browse tool-capable models"
else
  printf "      %s\n" "OpenRouter (no key present — add the OPENROUTER_API_KEY Codespaces secret)"
fi
echo
read -rp "Pick a number [default 1]: " choice </dev/tty; choice="${choice:-1}"

# ---- OpenRouter branch ----------------------------------------------------
if [[ -n "${OR_KEY}" && "${choice}" == "${OR_OPTION}" ]]; then
  echo "Fetching tool-capable OpenRouter models ..."
  curl -fsS -m 30 "https://openrouter.ai/api/v1/models?supported_parameters=tools" -o /tmp/or_models.json \
    || { echo "Could not reach OpenRouter."; exit 1; }
  mapfile -t ORROWS < <(python3 - <<'PY'
import json
data = json.load(open("/tmp/or_models.json")).get("data", [])
popular = {"anthropic","openai","google","x-ai","meta-llama","mistralai",
           "qwen","deepseek","z-ai","moonshotai","minimax"}
def perM(v):
    try: return float(v) * 1_000_000
    except Exception: return None
rows = []
for m in data:
    mid = m.get("id", "")
    vendor = mid.split("/")[0] if "/" in mid else mid
    arch = m.get("architecture", {}) or {}
    if "text" not in (arch.get("input_modalities") or []): continue
    if "tools" not in (m.get("supported_parameters") or []): continue
    if vendor not in popular: continue
    pr = m.get("pricing", {}) or {}
    pin, pout = perM(pr.get("prompt")), perM(pr.get("completion"))
    free = (pin == 0 and pout == 0)
    ctx = m.get("context_length") or 0
    ctxs = f"{ctx // 1000}k" if ctx else "?"
    if free: price = "FREE"
    elif pin is not None and pout is not None: price = f"${pin:.2f}/${pout:.2f} /M"
    else: price = "price n/a"
    rows.append((0 if free else 1, pin if pin is not None else 9e9, vendor, mid,
                 f"{price:<16} {mid} ({ctxs})"))
rows.sort(key=lambda r: (r[0], r[1], r[2], r[3]))
for r in rows: print(f"{r[3]}\t{r[4]}")
PY
)
  ((${#ORROWS[@]})) || { echo "No tool-capable models from popular vendors found."; exit 1; }
  OR_IDS=(); i=1
  echo; echo "OpenRouter models (tool-capable; free first, then by price):"
  for row in "${ORROWS[@]}"; do
    OR_IDS+=("${row%%$'\t'*}")
    printf "  %3d) %s\n" "$i" "${row#*$'\t'}"; ((i++))
  done
  echo
  read -rp "Primary model number [default 1]: " p </dev/tty; p="${p:-1}"
  PRIMARY="${OR_IDS[$((p-1))]:-}"; [[ -z "${PRIMARY}" ]] && { echo "Invalid choice."; exit 1; }
  read -rp "Fallback number(s), comma-separated (blank = none): " s </dev/tty
  FB=()
  if [[ -n "${s// /}" ]]; then
    IFS=',' read -ra IDX <<< "${s}"
    for n in "${IDX[@]}"; do n="${n// /}"; m="${OR_IDS[$((n-1))]:-}"; [[ -n "${m}" ]] && FB+=("${m}"); done
  fi
  apply_models "openrouter/" "${PRIMARY}" ${FB[@]+"${FB[@]}"}
  exit 0
fi

# ---- OU LiteLLM branch ----------------------------------------------------
if ! [[ "${choice}" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > N )); then
  echo "Invalid choice."; exit 1
fi
PRIMARY="${OU[$((choice-1))]}"
read -rp "Fallback number(s) from the list above, comma-separated (blank = none): " s </dev/tty
FB=()
if [[ -n "${s// /}" ]]; then
  IFS=',' read -ra IDX <<< "${s}"
  for n in "${IDX[@]}"; do n="${n// /}"; m="${OU[$((n-1))]:-}"; [[ -n "${m}" ]] && FB+=("${m}"); done
fi
apply_models "litellm/" "${PRIMARY}" ${FB[@]+"${FB[@]}"}
