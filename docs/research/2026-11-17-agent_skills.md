# Agent Skills (SKILL.md) portability — research notes (2026-11-17)

Legend: [P] = primary source read directly; [S] = secondary / third-party; [U] = unverified.

## 1. The spec (agentskills.io)

Source [P]: https://agentskills.io/specification ; repo https://github.com/agentskills/agentskills

Frontmatter (YAML between `---`), exactly six fields:

| Field | Req | Constraint |
|---|---|---|
| `name` | yes | 1-64 chars, `a-z0-9-`, no leading/trailing hyphen, no `--`, **must equal parent dir name** |
| `description` | yes | 1-1024 chars, non-empty; say what + when |
| `license` | no | short name or bundled file ref |
| `compatibility` | no | 1-500 chars; env requirements |
| `metadata` | no | map **string -> string**; "Clients can use this to store additional properties not defined by the spec"; use reasonably unique keys |
| `allowed-tools` | no | space-separated string; experimental |

- Unknown top-level keys: spec text is silent, but the reference validator **rejects** them.
  `skills-ref/src/skills_ref/validator.py` has `ALLOWED_FIELDS` and errors
  "Unexpected fields in frontmatter: ... Only [...] are allowed." [P]
- Client guidance is lenient: warn-and-load on name mismatch / >64 chars; skip only on missing description or unparseable YAML. Recommends quoting values containing `:`. [P] https://agentskills.io/client-implementation/adding-skills-support
- Dirs: `scripts/`, `references/`, `assets/` (recommendations, any files allowed). Reference files by path **relative to skill root**, one level deep. Body < 500 lines / <5k tokens recommended.
- **No variable substitution** in the spec. No `$ARGUMENTS`, no plugin-root var. Clients resolve relative paths against the skill dir (catalog passes `location`).
- Discovery convention (not mandated by spec): `<project>/.agents/skills/` and `~/.agents/skills/` for cross-client sharing; some clients also scan `.claude/skills/`. Project overrides user on name collision.
- `disable-model-invocation` is mentioned in the client guide as an example opt-out flag but is NOT a spec field.
- Validator: `skills-ref validate ./my-skill` (also `read-properties`, `to-prompt`). PyPI `skills-ref` 0.1.1, Alpha; README: "intended for demonstration purposes only". Install from repo (`pip install -e .` / `uv sync` in `skills-ref/`) or `pip install skills-ref`. [P]

## 2. Tool support (where skills are read from)

Official client showcase lists 46 clients (source data: https://github.com/agentskills/agentskills/blob/main/docs/snippets/clients.jsx [P]), incl. Claude Code, Claude, ChatGPT & Codex, GitHub Copilot, VS Code, Cursor, Gemini CLI, OpenCode, Amp, Goose, Kiro, Junie, Roo Code, Factory, OpenHands, Letta, TRAE, Mistral Vibe, Tabnine, Snowflake Cortex, Databricks, Spring AI, OpenClaw, Hermes. **Not in showcase:** Windsurf/Devin, Cline, Antigravity, Grok Build (but each has own skills docs — see below).

| Tool | Paths read | Notes on fields |
|---|---|---|
| Claude Code [P] https://code.claude.com/docs/en/skills | `~/.claude/skills`, `.claude/skills`, nested `.claude/skills`, `--add-dir`, `<plugin>/skills/`, managed dir, claude.ai account skills. **No `.agents/skills`** in docs read. | Superset: when_to_use, argument-hint, arguments, disable-model-invocation, user-invocable, allowed-tools, disallowed-tools, model, effort, context, agent, background, hooks, paths, shell + spec fields. "Claude Code ignores a field it doesn't recognize without reporting an error." Substitutions: `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`, `$name`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PROJECT_DIR}`, `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}`, `${CLAUDE_PLUGIN_ROOT}`/`${CLAUDE_PLUGIN_DATA}` (plugin only). |
| claude.ai upload / Skills API (`/v1/skills`) / `package_skill.py` [P] same page + https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview | zip upload (claude.ai settings) or API; surfaces don't sync | **Only** name, description, license, compatibility, metadata, allowed-tools. Extra key = **hard error**: `Unexpected key(s) in SKILL.md frontmatter: argument-hint. Allowed properties are: ...`. name: no XML, no reserved words `anthropic`/`claude`. API: no network, no runtime pkg install. claude.ai: network per admin setting. |
| OpenAI Codex / ChatGPT [P] https://learn.chatgpt.com/docs/build-skills (was developers.openai.com/codex/skills) | `.agents/skills` from CWD up to repo root, `~/.agents/skills`, `/etc/codex/skills`, bundled | name+description required. Optional sidecar `agents/openai.yaml` (interface display_name/icon/brand_color/default_prompt; `policy.allow_implicit_invocation`; `dependencies.tools` e.g. MCP). Invoke `$skill` / `/skills` (CLI), `@` (ChatGPT). ChatGPT desktop gets standalone skills; web/mobile via plugins. No arg substitution documented. Unknown-key handling not documented [U]. |
| GitHub Copilot [P] https://docs.github.com/en/copilot/concepts/agents/about-agent-skills | project `.github/skills`, `.claude/skills`, `.agents/skills`; personal `~/.copilot/skills`, `~/.agents/skills` | "Supported locations depend on the surface." |
| VS Code [P] https://code.visualstudio.com/docs/copilot/customization/agent-skills | `.github/skills`, `.claude/skills`, `.agents/skills`, `~/.copilot/skills`, `~/.claude/skills`, `~/.agents/skills` | Supports `argument-hint`, `user-invocable`, `disable-model-invocation`, `context: fork` (exp.). name must match dir, ≤64; description ≤1024. No substitution syntax. |
| Cursor [P] https://cursor.com/docs/context/skills | `.agents/skills`, `.cursor/skills` (+ `~/`), compat `.claude/skills`, `.codex/skills` (+ `~/`), recursive | name must match folder; `paths`, `disable-model-invocation`, `icon`, `color`, `metadata`. |
| Gemini CLI [P] https://geminicli.com/docs/cli/skills/ | `.gemini/skills` or `.agents/skills` alias (+ `~/`); `.agents` wins within tier | fields not documented on that page |
| Google Antigravity [P] https://antigravity.google/docs/skills | workspace `.agents/skills` (legacy `.agent/skills` still supported, per search snippet); global `~/.gemini/config/skills/` (+ CLI `~/.gemini/skills/`, legacy `~/.gemini/antigravity/skills/`) | name optional (defaults to folder), description required |
| Windsurf / Devin Desktop [P] https://docs.devin.ai/desktop/cascade/skills (docs.windsurf.com redirects here) | `.devin/skills`, `.agents/skills`, legacy `.windsurf/skills`; global `~/.config/devin/skills`, `~/.agents/skills` (Vercel table still says `~/.codeium/windsurf/skills`) | name, description |
| Cline [P] https://docs.cline.bot/customization/skills | `.cline/skills`, `.clinerules/skills`, `.claude/skills`; `~/.cline/skills`. `.agents/skills` not listed (Vercel CLI table says Cline uses `.agents/skills` [S]) | name must match dir; description ≤1024; global beats project on collision |
| OpenCode [P] https://opencode.ai/docs/skills/ | `.opencode/skills`, `.claude/skills`, `.agents/skills` (ancestor walk) + `~/.config/opencode/skills`, `~/.claude/skills`, `~/.agents/skills` | path = ID, name is label; honors `disable-model-invocation`, `metadata.opencode/autoinvoke`; doesn't enforce name rules |
| Amp [P] https://ampcode.com/docs/customize/skills | `~/.config/agents/skills`, `~/.agents/skills`, `~/.config/amp/skills`, `.agents/skills`, `.claude/skills`, `~/.claude/skills`, `~/.claude/plugins/cache/` | name, description, `mcpServers`; `${AMP_SKILL_DIR}` only in mcp config |
| Kiro [P] https://kiro.dev/docs/skills/ | `.kiro/skills`, `~/.kiro/skills`; custom agents need `skill://` resources | lists exactly the spec fields (name, description, license, compatibility, metadata); invalid frontmatter -> not found |
| Goose [S] | `.goose/skills`, `~/.config/goose/skills` (Vercel table); in showcase. Docs URL in showcase 404'd for me [U] | |
| Grok Build (xAI) [S] | Vercel CLI table: `.grok/skills`, `~/.grok/skills`. Hermes skill claims Grok auto-reads `.claude/` incl. skills. **No official xAI doc found [U]** | |

Cross-tool feature matrix (Vercel CLI docs [S] https://github.com/vercel-labs/skills/blob/main/docs/agents.md): `allowed-tools` widely honored (not Kiro, Zencoder); `context: fork` Claude Code only; hooks Claude Code/Cline/Kiro.

Takeaway: `.agents/skills/` is read by Codex, Copilot, VS Code, Cursor, Gemini CLI, Antigravity, Devin/Windsurf, OpenCode, Amp. `.claude/skills/` is additionally read by Copilot, VS Code, Cursor, Cline, OpenCode, Amp. `$ARGUMENTS` / `${CLAUDE_PLUGIN_ROOT}` are substituted ONLY by Claude Code.

## 3. Directories / registries

| Registry | How listing works | Requirements |
|---|---|---|
| skills.sh (Vercel) [P] https://skills.sh/docs ; CLI https://github.com/vercel-labs/skills | Leaderboard ranked by anonymous install telemetry from `npx skills add <owner/repo>`; no submit form documented. So "publishing" = public GitHub repo + people running `npx skills add tahmidbintaslim/HatchLock`. Routine security audits. | CLI discovers `SKILL.md` at root, `skills/` (≤3 levels), `.agents/skills/`, `.claude/skills/`, ~50 agent dirs, **and skills declared in `.claude-plugin/plugin.json` / `marketplace.json`**; custom paths via `skills.sh.json` `{"paths": [...]}`. Requires name + description; `metadata.internal: true` hides. CLI installs into `.agents/skills/<name>` (+ per-agent dirs), `skills-lock.json`. HatchLock's `skills/<name>/SKILL.md` layout is already discovered. |
| claudskills.com [P] https://claudskills.com/ | Crawls GitHub, Discord, web every 24h; or submit a public repo link | public repo, valid SKILL.md; site says frontmatter with name, description, allowed-tools; argument-hint "recommended" (site-specific curation, not spec) |
| agentskill.sh [P] https://agentskill.sh/submit | Submit GitHub repo or direct SKILL.md URL ("Analyze & Import"); repo scanned for all SKILL.md, rechecked every 24h, optional push webhook; optional GitHub connect for ownership/analytics | none formal stated |
| SkillsMP (skillsmp.com) [U] | Site 403'd to fetcher; appears to auto-index GitHub repos with creator pages showing stars. Submission/threshold not verified. | ? |
| Tessl registry [S] https://tessl.io/registry , https://docs.tessl.io/use/tile-to-plugin-migration | Packages ("tiles", now also plugins) with `tile.json`; publish via Tessl CLI (`tessl tile publish`; older `tessl skill publish`) + GitHub Action; version bump to republish. Also auto-mirrors GitHub skills (e.g. tessl.io/registry/skills/github/<owner>/<repo>/...) with review scores. Exact CLI unverified [U]. | Tessl account/workspace, tile.json |
| Smithery skills [S] https://smithery.ai/skills | Listings exist (incl. imported GitHub skills, "Install via Skills CLI"); no official skill-publish doc found [U] | ? |
| Anthropic | No public third-party skills marketplace; distribution via Claude Code plugin marketplaces; claude.ai/API are per-user/workspace uploads. anthropics/skills repo is Anthropic's own. | |

## 4. Recommendation for HatchLock

Problem: current frontmatter has `when_to_use`, `argument-hint`, `effort` at top level.
- Claude Code: fine. Most local agents: ignored (lenient). **claude.ai upload / Skills API / `skills-ref validate`: hard error.**

Portable frontmatter (passes skills-ref and claude.ai upload, still works in Claude Code):

```yaml
---
name: tight-diff            # == folder name, a-z0-9-, no "claude"/"anthropic"
description: >-             # <=1024 chars; fold old when_to_use text in here (it is the only trigger signal elsewhere)
  Produce the smallest correct diff for a change. Use when the user asks for a
  minimal patch, a focused fix, or to shrink an existing diff.
license: MIT
compatibility: Works in any Agent Skills client; doctor needs bash.   # optional, <=500
metadata:                   # string -> string only; quote everything
  author: tahmidbintaslim
  version: "1.0.0"
  argument-hint: "[file or change description]"   # informational only outside Claude Code
---
```

Trade-off: Claude Code reads `argument-hint`/`effort`/`when_to_use` only at top level; under `metadata` they become inert. Options:
1. Accept loss (argument-hint is cosmetic; `effort` minor; `when_to_use` folded into description). Simplest, one source of truth. **Recommended.**
2. Keep Claude-only keys in the plugin copy and generate a stripped copy (sed/yq) for claude.ai zips / `.agents/skills` export. Two artifacts, more CI.

Body portability:
- `$ARGUMENTS`: only Claude Code substitutes. Write the body so it still reads if left literal, e.g. "Target: $ARGUMENTS (if empty or unexpanded, use the user's latest request)."
- `${CLAUDE_PLUGIN_ROOT}`: Claude Code plugin only. Move doctor's bash script into `skills/doctor/scripts/doctor.sh` and reference it as `scripts/doctor.sh` relative to the skill dir (spec convention; every client resolves relative to SKILL.md). `${CLAUDE_SKILL_DIR}` also Claude-Code-only. Note doctor won't run on Claude API (no network/packages) and depends on bash.
- Keep body < 500 lines; quote any description containing `: `.

Validation CI: `pip install skills-ref && for d in skills/*/; do skills-ref validate "$d"; done` (alpha/demo-grade, but it enforces the exact allowed-key set and name rules — same set claude.ai enforces).

Distribution: keep `skills/<name>/SKILL.md` (Vercel CLI finds it, and also via `.claude-plugin/plugin.json`). Tell users: `npx skills add tahmidbintaslim/HatchLock` (installs to `.agents/skills` + chosen agents). Submit repo to claudskills.com and agentskill.sh; skills.sh lists by install telemetry.
