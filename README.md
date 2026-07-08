# claudecodex

Use **Claude Code's interface** with **GPT-5.5** (or `gpt-5.4-mini`) as the engine —
driven by your **ChatGPT Plus/Pro subscription** through a local Codex-auth proxy.

You keep the Claude Code agent workflow you like (file edits, terminal flow,
approvals, MCP servers, skills) but the model answering is GPT-5.x, billed
against your ChatGPT subscription instead of your Anthropic usage.

```
claudecodex
   → claude (real Claude Code UI)
   → local Anthropic-compatible proxy (127.0.0.1:18765)
   → Codex auth via your ChatGPT Plus/Pro subscription
   → GPT-5.5
   → streamed back into Claude Code
```

`claudecodex` is a thin launcher: it starts the proxy if needed, exports the
right environment **only for that process**, then `exec`s `claude`. Your plain
`claude` command stays completely stock — same login, same Anthropic models.

---

## Requirements

1. **Claude Code** — the `claude` CLI. Install: <https://claude.com/claude-code>
2. **claude-code-proxy** — the local Anthropic⇄Codex proxy by
   [@raine](https://github.com/raine/claude-code-proxy).
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

**2 — install the proxy** (skip if you already have it):

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
claudecodex                 # start Claude Code on gpt-5.5
claudecodex --mini          # start on gpt-5.4-mini (fast/cheap)   (alias: --54)
claudecodex --big           # start on gpt-5.5 explicitly          (alias: --55)
claudecodex "fix the bug"   # any normal claude args pass straight through
```

**Switch models mid-session:** type `/model`, pick `gpt-5.5` or `gpt-5.4-mini`,
then press **`s`** (session-only). Both models are always listed. Use `s`, not
Enter — Enter saves it as a *default* in the shared settings and would change
plain `claude` too.

By default `claudecodex` starts in **`--dangerously-skip-permissions`** (bypass)
mode so tool calls run without prompting. Toggle it off with the env var below,
or cycle modes live with **shift+tab**.

---

## Configuration

All optional — set as environment variables:

| Variable | Default | Meaning |
|---|---|---|
| `CLAUDECODEX_MODEL` | `gpt-5.5` | The "big" model |
| `CLAUDECODEX_SMALL_MODEL` | `gpt-5.4-mini` | The fast/cheap model |
| `CLAUDECODEX_CONTEXT` | `400000` | Context window (see note) |
| `CLAUDECODEX_SKIP_PERMISSIONS` | `1` | `1` = bypass permissions, `0` = normal prompts |
| `CLAUDECODEX_PORT` | `18765` | Proxy port |
| `CLAUDECODEX_AGENT_VIEW` | `0` | `1` = show the background-jobs dashboard on start |
| `CLAUDECODEX_PROXY_BIN` | `claude-code-proxy` | Proxy binary name/path |

Example:

```bash
CLAUDECODEX_SKIP_PERMISSIONS=0 CLAUDECODEX_MODEL=gpt-5.4 claudecodex
```

### Context window note

GPT-5.5's raw API window is 1M tokens, but through **Codex auth** (this proxy's
path) it's hard-capped at **400K** — advertising more triggers *"exceeds the
context window"* errors. Claude Code otherwise assumes 200K for unknown model
names, which makes the context gauge wrong; `claudecodex` sets it to the real
400K. Note that input past **272K** counts against your ChatGPT usage quota at
~2×, so drop `CLAUDECODEX_CONTEXT=272000` if you want to stay under that knee.

---

## What it sets (and why plain `claude` is safe)

Everything below is exported inside the launcher process and dies with it —
nothing is written to `~/.claude/settings.json` or your shell:

```
ANTHROPIC_BASE_URL=http://localhost:18765
ANTHROPIC_AUTH_TOKEN=claudecodex-local
ANTHROPIC_MODEL=gpt-5.5
ANTHROPIC_SMALL_FAST_MODEL=gpt-5.4-mini
CLAUDE_CODE_MAX_CONTEXT_TOKENS=400000
CLAUDE_CODE_AUTO_COMPACT_WINDOW=400000
CLAUDE_CODE_DISABLE_AGENT_VIEW=1
```

Your plugins, skills, and MCP servers are shared (the launcher does **not**
change `CLAUDE_CONFIG_DIR`), so they work in `claudecodex` too. Note that
claude.ai-hosted connectors are disabled while a token auth source is set —
that's expected for any custom endpoint.

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
