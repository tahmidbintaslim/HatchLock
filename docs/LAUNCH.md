# HatchLock launch kit

Everything needed to list HatchLock in each store. Each section says what is already prepared, what you do, and what to paste.

Before any submission, cut a release so every store points at the same commit:

```bash
git checkout main && git pull
```

```bash
./tests/test-suite.sh && claude plugin validate . --strict --profile directory
```

```bash
git tag v1.2.0 && git push origin v1.2.0
```

```bash
git rev-parse v1.2.0
```

Keep that 40-character commit SHA; Grok and Copilot listings need it.

## Shared listing copy

- **Name:** HatchLock
- **Short (≤30 chars):** Type-safety guardrails
- **One line (≤100 chars):** Stops AI code from hiding type errors: blocks @ts-ignore and as any, then runs your compilers.
- **Description:** When an AI coding assistant hits a type error, the quick way out is to tell the type checker to look away with `@ts-ignore`, `as any` or `# type: ignore`. HatchLock blocks those shortcuts before they are written, checks each edit with the compilers you already have, and gives the agent skills for small, clean changes. It runs on your machine and sends nothing anywhere. Free and open source (MIT).
- **Example prompts:**
  1. Fix the type errors in src/billing.ts without using any or @ts-ignore.
  2. Optimize the /orders endpoint, it runs one query per line item.
  3. Clean up lib/report_builder.py without changing its behaviour.
- **Icon / logo:** `assets/icon.png`, `assets/logo.png`, `.claude-plugin/icon.png` (1024 px PNG), `assets/icon.svg`
- **Website:** https://tahmidbintaslim.github.io/HatchLock/
- **Support:** https://github.com/tahmidbintaslim/HatchLock/issues
- **Privacy:** https://github.com/tahmidbintaslim/HatchLock/blob/main/PRIVACY.md
- **Category:** Developer Tools

## What each host gets

| Host | Blocks before write | After-edit check | End-of-turn check | Skills |
|---|---|---|---|---|
| Claude Code | Yes | Yes | Yes | Yes |
| GitHub Copilot CLI / VS Code | Yes* | Yes* | Yes* | Yes (verified) |
| Cursor | Yes* | No | No | Yes |
| Grok Build | Yes* | Not documented | Not documented | Yes |
| Devin (Windsurf), JetBrains Junie | Yes* | Yes* | Yes* | Yes |
| Google Antigravity | Yes* | No | Yes* | Yes |
| ChatGPT / Codex, claude.ai uploads | No | No | No | Yes |
| Any MCP client (`hatchlock-mcp`) | Agent must call it | Agent must call it | Agent must call it | Yes (as resources) |

\* Built to the host's documented hook contract; not yet run in a live session of that host.

---

## 1. Anthropic: Claude Code plugin directory

- **Ready:** plugin, icon, README, PRIVACY.md, `claude plugin validate --strict --profile directory` passes.
- **You:** sign in at https://claude.ai/directory/manage (paid plan) → **Plugin bundle** → connect the GitHub repo → Validate → Submit.
- Expect a human review because the hooks run shell scripts.
- The directory keeps the **first** icon you submit.

## 2. OpenAI: ChatGPT / Codex plugin directory (skills only)

- **Ready:** `.codex-plugin/plugin.json`, PRIVACY.md, spec-valid skills, build script.
- **You:**
  1. Verify your developer identity in your platform.openai.com organization settings.
  2. Run `./scripts/build-openai-zip.sh`.
  3. At https://platform.openai.com/plugins choose **Create plugin** → **Skills only** and upload `dist/hatchlock-openai.zip`.

## 3. GitHub Copilot: `awesome-copilot` marketplace

- **Verified:** Copilot CLI 1.0.112 installs this repo as a plugin and as a marketplace (`copilot plugin marketplace add tahmidbintaslim/HatchLock`).
- **You:** open the "external plugin" issue form at https://github.com/github/awesome-copilot/issues/new/choose with:
  - repository `tahmidbintaslim/HatchLock`
  - release tag `v1.2.0`
  - the commit SHA
- Plugins with hooks need extra maintainer approvals and are re-reviewed about every 6 months.
- Users can install today: `copilot plugin marketplace add tahmidbintaslim/HatchLock`, then `copilot plugin install hatchlock@hatchlock-marketplace`.

## 4. Cursor Marketplace

- **Ready:** `.cursor-plugin/plugin.json`, `hooks/cursor-hooks.json` (blocks `Write`), rules in `.cursor/rules/`.
- **You:** submit at https://cursor.com/marketplace/publish (public open-source repo; every update is reviewed by hand).
- For a Cursor user who wants the checks today, add `hatchlock-mcp` (section 8) to `.cursor/mcp.json`.

## 5. xAI: Grok Build plugin marketplace

- **Ready:** `.grok-plugin/plugin.json`. Hooks accept Grok's camelCase payload and `GROK_*` variables. Hooks have explicit timeouts (Grok's default is 5 s).
- **You:**
  1. Fork https://github.com/xai-org/plugin-marketplace.
  2. Add this entry to `.grok-plugin/marketplace.json`, replacing `<SHA>` with the release commit:

     ```json
     {
       "name": "hatchlock",
       "description": "Blocks type-checker escape hatches (@ts-ignore, as any, # type: ignore) before they are written and checks edits with your own compilers.",
       "category": "development",
       "source": { "source": "url", "url": "https://github.com/tahmidbintaslim/HatchLock.git", "sha": "<SHA>" },
       "homepage": "https://tahmidbintaslim.github.io/HatchLock/",
       "keywords": ["hatchlock"],
       "author": { "name": "Tahmid Bin Taslim Rafi" }
     }
     ```

  3. Run `python3 scripts/generate-plugin-index.py && python3 scripts/validate-catalog.py && python3 scripts/generate-plugin-index.py --check`.
  4. Open the PR.
- In the PR, explain that the Stop hook has no matcher because Stop has no tool, and that every hook only runs local compilers.

## 6. Google Antigravity

- **Ready:** `./scripts/build-antigravity.sh` builds `dist/antigravity/hatchlock` with a root `plugin.json`, a root `hooks.json`, and an adapter that returns Antigravity's JSON decisions.
- **You:**
  1. Check the package with `agy plugin validate dist/antigravity/hatchlock --strict`.
  2. Submit through the partner intake form: https://forms.gle/2EX5RFYPoJe1UgxR9 (curated; individuals may not be accepted).
- Users can install the built folder with `agy plugin install <path>`.
- Gemini CLI no longer serves individual users (June 2026), so it is not targeted.

## 7. Devin (Windsurf) and JetBrains Junie

- No submission needed: both read `.claude-plugin/` directly.
  - Devin: `devin plugins install tahmidbintaslim/HatchLock`
  - Junie: `/extensions marketplace add https://github.com/tahmidbintaslim/HatchLock`

## 8. MCP server: `hatchlock-mcp`

- **Ready:** `mcp/` (tests pass with the official MCP client), `mcp/server.json`, `glama.json`.
- **You:**
  1. Publish to npm (needs your npm account):

     ```bash
     cd mcp && npm publish --access public
     ```

  2. Publish to the official MCP Registry (signs in with your GitHub account):

     ```bash
     brew install mcp-publisher
     ```

     ```bash
     cd mcp && mcp-publisher login github && mcp-publisher publish
     ```

  3. **Glama:** `glama.json` claims the listing; add the repo at https://glama.ai/mcp/servers.
  4. **PulseMCP:** submissions are paused; it imports from the official registry.
- The server doesn't run in ChatGPT web or claude.ai web chat, which only accept remote servers.

## 9. Skill directories

- **skills.sh:** no submission; it ranks by installs from `npx skills add tahmidbintaslim/HatchLock`.
- **claudskills.com:** crawls GitHub daily, or submit the repo link.
- **agentskill.sh:** submit the repo URL.

## 10. awesome-claude-code

- Once the repo is 14 days old or has 100 stars, submit through the issue form at https://github.com/hesreallyhim/awesome-claude-code with a one-line, non-promotional description.

## After launch

- Bump the version in `.claude-plugin/plugin.json`, `.grok-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `.codex-plugin/plugin.json`, `mcp/package.json`, `mcp/server.json` and the `hatchlock-mcp@x.y.z` pins in `mcp/README.md`. The test suite fails if any of these drift.
- For Grok and Copilot, submit the new commit SHA.
