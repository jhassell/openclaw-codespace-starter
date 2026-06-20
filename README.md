# OpenClaw Codespace Starter (OU LiteLLM)

A GitHub **Codespaces** starter that installs [OpenClaw](https://github.com/openclaw/openclaw), points it at the **OU LiteLLM gateway** (model `gemma4` by default), verifies your key, and — the moment the Codespace opens — **starts the gateway and drops you into an interactive TUI**. No wizard, no manual steps.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/jhassell/openclaw-codespace-starter?quickstart=1)

## What happens when you open the Codespace

1. **On create** (`postCreate`): installs OpenClaw (npm, public registry, with a leftover-cleanup step to avoid npm `ENOTEMPTY`) and writes `~/.openclaw/openclaw.json` (LiteLLM provider, `gemma4` default). No onboarding wizard.
2. **On open**, two terminals start automatically (VS Code tasks):
   - **OpenClaw: Gateway** — runs a **pre-flight** that checks your LiteLLM key against the OU `/v1/models` endpoint. Key bad → clear error, gateway **not** started. Key good → `openclaw gateway run` (loopback, port 18789).
   - **OpenClaw: TUI** — waits for the gateway to be healthy (and **aborts with a message if the pre-flight failed**), then launches `openclaw tui`. You can start chatting right away.

## Quick start

1. **Use this template** → create your repo.
2. **Add your key:** set a Codespaces secret named `LITELLM_API_KEY` (starts with `sk-`). You're prompted for it at creation because `devcontainer.json` declares it. (Optionally also set `OPENROUTER_API_KEY` to unlock OpenRouter models in the picker.)
3. **Code → Codespaces → Create codespace on main.**
4. Wait for the install to finish; the **Gateway** and **TUI** terminals open on their own. Start typing in the TUI.

Didn't set the secret? Open a terminal, run `bash scripts/set-key.sh`, then re-run the **OpenClaw: Gateway** / **OpenClaw: TUI** tasks (Command Palette → *Tasks: Run Task*) or reload the window.

## The key, and the pre-flight check

Your key lives only in `~/.openclaw/.env` (gitignored) and is referenced from the config as `${LITELLM_API_KEY}` — never written into `openclaw.json`. Before every gateway start, `scripts/preflight.sh` calls the OU `/v1/models` endpoint with your key:

- **Valid** → the gateway starts.
- **Rejected (401/403) or unreachable** → a clear on-screen error, the gateway is **aborted**, and the TUI doesn't launch.

Fix a bad key with `bash scripts/set-key.sh`, then re-run the tasks.

## Choosing models

`gemma4` is the default primary with no fallback — zero config needed. Three ways to change it:

- **Interactive (recommended):** run `bash scripts/select-model.sh` — or, one click, **Command Palette → *Tasks: Run Task* → *OpenClaw: Choose Model***, or the shortcut **Ctrl+Alt+M** (Mac **Cmd+Alt+M**). The shortcut is auto-installed in fresh Codespaces; otherwise copy `.vscode/keybindings.sample.jsonc` into your VS Code keybindings (Command Palette → *Preferences: Open Keyboard Shortcuts (JSON)*). The picker lists the models your gateway actually serves (live, from `/v1/models`) and lets you pick a **primary** and optional **secondary/fallback**. Applied through OpenClaw and **hot-reloaded** — no restart.
- **In chat:** type `/model` in the TUI to switch the current session's model.
- **Pinned at boot (reproducible):** set Codespaces secrets/variables `OPENCLAW_MODEL` (e.g. `llama3.1`) and optionally `OPENCLAW_MODEL_FALLBACKS` (comma-separated, e.g. `mistral,gemma4`). `configure.sh` bakes them into the config at creation — no prompt.

Models are referenced as `litellm/<id>`, where `<id>` is what the gateway reports.

### Using OpenRouter models

The picker can also switch to [OpenRouter](https://openrouter.ai) (400+ models behind one API). It appears in `select-model.sh` **only when an OpenRouter key is present** — otherwise it's shown as `OpenRouter (no key present)` and isn't selectable. To enable it, add an `OPENROUTER_API_KEY` Codespaces secret (starts with `sk-or-`, from https://openrouter.ai/keys); the Codespace prompts for it at creation alongside the OU key.

When you pick the OpenRouter option, the script fetches OpenRouter's **tool-capable** models (the ones suited to OpenClaw's agentic use), curated to popular vendors plus free options, with `$/M-token` prices (free listed first). Your choice is applied as `openrouter/<vendor>/<model>`. Note: OpenRouter bills your own OpenRouter account, and if you add the key after the gateway is already running, restart it so it can use OpenRouter.

## Commands

| Command | What it does |
| --- | --- |
| *OpenClaw: Gateway* task (auto) | pre-flight key check, then `openclaw gateway run` |
| *OpenClaw: TUI* task (auto) | waits for gateway health, then `openclaw tui` |
| `bash scripts/select-model.sh` | pick primary + secondary from OU models, or switch to OpenRouter |
| `bash scripts/set-key.sh` | enter/replace your `sk-` key |
| `bash scripts/configure.sh` | re-render config from the template |
| `openclaw tui` | open the TUI manually |
| `openclaw gateway run` | start the gateway manually |
| `openclaw models status` | show the resolved primary + fallbacks |
| `openclaw doctor` | diagnose config/auth problems |

## Troubleshooting

- **Terminals didn't open automatically** — VS Code may ask to *Allow Automatic Tasks*; click Allow (`.vscode/settings.json` sets this on). Otherwise Command Palette → *Tasks: Run Task* → *OpenClaw: Gateway* / *OpenClaw: TUI*. Reloading the window re-triggers them.
- **Key rejected at pre-flight** — invalid/expired key: `bash scripts/set-key.sh`, then re-run the tasks.
- **`404` from the model endpoint** — your endpoint may need the `/v1` suffix: re-run with `LITELLM_BASE_URL="https://litellm.lib.ou.edu/v1" bash scripts/configure.sh`.
- **"Model is not allowed" / model errors** — list valid options with `bash scripts/select-model.sh` or `openclaw models list`.
- **`openclaw: command not found`** — open a fresh terminal (PATH is set in `~/.bashrc`) or re-run `bash .devcontainer/setup.sh`.

## How it works

- `.devcontainer/devcontainer.json` — Node base image, `LITELLM_API_KEY` secret prompt, forwards port 18789, runs `setup.sh` on create.
- `.devcontainer/setup.sh` — installs OpenClaw, renders the config.
- `config/openclaw.template.json5` → `~/.openclaw/openclaw.json` — LiteLLM provider, `gateway.mode=local` + `bind=loopback`, primary/fallback models.
- `.vscode/tasks.json` — opens the Gateway + TUI terminals on folder open.
- `scripts/` — `install-openclaw`, `preflight`, `start-gateway`, `start-tui`, `select-model`, `set-key`, `configure`, `_env`.

## Links

- OpenClaw docs — https://docs.openclaw.ai
- LiteLLM provider — https://docs.openclaw.ai/providers/litellm
- TUI — https://docs.openclaw.ai/cli/tui
- Models CLI — https://docs.openclaw.ai/concepts/models
