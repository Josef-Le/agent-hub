# memory-lint

Audit the two-tier memory system (hot MEMORY.md + warm memory/*.md) for health issues and report findings. The cold tier (llm-wiki/wiki/) was pruned 2026-06-21 and is now raw archival only. Read-only during the audit pass; writes only to `log.md` when appending the result.

## Trigger

User types `/memory-lint` or asks to "lint memory", "check memory health", or "audit the memory system".

## Paths (fixed)

- **Hot tier:** `~/workspace/ai/memory/MEMORY.md`
- **Warm tier dir:** `~/workspace/ai/memory/` (all `*.md` except MEMORY.md itself)
- **Cold tier dir:** `~/workspace/ai/llm-wiki/`
- **Log file:** `~/workspace/ai/llm-wiki/log.md`

Expand `~` to the literal home path (`/Users/jleizerovich`) in all Bash commands.

---

## Steps

### Phase 1 — Hot Tier: MEMORY.md

**1.1 Line count**

```bash
wc -l ~/workspace/ai/memory/MEMORY.md
```

Thresholds:
- ≤ 160 lines → OK
- 161–199 lines → WARN
- ≥ 200 lines → BLOCK (escalate to user; do not proceed silently)

**1.2 Extract every filename linked in MEMORY.md**

```bash
grep -oE '\([^)]+\.md\)' ~/workspace/ai/memory/MEMORY.md | tr -d '()'
```

For each extracted filename, check that the file exists in the warm tier dir:

```bash
ls ~/workspace/ai/memory/<filename>
```

Collect any filenames that do NOT exist on disk — these are **broken forward links**.

**1.3 Extract every *.md file in the warm tier dir**

```bash
ls ~/workspace/ai/memory/*.md | grep -v 'MEMORY.md' | xargs -n1 basename
```

For each filename, check that MEMORY.md contains a link to it:

```bash
grep -F '<filename>' ~/workspace/ai/memory/MEMORY.md
```

Collect any files NOT referenced in MEMORY.md — these are **orphan warm files** (missing backward links).

**1.4 Duplicate entries**

```bash
grep -oE '\([^)]+\.md\)' ~/workspace/ai/memory/MEMORY.md | tr -d '()' | sort | uniq -d
```

Any filename appearing more than once is a **duplicate entry**.

**1.5 TOP-PRIORITY block integrity**

Read the first 10 non-blank, non-heading lines of MEMORY.md (skip `# Memory Index` and blank lines). Each of these 10 entries must have a `**bold**` title — i.e., the link text is wrapped in `**...**`. Flag any of the first 10 that are missing bold formatting as **missing bold in TOP-PRIORITY block**.

Bash to extract first 10 entry lines:
```bash
grep -E '^\- \[' ~/workspace/ai/memory/MEMORY.md | head -10
```

Check each for the pattern `\[**` at the start of the link text.

---

### Phase 2 — Warm Tier: memory/*.md files

**2.1 Frontmatter completeness**

For each warm file, check it has a YAML frontmatter block with all three required fields:
- `name:`
- `description:`
- `metadata.type:` (present if the block contains `type:` under a `metadata:` key, or `node_type:` under metadata)

```bash
for f in ~/workspace/ai/memory/*.md; do
  [[ "$(basename $f)" == "MEMORY.md" ]] && continue
  head -10 "$f"
  echo "=== $f ==="
done
```

A file passes frontmatter check if lines 1–N (before the closing `---`) include `name:`, `description:`, and either `type:` or `node_type:`. Collect files that are missing any field.

**2.2 Cross-link resolution**

Scan all warm files for `**Related:** [[slug]]` footer patterns:

```bash
grep -rn '\[\[' ~/workspace/ai/memory/ --include="*.md"
```

For each `[[slug]]` found, check that `slug.md` exists in the warm tier dir:

```bash
ls ~/workspace/ai/memory/<slug>.md
```

Collect any `[[slug]]` references where the target file does not exist — these are **broken cross-links**. Record as `filename:[[slug]]`.

**2.3 Staleness candidates**

For each warm file:

a. Try to extract `updated:` from frontmatter:
```bash
grep 'updated:' <file>
```

If found, parse the date and check if it is > 90 days before today (2026-06-20).

b. If no `updated:` field, check filesystem mtime:
```bash
stat -f "%Sm" -t "%Y-%m-%d" <file>   # macOS
```

If mtime > 90 days ago, mark as a **staleness candidate**.

These are NOT auto-archived — list them for human review only.

**2.4 Contradiction detection (judgment)**

Read the content of all warm files. Apply judgment to identify pairs making contradictory assertions. Focus on these patterns:

- File A says a feature/service is **disabled/decommissioned/stopped**; File B says it is **active/running/enabled** (without acknowledging the decommission).
- File A says use path P; File B says P was **renamed, deleted, or moved**.
- Two files giving **conflicting model routing rules** (e.g., "always use Opus" vs "Opus is blocked").
- Two files with contradictory instructions for the same tool/command.

Do not flag files where one explicitly supersedes the other (e.g., "X was decommissioned on DATE" is not a contradiction with a historical description of X if the decommission file acknowledges the history).

For each flagged pair, produce:
```
CONTRADICTION CANDIDATE — human review required
  File A: <filename>: "<quote>"
  File B: <filename>: "<quote>"
```

---

### Phase 3 — Cold Tier: llm-wiki

**3.1 Broken wikilinks in wiki pages**

Scan all wiki page files for `[[slug]]` patterns:

```bash
grep -rn '\[\[' ~/workspace/ai/llm-wiki/wiki/ --include="*.md"
```

For each `[[slug]]`, check resolution in this order:
1. `~/workspace/ai/llm-wiki/wiki/**/<slug>.md` (any subdirectory)
2. `~/workspace/ai/memory/<slug>.md`

```bash
find ~/workspace/ai/llm-wiki/wiki -name "<slug>.md"
ls ~/workspace/ai/memory/<slug>.md
```

Collect any `[[slug]]` where neither check resolves — these are **broken wiki wikilinks**. Record as `wiki/category/page.md:[[slug]]`.

**3.2 Orphan wiki pages**

List all `.md` files under `~/workspace/ai/llm-wiki/wiki/` (excluding `_archive/`):

```bash
find ~/workspace/ai/llm-wiki/wiki -name "*.md" -not -path "*/_archive/*"
```

For each file, check that its relative path (`wiki/category/slug.md`) appears in `~/workspace/ai/llm-wiki/index.md`:

```bash
grep -F 'wiki/category/slug.md' ~/workspace/ai/llm-wiki/index.md
```

Collect files NOT found in index — these are **orphan wiki pages**.

**3.3 Archive leak check**

List files in `~/workspace/ai/llm-wiki/wiki/_archive/` (if it exists):

```bash
ls ~/workspace/ai/llm-wiki/wiki/_archive/ 2>/dev/null | sed 's/^/_archive\//'
```

For each archived file, check whether it appears in `index.md`. Any archived file referenced from index is an **archive leak**.

---

### Phase 4 — Write to log.md

Count total issues:
- Hot tier: broken forward links + orphan warm files + duplicates + missing bold entries
- Warm tier: incomplete frontmatter files + broken cross-links + staleness candidates + contradiction candidates
- Cold tier: broken wiki wikilinks + orphan wiki pages + archive leaks

Append exactly one line to `~/workspace/ai/llm-wiki/log.md`:

```
{YYYY-MM-DD HH:MM} | lint | - | {N} issues found: {brief summary}
```

Example:
```
2026-06-20 14:33 | lint | - | 5 issues found: 2 broken fwd-links, 1 orphan warm, 1 stale candidate, 1 broken wikilink
```

Use `date '+%Y-%m-%d %H:%M'` for the timestamp.

If N=0: `{date} | lint | - | 0 issues — all tiers GREEN`

---

### Phase 5 — Report to user

Produce the structured report below.

---

## Output format

```
## /memory-lint Report — {YYYY-MM-DD}

### HOT TIER (MEMORY.md)
- Lines: {N} (limit: 200) — {OK|WARN|BLOCK}
- Forward links: {N} checked, {M} broken → {list filenames or "none"}
- Orphan warm files (no MEMORY.md entry): {list or "none"}
- Duplicates: {none | list}
- TOP-PRIORITY bold: {10/10 OK | N/10 missing bold — list which entries}

### WARM TIER (memory/*.md)
- Frontmatter: {N}/{total} complete{; missing: list or ""}
- Cross-links: {N} total [[slug]] refs, {M} broken → {list "file:[[slug]]" or "none"}
- Stale candidates (>90d): {list "filename (last: DATE)" or "none"}
- Contradictions:
  {CANDIDATE list with File A / File B quotes, or "none found"}

### COLD TIER (llm-wiki)
- Broken wikilinks: {N} → {list "page:[[slug]]" or "none"}
- Orphan pages (not in index): {list or "none"}
- Archive leaks (archived but in index): {list or "none"}

### Summary
Total issues: {N}
  Hot tier:  {N}
  Warm tier: {N}
  Cold tier: {N}

Recommended actions (priority order):
1. {highest-severity item — BLOCK first if present}
2. ...
```

If all checks pass: end with `All tiers GREEN.`

---

## What NOT to do

- **Do NOT auto-delete** any file, even orphans or stale candidates. List them; let the user decide.
- **Do NOT edit MEMORY.md** during the audit (not even to fix duplicates or add missing entries).
- **Do NOT edit any warm-tier file** (no frontmatter fixes, no cross-link repairs).
- **Do NOT remove wiki pages** or modify `index.md`.
- **The ONLY write** this skill performs is appending one line to `log.md` in Phase 4.
- **Do NOT auto-resolve contradictions.** Flag them as CANDIDATE and stop. Resolution requires explicit user instruction.
- **Do NOT archive stale files.** Staleness = candidate for human review, not automatic action.
