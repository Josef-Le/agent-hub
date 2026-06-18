# Agent Hub Topology — Consolidated 2026-06-14

## Overview

This hub centralizes all AI tool configurations and instructions under `~/workspace/ai/agent-hub/`, replacing 7+ scattered locations with symlinks. All file content remains byte-identical to pre-consolidation; only locations and references changed.

---

## Directory Structure

```
agent-hub/
├── instructions/               # Instruction files (CLAUDE.md, SOUL.md, etc.)
│   ├── claude-global.md        ← ~/.claude/CLAUDE.md (symlink)
│   ├── rtk.md                  ← ~/.claude/RTK.md (symlink)
│   ├── hermes-soul.md          ← ~/.hermes/SOUL.md (symlink)
│   ├── workspace-agents.md     ← ~/workspace/ai/AGENTS.md (symlink)
│   ├── cline-rules.md          ← ~/workspace/ai/.clinerules (symlink)
│   └── _ai-instructions/       ← ~/workspace/ai/.ai-instructions (symlink)
├── skills/                     # Tool-specific skill definitions
│   ├── hermes-skills/          ← ~/.hermes/skills (symlink)
│   ├── opencode-skills/        ← ~/.config/opencode/skills (symlink)
│   └── claude-skills/          # (reserved for future)
├── plugins/                    # Tool-specific plugins
│   ├── claude/                 ← ~/.claude/plugins (symlink)
│   ├── hermes/                 ← ~/.hermes/plugins (symlink)
│   └── opencode/               # (reserved for future)
├── mcp/                        # MCP server configurations
│   └── hermes-mcp-servers/     ← ~/.hermes/mcp-servers (symlink)
├── memories-templates/         # Archived memory templates
│   └── hermes-archive/         ← ~/.hermes/memories/_backups (symlink)
├── hooks/                      # Claude Code hook scripts
│   └── claude-routing-inject.sh  # UserPromptSubmit: injects model routing mandate every turn
├── personas/                   # Agent personas (reserved)
├── _inventory/                 # Snapshots & diagnostics
│   ├── state-pre.txt           # Pre-consolidation state (Phase 0)
│   ├── smoke-phase7.txt        # Phase 7 smoke test results
│   └── validate-phase12.txt    # Phase 12 validation results
├── _scripts/                   # Consolidation & maintenance scripts
│   ├── move_and_link.sh        # Helper for safe moves + symlinks
│   ├── smoke.sh                # Quick validation battery
│   └── validate.sh             # Full validation suite
├── _docs/                      # Documentation
│   ├── topology.md             # This file
│   ├── tool-decisions-20260614.md # Tool diagnosis & decisions
│   └── model-routing-enforcement.md # Distributable: Claude Code subagent cost-tier enforcement
├── _attic/                     # Archived tools & configs
│   └── headroom-archived-20260614-*/
│       ├── launchagents/
│       │   └── io.headroom.proxy.plist
│       └── RESTORE.md
└── README.md                   # Hub overview
```

---

## All Symlinks (Complete Reference)

| Source | Target | Purpose | Read-back test |
|--------|--------|---------|---|
| `~/.claude/CLAUDE.md` | `agent-hub/instructions/claude-global.md` | Claude Code global instructions (includes @-imports) | ✓ `cat ~/.claude/CLAUDE.md` |
| `~/.claude/RTK.md` | `agent-hub/instructions/rtk.md` | RTK proxy instructions | ✓ `cat ~/.claude/RTK.md` |
| `~/.claude/plugins` | `agent-hub/plugins/claude` | Claude Code plugin definitions | ✓ `ls ~/.claude/plugins/` |
| `~/.hermes/SOUL.md` | `agent-hub/instructions/hermes-soul.md` | Hermes agent persona & soul definition | ✓ `cat ~/.hermes/SOUL.md` |
| `~/.hermes/skills` | `agent-hub/skills/hermes-skills` | 31+ Hermes skill categories | ✓ `ls ~/.hermes/skills/ \| wc -l` |
| `~/.hermes/plugins` | `agent-hub/plugins/hermes` | Hermes plugin ecosystem | ✓ `ls ~/.hermes/plugins/` |
| `~/.hermes/mcp-servers` | `agent-hub/mcp/hermes-mcp-servers` | Hermes MCP server definitions (postgres-rw, etc.) | ✓ `ls ~/.hermes/mcp-servers/` |
| `~/.hermes/memories/_backups` | `agent-hub/memories-templates/hermes-archive` | Archived Hermes memory templates | ✓ `ls ~/.hermes/memories/_backups/` |
| `~/.config/opencode/skills` | `agent-hub/skills/opencode-skills` | OpenCode skill definitions | ✓ `ls ~/.config/opencode/skills/` |
| `~/workspace/ai/AGENTS.md` | `agent-hub/instructions/workspace-agents.md` | Universal AI agent instructions | ✓ `cat ~/workspace/ai/AGENTS.md` |
| `~/workspace/ai/.clinerules` | `agent-hub/instructions/cline-rules.md` | Cline AI agent rules | ✓ `cat ~/workspace/ai/.clinerules` |
| `~/workspace/ai/.ai-instructions` | `agent-hub/instructions/_ai-instructions` | Workspace AI instruction files | ✓ `ls ~/workspace/ai/.ai-instructions/` |

---

## Protected Zones (NOT Touched)

- `~/.hermes/state.db` — Live SQLite database (regular file, NOT symlinked)
- `~/.hermes/audit/`, `cache/`, `logs/`, `checkpoints/`, etc. — Runtime directories
- `~/.hermes/hermes-agent/` — Hermes source repository
- `~/workspace/ghub/Azulays-agentic-teams/` — Oktagon squad territory
- `~/workspace/ghub/` (all Varonis-Systems repos) — Work repos
- `~/workspace/ai/servicenow-client/` — Varonis work, not personal infra
- `~/workspace/ai/varonis-mail-mcp/`, `varonis-teams-mcp/` — Personal MCP servers (kept in place)
- `~/workspace/ai/tlaams/` — Hermes-driven TLAAMS project (not moved, only LaunchAgents restarted)

---

## Tool Decisions (Phase 8-9-10)

| Tool | Status | Action | Details |
|------|--------|--------|---------|
| **Headroom LaunchAgent** | Broken (port 8787 conflict) | Archived | See `_attic/headroom-archived-20260614-*/RESTORE.md` |
| **token-saver MITM** | Active & working | Kept | Running on port 8888, intercepts HTTP/HTTPS, cost savings active |
| **mcp-neo4j-cypher** | Orphaned (unused) | Registered in Claude Code | Can now query Neo4j directly from Claude Code |
| **hermes mcp_serve** | Dormant | Kept (on-demand) | Stays at `~/workspace/ai/hermes-1m-pr/mcp_serve.py`, invoke with `hermes mcp serve` |
| **Azure DevOps PAT** | Plaintext in config | Flagged for manual action | See tool-decisions-20260614.md — out of consolidation scope |

---

## Migrations

- **tlaams-evolution**: `~/workspace/tlaams-evolution` → `~/workspace/ai/tlaams-evolution` (2026-06-14)
  - Path references updated in ~/.zshrc, ~/.zprofile
  - Git status verified in new location

---

## Restore from Backup

Full backup taken pre-consolidation (Phase 1) at:
```
~/Desktop/agent-hub-backup-20260614-*/
├── configs.tar.gz        # ~/.claude, ~/.hermes, ~/.config/opencode, workspace AI dirs
├── vscode.tar.gz         # VS Code settings
├── launchagents.tar.gz   # LaunchAgent plists
├── shell.tar.gz          # ~/.zshrc, ~/.zshenv, ~/.zprofile
├── hashes-before.txt     # SHA256 of all files (for integrity check)
└── verify.txt            # Tar integrity results
```

**Full restore** (if needed):
```bash
TS=20260614-210138  # Your session timestamp
cd /
tar xzf ~/Desktop/agent-hub-backup-$TS/configs.tar.gz
tar xzf ~/Desktop/agent-hub-backup-$TS/shell.tar.gz
launchctl load ~/Library/LaunchAgents/ai.hermes.*.plist
```

---

## How to Add a New Skill

1. Create skill file in the appropriate hub subdirectory:
   - Claude skill: `agent-hub/skills/claude-skills/<skill-name>/`
   - Hermes skill: `agent-hub/skills/hermes-skills/<skill-name>/`
   - OpenCode skill: `agent-hub/skills/opencode-skills/<skill-name>/`

2. Symlink is already in place, so the new skill is immediately available to the tool:
   ```bash
   # Example: new Claude skill
   mkdir -p ~/workspace/ai/agent-hub/skills/claude-skills/my-skill
   # New files here are immediately visible at ~/.claude/plugins/ (via symlink)
   ```

3. Restart the tool if it caches skill definitions:
   - Claude Code: No restart needed (reads ~/.claude/ on tool startup)
   - Hermes: `launchctl reload ai.hermes.gateway.plist` (or restart HermesCronBar)

---

## Validation Checklist

Run anytime to verify the hub is healthy:

```bash
~/workspace/ai/agent-hub/_scripts/smoke.sh     # Quick smoke test (18 checks)
~/workspace/ai/agent-hub/_scripts/validate.sh  # Full validation (content, structure, protection)
```

---

## Session History

| Phase | Scope | Status | Gate |
|-------|-------|--------|------|
| 0 | Pre-flight checks | ✓ PASS | State snapshot saved |
| 1 | Backups (tar, hashes) | ✓ PASS | All tars verified |
| 2 | Hub scaffolding | ✓ PASS | 13+ directories created |
| 3 | Stop services | ✓ PASS | Hermes, headroom unloaded |
| 4 | Claude consolidation | ✓ PASS | 3 files moved, symlinks validated |
| 5 | Hermes consolidation | ✓ PASS | 5 items moved, state.db untouched |
| 6 | Workspace consolidation | ✓ PASS | 4 items moved, smoke passing |
| 7 | Restart services | ✓ PASS | 18/18 smoke checks pass |
| 8 | Tool diagnosis | ✓ COMPLETE | 5 tools diagnosed |
| 9 | Tool decisions | ✓ DECIDED | User verdicts: archive, register, keep |
| 10 | Execute decisions | ✓ PASS | Headroom archived, neo4j registered |
| 11 | tlaams-evolution migration | ✓ PASS | Moved, paths updated, git OK |
| 12 | Final validation | ✓ PASS | All checks pass (18/18) |
| 13 | Documentation | ✓ COMPLETE | topology.md, README updated |

---

## Quick Command Reference

```bash
# Validate hub health
~/workspace/ai/agent-hub/_scripts/smoke.sh

# Check symlink targets
find ~/.claude ~/.hermes ~/.config/opencode -maxdepth 2 -type l -exec readlink {} \;

# View hub structure
tree ~/workspace/ai/agent-hub -L 2 -I '_inventory|_scripts'

# Restore archived tool (example: headroom)
cat ~/workspace/ai/agent-hub/_attic/headroom-archived-*/RESTORE.md

# Update a skill
# Changes to ~/workspace/ai/agent-hub/skills/hermes-skills/* are immediately visible at ~/.hermes/skills/*
```

---

**Generated:** 2026-06-14  
**Consolidation session:** groovy-painting-brook  
**Hub root:** `~/workspace/ai/agent-hub/`
