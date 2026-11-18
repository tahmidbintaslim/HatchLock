# HatchLock: distributing to other agents (as of 2026-11-17)

Key: [V] = read on the vendor's own docs page this session. [S] = secondary source or search snippet only, not verified. [?] = open question.

## Cross-cutting: Agent Plugins 1.0.0 (open standard, Aug 2026)
- Root `plugin.json` with `$schema: https://agent-plugins.org/schemas/1.0.0/plugin.schema.json`, `skills/<n>/SKILL.md`, root `mcp.json` (with an explicit `type` on each entry). The standard only covers **skills + MCP**. Hooks, rules and LSP are left to each client's own extensions. [S] https://agent-plugins.org , https://developers.googleblog.com/agent-plugins-package-your-skills-tools-and-more/
- Read by Copilot CLI, VS Code, Cursor, Kiro (powers) and Devin [V on each vendor page below]. It would carry HatchLock's skills, but **not its blocking hooks**.

## 1. GitHub Copilot (CLI + VS Code + cloud agent)
**Plugin layout** [V] https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference
- Manifest lookup order (legacy): `.plugin/plugin.json`, `plugin.json`, `.github/plugin/plugin.json`, **`.claude-plugin/plugin.json`**. An Agent Plugins 1.0 root `plugin.json` takes precedence over all of these.
- Legacy fields: `name` (kebab-case, ≤64 chars), description, version, author, homepage, repository, license, keywords, category, tags, plus the paths `agents`, `skills`, `commands`, `hooks`, `extensions`, `mcpServers`, `lspServers`.
- Components: `skills/*/SKILL.md`, `agents/*.agent.md`, `hooks.json` or `hooks/hooks.json`, `.mcp.json`, `lsp.json` / `.github/lsp.json` / `lspServers`. Agent Plugins 1.0 variant: `com.github.copilot/{hooks/hooks.json,lsp.json,agents,commands,rules}`.
- `CLAUDE_PLUGIN_ROOT` / `CLAUDE_PLUGIN_DATA` are accepted as aliases. Project discovery also reads `.claude/skills` and `.claude/agents`.
- Marketplace manifest lookup: `marketplace.json`, `.plugin/`, `.github/plugin/` (recommended), **`.claude-plugin/marketplace.json`**. Fields: `name`, `owner`, `plugins[{name, source, ...}]`. A source can be a path, or a GitHub/URL object with `ref` and a 40-char `sha`.
- Commands: `copilot plugin marketplace add owner/repo`, `copilot plugin install plugin@marketplace` (also `OWNER/REPO[:path]`, a git URL, or a local path).
- **Conclusion:** HatchLock's existing `.claude-plugin/` repo is very likely installable as-is in Copilot CLI. Not tested.

**Hooks** [V] https://docs.github.com/en/copilot/reference/hooks-configuration
- Events: sessionStart, sessionEnd, userPromptSubmitted, userPromptTransformed, preToolUse, postToolUse, postToolUseFailure, permissionRequest (CLI), notification (CLI), agentStop, subagentStart, subagentStop, preCompact, errorOccurred.
- File shape: `{"version":1,"hooks":{"preToolUse":[{"type":"command","bash":"...","powershell":"...","timeoutSec":30}]}}`. Sources: `.github/hooks/*.json`, `~/.copilot/hooks/`, a plugin's `hooks.json`, and also **`.claude/settings.json`**.
- camelCase payload: `toolName`, `toolArgs`. **PascalCase event names (`PreToolUse`) switch to the Claude/VS Code-compatible payload**: `tool_name`, `tool_input`, Claude matchers and Claude tool names (Write/Edit).
- **BLOCK: YES.** Exit 2 denies. Any other non-zero exit also denies (fail-closed). A timeout fails open. Or print `{"permissionDecision":"deny","permissionDecisionReason":"..."}` on stdout. `modifiedArgs` rewrites the arguments. The cloud agent only loads `.github/hooks/*.json` and only honours `bash`/`command`.
- [?] It is unverified whether a Claude-format plugin `hooks/hooks.json` (with Claude's nested `matcher` and `hooks` arrays) is parsed as-is. Test this with `copilot plugin install`.

**VS Code agent plugins** [V] https://code.visualstudio.com/docs/copilot/customization/agent-plugins , https://code.visualstudio.com/docs/copilot/customization/hooks
- Reads the "Copilot, Claude, and legacy OpenPlugin formats". Auto-discovers plugins installed by Copilot CLI under `~/.copilot/installed-plugins/`.
- Marketplaces are added with the `chat.plugins.marketplaces` setting (experimental). Install via Agent Customizations → Browse, or the `vscode://chat-plugin/install` deep link.
- Agent hooks are in **Preview**. Events: sessionStart, userPromptSubmitted, preToolUse, postToolUse, preCompact, subagentStart/Stop, agentStop, sessionEnd. To deny, return `permissionDecision:"deny"`. Also reads `.claude/settings.json`.

**Getting listed** [V] https://github.com/github/awesome-copilot/blob/main/CONTRIBUTING.md
- `awesome-copilot` is the built-in, non-removable default marketplace. For a plugin hosted elsewhere, use the **external plugin issue form**: owner/repo, path, release tag, 40-char SHA, license and so on. Do not open a PR that edits `plugins/external.json`.
- The intake runs quality gates (manifest checks, `vally lint`, a Copilot CLI install smoke test). A maintainer then comments `/approve`, a bot opens a PR to `main`, and the plugin is re-reviewed about every 6 months. Plugins with hooks or scripts are rated `merge-risk:high`, which needs more approvals.
- `github/copilot-plugins` is no longer a default marketplace.

## 2. Cursor
**Plugin layout** [V] https://cursor.com/docs/reference/plugins
- `.cursor-plugin/plugin.json`. Only `name` is required (kebab-case). Optional: description, version, author, homepage, repository, license, keywords, `logo`, `rules`, `agents`, `skills`, `commands`, `hooks`, `mcpServers`, `variables` (a JSON Schema for secrets).
- Default folders: `skills/*/SKILL.md`, `rules/*.mdc` (frontmatter `description`, `alwaysApply`, `globs`), `agents/`, `commands/`, `hooks/hooks.json`, root `mcp.json`.
- Multi-plugin repos also need `.cursor-plugin/marketplace.json` (`name`, `owner`, `plugins`; ≤10 MB).
- Agent Plugins 1.0 (root `plugin.json`) is also accepted, but only for skills + MCP. `${CLAUDE_PLUGIN_ROOT}` expands in MCP config.
- [?] Does Cursor read `.claude-plugin/plugin.json` directly? The docs do not say. The setting "Include Third-Party Plugins, Skills, and Other Configs" (Settings → Agents → Third-Party Imports, on by default) suggests it may, but plugin import is undocumented. **Plan to ship `.cursor-plugin/plugin.json` alongside `.claude-plugin/`.**

**Hooks** [V] https://cursor.com/docs/agent/hooks , https://cursor.com/docs/reference/third-party-hooks
- Events: sessionStart, sessionEnd, preToolUse, postToolUse, postToolUseFailure, subagentStart/Stop, beforeShellExecution, afterShellExecution, beforeMCPExecution, afterMCPExecution, beforeReadFile, **afterFileEdit**, beforeSubmitPrompt, preCompact, stop, afterAgentResponse, afterAgentThought, plus the Tab hooks and workspaceOpen.
- Format: `{"version":1,"hooks":{"preToolUse":[{"command":"...","matcher":"Write"}]}}`. Sources: `.cursor/hooks.json`, `~/.cursor/hooks.json`, enterprise MDM, the team dashboard, and plugins (command hooks only).
- **BLOCK: YES, via `preToolUse` with matcher `Write`.** There is no beforeFileEdit event. Exit 2, or return `{"permission":"deny","user_message":"..","agent_message":".."}`. Payload: `tool_name`, `tool_input`, `tool_use_id`, `cwd`. The exact shape of `tool_input` for Write is undocumented, so test it. `afterFileEdit` (`file_path`, `edits[{old_string,new_string}]`) cannot block, but it suits HatchLock's PostToolUse compiler check.
- Claude Code hooks are loaded from `.claude/settings{,.local}.json` and `~/.claude/settings.json`. Mapping: PreToolUse→preToolUse, PostToolUse→postToolUse, Stop→stop, and so on. **Claude `Edit` and `Write` both map to Cursor `Write`.** Not supported: Notification, PermissionRequest, the Glob tool, and team distribution.
- Forum reports [S]: `.claude` hooks sometimes did not load, and on Windows they ran in the wrong shell and blocked every call.

**Rules:** HatchLock already ships `.cursor/rules/hatchlock-tight-diff.mdc`. Inside a plugin, put it in `rules/`.

**Marketplace** [V] https://cursor.com/docs/reference/plugins , https://cursor.com/blog/marketplace
- Submit a **public** Git repo at https://cursor.com/marketplace/publish. The Cursor team **reviews it manually**. It must be open source, and every update is reviewed again.
- Checklist: valid manifest; unique kebab-case name; clear description; valid frontmatter; a README covering usage and config; every `${VAR}` declared; only relative paths, with no `..`.
- Teams can import a private team marketplace (Dashboard → Settings → Plugins) [S].
- The community directory cursor.directory is self-serve: paste a repo URL [S].

## 3. Windsurf → now Devin (desktop/Cascade + Devin CLI)
[V] https://docs.devin.ai/desktop/cascade/hooks , https://docs.devin.ai/cli/extensibility/hooks/overview.md , https://docs.devin.ai/cli/extensibility/plugins/overview.md
- docs.windsurf.com now redirects to docs.devin.ai. Plugins look for `.devin-plugin/plugin.json`, then **`.claude-plugin/plugin.json`**, then a root `plugin.json`. `.mcp.json` and `${CLAUDE_PLUGIN_ROOT}` are honoured. Install with `devin plugins install owner/repo[#subdir]`.
- No public marketplace is documented. Org admins can mark plugins as required or offered.
- Hooks: PreToolUse, PostToolUse, PermissionRequest, UserPromptSubmit, Stop, PostCompaction, SessionStart, SessionEnd. Config: `.devin/hooks.v1.json`, and **`.claude/settings.json` (read by default)**.
- **BLOCK: YES.** Exit 2, or `{"decision":"block","reason":..}`. The write tool's name is not given on the page [?].
- The old Windsurf `pre_write_code` hooks format is not on the current docs [?].

## 4. Cline
[V] https://docs.cline.bot/sdk/plugins.md , https://docs.cline.bot/customization/plugins.md ; [S] https://cline.bot/blog/cline-v3-36-hooks
- SDK/CLI plugins: a `package.json` `cline.plugins` field pointing at TS/JS that exports an AgentPlugin. Distributed via npm, git or a URL. **No marketplace.** Not available in the VS Code or JetBrains extensions.
- SDK `beforeTool` returns `{skip:true, reason}` to block. Hooks have a 3 s timeout and fail open by default.
- Extension file hooks [S]: `.clinerules/hooks/PreToolUse` (executable, no extension) prints `{"cancel":true,"errorMessage":..,"contextModification":..}`. Originally macOS/Linux only.
- Skills: docs.cline.bot/customization/skills.md (not read). The MCP Marketplace is MCP servers only.
- Does not read Claude plugins (nothing in the docs).

## 5. Kiro
[V] https://kiro.dev/docs/hooks/ , /hooks/types/ , /hooks/actions/ , /powers/
- Hooks live in `.kiro/hooks/*.json`: `{version:"v1", hooks:[{name, trigger:"PreToolUse", matcher, action:{type:"command"|"agent"}}]}`.
- **BLOCK: YES.** A PreToolUse command that exits non-zero blocks the tool, and its stderr goes to the agent.
- Powers = Agent Plugins format (`plugin.json` + `skills/` + `mcp.json`). The legacy format is POWER.md. Install with one click from kiro.dev/powers or from GitHub. The submission process is not documented [?]. Hooks cannot be packaged in a power.

## 6. OpenCode
[V] https://opencode.ai/docs/plugins/ , https://opencode.ai/docs/build/plugins/server/
- TS plugin (`@opencode/plugin`, `Plugin.define`). Lives in `.opencode/plugins/`, or as an npm/git package listed in `opencode.json` `plugins`. Install with `opencode plugin add`.
- Hook: `ctx.tool.hook("execute.before", ev => ...)` with `ev.tool` and `ev.input`. It can **replace** the input. Whether throwing blocks the call is **not documented** [?]. Older v1 used `tool.execute.before` with a throw [S].
- No official registry is documented.

## 7. Amp
[V] https://ampcode.com/manual/plugin-api
- Bun TS plugins in `.amp/plugins/` or `~/.config/amp/plugins/`. Experimental, CLI only, needs `PLUGINS=all` [S].
- `amp.on('tool.call', ...)` returns `{action:'reject-and-continue', message}` to **BLOCK**, or `{action:'allow'}`.
- Skills use SKILL.md. No plugin registry.

## 8. Continue
[S] PR #11029 (merged 2026-03-04) added Claude Code-compatible CLI hooks. They are read from `.continue/settings.json` **and `.claude/`**, and exit 2 blocks. The docs PR #11353 had not merged as of the search, so this is unverified.
- Packaging: config.yaml "blocks" and rules on the Continue Hub (hub.continue.dev). https://docs.continue.dev/hub/blocks/intro

## 9. Zed
[V] https://zed.dev/docs/ai/tool-permissions
- **No hooks.** Tool permissions use regex on `edit_file` input (the **path** only), so an edit cannot be blocked based on its content.
- Has skills, instructions, MCP and ACP external agents. Claude Code runs via ACP, so HatchLock's own hooks would still fire inside the Claude Code agent [inferred].
- Extensions are published by PR to zed-industries/extensions [known, not re-checked].

## 10. JetBrains Junie
[V] https://junie.jetbrains.com/docs/junie-cli-extensions.html , https://junie.jetbrains.com/docs/junie-cli-hooks.html
- **Reads Claude marketplaces directly**: `/extensions marketplace add <git|path|URL>` accepts `.claude-plugin/marketplace.json`. Extension hooks use `hooks/hooks.json` with `${CLAUDE_PLUGIN_ROOT}`. A built-in JetBrains marketplace also exists.
- Hooks: SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop, StopFailure, PermissionRequest, SessionEnd.
- **BLOCK: YES.** Exit 2, or `{"decision":"block"|"deny","reason"}`. Other non-zero exits fail open unless `blockOnError:true`. Project `.junie/config.json` hooks are ignored by default.
- Hooks fire in the CLI and ACP. IDE plugin support is not stated [?].
- Skills: `.junie/skills/`. It offers to import from `.claude/skills/`.
- The JetBrains AI Assistant itself: no hooks found [?].
