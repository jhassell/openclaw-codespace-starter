#!/usr/bin/env bash
# Install OpenClaw via the OFFICIAL installer.
# NOTE: the npm package literally named "openclaw" on the public registry is a
# 0.0.0 placeholder stub (no build output) — do NOT `npm install -g openclaw`.
# The real CLI comes from https://openclaw.ai/install.sh. This script also cleans
# any partial/stub global install first (avoids the npm ENOTEMPTY rename error)
# and verifies a real version actually landed.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${HERE}/_env.sh" 2>/dev/null || true

is_real() { command -v openclaw >/dev/null 2>&1 && ! openclaw --version 2>/dev/null | grep -qi '0\.0\.0'; }

if is_real; then
  echo "OpenClaw already installed: $(openclaw --version 2>/dev/null)"
  exit 0
fi

# Remove any partial OR stub global install (fixes npm ENOTEMPTY on reinstall).
NGR="$(npm root -g 2>/dev/null || true)"
if [ -n "${NGR}" ]; then
  npm rm -g openclaw >/dev/null 2>&1 || true
  rm -rf "${NGR}/openclaw" "${NGR}"/.openclaw-* 2>/dev/null || true
fi

echo "Installing OpenClaw via the official installer (openclaw.ai/install.sh)…"
OPENCLAW_NO_ONBOARD=1 OPENCLAW_NO_PROMPT=1 \
  bash -c 'curl -fsSL --proto "=https" --tlsv1.2 https://openclaw.ai/install.sh | bash -s -- --no-onboard --no-prompt' || true

# shellcheck disable=SC1091
source "${HERE}/_env.sh" 2>/dev/null || true
if is_real; then
  echo "✓ OpenClaw installed: $(openclaw --version 2>/dev/null)"
  exit 0
fi
echo "✗ OpenClaw install failed (or only the 0.0.0 npm stub is present)."
echo "  Try manually: curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard --no-prompt"
exit 1
