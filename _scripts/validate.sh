#!/bin/bash
HUB=~/workspace/ai/agent-hub

echo "=== A. Symlink integrity ==="
$HUB/_scripts/smoke.sh || exit 1

echo "=== B. Content equality (pre vs post) ==="
TS=$(cat /tmp/agent-hub-ts)
{
  for f in $(awk '{print $2}' ~/Desktop/agent-hub-backup-$TS/hashes-before.txt); do
    [ -e "$f" ] && shasum -a 256 "$f" 2>/dev/null
  done
} | sort > $HUB/_inventory/hashes-after.txt

if ! diff ~/Desktop/agent-hub-backup-$TS/hashes-before.txt $HUB/_inventory/hashes-after.txt >/dev/null 2>&1; then
  echo "  (paths changed as expected; checking content hashes...)"
  awk '{print $1}' ~/Desktop/agent-hub-backup-$TS/hashes-before.txt | sort -u > /tmp/h-before
  awk '{print $1}' $HUB/_inventory/hashes-after.txt | sort -u > /tmp/h-after
  comm -23 /tmp/h-before /tmp/h-after > /tmp/h-missing
  if [ -s /tmp/h-missing ]; then
    echo "FAIL: content hashes missing:"
    cat /tmp/h-missing
    exit 1
  fi
fi
echo "  ✓ All content preserved"

echo "=== C. Tool functional ==="
claude --version | head -1 || exit 1
rtk gain >/dev/null || exit 1
launchctl list | grep -q ai.hermes.gateway || exit 1

echo "=== D. Hub structure ==="
[ -d $HUB/instructions ] && [ -d $HUB/skills/hermes-skills ] && [ -d $HUB/plugins/claude ] || exit 1

echo "=== E. Protected zones untouched ==="
[ -d ~/workspace/ghub/Azulays-agentic-teams ] && [ ! -L ~/workspace/ghub/Azulays-agentic-teams ] || { echo "FAIL: Azulays touched"; exit 1; }
[ -f ~/.hermes/state.db ] && [ ! -L ~/.hermes/state.db ] || { echo "FAIL: state.db touched"; exit 1; }
[ -d ~/workspace/ai/servicenow-client ] && [ ! -L ~/workspace/ai/servicenow-client ] || { echo "FAIL: servicenow-client touched"; exit 1; }
[ -d ~/workspace/ai/varonis-mail-mcp ] && [ ! -L ~/workspace/ai/varonis-mail-mcp ] || { echo "FAIL: varonis-mail-mcp displaced"; exit 1; }
[ -d ~/workspace/ai/varonis-teams-mcp ] && [ ! -L ~/workspace/ai/varonis-teams-mcp ] || { echo "FAIL: varonis-teams-mcp displaced"; exit 1; }
[ -d ~/workspace/ai/tlaams ] && [ ! -L ~/workspace/ai/tlaams ] || { echo "FAIL: tlaams project displaced"; exit 1; }

echo "✓ ALL VALIDATIONS PASSED"
