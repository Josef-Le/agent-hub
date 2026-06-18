#!/bin/bash
# sync-mcps.sh
# Renders MCP configs from registry.json to all agent runtimes on change.
# Trigger: launchd WatchPaths on mcp/registry.json, or run manually.
# Source of truth: agent-hub/mcp/registry.json

RENDER="$HOME/workspace/ai/agent-hub/mcp/render.py"

# Remove hash so render.py doesn't skip due to stale cache
rm -f "$(dirname "$RENDER")/.render_hash"

"$RENDER" --apply 2>&1 | tee -a /tmp/ai.agenthub.mcp-sync.log
