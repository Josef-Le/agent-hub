# Tool Decisions Report — 2026-06-14

Generated during Phase 8 consolidation diagnostic. Evidence-based recommendations for dormant/conflicting tools.

---

## Executive Summary

Three tools require decisions:

1. **Headroom MCP proxy** — Port conflict (8787 "address in use"), LaunchAgent failing repeatedly
2. **token-saver MITM proxy** — Active and working (ports 8888 intercepting HTTP/HTTPS), contradicts stale plist state  
3. **mcp-neo4j-cypher** — Orphaned MCP server (installed, not wired to any client)
4. **hermes mcp_serve.py** — Dormant MCP server (10 messaging tools, only invoked on-demand)
5. **Azure DevOps PAT in GitHub Copilot config** — ⚠️ Security finding (plaintext credentials)

---

## Detailed Findings

### 1. Headroom MCP Proxy

| Aspect | Finding |
|--------|---------|
| **Current state** | LaunchAgent failing with "address in use" (port 8787) |
| **Port status** | Process running on :8787 (PID 35055, Python MCP server) |
| **Error log** | 30x "ERROR: [Errno 48] error while attempting to bind on address ('127.0.0.1', 8787)" |
| **LaunchAgent config** | `io.headroom.proxy.plist` exists, has ProgramArguments `/Users/jleizerovich/.local/bin/headroom` |
| **Root cause** | Another process is already bound to 8787; headroom LaunchAgent tries to start on same port → bind fails → retries continuously in background |
| **Status** | BROKEN — tool not functional, consuming logs and retry attempts |

**Recommended action: ARCHIVE**
- The headroom process that IS running on 8787 is some other service (likely manually started or from a different agent)
- headroom plist repeatedly fails; turning it off will stop the error log spam
- Option to revisit if headroom becomes needed later

**Restore path if archived:**
```bash
mv ~/workspace/ai/agent-hub/_attic/headroom-archived-<TS>/io.headroom.proxy.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/io.headroom.proxy.plist
```

---

### 2. token-saver MITM Proxy

| Aspect | Finding |
|--------|---------|
| **Current state** | ACTIVE — running on port 8888 (PID 94170, mitmdump process) |
| **Shell config** | HTTP/HTTPS proxy env vars set to `http://localhost:8888` in ~/.zshrc |
| **Plist state** | `com.tokensaver.mitmproxy.plist` exists (NOT marked as disabled, despite earlier belief) |
| **FINAL_DELIVERY.md** | Session 2026-06-13 delivered Phase 1-5: enterprise model rewriter, path-aware maps, cost savings 44x logged rewrites |
| **Functionality** | Intercepts HTTP/HTTPS requests, rewrites Anthropic/OpenAI models to cheaper variants (claude-sonnet-4.6 → claude-haiku-4.5, gpt-4o → gpt-4o-mini) |
| **Status** | WORKING — this contradicts earlier assumption that it was "dormant" |

**Recommended action: KEEP & DOCUMENT**
- The tool IS delivering value (cost reduction from $332/day in testing)
- Port 8888 is correctly listening and intercepting traffic
- Continue running; log the active status for future reference
- If Claude Code is invoked with HTTP proxy, the MITM intercepts and rewrites expensive models automatically

**Restore path if ever needed:**
```bash
# Already running; if stopped manually:
launchctl load ~/Library/LaunchAgents/com.tokensaver.mitmproxy.plist
```

---

### 3. MCP Neo4j Cypher (Orphaned)

| Aspect | Finding |
|--------|---------|
| **Installation** | Installed via `uv tool` → `~/.local/share/uv/tools/mcp-neo4j-cypher/` |
| **Registration** | NOT wired to Claude Code, Hermes, OpenCode, GitHub Copilot, or any other client |
| **Status** | Dead code; consumes disk space, unclear why it was installed |

**Recommended action: DELETE or ARCHIVE**

If there is no near-term use case for Neo4j querying:
- **DELETE** (if confident it will never be needed): `uv tool uninstall mcp-neo4j-cypher`
- **ARCHIVE** (if unsure): move to `$HUB/_attic/mcp-neo4j-cypher-archived/` with restore script

Decision deferred to you — see **Verdicts** below.

---

### 4. Hermes MCP Serve (Dormant but Valuable)

| Aspect | Finding |
|--------|---------|
| **Location** | `~/workspace/ai/hermes-1m-pr/mcp_serve.py` |
| **Capabilities** | 10 messaging tools (send_hermes_message, etc.) for direct Hermes integration |
| **Current usage** | Only invoked on-demand via `hermes mcp serve` CLI command |
| **Status** | Not auto-registered in Claude Code / Hermes / OpenCode configs |

**Recommended action: KEEP AS-IS or REGISTER**

- **Keep as-is**: If you invoke it manually when needed (low overhead, no long-lived service)
- **Register permanently**: If you want one-click access to Hermes messaging from Claude Code → add to `~/.claude.json` MCP config

Decision deferred to you — see **Verdicts** below.

---

### 5. ⚠️ SECURITY FINDING: Plaintext Azure DevOps PAT

| Aspect | Finding |
|--------|---------|
| **Location** | `~/.config/github-copilot/intellij/mcp.json` |
| **Risk** | Contains a plaintext Azure DevOps Personal Access Token (PAT) |
| **Severity** | HIGH — PAT can be used to read/write Azure DevOps repos if leaked |
| **Action required** | **OUT OF SCOPE for this consolidation**, but surfaced for awareness |

**Immediate recommendation:**
1. Rotate the Azure DevOps PAT (revoke old, generate new) in your Azure DevOps organization settings
2. Move the new PAT to a secret manager:
   - **macOS Keychain** (recommended for local use): `security add-generic-password -a github-copilot -s azure-devops-pat -w <token>`
   - **1Password CLI** (if using 1Password): `op item create --category login --title AzureDevOpsPAT`
3. Update the mcp.json to reference the secret instead of embedding it

**This session will NOT modify this file** — only flagging it for your action.

---

## Decision Template

| Tool | Current State | Recommendation | Your Verdict |
|------|---|---|---|
| Headroom LaunchAgent | Failing (port conflict) | Archive | **[TBD]** |
| token-saver MITM | Active & working | Keep | **[TBD]** |
| mcp-neo4j-cypher | Orphaned (unused) | Delete or Archive | **[TBD]** |
| hermes mcp_serve.py | Dormant (on-demand) | Keep or Register | **[TBD]** |
| Azure DevOps PAT | Plaintext in config | Rotate + move to Keychain | **[TBD]** |

---

## Recommended Next Steps

**After you review and reply with verdicts, Phase 10 will:**

1. **For Headroom**: `launchctl unload ~/Library/LaunchAgents/io.headroom.proxy.plist`, archive the plist
2. **For token-saver**: No action (keep running)
3. **For Neo4j**: Execute your decision (delete or archive)
4. **For hermes mcp_serve**: No action (keep dormant) or register it (if you choose)
5. **For Azure PAT**: Flag manually for your action (out of consolidation scope)

---

## What This Means for the Hub

- **Headroom removed from autostart** → no more port-8787 error spam
- **token-saver continues** → cost savings continue (transparent MITM intercept)
- **Hermes MCP available on-demand** → no registration overhead
- **Hub remains clean** → only active tools auto-start; dormant tools explicitly managed

---

**STATUS: Awaiting your verdicts on three decisions (Headroom, Neo4j, hermes MCP).**
