# HatchLock everywhere: multi-platform plan

Research notes (with sources): `docs/research/2026-11-17-*.md`.

## What "everywhere" can mean

HatchLock is model-agnostic. Models (Claude, GPT, Gemini, Grok) reach it through the **agent or editor** they run in, so the targets are those hosts. Two capability levels exist:

- **Full** (blocks an edit before it is written, plus compiler checks): hosts with pre-write hooks.
- **Guidance** (skills only, no blocking): chat apps and hosts without blocking hooks.

| Host | Level | How it loads HatchLock | Where it is listed | Who submits |
|---|---|---|---|---|
| Claude Code | Full | Native (done) | Self-hosted marketplace (live); Anthropic directory | You (portal, paid plan) |
| GitHub Copilot CLI / VS Code | Full | Reads `.claude-plugin/` and `CLAUDE_PLUGIN_ROOT` directly; needs an install test | `github/awesome-copilot` (issue form, SHA-pinned) | You (issue) |
| Cursor | Full | Needs `.cursor-plugin/plugin.json` + Cursor hook adapter (`preToolUse`, `permission: deny`) | cursor.com/marketplace/publish (manual review) | You (form) |
| Grok Build | Full* | Reads Claude plugins; scripts need `GROK_*` env and camelCase payload fallbacks | `xai-org/plugin-marketplace` (PR, SHA-pinned) | You (fork + PR); I prepare the entry |
| Devin (Windsurf) | Full | Reads `.claude-plugin/` and Claude hooks | No public marketplace (install from git) | n/a |
| JetBrains Junie | Full | Adds `.claude-plugin/marketplace.json` directly | JetBrains marketplace | You |
| Google Antigravity | Full* | Needs `.antigravity-plugin/plugin.json`, root `hooks.json`, JSON-output hook adapter | `antigravity-plugins-official` (partner form) | You (form) |
| ChatGPT / Codex | Guidance | Skills-only zip (built) | OpenAI plugin portal | You |
| claude.ai / Claude API skills | Guidance | Skill uploads (need spec-only frontmatter) | n/a (per-user upload) | You |
| Kiro, Cline, Zed, Continue, Claude Desktop, others | Tools on request | MCP server (new) | Official MCP Registry, Glama, Cursor MCP directory | You (npm + `mcp-publisher login`) |
| Skill directories (skills.sh, claudskills, agentskill.sh) | Guidance | Crawl `skills/` from GitHub | Automatic or one-line submission | Automatic / you |

\* Grok: only `PreToolUse` is documented as blocking, so the after-edit and end-of-turn checks may not feed back. Antigravity: blocking before a write and "keep going" at end of turn work; the after-edit check cannot feed back.

Not reachable: **ChatGPT web and claude.ai web chat cannot run a local MCP server** (remote HTTP only). A hosted server would need to read the user's files, which HatchLock deliberately never does.

## Work, in order

### P1. Portable core (all hosts)
1. **Spec-only skill frontmatter.** Keep `name`, `description`, `license`, `metadata`; fold `when_to_use` into `description`; move `argument-hint` into `metadata`; drop `effort`. Cost: Claude Code no longer shows the argument hint for `/hatchlock:doctor`.
2. **Self-contained doctor skill.** Move the script to `skills/doctor/scripts/doctor.sh`, called by relative path.
3. **Host-neutral scripts.** Accept `CLAUDE_PROJECT_DIR` / `GROK_WORKSPACE_ROOT` / cwd, `tool_input` / `toolInput`, and `CLAUDE_PLUGIN_ROOT` / `GROK_PLUGIN_ROOT`.
4. **CI:** validate every skill with `skills-ref validate`.
5. **Latest docs:** tight-diff tells the agent to look up current library docs (for example through a docs MCP such as Context7) before using an unfamiliar API; README explains how to add Context7. HatchLock does not bundle it (Context7 needs a per-user key and network access, which would break HatchLock's "nothing leaves your machine" promise).

### P2. Host adapters (tests use each host's documented payloads)
6. **Cursor:** `.cursor-plugin/plugin.json`, `rules/`, Cursor-format hooks file, adapter that maps Cursor's payload and answers `{"permission":"deny"}`.
7. **Antigravity:** `.antigravity-plugin/plugin.json`, root `hooks.json`, adapter for `toolCall{name,args}` (`write_to_file`, `replace_file_content`) answering `{"decision":"deny"}` / `{"decision":"continue"}`.
8. **Grok:** marketplace entry JSON ready to paste, pinned to the release commit.
9. **Copilot:** install test with the Copilot CLI if it runs here; otherwise documented as untested.

### P3. MCP server `hatchlock-mcp`
10. Node, MCP TypeScript SDK v2, stdio, no network. Read-only tools: `check_suppressions`, `verify_file`, `verify_project`, `doctor`, each wrapping the existing scripts.
11. `server.json` for the official registry (`io.github.tahmidbintaslim/hatchlock`), `glama.json`, README install snippets for Cursor, VS Code, Claude Desktop, Cline, Zed, Kiro.
12. Publishing needs **your npm account** (npm token) and **your GitHub login** for `mcp-publisher`.

### P4. Launch kit
13. `docs/LAUNCH.md`: one section per store with the exact steps, listing copy (within each store's limits), icon paths, and what is already prepared.

## Honest limits
- Grok, Antigravity, Copilot and Cursor hooks are built from their docs; none has been run live here.
- Some listings (Antigravity partner form, Cursor marketplace, Anthropic directory) are reviewed and may decline an individual developer's plugin.
- ChatGPT and claude.ai web get guidance only; no store gets blocking without a pre-write hook.
