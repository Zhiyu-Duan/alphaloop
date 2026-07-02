# OpenOrder — Agent Instructions

> **For AI agents reading this repo**: openorder is a *skill*, not an application. It teaches you how to maintain a persistent investment-research wiki on the user's machine.
>
> openorder is bundled inside **[AlphaLoop](../../AGENTS.md)** — the human-agent investment-research operating model. It is the **memory layer** of that suite: the mandatory read-then-write-back step that closes the compounding loop.

## What you are looking at

openorder is a [Karpathy LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) implementation, specialized for investment research and wired into AlphaLoop's orchestrator. The full skill spec lives in [`SKILL.md`](SKILL.md). **Read it before doing anything else.**

This `AGENTS.md` exists so agents that follow the [`AGENTS.md` standard](https://github.com/openai/codex/blob/main/AGENTS.md) (OpenAI Codex, OpenCode, Hermes, OpenClaw, Aider, etc.) can discover and load the skill consistently. It mirrors [`SKILL.md`](SKILL.md).

## Quick install (any agent)

Install via the parent AlphaLoop repo — openorder ships with it, along with the five sibling skills it interoperates with.

```bash
git clone https://github.com/realnaka/alphaloop.git
cd alphaloop
./install.sh
```

The installer auto-detects installed agents and symlinks the whole `skills/` tree (openorder included) into each:

| Detected | Installed to |
|---|---|
| Claude Code | `~/.claude/skills/openorder/SKILL.md` |
| Cursor (IDE/CLI) | `~/.cursor/skills-cursor/openorder/` (symlink) |
| Codex CLI | `~/.codex/skills/openorder/` (symlink) |
| Hermes Agent | `~/.hermes/skills/openorder/` (symlink) |
| OpenClaw | `~/.openclaw/skills/openorder/` (symlink) |
| OpenCode | `~/.config/opencode/agent/alphaloop.md` (AlphaLoop-level `AGENTS.md`) |
| Aider | `CONVENTIONS.md` symlink per repo (manual) |

It also initializes an empty wiki at `${OPENORDER_HOME:-$HOME/openorder}/` with `INDEX.md`, `log.md`, `raw/`, and the standard sub-directories, seeded from [`examples/`](examples/).

## How to use as an agent

Whenever a conversation touches a ticker, company, industry, earnings release, or investment framework:

1. **Always first**: `Read ${OPENORDER_HOME}/INDEX.md`
2. Then read the relevant sub-files (`companies/`, `industries/`, `frameworks/`, `earnings/`, `portfolios/`, `log.md`)
3. Answer using wiki content + real-time data (real-time prices via [`stock-data-fetch`](../stock-data-fetch/SKILL.md))
4. **Write back**: any new insight, decision, or ingested source MUST update the wiki AND append `log.md`
5. See [`SKILL.md`](SKILL.md) sections 4–8 for the full READ / INGEST / WRITE / LOG / LINT operations

Coordinating with sibling skills (see [`../../SKILL.md`](../../SKILL.md) for the routing table):

- Second-hand claims first go through [`claim-verification`](../claim-verification/SKILL.md); openorder stores the **verified** conclusion (with ✅🟡🔴⚠️ tags preserved)
- Real prices are pulled via [`stock-data-fetch`](../stock-data-fetch/SKILL.md); never write stale prices into a company profile
- Trades get double-logged: openorder captures the thesis, [`trade-journal`](../trade-journal/SKILL.md) captures the **source framework** for feedback attribution
- If a tool fails while ingesting, escalate per [`agent-tool-escalation`](../agent-tool-escalation/SKILL.md) — don't leave the raw source un-ingested

## Key files in this skill

| File | Purpose |
|---|---|
| [`SKILL.md`](SKILL.md) | Full skill specification (the source of truth) |
| [`AGENTS.md`](AGENTS.md) | This file (mirror for `AGENTS.md`-aware agents) |
| [`README.md`](README.md) | Human-facing pitch and quick start |
| [`examples/`](examples/) | Seed templates for `INDEX.md`, `log.md`, wiki `README.md`, `raw/README.md`, company & earnings templates |
| [`docs/compatibility.md`](docs/compatibility.md) | Supported agents and their install paths |
| [`docs/customize.md`](docs/customize.md) | How to port openorder's wiki pattern to other domains (crypto, biotech, etc.) |
| [`docs/credits.md`](docs/credits.md) | Lineage from Karpathy's gist and Memex |

## What this skill does NOT contain

- **No real research data**: only the skill + templates. Wiki content (company profiles, earnings analyses, portfolios) lives at `${OPENORDER_HOME}` on the local machine and is **never** committed to this public repo.
- **No personal data**: no real tickers, no real positions, no proprietary frameworks beyond the abstract scoring scaffold in templates.
- **No telemetry / network calls**: pure markdown + your agent. Nothing phones home.

## Inheritance

openorder builds directly on Karpathy's pattern:
- Three layers (Raw / Wiki / Schema) ← Karpathy
- `INDEX.md` + `log.md` dual indexing ← Karpathy
- Ingest / Query / Lint operations ← Karpathy

The investment-research domain framing, chokepoint-style scoring in templates, and the interlocks with AlphaLoop's other sub-skills (claim-verification, stock-data-fetch, strategic-materials, trade-journal, agent-tool-escalation) are original to openorder / AlphaLoop.

License: MIT. See [`../../LICENSE`](../../LICENSE).

---

**Read [`SKILL.md`](SKILL.md) next.**
