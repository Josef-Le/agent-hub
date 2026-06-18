# Agent Hub

Single source-of-truth for all AI tool configurations, skills, instructions, and MCP servers.

**All tool-specific dirs (`~/.claude/`, `~/.hermes/`, `~/.config/opencode/`, etc.) are now symlinks back into this hub.**

## Quick Links

- **[Topology & Symlink Map](/_docs/topology.md)** — Complete reference of all symlinks and their targets
- **[Tool Decisions Report](/_docs/tool-decisions-20260614.md)** — Diagnosis & verdicts on dormant/broken tools
- **[Model Routing Enforcement](_docs/model-routing-enforcement.md)** — How subagent model costs are enforced (distributable pattern)
- **[Backup Location](../Desktop/agent-hub-backup-20260614-*/)** — Full pre-consolidation backup (tar archives)

## What Lives Here

- **instructions/** — CLAUDE.md, SOUL.md, AGENTS.md, model-routing rules
- **hooks/** — Claude Code hook scripts (UserPromptSubmit, PreToolUse, Stop)
- **skills/** — 31+ Hermes skill categories, Claude skills, OpenCode skills
- **plugins/** — Claude, Hermes, and OpenCode plugin definitions
- **mcp/** — MCP server configs (postgres-rw, neo4j-cypher, etc.)
- **_attic/** — Archived tools with restore scripts (headroom, etc.)
- **_scripts/** — Maintenance: smoke.sh (validation), move_and_link.sh (safe moves)
- **_inventory/** — Consolidation snapshots & diagnostic results

## Restore from Backup

If something goes wrong:

```bash
TS=20260614-210138  # Your session timestamp
cd /
tar xzf ~/Desktop/agent-hub-backup-$TS/configs.tar.gz
```

See [topology.md](/_docs/topology.md) for full restore procedure.

## For Developers

**Adding a new skill?** Just create it in the appropriate `skills/` subdirectory. The symlink ensures it's immediately available to the tool.

**Modifying instructions?** Edit the files in `instructions/` directly. Tools read them via symlinks.

**Restoring an archived tool?** See the RESTORE.md in each `_attic/` subdirectory.

---

**Hub root:** `~/workspace/ai/agent-hub/`  
**Consolidated:** 2026-06-14  
**Status:** All phases complete, validation: PASS ✓
