#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2" >/dev/null 2>&1; then echo "PASS $1"; PASS=$((PASS+1)); else echo "FAIL $1"; FAIL=$((FAIL+1)); fi }

check "claude binary"        "claude --version | grep -q '2\\.'"
check "rtk binary"            "rtk --version | grep -q 'rtk '"
check "rtk hook installed"    "grep -q 'rtk' ~/.claude/settings.json ~/.claude/settings.local.json 2>/dev/null"
check "claude CLAUDE.md link" "[ -L ~/.claude/CLAUDE.md ] && [ -r ~/.claude/CLAUDE.md ]"
check "claude RTK.md link"    "[ -L ~/.claude/RTK.md ] && [ -r ~/.claude/RTK.md ]"
check "claude plugins link"   "[ -L ~/.claude/plugins ] && [ -d ~/.claude/plugins ]"
check "hermes SOUL.md link"   "[ -L ~/.hermes/SOUL.md ] && [ -r ~/.hermes/SOUL.md ]"
check "hermes skills link"    "[ -L ~/.hermes/skills ] && [ -d ~/.hermes/skills ]"
check "hermes plugins link"   "[ -L ~/.hermes/plugins ] && [ -d ~/.hermes/plugins ]"
check "hermes mcp link"       "[ -L ~/.hermes/mcp-servers ] && [ -d ~/.hermes/mcp-servers ]"
check "hermes state.db real"  "[ -f ~/.hermes/state.db ] && [ ! -L ~/.hermes/state.db ]"
check "opencode skills link"  "[ -L ~/.config/opencode/skills ] && [ -d ~/.config/opencode/skills ]"
check "workspace AGENTS.md"   "[ -L ~/workspace/ai/AGENTS.md ] && [ -r ~/workspace/ai/AGENTS.md ]"
check "workspace .clinerules" "[ -L ~/workspace/ai/.clinerules ] && [ -r ~/workspace/ai/.clinerules ]"
check "no broken symlinks in consolidation scope" "! find ~/.claude ~/.hermes/SOUL.md ~/.hermes/skills ~/.hermes/plugins ~/.hermes/mcp-servers ~/.config/opencode/skills -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | grep -q ."
check "skill-sync launchd"    "launchctl list | grep -q ai.agenthub.skill-sync"
check "skill-sync script"     "[ -x ~/workspace/ai/agent-hub/_scripts/sync-skills.sh ]"
check "hermes process up"     "launchctl list | grep -q ai.hermes.gateway"
check "ollama still up"       "lsof -nP -iTCP:11434 -sTCP:LISTEN 2>/dev/null | grep -q LISTEN"
check "SSM tunnel still up"   "ps auxww | grep -v grep | grep -q session-manager-plugin"

echo "---"
echo "PASS: $PASS  FAIL: $FAIL"
[ $FAIL -eq 0 ]
