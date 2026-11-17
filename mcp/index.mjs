#!/usr/bin/env node
// HatchLock as a local MCP server (stdio). Wraps the plugin's bash checks so any
// MCP client can call them. Runs your own compilers; makes no network calls.
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { McpServer } from '@modelcontextprotocol/server';
import { StdioServerTransport } from '@modelcontextprotocol/server/stdio';
import { loadSkills } from '@modelcontextprotocol/server/ext/skills/node';
import * as z from 'zod';

const here = dirname(fileURLToPath(import.meta.url));
// Published package carries its own copies (see prepack); in the repo, use ../scripts and ../skills.
const pick = (name) => (existsSync(join(here, name)) ? join(here, name) : join(here, '..', name));
const SCRIPTS = pick('scripts');
const SKILLS = pick('skills');
const VERSION = '1.2.0';

// Run one HatchLock script with a hook-style JSON payload on stdin.
function run(script, payload, projectDir, args = []) {
  const res = spawnSync('bash', [join(SCRIPTS, script), ...args], {
    input: JSON.stringify(payload),
    cwd: projectDir,
    env: { ...process.env, CLAUDE_PROJECT_DIR: projectDir },
    encoding: 'utf8',
    timeout: 300_000,
  });
  return { code: res.status ?? 1, out: (res.stdout || '').trim(), err: (res.stderr || res.error?.message || '').trim() };
}

const projectOf = (dir) => resolve(dir || process.cwd());
const text = (t) => [{ type: 'text', text: t }];
const readOnly = { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false };
const projectDirField = z.string().optional().describe('Project root. Defaults to the server working directory.');

const server = new McpServer({ name: 'hatchlock', version: VERSION });

server.registerTool(
  'check_suppressions',
  {
    title: 'Check for type-checker escape hatches',
    description:
      'Call BEFORE writing or editing a file. Reports new @ts-ignore, @ts-expect-error, @ts-nocheck, as any, : any, ' +
      '# type: ignore, # pyright: ignore, @phpstan-ignore, #[allow(dead_code)] or //nolint in the proposed text. ' +
      'If blocked, fix the type instead of writing the suppression.',
    inputSchema: z.object({
      path: z.string().describe('File that will be written (its extension picks the language).'),
      new_text: z.string().describe('The new file content, or the replacement text for an edit.'),
      old_text: z.string().optional().describe('The text being replaced, so existing suppressions are not flagged.'),
    }),
    outputSchema: z.object({ blocked: z.boolean() }),
    annotations: readOnly,
  },
  async ({ path, new_text, old_text }) => {
    const payload = { tool_input: { file_path: resolve(path), content: new_text, ...(old_text ? { old_string: old_text } : {}) } };
    const r = run('guard-escape-hatches.sh', payload, process.cwd());
    const blocked = r.code === 2;
    return { content: text(blocked ? r.err : 'No new type-checker suppressions.'), structuredContent: { blocked } };
  },
);

server.registerTool(
  'verify_file',
  {
    title: 'Check one file with local tools',
    description: 'Call AFTER editing a file. Runs a fast syntax/type check on that file with tools already installed (pyright, shellcheck, gofmt, php -l, ...). Files outside the project are skipped.',
    inputSchema: z.object({ path: z.string().describe('File that was edited.'), project_dir: projectDirField }),
    outputSchema: z.object({ passed: z.boolean() }),
    annotations: readOnly,
  },
  async ({ path, project_dir }) => {
    const dir = projectOf(project_dir);
    const r = run('verify-edit.sh', { tool_input: { file_path: resolve(dir, path) } }, dir);
    const passed = r.code !== 2;
    return { content: text(passed ? 'File check passed (or no checker installed for this language).' : r.err), structuredContent: { passed } };
  },
);

server.registerTool(
  'verify_project',
  {
    title: 'Run project compilers',
    description: 'Call BEFORE saying a task is done. Runs project-wide checks (tsc, cargo check, go vet, ...) for languages with uncommitted git changes.',
    inputSchema: z.object({ project_dir: projectDirField }),
    outputSchema: z.object({ passed: z.boolean() }),
    annotations: readOnly,
  },
  async ({ project_dir }) => {
    const dir = projectOf(project_dir);
    const r = run('verify-project.sh', { stop_hook_active: false }, dir);
    const passed = r.code !== 2;
    return { content: text(passed ? 'Project checks passed (or nothing changed).' : r.err), structuredContent: { passed } };
  },
);

server.registerTool(
  'doctor',
  {
    title: 'Show available language servers and compilers',
    description: 'Lists which compilers and language servers HatchLock can use for the languages in the project.',
    inputSchema: z.object({ project_dir: projectDirField, all: z.boolean().optional().describe('List every supported language.') }),
    annotations: readOnly,
  },
  async ({ project_dir, all }) => {
    const dir = projectOf(project_dir);
    const r = run('lsp-doctor.sh', {}, dir, all ? ['--all'] : []);
    return { content: text(r.out || r.err) };
  },
);

// Serve the same SKILL.md files over MCP for clients that support the skills extension.
if (existsSync(SKILLS)) (await loadSkills(SKILLS)).attach(server);

await server.connect(new StdioServerTransport());
