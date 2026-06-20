#!/usr/bin/env bash
# memory-lint.sh — mechanical health check for the three-tier memory system
# Runs weekly via com.josef.memory-lint launchd job (Sunday 04:00)
# Contradiction detection and consolidation merges are LLM-only; not done here.

set -euo pipefail

MEM="${MEM_DIR:-$HOME/workspace/ai/memory}"
WIKI="${WIKI_DIR:-$HOME/workspace/ai/llm-wiki}"
LOG="$WIKI/log.md"

issues=0
report=""

add() { report="${report}\n$1"; }
fail() { add "  ISSUE: $1"; issues=$((issues + 1)); }

# ── HOT TIER ─────────────────────────────────────────────────────────────────
add "\n### HOT TIER"
lines=$(wc -l < "$MEM/MEMORY.md")
if [ "$lines" -ge 200 ]; then
  fail "MEMORY.md: $lines lines — BLOCK (>=200)"
elif [ "$lines" -ge 160 ]; then
  add "  WARN: MEMORY.md: $lines lines (>=160, approaching cap)"
else
  add "  OK:  MEMORY.md: $lines lines"
fi

# Forward links
broken_fwd=0
while IFS= read -r fn; do
  [ -f "$MEM/$fn" ] || { fail "broken forward link: $fn"; broken_fwd=$((broken_fwd+1)); }
done < <(grep -oE '\([^)]+\.md\)' "$MEM/MEMORY.md" | tr -d '()')

# Orphan warm files (no MEMORY.md entry)
orphan_warm=0
while IFS= read -r fn; do
  grep -qF "($fn)" "$MEM/MEMORY.md" || { fail "orphan warm file: $fn"; orphan_warm=$((orphan_warm+1)); }
done < <(ls "$MEM"/*.md | grep -v 'MEMORY.md' | xargs -n1 basename)

# Duplicates
dupes=$(grep -oE '\([^)]+\.md\)' "$MEM/MEMORY.md" | tr -d '()' | sort | uniq -d)
[ -n "$dupes" ] && fail "duplicate MEMORY.md entries: $dupes"

[ "$broken_fwd" -eq 0 ] && [ "$orphan_warm" -eq 0 ] && [ -z "$dupes" ] && add "  OK:  bidirectional integrity clean"

# ── WARM TIER ─────────────────────────────────────────────────────────────────
add "\n### WARM TIER"

# Broken [[slug]] cross-links
broken_xlinks=0
while IFS= read -r line; do
  file=$(echo "$line" | cut -d: -f1)
  content=$(echo "$line" | cut -d: -f3-)
  while IFS= read -r ref; do
    slug=$(echo "$ref" | tr -d '[]')
    [ "$slug" = "Related" ] && continue
    if [ ! -f "$MEM/$slug.md" ]; then
      fail "broken cross-link in $(basename "$file"): [[$slug]]"
      broken_xlinks=$((broken_xlinks+1))
    fi
  done < <(echo "$content" | grep -oE '\[\[[A-Za-z0-9_-]+\]\]' 2>/dev/null || true)
done < <(grep -rn '\[\[' "$MEM" --include="*.md" 2>/dev/null | grep -v 'MEMORY.md')
[ "$broken_xlinks" -eq 0 ] && add "  OK:  cross-links clean"

# Staleness: mtime >90 days (macOS stat)
CUTOFF=$(date -v-90d '+%Y%m%d')
stale_count=0
while IFS= read -r f; do
  [[ "$(basename "$f")" == "MEMORY.md" ]] && continue
  mtime=$(stat -f "%Sm" -t "%Y%m%d" "$f")
  if [ "$mtime" -lt "$CUTOFF" ]; then
    human=$(stat -f "%Sm" -t "%Y-%m-%d" "$f")
    add "  STALE CANDIDATE: $(basename "$f") (mtime: $human)"
    stale_count=$((stale_count+1))
  fi
done < <(ls "$MEM"/*.md)
[ "$stale_count" -eq 0 ] && add "  OK:  no stale warm files"

# Consolidation candidates: MEMORY.md one-liners that share >=4 content words (Python for speed)
add "\n### CONSOLIDATION CANDIDATES"
consolidation_output=$(python3 - "$MEM/MEMORY.md" <<'PYEOF'
import re, sys
STOP = set("the a an do i is my to for of how with and it that on in at be we are this all never always before after if when then not use check file run".split())
entries = []
for line in open(sys.argv[1]):
    m = re.match(r'^- \[.+?\]\((.+?\.md)\) — (.+)', line)
    if m:
        fn, desc = m.group(1), m.group(2)
        words = set(w.lower() for w in re.findall(r'[a-z]{4,}', desc.lower()) if w not in STOP)
        entries.append((fn, words, desc[:60]))
candidates = []
for i in range(len(entries)):
    for j in range(i+1, len(entries)):
        shared = entries[i][1] & entries[j][1]
        if len(shared) >= 4:
            candidates.append(f"  CANDIDATE: {entries[i][0]} ↔ {entries[j][0]} (shared: {', '.join(sorted(shared))})")
print('\n'.join(candidates) if candidates else "  none found")
PYEOF
)
add "$consolidation_output"

# ── COLD TIER ─────────────────────────────────────────────────────────────────
add "\n### COLD TIER"

# Broken wikilinks in kept wiki pages
broken_wiki=0
while IFS= read -r line; do
  file=$(echo "$line" | cut -d: -f1)
  content=$(echo "$line" | cut -d: -f3-)
  while IFS= read -r ref; do
    slug=$(echo "$ref" | tr -d '[]')
    found=$(find "$WIKI/wiki" -name "${slug}.md" 2>/dev/null | head -1)
    [ -z "$found" ] && found=$(ls "$MEM/${slug}.md" 2>/dev/null || true)
    if [ -z "$found" ]; then
      fail "broken wiki wikilink in $(basename "$file"): [[$slug]]"
      broken_wiki=$((broken_wiki+1))
    fi
  done < <(echo "$content" | grep -oE '\[\[[A-Za-z0-9_-]+\]\]' 2>/dev/null || true)
done < <(grep -rn '\[\[' "$WIKI/wiki" --include="*.md" 2>/dev/null | grep -v '_archive')
[ "$broken_wiki" -eq 0 ] && add "  OK:  wiki wikilinks clean"

# Orphan wiki pages
orphan_wiki=0
while IFS= read -r f; do
  rel=$(echo "$f" | sed "s|$WIKI/||")
  grep -qF "$rel" "$WIKI/index.md" || { add "  ORPHAN wiki page: $rel"; orphan_wiki=$((orphan_wiki+1)); }
done < <(find "$WIKI/wiki" -name "*.md" -not -path "*/_archive/*" 2>/dev/null)
[ "$orphan_wiki" -eq 0 ] && add "  OK:  no orphan wiki pages"

# Archive leaks
while IFS= read -r fn; do
  grep -qF "$fn" "$WIKI/index.md" && fail "archive leak: $fn appears in index.md"
done < <(ls "$WIKI/wiki/_archive/" 2>/dev/null || true)

# ── LOG + EXIT ────────────────────────────────────────────────────────────────
ts=$(date '+%Y-%m-%d %H:%M')
if [ "$issues" -eq 0 ]; then
  summary="0 issues — all tiers GREEN"
else
  summary="$issues issue(s) found — run memory-lint.sh manually for details"
fi
echo "${ts} | lint | - | ${summary}" >> "$LOG"

echo -e "$report"
echo ""
echo "Total issues: $issues"
echo "Log: $LOG"

[ "$issues" -eq 0 ] && exit 0 || exit 1
