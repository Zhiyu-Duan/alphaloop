#!/usr/bin/env bash
# AlphaLoop installer
#   - auto-detects installed AI agents
#   - symlinks the orchestrator (this repo) + every bundled sub-skill
#     into each agent's skills directory
#   - initializes an empty openorder wiki at ${OPENORDER_HOME:-$HOME/openorder}
#
# Usage:
#   ./install.sh                       # install for all detected agents
#   ./install.sh --home ~/my-wiki      # custom wiki home
#   ./install.sh --prefix ~/sandbox    # install under a custom HOME-like prefix (for testing)
#   ./install.sh --dry-run             # show what would be done
#   ./install.sh --uninstall           # remove all symlinks (wiki untouched)

set -euo pipefail

# ---- locate the repo (where SKILL.md lives) ----
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_FILE="$REPO_DIR/SKILL.md"
AGENTS_FILE="$REPO_DIR/AGENTS.md"
SKILLS_DIR="$REPO_DIR/skills"

if [[ ! -f "$SKILL_FILE" ]]; then
  echo "SKILL.md not found at $SKILL_FILE" >&2
  exit 1
fi

# ---- args ----
PREFIX="$HOME"
WIKI_HOME="${OPENORDER_HOME:-$HOME/openorder}"
DRY_RUN=0
UNINSTALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --home)        WIKI_HOME="$2"; shift 2 ;;
    --prefix)      PREFIX="$2"; shift 2 ;;
    --dry-run)     DRY_RUN=1; shift ;;
    --uninstall)   UNINSTALL=1; shift ;;
    -h|--help)     sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

run() {
  if (( DRY_RUN )); then
    printf '  [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# ---- the skills this suite ships (orchestrator + sub-skills) ----
# "alphaloop" maps to the repo root (its SKILL.md is the orchestrator).
declare -a SUBSKILLS=(
  claim-verification
  agent-tool-escalation
  openorder
  strategic-materials
  stock-data-fetch
  trade-journal
)

# Map a skill name -> source dir
src_for() {
  local name="$1"
  if [[ "$name" == "alphaloop" ]]; then
    echo "$REPO_DIR"
  else
    echo "$SKILLS_DIR/$name"
  fi
}

declare -a INSTALLED=()
declare -a SKIPPED=()

# Symlink one skill dir into one agent root
link_skill() {
  local agent_label="$1" agent_root="$2" skill_name="$3"
  local target_dir="$agent_root/$skill_name"
  local source_dir; source_dir="$(src_for "$skill_name")"

  if (( UNINSTALL )); then
    if [[ -L "$target_dir" ]]; then
      printf '  removing %s\n' "$target_dir"
      run rm -f "$target_dir"
    fi
    return
  fi

  if [[ -e "$target_dir" || -L "$target_dir" ]]; then
    printf '  replacing existing %s\n' "$target_dir"
    run rm -rf "$target_dir"
  fi
  run ln -snf "$source_dir" "$target_dir"
}

# Install the whole suite for one skill-dir-based agent
install_for_skill_agent() {
  local label="$1" agent_root="$2"
  local parent; parent="$(dirname "$agent_root")"

  if (( UNINSTALL )); then
    if [[ -d "$agent_root" ]]; then
      link_skill "$label" "$agent_root" "alphaloop"
      for s in "${SUBSKILLS[@]}"; do link_skill "$label" "$agent_root" "$s"; done
    fi
    return 0
  fi

  if [[ ! -d "$parent" ]]; then
    SKIPPED+=("$label (parent $parent not found)")
    return 0
  fi
  run mkdir -p "$agent_root"
  link_skill "$label" "$agent_root" "alphaloop"
  for s in "${SUBSKILLS[@]}"; do link_skill "$label" "$agent_root" "$s"; done
  INSTALLED+=("$label -> $agent_root (alphaloop + ${#SUBSKILLS[@]} sub-skills)")
  return 0
}

# Install AGENTS.md mirror for AGENTS.md-based agents
install_for_agents_md() {
  local label="$1" target_file="$2"
  if (( UNINSTALL )); then
    if [[ -L "$target_file" ]]; then
      printf '  removing %s\n' "$target_file"
      run rm -f "$target_file"
    fi
    return 0
  fi
  local parent; parent="$(dirname "$target_file")"
  if [[ ! -d "$parent" ]]; then
    SKIPPED+=("$label (parent $parent not found)")
    return 0
  fi
  [[ -e "$target_file" || -L "$target_file" ]] && run rm -f "$target_file"
  run ln -snf "$AGENTS_FILE" "$target_file"
  INSTALLED+=("$label -> $target_file")
  return 0
}

echo "AlphaLoop installer"
echo "==================="
echo "  Repo:      $REPO_DIR"
echo "  Prefix:    $PREFIX"
echo "  Wiki home: $WIKI_HOME"
[[ $DRY_RUN -eq 1 ]] && echo "  Mode:      DRY RUN (no changes)"
[[ $UNINSTALL -eq 1 ]] && echo "  Mode:      UNINSTALL"
echo

echo "Step 1/2: Wiring agents..."

# --- skill-dir based agents ---
install_for_skill_agent "Claude Code" "$PREFIX/.claude/skills"
install_for_skill_agent "Cursor"      "$PREFIX/.cursor/skills-cursor"
install_for_skill_agent "Codex CLI"   "$PREFIX/.codex/skills"
install_for_skill_agent "Hermes"      "$PREFIX/.hermes/skills"
install_for_skill_agent "OpenClaw"    "$PREFIX/.openclaw/skills"

# --- AGENTS.md based agents ---
install_for_agents_md "OpenCode" "$PREFIX/.config/opencode/agent/alphaloop.md"

echo "  Aider uses project-local CONVENTIONS.md - see skills/openorder/docs/compatibility.md"
echo

# ---- init wiki home (reuses openorder example seeds) ----
if (( ! UNINSTALL )); then
  echo "Step 2/2: Initializing wiki at $WIKI_HOME ..."
  run mkdir -p "$WIKI_HOME"/{raw/earnings,raw/articles,raw/filings,raw/research-notes,companies,industries,frameworks,earnings,portfolios,templates}

  OO_EX="$SKILLS_DIR/openorder/examples"
  for pair in \
    "INDEX.example.md:$WIKI_HOME/INDEX.md" \
    "log.example.md:$WIKI_HOME/log.md" \
    "wiki-README.example.md:$WIKI_HOME/README.md" \
    "raw-README.example.md:$WIKI_HOME/raw/README.md" \
    "company-template.md:$WIKI_HOME/templates/company-template.md" \
    "earnings-template.md:$WIKI_HOME/templates/earnings-template.md"; do
    ex="$OO_EX/${pair%%:*}"; dst="${pair#*:}"
    if [[ -e "$dst" ]]; then
      printf '  keeping existing %s\n' "$dst"
    elif [[ -f "$ex" ]]; then
      run cp "$ex" "$dst"
      printf '  seeded %s\n' "$dst"
    fi
  done

  if [[ ! -d "$WIKI_HOME/.git" ]]; then
    run bash -c "cd '$WIKI_HOME' && git init -q -b main 2>/dev/null && {
      echo '.DS_Store'  > .gitignore
      echo '*.pdf'     >> .gitignore
      echo '*.key'     >> .gitignore
      echo '.env*'     >> .gitignore
    } || true"
  fi
fi

echo
echo "==================="
if (( UNINSTALL )); then
  echo "Uninstall complete. Wiki at $WIKI_HOME left untouched."
else
  if [[ ${#INSTALLED[@]} -gt 0 ]]; then
    echo "Installed for:"
    for line in "${INSTALLED[@]}"; do echo "    - $line"; done
  fi
  if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo "Skipped:"
    for line in "${SKIPPED[@]}"; do echo "    - $line"; done
  fi
  echo
  echo "Next steps:"
  echo "  1. Open a fresh AI chat and hand it an investment thesis, a research screenshot,"
  echo "     or ask about a stock - AlphaLoop will run the verify -> price -> pick -> log loop."
  echo "  2. Browse your wiki:  ls $WIKI_HOME"
  echo "  3. Set OPENORDER_HOME in your shell rc for a non-default wiki path."
fi
