# claudecodex — Run Claude Code with GPT-5.6 using your ChatGPT subscription

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-blue.svg)](claudecodex)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS-lightgrey.svg)](#install)
[![Model](https://img.shields.io/badge/model-GPT--5.6%20Sol-orange.svg)](#usage)

**claudecodex** lets you use **Claude Code with OpenAI models** — GPT-5.6
(Sol / Terra / Luna) as the engine — billed to your **ChatGPT Plus/Pro
subscription** through a local **Codex proxy**, **without an Anthropic API key
or an OpenAI API key**.

You keep the Claude Code agent workflow you like (file edits, terminal flow,
approvals, MCP servers, skills) but the model answering is GPT-5.6, running on
the ChatGPT subscription you already pay for instead of your Anthropic usage.

One-line install. Plain `claude` stays completely stock.

## How it works

claudecodex launches the real Claude Code UI, points it at a local
Anthropic-compatible proxy on 127.0.0.1:18765, and the proxy forwards requests
to GPT-5.6 via Codex auth on your ChatGPT subscription:

```
claudecodex
   → claude (real Claude Code UI)
   → local Anthropic-compatible proxy (127.0.0.1:18765)
   → Codex auth via your ChatGPT Plus/Pro subscription
   → GPT-5.6-sol
   → streamed back into Claude Code
```

**Jump to:** [Install](#install) · [Usage & model switching](#usage) ·
[Configuration](#configuration) · [vs alternatives](#claudecodex-vs-other-ways-to-use-claude-code-with-openai-models) ·
[Troubleshooting](#troubleshooting) · [FAQ: Claude Code without an Anthropic API key](#can-i-use-claude-code-without-an-anthropic-subscription-or-api-key)

## Demo

![claudecodex demo — Claude Code running GPT-5.6 Sol via a ChatGPT subscription](assets/demo.gif)

*(8× speed — [watch the full demo video](assets/claudecodex.mp4))*

---

## Why run Claude Code with OpenAI models?

- **Claude Code UI + GPT models** — the best agentic coding interface, driving
  OpenAI's strongest coding model (GPT-5.6 Sol at `max` reasoning effort).
- **Uses the ChatGPT subscription you already have** — no pay-per-token API
  bills; requests go through Codex auth on your Plus/Pro plan.
- **Zero interference** — a thin launcher that `exec`s `claude` with
  process-local environment variables. Your normal `claude` command, login,
  settings, and Anthropic models are untouched.
- **Full 372K context window** — configured to GPT-5.6 Sol's real Codex
  context limit, so the context gauge and auto-compaction are accurate.
- **Model switching built in** — flip between Sol (best), Terra (mid), and
  Luna (fast/cheap) per launch or mid-session.

`claudecodex` is a thin launcher: it starts the proxy if needed, exports the
right environment **only for that process**, then `exec`s `claude`.

---

## Requirements

1. **Claude Code** — the `claude` CLI. Install: <https://claude.com/claude-code>
2. **claude-code-proxy** — the local Anthropic⇄Codex proxy by
   [@raine](https://github.com/raine/claude-code-proxy). Needs a build that knows
   the GPT-5.6 models (**v0.1.8+**; v0.1.17 or newer recommended).
3. **A ChatGPT Plus/Pro account**, authenticated through the proxy's Codex login.
   The proxy keeps its **own** login (it does not reuse the standalone Codex
   CLI's credentials), so you authenticate it once with
   `claude-code-proxy codex auth login`.

> This is for **personal, local use** with your own subscription. Don't expose
> it as a public API or resell access — routing a ChatGPT subscription through
> non-official clients is a gray area under OpenAI's terms.

---

## Install

**1 — install the launcher (one-liner):**

```bash
curl -fsSL https://raw.githubusercontent.com/karem505/claudecodex/main/install.sh | bash
```

**2 — install the proxy** (skip if you already have v0.1.8+):

```bash
curl -fsSL https://raw.githubusercontent.com/raine/claude-code-proxy/main/scripts/install.sh | bash
```

**3 — log the proxy in to your ChatGPT/Codex account:**

```bash
claude-code-proxy codex auth login      # browser OAuth
# or, on a headless box:
claude-code-proxy codex auth device     # device-code flow
```

That's it — the installer checks steps 2 and 3 for you and prints these exact
commands if anything's missing.

---

## Usage

```bash
claudecodex                 # start Claude Code on gpt-5.6-sol (max effort)
claudecodex --mini          # start on gpt-5.6-luna (fast/cheap)   (alias: --luna)
claudecodex --terra         # start on gpt-5.6-terra (mid tier)
claudecodex --big           # start on gpt-5.6-sol explicitly      (alias: --sol)
claudecodex "fix the bug"   # any normal claude args pass straight through
```

**Switch models mid-session:** type `/model`, pick `gpt-5.6-sol` or `gpt-5.6-luna`,
then press **`s`** (session-only). Both models are always listed. Use `s`, not
Enter — Enter saves it as a *default* in the shared settings and would change
plain `claude` too.

By default `claudecodex` starts in **`--dangerously-skip-permissions`** (bypass)
mode so tool calls run without prompting. Toggle it off with the env var below,
or cycle modes live with **shift+tab**.

### Thinking level

`gpt-5.6-sol` launches at **`max`** effort — the highest reasoning level reachable
through claude-code-proxy today (forwarded to Codex as `reasoning.effort=max`).
`luna`/`terra` keep Claude Code's own effort setting. Change it live with
`/effort`, or per-launch with `CLAUDECODEX_EFFORT`.

> **About "ultra":** GPT-5.6 Sol's `ultra` mode (parallel subagents) exists in the
> official Codex app, but it is **not yet exposed by claude-code-proxy** — the
> proxy caps at `max`, and Claude Code's effort scale has no `ultra` (it would
> clamp to `xhigh`). `claudecodex` therefore uses `max`, the real ceiling. If you
> set `CLAUDECODEX_EFFORT=ultra` it is auto-downgraded to `max` with a notice;
> once a proxy build ships `ultra`, that env value will pass straight through.

---

## Configuration

All optional — set as environment variables:

| Variable | Default | Meaning |
|---|---|---|
| `CLAUDECODEX_MODEL` | `gpt-5.6-sol` | The "big" model |
| `CLAUDECODEX_SMALL_MODEL` | `gpt-5.6-luna` | The fast/cheap model |
| `CLAUDECODEX_EFFORT` | `max` (on sol) | Thinking level: `low`/`medium`/`high`/`xhigh`/`max` |
| `CLAUDECODEX_CONTEXT` | `372000` | Context window (see note) |
| `CLAUDECODEX_SKIP_PERMISSIONS` | `1` | `1` = bypass permissions, `0` = normal prompts |
| `CLAUDECODEX_PORT` | `18765` | Proxy port |
| `CLAUDECODEX_AGENT_VIEW` | `0` | `1` = show the background-jobs dashboard on start |
| `CLAUDECODEX_PROXY_BIN` | `claude-code-proxy` | Proxy binary name/path |

Example:

```bash
CLAUDECODEX_EFFORT=high CLAUDECODEX_MODEL=gpt-5.6-terra claudecodex
```

### Context window note

`gpt-5.6-sol`'s **Codex context window is 372K tokens** (~353K effective after
the 95% multiplier). The API model is 1.05M, but the Codex subscription path caps
at 372K — advertising more triggers *"exceeds the context window"* errors. The
**272K** figure often quoted is just the pricing knee (input past 272K bills at
~2×), not the hard cap. Claude Code otherwise assumes 200K for unknown model
names, so `claudecodex` sets the real 372K; its autocompact buffer keeps a margin
below that. Tune with `CLAUDECODEX_CONTEXT`.

---

## What it sets (and why plain `claude` is safe)

Everything below is exported inside the launcher process and dies with it —
nothing is written to `~/.claude/settings.json` or your shell:

```
ANTHROPIC_BASE_URL=http://localhost:18765
ANTHROPIC_AUTH_TOKEN=claudecodex-local
ANTHROPIC_MODEL=gpt-5.6-sol
ANTHROPIC_SMALL_FAST_MODEL=gpt-5.6-luna
CLAUDE_CODE_MAX_CONTEXT_TOKENS=372000
CLAUDE_CODE_AUTO_COMPACT_WINDOW=372000
CLAUDE_CODE_DISABLE_AGENT_VIEW=1
# plus, session-scoped via flags: --model / --effort / --dangerously-skip-permissions
```

Your plugins, skills, and MCP servers are shared (the launcher does **not**
change `CLAUDE_CONFIG_DIR`), so they work in `claudecodex` too. Note that
claude.ai-hosted connectors are disabled while a token auth source is set —
that's expected for any custom endpoint.

---

## FAQ

### How do I use Claude Code with my ChatGPT Plus or Pro subscription?

Install the claudecodex launcher, install [claude-code-proxy](https://github.com/raine/claude-code-proxy)
(v0.1.8+), and run `claude-code-proxy codex auth login` once. Then run `claudecodex` —
Claude Code starts with GPT-5.6 Sol as the model, billed to your ChatGPT subscription.
See [Install](#install).

### Can I use Claude Code with GPT or other OpenAI models?

Yes — that is exactly what claudecodex does. Claude Code talks to any
Anthropic-compatible endpoint via `ANTHROPIC_BASE_URL`;
[claude-code-proxy](https://github.com/raine/claude-code-proxy) translates
those requests to OpenAI's Codex backend, so Claude Code runs GPT-5.6
(Sol, Terra, or Luna) as its model.

### Can I use Claude Code without an Anthropic subscription or API key?

Yes. In a `claudecodex` session, no Anthropic account is used at all — auth and
billing go through your ChatGPT Plus/Pro subscription via Codex. (You still
install the Claude Code CLI itself, which is free to download.)

### Does this cost anything beyond my ChatGPT subscription?

No. Requests are billed against the ChatGPT Plus/Pro plan you already have —
there are no per-token API charges, because it uses Codex subscription auth,
not an OpenAI API key.

### Will this break or change my normal `claude` setup?

No. The launcher exports everything process-locally and passes session-scoped
flags only. Plain `claude` keeps its own login, model, settings, and history.
See [What it sets](#what-it-sets-and-why-plain-claude-is-safe).

### Which GPT-5.6 model should I pick?

- **Sol** (`claudecodex`) — strongest coding model, launches at `max` effort. Default.
- **Terra** (`claudecodex --terra`) — mid tier, faster.
- **Luna** (`claudecodex --mini`) — fastest/cheapest, good for quick edits.

### Is it against OpenAI's terms to use a ChatGPT subscription with Claude Code?

It's for **personal, local use** with your own subscription. Routing a ChatGPT
subscription through non-official clients is a gray area under OpenAI's terms —
don't expose it as a public API or resell access. Use at your own discretion.

---

## claudecodex vs other ways to use Claude Code with OpenAI models

| | claudecodex | claude-code-router / LiteLLM | OpenRouter bridges |
|---|---|---|---|
| Billing | ChatGPT Plus/Pro subscription — no per-token cost | OpenAI API key, pay per token | OpenRouter credits, pay per token |
| Anthropic API key needed | No | No | No |
| Setup | One-liner + one proxy login | Router/proxy config files | API key + config |
| Touches plain `claude` | No — process-local env only | Often global config/env | Varies |
| GPT-5.6 Sol at `max` effort | Yes, default | Depends on provider support | Depends on provider support |

If you want pay-per-token API access with many providers, a router is the better
fit. If you want the **strongest OpenAI coding model inside Claude Code on the
flat-rate ChatGPT subscription you already pay for**, that's claudecodex.

---

## Related projects

- [raine/claude-code-proxy](https://github.com/raine/claude-code-proxy) — the
  local Anthropic⇄Codex proxy that makes this possible.
- [Claude Code](https://claude.com/claude-code) — Anthropic's agentic coding CLI.
- [OpenAI Codex](https://openai.com/codex/) — the subscription backend serving GPT-5.6.

---

## Troubleshooting

### "exceeds the context window" error

The Codex subscription path caps GPT-5.6 Sol at 372K tokens (the API model's
1.05M does not apply). claudecodex sets 372K by default; if you overrode
`CLAUDECODEX_CONTEXT`, lower it back to `372000`.

### Claude Code can't connect / proxy not running

Check that claude-code-proxy is installed (v0.1.8+) and authenticated:

```bash
claude-code-proxy --version
claude-code-proxy codex auth login
```

If the proxy fails to start, check the log at
`~/.local/state/claudecodex/proxy.log`.

### 401 Not authenticated after upgrading the proxy

Proxy upgrades can reset its Codex login (it's separate from the standalone
Codex CLI's login). Re-run `claude-code-proxy codex auth login`.

---

## Uninstall

```bash
rm ~/.local/bin/claudecodex
# optional: remove the proxy + its login
claude-code-proxy codex auth logout
```

---

## License

MIT — see [LICENSE](LICENSE).

Not affiliated with Anthropic or OpenAI. "Claude Code" and "GPT" are trademarks
of their respective owners.
