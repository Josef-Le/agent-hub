#!/usr/bin/env bash
# memory-autocommit.sh — nightly git commit of memory/*.md changes
# Runs via com.josef.memory-autocommit launchd job (daily 23:50)

set -uo pipefail

MEM="$HOME/workspace/ai/memory"
LOG="$HOME/workspace/ai/llm-wiki/memory-autocommit.log"
TS=$(date '+%Y-%m-%d %H:%M')

cd "$MEM"

# Stage only .md files (avoid accidentally committing other artifacts)
git add *.md 2>/dev/null || true

if git diff --cached --quiet; then
  echo "$TS | skip | nothing to commit" >> "$LOG"
  exit 0
fi

count=$(git diff --cached --name-only | wc -l | tr -d ' ')
msg="auto: daily memory snapshot $(date '+%Y-%m-%d') ($count file(s) changed)"

if git commit -m "$msg" >> "$LOG" 2>&1; then
  echo "$TS | committed | $count file(s)" >> "$LOG"
else
  echo "$TS | FAILED | git commit returned non-zero" >> "$LOG"
  exit 1
fi
