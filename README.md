# OpenClaw Codespace Starter (OU LiteLLM)

A GitHub **Codespaces** starter that automatically installs [OpenClaw](https://github.com/openclaw/openclaw) and wires it to the **OU LiteLLM gateway** (`https://litellm.lib.ou.edu`, model `gemma4`). Spin up a Codespace, paste your `sk-` key, and you have a working OpenClaw assistant — no local setup.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/jhassell/openclaw-codespace-starter?quickstart=1)

> Replace `OWNER/REPO` in the badge link above with your GitHub repo (e.g. `hassell/openclaw-ou`).

## What you get

When the Codespace is created, `postCreateCommand` runs `.devcontainer/setup.sh`, which:

1. Installs OpenClaw via the official installer (`https://openclaw.ai/install.sh`, non-interactive).
2. Writes `~/.openclaw/openclaw.json` configured for the OU LiteLLM gateway with `gemma4` as the default model.
3. Stores your API key in `~/.openclaw/.env` (never committed) and installs a one-time onboarding prompt for new terminals.

## Quick start

1. **Create your repo** from this template (green **Use this template** button) and update the badge link above.
2. **Launch a Codespace**: *Code → Codespaces → Create codespace on main*.
3. **Enter your key when prompted.** Because `.devcontainer/devcontainer.json` declares a recommended secret, Codespaces asks for `LITELLM_API_KEY` at creation. Paste your OU key (starts with `sk-`).
4. **Open a new terminal.** The first-run helper confirms your key (or prompts for it if you skipped the secret) and offers to launch `openclaw onboard`.
5. **Start it:** `./scripts/start.sh` — the Control UI is forwarded on port **18789**.

### Didn't set the secret?

Run this anytime to enter your key (hidden input) and regenerate the config:

```bash
bash scripts/set-key.sh
```

## How the key is handled

The key lives only in `~/.openclaw/.env` inside your Codespace and is referenced from the config as `${LITELLM_API_KEY}`. It is **not** written into `openclaw.json` and is gitignored. Set it once as a [Codespaces secret](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces) (recommended) so every new Codespace picks it up automatically.

## Customizing

Defaults live at the top of `scripts/configure.sh` (and the template at `config/openclaw.template.json5`). Override without editing files by exporting before you run `configure.sh`:

| Variable | Default | Purpose |
| --- | --- | --- |
| `LITELLM_BASE_URL` | `https://litellm.lib.ou.edu` | Gateway base URL |
| `OPENCLAW_MODEL` | `gemma4` | Model id (becomes `litellm/<id>`) |
| `OPENCLAW_MODEL_NAME` | `Gemma 4 (OU LiteLLM)` | Display name |

```bash
LITELLM_BASE_URL="https://litellm.lib.ou.edu/v1" OPENCLAW_MODEL="gemma4" bash scripts/configure.sh
```

## Commands

| Command | What it does |
| --- | --- |
| `bash .devcontainer/setup.sh` | Re-run install + configuration (idempotent) |
| `bash scripts/set-key.sh` | Enter/replace your `sk-` key |
| `bash scripts/configure.sh` | Re-render config from the template |
| `./scripts/start.sh` | Start OpenClaw (Control UI on `:18789`) |
| `openclaw onboard` | OpenClaw's interactive setup wizard |
| `openclaw doctor` | Diagnose config/auth problems |

## Troubleshooting

- **`openclaw: command not found`** — open a fresh terminal (PATH is set in `~/.bashrc`), or re-run `bash .devcontainer/setup.sh`.
- **Gateway won't start / "Invalid config"** — OpenClaw uses strict schema validation. Run `openclaw doctor --fix`.
- **`404` on model calls** — your endpoint may expect the `/v1` suffix. Re-run with `LITELLM_BASE_URL="https://litellm.lib.ou.edu/v1" bash scripts/configure.sh`.
- **`401 Unauthorized`** — the key is wrong or a placeholder. Run `bash scripts/set-key.sh`.
- **`Gateway start blocked … missing gateway.mode`** — run `openclaw config set gateway.mode local`, then start again. (The template sets this; configs created before this fix may lack it.)
- **`Refusing to bind gateway to auto without auth`** (containers/Codespaces) — run `openclaw config set gateway.bind loopback`. The template sets this; Codespaces forwards the loopback port for you.

## Use outside Codespaces

The same scripts work in any Linux/macOS/WSL shell: clone the repo, run `bash .devcontainer/setup.sh`, then `bash scripts/set-key.sh`.

## Links

- OpenClaw docs — https://docs.openclaw.ai
- LiteLLM provider config — https://docs.openclaw.ai/providers/litellm
- Configuration reference — https://docs.openclaw.ai/gateway/configuration
