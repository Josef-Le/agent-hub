# Claude Code — Model Routing Enforcement

How to enforce cost-tier model routing in Claude Code so that subagents never silently upgrade to
Opus, and Haiku is used for all mechanical leaf work without relying on instructions or memory.

Verified on Claude Code 2.1.181, 2026-06-18.

---

## The Problem

Claude Code spawns subagents via the `Agent` tool. Without enforcement:
- An unspecified `model:` inherits the session model (expensive if session is Opus)
- Instructions in CLAUDE.md drift — they're reminders, not enforcement
- `PreToolUse` hooks with `matcher: "Agent"` **do not fire** for Agent tool calls (confirmed limitation)

---

## The Solution: Three Layers

### Layer 1 — Hard block via `permissions.deny` (strongest)

Add to `~/.claude/settings.json`:

```json
{
  "model": "sonnet",
  "permissions": {
    "deny": [
      "Agent(model:opus)",
      "Agent(model:fable)",
      "Agent(model:best)",
      "Agent(model:claude-opus-4-8)",
      "Agent(model:claude-opus-4-6)",
      "Agent(model:claude-fable-5)"
    ]
  },
}
```

- `"model": "sonnet"` — closes the inheritance gap; unspecified subagents fall back to Sonnet, not Opus
- `permissions.deny` — intercepts Agent tool calls at the permissions layer (separate from hooks)
- **Do NOT add `availableModels`** — despite documentation suggesting it's UI-only, it enforces at the session level and blocks `claude --model opus` and `/model opus`. Tested and confirmed broken.
- **To use Opus deliberately:** `claude --model opus`. Subagent calls still get denied by `permissions.deny`.

### Layer 2 — Routing mandate injected every turn

Add `hooks/claude-routing-inject.sh` (this repo) as a `UserPromptSubmit` hook in
`~/.claude/settings.local.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "bash /path/to/agent-hub/hooks/claude-routing-inject.sh"
      }]
    }]
  }
}
```

The script outputs `additionalContext` with the routing legend on every prompt — the same mechanism
as a system-prompt injection but triggered by a hook. Claude sees the mandate fresh every turn
without it living in a static CLAUDE.md that can drift.

### Layer 3 — Explicit `model:` on every `agent()` call in Workflow scripts

In any `.js` workflow, set `model:` explicitly on every `agent()` call:

```js
// Good — explicit, not subject to session inheritance
await agent(prompt, { label: 'my-task', schema: MY_SCHEMA, model: 'sonnet' })
await agent(prompt, { label: 'rename-files', model: 'haiku' })

// Bad — inherits session model (Opus if session started on Opus)
await agent(prompt, { label: 'my-task', schema: MY_SCHEMA })
```

---

## Routing Legend

```
🟢 haiku  — deterministic mechanical work; correct output is exact-match checkable
             file edits, renames, grep/search, bash one-liners, format fixes,
             config changes, adding imports, boilerplate
             → DEFAULT for leaf work. Pick haiku first; escalate to sonnet only if it fails.

🔵 sonnet — anything needing judgment
             code synthesis, debugging, error-handling, API logic, review, refactoring

🔵 sonnet — orchestration tasks
  (lead)    multi-step plans, adversarial verification, launchd/git mutations, wave gates
```

**Sonnet is the subagent ceiling.** If a task needs Opus-level reasoning, do it in the main
session (where you already are Sonnet/Opus), not via a subagent.

---

## What Does NOT Work

| Approach | Why it fails |
|----------|-------------|
| `PreToolUse` hook with `matcher: "Agent"` | Hook never fires for Agent tool calls — confirmed by e2e test |
| `updatedInput` rewrite in PreToolUse | Irrelevant since the hook doesn't fire at all |
| `CLAUDE_CODE_SUBAGENT_MODEL` env var | Silently overrides ALL per-call model params when set; only unset in Sonnet/Opus sessions |
| CLAUDE.md instructions alone | Soft — can drift, not enforced at call time |

---

## Verification

1. Start a new Claude Code session (default or `--model sonnet`)
2. Run: `Agent({ description: "test", prompt: "echo hi", model: "opus" })`
3. Expected: **permission denied** — tool never executes
4. Run: `Agent({ description: "test", prompt: "echo hi", model: "haiku" })`
5. Expected: runs as Haiku 4.5
6. Run: `Agent({ description: "test", prompt: "echo hi" })` (no model)
7. Expected: runs as Sonnet 4.6 (session default)

---

## Files in This Repo

- `hooks/claude-routing-inject.sh` — the UserPromptSubmit hook script
- `_docs/model-routing-enforcement.md` — this document
