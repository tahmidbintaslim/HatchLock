# Grok Build + Google (Antigravity) plugin distribution — notes (researched 2026-11-17)

Status legend: [V] verified in primary source (fetched), [U] unverified / inferred.

## A) xAI Grok Build

Primary sources (fetched):
- https://docs.x.ai/build/features/skills-plugins-marketplaces.md
- https://docs.x.ai/build/features/hooks.md
- https://docs.x.ai/build/settings/reference.md , https://docs.x.ai/build/cli/reference.md
- https://github.com/xai-org/plugin-marketplace (README.md, CONTRIBUTING.md, .github/PULL_REQUEST_TEMPLATE.md, scripts/plugin_catalog.py; HEAD commit 2026-11-16)
- Launch post: https://x.ai/news/grok-plugin-marketplace (marketplace launched ~2026-06-11, per secondary coverage)

### Plugin format [V]
- Plugin = dir with any of: skills/ (SKILL.md), commands/, agents/, hooks/hooks.json, .mcp.json, .lsp.json. Optional plugin.json manifest.
- Manifest lookup order (scripts/plugin_catalog.py): .grok-plugin/plugin.json, .cursor-plugin/plugin.json, .claude-plugin/plugin.json. CONTRIBUTING: ".claude-plugin/plugin.json is also accepted for Claude-ecosystem plugins".
- validate-catalog.py also accepts .claude-plugin/marketplace.json as a catalog path.
- Docs: "Grok is fully compatible with Claude Code with zero configuration needed. Grok automatically reads Claude Code marketplaces, plugins, skills, MCPs, agents, hooks, and instruction files".
- Plugin load paths: ./.grok/plugins/, ~/.grok/plugins/, ~/.grok/plugins/marketplaces/, [plugins] paths in ~/.grok/config.toml, --plugin-dir <PATH>.
- CLI: `grok plugin <list|install|uninstall|update|enable|disable|details|validate>`, `grok plugin marketplace <list|add|remove|update>`, `grok inspect --json`. TUI: /plugins, /hooks, /skills, /mcps, /marketplace.
- Compat toggles: [compat.claude] skills/rules/agents/mcps/hooks (default true); env GROK_CLAUDE_HOOKS_ENABLED etc.

### Skills [V]
- Dirs: ./.grok/skills/ (walked to repo root), ~/.grok/skills/, plugin skills/, ~/.agents/skills/, [skills] paths.
- Frontmatter: name, description, when-to-use, paths, allowed-tools (ignored for perms), argument-hint, user-invocable, disable-model-invocation, metadata. model/effort/license/compatibility accepted but not applied.

### Hooks — compatibility with HatchLock's Claude hooks
- [V] Events: SessionStart, SessionEnd, UserPromptSubmit, PreToolUse, PostToolUse, PostToolUseFailure, PermissionDenied, Stop, StopFailure, Notification, SubagentStart, SubagentStop, PreCompact, PostCompact. Same names as Claude Code.
- [V] Claude tool names (Bash, Read, Edit...) in matchers "are mapped to Grok's automatically".
- [V] Docs: "PreToolUse ... the only blocking event". Exit 0 allows, exit 2 denies, or stdout {"decision":"deny","reason":"..."}. Anything else fail-open. "For passive events, stdout is ignored".
  => HatchLock's PostToolUse exit-2 feedback and Stop exit-2 "keep going" are NOT documented to work in Grok. [U] whether Grok emulates Claude semantics for Claude-format plugins.
- [V] Stdin JSON documented with camelCase: hookEventName, sessionId, cwd, workspaceRoot, toolName, toolInput.
  [U] whether snake_case tool_input.file_path / .content / .new_string are also sent for Claude-format hooks. Scripts should read both: `.tool_input // .toolInput`.
  [U] whether NotebookEdit / Write map to a Grok tool name.
- [V] Env: GROK_HOOK_EVENT, GROK_HOOK_NAME, GROK_SESSION_ID, GROK_WORKSPACE_ROOT; plugin hooks also GROK_PLUGIN_ROOT, GROK_PLUGIN_DATA.
  [U] CLAUDE_PLUGIN_ROOT / ${CLAUDE_PLUGIN_ROOT} substitution in hooks.json commands: not in xAI docs (only a third-party README claims it works). CLAUDE_PROJECT_DIR: not documented. Fallback: `${CLAUDE_PLUGIN_ROOT:-$GROK_PLUGIN_ROOT}`, `${CLAUDE_PROJECT_DIR:-$GROK_WORKSPACE_ROOT}`.
- [U] userConfig / CLAUDE_PLUGIN_OPTION_*: not documented anywhere in Grok docs — assume unsupported; defaults must work without it.
- [V] LSP: .lsp.json is a recognized plugin component; LSP tool is off by default (GROK_LSP_TOOLS / [features] lsp_tools).
- [V] Hook timeout default 5 s (Claude: 60 s) — set "timeout" explicitly.
- [V] Project hooks need trust (/hooks-trust or --trust); `grok plugin install <name> --trust`.

### Official marketplace: github.com/xai-org/plugin-marketplace [V]
- Catalog: .grok-plugin/marketplace.json {name, description, owner{name}, plugins[]}. Generated .grok-plugin/plugin-index.json (never hand-edit).
- Entry fields: name (kebab, required), source (required), description (recommended), category, homepage, keywords, domains, version, author, tags.
- Remote source (recommended for third-party):
  {"source":"url","url":"https://github.com/<org>/<repo>.git","sha":"<40-char lowercase commit>"} — Grok re-verifies HEAD==sha after clone. Branches/tags/short SHAs rejected.
- Local source: {"type":"local","path":"./external_plugins/<name>"} — requires README.md + plugin manifest.
- Process: fork -> add ONE entry -> `git ls-remote <repo> HEAD` for sha -> `python3 scripts/generate-plugin-index.py` -> `python3 scripts/validate-catalog.py` + `generate-plugin-index.py --check` -> PR with template; CI + code-owner review.
- Listing rules: own/right to distribute; source from official org not personal account (personal-account branded plugin "will be questioned"); license stated; homepage + clear description; brand-scoped keywords/domains (generic terms like "database", "api", "cli", "deploy" pushed back — they drive the proactive plugin CTA); no duplicates; to update bump sha.
- Security rejects: curl|bash / download+exec / postinstall RCE; secret/env exfiltration, undisclosed telemetry; "lifecycle hooks that run shell on Bash/Write with no matcher"; obfuscated/minified-no-source; prompt injection in SKILL.md. Declare network endpoints + credentials in README.
- Catalog had 36 entries at HEAD (2026-11-16).
- HatchLock note: repo is under personal account tahmidbintaslim — fine since it's not someone else's brand, but expect ownership questions; hooks have matchers (Write|Edit|NotebookEdit) which satisfies the matcher rule; Stop hook has no matcher (Stop has no tool) — explain in PR.

## B) Google

### Gemini CLI status [V]
- https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/ (2026-05-19): on 2026-06-18 Gemini CLI + Gemini Code Assist IDE extensions stopped serving Google AI Pro/Ultra and free Code Assist for individuals. Code Assist Standard/Enterprise (and Code Assist for GitHub via Google Cloud) keep access. Extensions carry over "now as Antigravity plugins"; no 1:1 parity.
- geminicli.com banner (fetched 2026-11-17): "Unpaid tier and Google One users: Gemini CLI was replaced by Antigravity". Gallery geminicli.com/extensions still live; listing = add GitHub topic `gemini-cli-extension` (crawler, no submission). Legacy format: gemini-extension.json at repo root; hooks events BeforeTool/AfterTool/BeforeAgent/AfterAgent/SessionStart/... (enterprise-only audience now). Low priority target.
- Current target: Antigravity CLI (`agy`), plus Antigravity App + IDE (same plugin format).

### Antigravity plugin format [V] — https://antigravity.google/docs/build-plugins (fetch .md suffix for raw markdown)
- Manifest: <root>/plugin.json, or <root>/.antigravity-plugin/plugin.json (takes precedence; intended for multi-provider repos with .claude-plugin/). Schema https://antigravity.google/schemas/v1/plugin.json, additionalProperties:false.
  Fields: name (kebab, required), displayName, description, version, disabled, logo, suggestedPrompts (<=3), skills (extra dirs), author (string|{name,email,url}), homepage, repository, license, keywords, extensions (object).
  Marketplace-required: name, displayName, description, version, logo (bundled 1:1 >=128px), suggestedPrompts, author; plus README.md. displayName must not start with Antigravity/Gemini/Claude/Cursor.
- Components at <root>: skills/<name>/SKILL.md, mcp_config.json (NOT .mcp.json), hooks.json (NOT hooks/hooks.json), agents/<name>.md, rules/AGENTS.md or rules/<rule>.md, scripts/ (0755), assets/.
- Skills: name must equal dir name, 1–64 chars; description 1–1024; disable-model-invocation; license/compatibility. Workspace skills .agents/skills/; global ~/.gemini/skills/ or ~/.gemini/antigravity-cli/skills/.
- MCP: mcp_config.json {mcpServers:{...}}; remote key `serverUrl` (url also shown in plugin docs); `variables` per server prompt user for values (closest analogue to userConfig) -> plugin installs disabled until filled; ${PLUGIN_ROOT}, ${PLUGIN_DATA} expanded in MCP args/cwd/env; servers namespaced <plugin>_<server>.
- No LSP component documented [U: no .lsp.json equivalent found].
- Installed to ~/.gemini/config/plugins/<name> (read-only). Manual: .agents/plugins/ or ~/.gemini/config/plugins/.
- CLI: agy plugin validate [--strict|--json], install <name>[@antigravity-plugins-official] | <github url> | <path>, list --json, enable/disable/uninstall, `agy plugin import [gemini|claude]` (imports from ~/.gemini/extensions/ or ~/.claude/plugins/; per import output commands->skills, MCP -> mcp_config.json; hook conversion not shown [U]).
- validate warns (not errors) on .mcp.json, hooks/hooks.json, commands/, root AGENTS.md/GEMINI.md in multi-tool repos — so a single repo can ship both Claude and Antigravity layouts.

### Antigravity hooks [V] — https://antigravity.google/docs/hooks
- hooks.json = named groups: {"<group>": {"enabled":true, "PreToolUse":[{matcher, hooks:[{type:"command",command,timeout}]}], "Stop":[{type,command,timeout}]}}. Flat arrays for SessionStart/PreInvocation/PostInvocation/Stop.
- Events: SessionStart, PreToolUse, PostToolUse, PreInvocation, PostInvocation, Stop. (No UserPromptSubmit/SessionEnd names.)
- Plugin hook cwd = plugin root; use relative paths ./scripts/... NOT ${PLUGIN_ROOT}. Timeout default 30 s.
- Contract: exit 0 + JSON on stdout. ANY non-zero exit = logged error, ignored (fail-open). => exit-2 semantics DO NOT carry over; must rewrite to emit JSON.
- Stdin camelCase: common conversationId, workspacePaths[], transcriptPath, artifactDirectoryPath, modelName, lastUserInput. PreToolUse/PostToolUse: toolCall{name,args}, stepIdx; PostToolUse adds error.
- Tool names/args differ: write_to_file{TargetFile, CodeContent, Overwrite}, replace_file_content{TargetFile, TargetContent, ReplacementContent,...}, multi_replace_file_content{TargetFile, ReplacementChunks[]}, run_command{CommandLine,Cwd}. Matcher for HatchLock: "write_to_file|replace_file_content|multi_replace_file_content".
- PreToolUse output: {"decision":"allow|auto_approve|deny|ask|force_ask|deny_unless_prior_grant","reason","overwrite":{...},"permissionOverrides":[...]}.
- PostToolUse output: {} only — cannot feed errors back. Workaround [U]: PostInvocation/PreInvocation injectSteps {"systemMessage":...} or Stop continue.
- Stop output: {"decision":"continue","reason":"..."} keeps agent running (reason injected as system msg). Input has fullyIdle, terminationReason.
- PostInvocation can return terminationBehavior "force_continue" + injectSteps.
- No project-dir env var documented; use workspacePaths[0] from stdin [V absent env doc].

### Antigravity Marketplace listing [V]
- Official marketplace id: antigravity-plugins-official. Curated (Google + partners).
- Submission: pass `agy plugin validate`, complete plugin.json, README, logo -> "Antigravity Marketplace partner intake form" https://forms.gle/2EX5RFYPoJe1UgxR9. No topic-crawler/PR path documented [U whether individuals are accepted — "partner" wording suggests curated].
- Without listing, users can `agy plugin install https://github.com/tahmidbintaslim/HatchLock`.
