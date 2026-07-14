# claudecodex

Use **Claude Code's interface** with **GPT-5.6** (Sol / Terra / Luna) as the engine —
driven by your **ChatGPT Plus/Pro subscription** through a local Codex-auth proxy.

You keep the Claude Code agent workflow you like (file edits, terminal flow,
approvals, MCP servers, skills) but the model answering is GPT-5.6, billed
against your ChatGPT subscription instead of your Anthropic usage.

```
claudecodex
   → claude (real Claude Code UI)
   → local Anthropic-compatible proxy (127.0.0.1:18765)
   → Codex auth via your ChatGPT Plus/Pro subscription
   → GPT-5.6-sol
   → streamed back into Claude Code
```

`claudecodex` is a thin launcher: it starts the proxy if needed, exports the
right environment **only for that process**, then `exec`s `claude`. Your plain
`claude` command stays completely stock — same login, same Anthropic models.

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
| `CLAUDECODEX_CONTEXT` | `272000` | Context window (see note) |
| `CLAUDECODEX_SKIP_PERMISSIONS` | `1` | `1` = bypass permissions, `0` = normal prompts |
| `CLAUDECODEX_PORT` | `18765` | Proxy port |
| `CLAUDECODEX_AGENT_VIEW` | `0` | `1` = show the background-jobs dashboard on start |
| `CLAUDECODEX_PROXY_BIN` | `claude-code-proxy` | Proxy binary name/path |

Example:

```bash
CLAUDECODEX_EFFORT=high CLAUDECODEX_MODEL=gpt-5.6-terra claudecodex
```

### Context window note

Through **Codex auth** (this proxy's path) GPT-5.6's ChatGPT subscription context
limit is **272K tokens**. Claude Code otherwise assumes 200K for unknown model
names, which makes the context gauge wrong and compacts too early; `claudecodex`
sets it to the real 272K. Bump `CLAUDECODEX_CONTEXT` if OpenAI raises the
subscription limit.

---

## What it sets (and why plain `claude` is safe)

Everything below is exported inside the launcher process and dies with it —
nothing is written to `~/.claude/settings.json` or your shell:

```
ANTHROPIC_BASE_URL=http://localhost:18765
ANTHROPIC_AUTH_TOKEN=claudecodex-local
ANTHROPIC_MODEL=gpt-5.6-sol
ANTHROPIC_SMALL_FAST_MODEL=gpt-5.6-luna
CLAUDE_CODE_MAX_CONTEXT_TOKENS=272000
CLAUDE_CODE_AUTO_COMPACT_WINDOW=272000
CLAUDE_CODE_DISABLE_AGENT_VIEW=1
# plus, session-scoped via flags: --model / --effort / --dangerously-skip-permissions
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
