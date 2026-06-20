#!/usr/bin/env bash
# test_memory_lint.sh — regression tests for memory-lint.sh
# Usage: bash test_memory_lint.sh
# All tests run in temp dirs; real memory/wiki are never touched.

set -uo pipefail

LINT="$(dirname "$0")/memory-lint.sh"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; echo "        $2"; FAIL=$((FAIL+1)); }

# Create a minimal valid test environment
# Returns the tmpdir path via stdout
setup_env() {
  local d
  d=$(mktemp -d)
  local mem="$d/memory"
  local wiki="$d/wiki"
  mkdir -p "$mem" "$wiki/wiki" "$wiki/raw"

  cat > "$mem/MEMORY.md" <<'EOF'
# Memory Index

- [Test entry](test-entry.md) — a test memory file
EOF

  cat > "$mem/test-entry.md" <<'EOF'
---
name: test-entry
description: "A test entry"
metadata:
  type: feedback
---
Test content with no cross-links.
EOF

  cat > "$wiki/index.md" <<'EOF'
# LLM Wiki Index
No synthesis pages.
EOF
  printf '' > "$wiki/log.md"

  echo "$d"
}

run_lint() {
  local d="$1"
  MEM_DIR="$d/memory" WIKI_DIR="$d/wiki" bash "$LINT" 2>&1
}

echo ""
echo "=== memory-lint.sh test suite ==="
echo ""

# ── 1: Clean state → exit 0 ───────────────────────────────────────────────────
echo "[1] Clean state → exit 0"
d=$(setup_env)
output=$(run_lint "$d" || true)
code=$(MEM_DIR="$d/memory" WIKI_DIR="$d/wiki" bash "$LINT" 2>/dev/null; echo $?)
if MEM_DIR="$d/memory" WIKI_DIR="$d/wiki" bash "$LINT" > /dev/null 2>&1; then
  pass "exits 0 on clean state"
else
  fail "exits 0 on clean state" "exited non-zero. output: $output"
fi
rm -rf "$d"

# ── 2: Orphan warm file (not in MEMORY.md) → exit 1 ──────────────────────────
echo "[2] Orphan warm file → exit 1 + 'orphan warm file'"
d=$(setup_env)
echo "---" > "$d/memory/orphan-file.md"
if output=$(run_lint "$d" 2>&1); then
  fail "orphan warm file" "expected exit 1, got exit 0. output: $output"
elif echo "$output" | grep -q "orphan warm file"; then
  pass "exit 1 with 'orphan warm file' in output"
else
  fail "orphan warm file" "exit was non-zero but 'orphan warm file' not in output: $output"
fi
rm -rf "$d"

# ── 3: Broken MEMORY.md forward link → exit 1 + 'broken forward link' ─────────
echo "[3] Broken MEMORY.md forward link → exit 1"
d=$(setup_env)
echo "- [Missing](no-such-file.md) — this file does not exist" >> "$d/memory/MEMORY.md"
if output=$(run_lint "$d" 2>&1); then
  fail "broken forward link" "expected exit 1, got exit 0. output: $output"
elif echo "$output" | grep -q "broken forward link"; then
  pass "exit 1 with 'broken forward link' in output"
else
  fail "broken forward link" "exit was non-zero but message not found: $output"
fi
rm -rf "$d"

# ── 4: Broken [[cross-link]] in warm file → exit 1 + 'broken cross-link' ──────
echo "[4] Broken [[cross-link]] → exit 1"
d=$(setup_env)
printf '\n**Related:** [[nonexistent-slug]]\n' >> "$d/memory/test-entry.md"
if output=$(run_lint "$d" 2>&1); then
  fail "broken cross-link" "expected exit 1, got exit 0. output: $output"
elif echo "$output" | grep -q "broken cross-link"; then
  pass "exit 1 with 'broken cross-link' in output"
else
  fail "broken cross-link" "exit non-zero but message not found: $output"
fi
rm -rf "$d"

# ── 5: MEMORY.md ≥200 lines → exit 1 + 'BLOCK' ───────────────────────────────
echo "[5] MEMORY.md ≥200 lines → exit 1 + 'BLOCK'"
d=$(setup_env)
yes "" 2>/dev/null | head -200 >> "$d/memory/MEMORY.md"
if output=$(run_lint "$d" 2>&1); then
  fail "MEMORY.md 200 lines" "expected exit 1, got exit 0. output: $output"
elif echo "$output" | grep -q "BLOCK"; then
  pass "exit 1 with 'BLOCK' in output"
else
  fail "MEMORY.md 200 lines" "exit non-zero but 'BLOCK' not found: $output"
fi
rm -rf "$d"

# ── 6: MEMORY.md 160-199 lines → exit 0 + 'WARN' ─────────────────────────────
echo "[6] MEMORY.md 160 lines → exit 0 + 'WARN'"
d=$(setup_env)
yes "" 2>/dev/null | head -160 >> "$d/memory/MEMORY.md"
output=$(run_lint "$d" 2>&1 || true)
if echo "$output" | grep -q "WARN"; then
  pass "exit with 'WARN' at 160+ lines"
else
  fail "MEMORY.md 160 lines WARN" "expected WARN, got: $output"
fi
rm -rf "$d"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
TOTAL=$((PASS+FAIL))
echo "Results: $PASS/$TOTAL passed"
echo ""
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
