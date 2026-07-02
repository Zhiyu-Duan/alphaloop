# Cross-Agent Compatibility Guide

openorder is designed to work with **any AI coding agent that supports `SKILL.md` or `AGENTS.md`**. It ships as part of [AlphaLoop](../../README.md); the root [`install.sh`](../../install.sh) handles the wiring for all the agents listed here.

## Auto-detected by AlphaLoop's `install.sh`

Running `./install.sh` from the AlphaLoop repo root symlinks the entire `skills/` tree (openorder included, alongside its sibling skills) into each agent's expected skills directory. Because they are symlinks, `git pull` updates the source once and every agent picks it up automatically.

### Claude Code (Anthropic)

```
~/.claude/skills/openorder/  →  symlink to alphaloop/skills/openorder/
```

Skill is loaded automatically when its `description` matches conversation keywords. See [Claude Code skills docs](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview) for the loading model.

### Cursor (IDE + CLI)

```
~/.cursor/skills-cursor/openorder/  →  symlink to alphaloop/skills/openorder/
```

User-level skills work in **every Cursor project** automatically. Project-level skills (`.cursor/skills/`) are not used by openorder by default.

### Codex CLI (OpenAI)

```
~/.codex/skills/openorder/  →  symlink to alphaloop/skills/openorder/
```

Codex respects both `SKILL.md` (frontmatter-based) and `AGENTS.md` (project-level instructions). openorder ships both.

### Hermes Agent (NousResearch)

```
~/.hermes/skills/openorder/  →  symlink to alphaloop/skills/openorder/
```

Hermes auto-loads skills from `~/.hermes/skills/` and `~/.hermes/optional-skills/`. openorder's `AGENTS.md` is what Hermes reads.

### OpenClaw

```
~/.openclaw/skills/openorder/  →  symlink to alphaloop/skills/openorder/
```

OpenClaw's three-layer (Channel/Brain/Body) architecture loads skills from its body layer.

### OpenCode (sst)

OpenCode reads a single top-level `AGENTS.md`, so the installer symlinks AlphaLoop's root `AGENTS.md` (which itself points into each sub-skill):

```
~/.config/opencode/agent/alphaloop.md  →  symlink to alphaloop/AGENTS.md
```

When conversations touch investment topics, OpenCode follows the routing table there and drops into `skills/openorder/SKILL.md`.

## Manual setup (per-project agents)

### Aider

Aider uses a project-local `CONVENTIONS.md`. To add AlphaLoop (and thus openorder) to a specific repo:

```bash
cd /path/to/your/repo
ln -s /path/to/alphaloop/AGENTS.md CONVENTIONS.md
```

Or merge AlphaLoop rules into your existing `CONVENTIONS.md`.

### Cline / Roo Code

Both use `.clinerules` in the project root:

```bash
cd /path/to/your/repo
ln -s /path/to/alphaloop/AGENTS.md .clinerules
```

### Continue.dev

Continue uses `~/.continue/config.json`. Add a custom rule referencing the openorder skill:

```json
{
  "systemMessage": "Always check ${OPENORDER_HOME}/INDEX.md before answering investment questions. See full skill at ~/.claude/skills/openorder/SKILL.md."
}
```

### Other AGENTS.md-aware agents

Most modern agents (Goose, Helix-AI, etc.) follow the `AGENTS.md` convention. Symlink AlphaLoop's root `AGENTS.md`:

```bash
ln -s /path/to/alphaloop/AGENTS.md ~/path/to/agent/config/AGENTS.md
```

## Verifying the install

After running AlphaLoop's `./install.sh`, check:

```bash
ls -la ~/.claude/skills/openorder           2>/dev/null && echo "✓ Claude Code"
ls -la ~/.cursor/skills-cursor/openorder    2>/dev/null && echo "✓ Cursor"
ls -la ~/.codex/skills/openorder            2>/dev/null && echo "✓ Codex"
ls -la ~/.hermes/skills/openorder           2>/dev/null && echo "✓ Hermes"
ls -la ~/.openclaw/skills/openorder         2>/dev/null && echo "✓ OpenClaw"
ls -la ~/.config/opencode/agent/alphaloop.md 2>/dev/null && echo "✓ OpenCode"
```

Then open a fresh chat in any installed agent and try:

> *"NVDA 现在多少钱，最新 thesis 是啥？"* / *"What's NVDA trading at?"*

If the agent autonomously reads `~/openorder/INDEX.md` before answering, openorder is wired correctly.

## Uninstall

From the AlphaLoop repo root:

```bash
./install.sh --uninstall
```

This removes all symlinks (openorder and its sibling skills). Your wiki at `~/openorder/` is left untouched.

## Reporting compatibility issues

If you tested openorder / AlphaLoop with an agent not listed here, please open an issue or PR on the [AlphaLoop repo](https://github.com/realnaka/alphaloop) — we'd love to add it to the matrix.
