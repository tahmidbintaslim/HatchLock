# hatchlock-mcp

HatchLock's type-safety checks as a local [MCP](https://modelcontextprotocol.io) server. Use it in any editor or agent that supports MCP (Cursor, VS Code, Claude Desktop, Cline, Zed, Kiro, Windsurf/Devin, JetBrains and others) to stop AI-written code from hiding type errors.

It runs on your machine with the compilers you already have. **No network calls, no account, nothing is sent anywhere.**

## Tools

| Tool | When the agent should call it | What it does |
| :--- | :--- | :--- |
| `check_suppressions` | Before writing or editing a file | Reports new `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `as any`, `: any`, `# type: ignore`, `# pyright: ignore`, `@phpstan-ignore`, `#[allow(dead_code)]`, `//nolint` |
| `verify_file` | After editing a file | Fast check of that file with local tools (pyright, shellcheck, gofmt, `php -l`, ...) |
| `verify_project` | Before saying the task is done | Project compilers (`tsc`, `cargo check`, `go vet`, ...) for languages with uncommitted changes |
| `doctor` | Any time | Which compilers and language servers are available |

All tools are read-only. The server also serves HatchLock's skills (`tight-diff`, `optimize`, `architect`, `clean`, `doctor`) as `skill://` resources.

An MCP server can't force the agent to call it. For blocking that the agent can't skip, use the HatchLock plugin in Claude Code, GitHub Copilot, Cursor, Grok Build or Google Antigravity.

## Install

Requires Node.js 20+, `bash` and `jq`.

**Cursor** (`.cursor/mcp.json`), **Claude Desktop** (`claude_desktop_config.json`), **Cline**, **Windsurf**:

```json
{
  "mcpServers": {
    "hatchlock": { "command": "npx", "args": ["-y", "hatchlock-mcp@1.3.0"] }
  }
}
```

**VS Code** (`.vscode/mcp.json`):

```json
{
  "servers": {
    "hatchlock": { "type": "stdio", "command": "npx", "args": ["-y", "hatchlock-mcp@1.3.0"] }
  }
}
```

**Zed** (`settings.json`):

```json
{
  "context_servers": {
    "hatchlock": { "command": "npx", "args": ["-y", "hatchlock-mcp@1.3.0"] }
  }
}
```

Tip: add a line to your agent rules such as "Before writing code, call `check_suppressions`; before finishing, call `verify_project`."

## Up-to-date docs

HatchLock checks types; it doesn't fetch documentation. To have the agent read current library docs for each language, also add a docs server such as [Context7](https://github.com/upstash/context7) (`https://mcp.context7.com/mcp`, free API key).

MIT licensed. Source: https://github.com/tahmidbintaslim/HatchLock
