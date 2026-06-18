#!/bin/bash
# sync-skills.sh
# Syncs agent-hub/skills/claude-skills/*.md to all agent runtimes.
# Trigger: launchd WatchPaths on skills/claude-skills/, or run manually.
# Source of truth: agent-hub/skills/claude-skills/*.md
set -euo pipefail

HUB="$HOME/workspace/ai/agent-hub"
CLAUDE_SKILLS="$HUB/skills/claude-skills"
CLAUDE_COMMANDS="$HOME/.claude/commands"
HERMES_SKILLS="$HUB/skills/hermes-skills"
AGENTS_SKILLS="$HOME/.agents/skills"

added=0
for skill in "$CLAUDE_SKILLS"/*.md; do
  [ -f "$skill" ] || continue
  name=$(basename "$skill" .md)

  # Claude Code + VS Code IDE extension
  link="$CLAUDE_COMMANDS/$name.md"
  if [ ! -L "$link" ] || [ ! -e "$link" ]; then
    [ -L "$link" ] && rm "$link"
    ln -s "$skill" "$link"
    echo "claude: linked $name"
    added=$((added + 1))
  fi

  # Hermes (needs a dir/SKILL.md)
  skill_dir="$HERMES_SKILLS/$name"
  skill_file="$skill_dir/SKILL.md"
  mkdir -p "$skill_dir"
  if [ ! -L "$skill_file" ] || [ ! -e "$skill_file" ]; then
    rm -f "$skill_file"
    ln -s "../../claude-skills/$name.md" "$skill_file"
    echo "hermes: linked $name"
    added=$((added + 1))
  fi

  # VS Code agent skills (~/.agents/skills/<name>/SKILL.md)
  agent_dir="$AGENTS_SKILLS/$name"
  agent_file="$agent_dir/SKILL.md"
  mkdir -p "$agent_dir"
  if [ ! -L "$agent_file" ] || [ ! -e "$agent_file" ]; then
    rm -f "$agent_file"   # handles both broken symlinks and pre-existing real files
    ln -s "$(realpath "$skill")" "$agent_file"
    echo "agents: linked $name"
    added=$((added + 1))
  fi
done

[ "$added" -gt 0 ] && echo "sync-skills: $added link(s) created/repaired" || echo "sync-skills: nothing new"
