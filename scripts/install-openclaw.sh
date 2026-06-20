#!/usr/bin/env bash
# Robustly (re)install OpenClaw via npm. Cleans partial installs that cause the
# npm ENOTEMPTY rename error on retry, forces the public registry, and verifies.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${HERE}/_env.sh" 2>/dev/null || true

if command -v openclaw >/dev/null 2>&1; then
  echo "OpenClaw already installed: $(openclaw --version 2>/dev/null || echo present)"
  exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "❌ npm not found on PATH — cannot install OpenClaw."
  exit 1
fi

# The ENOTEMPTY fix: remove any partial/leftover global package before installing.
NGR="$(npm root -g 2>/dev/null || true)"
if [ -n "${NGR}" ]; then
  rm -rf "${NGR}/openclaw" "${NGR}"/.openclaw-* 2>/dev/null || true
fi

echo "Installing openclaw@latest via npm…"
OPENCLAW_NO_ONBOARD=1 OPENCLAW_NO_PROMPT=1 \
  npm install -g openclaw@latest --registry=https://registry.npmjs.org/ --no-fund --no-audit 2>&1 | tail -20 || true

# Re-resolve PATH and verify the binary landed.
# shellcheck disable=SC1091
source "${HERE}/_env.sh" 2>/dev/null || true
if command -v openclaw >/dev/null 2>&1; then
  echo "✓ OpenClaw installed: $(openclaw --version 2>/dev/null)"
  exit 0
fi
echo "✗ OpenClaw install failed (see npm output above)."
exit 1
