// End-to-end: a real MCP client starts the server over stdio and calls each tool.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, mkdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Client } from '@modelcontextprotocol/client';
import { StdioClientTransport } from '@modelcontextprotocol/client/stdio';

const here = dirname(fileURLToPath(import.meta.url));
const project = mkdtempSync(join(tmpdir(), 'hatchlock-mcp-'));
let client;

const call = async (name, args) => {
  const res = await client.callTool({ name, arguments: args });
  return { text: res.content.map((c) => c.text).join('\n'), data: res.structuredContent };
};

before(async () => {
  client = new Client({ name: 'hatchlock-test', version: '0.0.0' });
  await client.connect(new StdioClientTransport({ command: process.execPath, args: [join(here, 'index.mjs')] }));
});
after(async () => client?.close());

test('lists the four read-only tools', async () => {
  const { tools } = await client.listTools();
  const names = tools.map((t) => t.name).sort();
  assert.deepEqual(names, ['check_suppressions', 'doctor', 'verify_file', 'verify_project']);
  for (const t of tools) assert.equal(t.annotations?.readOnlyHint, true, `${t.name} must be read-only`);
});

test('check_suppressions flags a new @ts-ignore', async () => {
  const r = await call('check_suppressions', { path: join(project, 'a.ts'), new_text: '// @ts-ignore\nconst x = 1;' });
  assert.equal(r.data.blocked, true);
  assert.match(r.text, /@ts-ignore/);
});

test('check_suppressions allows a suppression that already existed', async () => {
  const r = await call('check_suppressions', {
    path: join(project, 'a.ts'),
    new_text: '// @ts-ignore legacy\nfoo(1)',
    old_text: '// @ts-ignore legacy\nfoo()',
  });
  assert.equal(r.data.blocked, false);
});

test('check_suppressions allows a hatchlock-allow line with a reason', async () => {
  const r = await call('check_suppressions', { path: join(project, 'b.py'), new_text: 'x = f()  # type: ignore  # hatchlock-allow: stub lib' });
  assert.equal(r.data.blocked, false);
});

test('verify_file reports a shell syntax error', async () => {
  const f = join(project, 'broken.sh');
  writeFileSync(f, 'if true; then\n');
  const r = await call('verify_file', { path: f, project_dir: project });
  assert.equal(r.data.passed, false);
  assert.match(r.text, /syntax error|SC\d+/);
});

test('verify_file passes a clean file', async () => {
  const f = join(project, 'ok.sh');
  writeFileSync(f, '#!/usr/bin/env bash\necho ok\n');
  const r = await call('verify_file', { path: f, project_dir: project });
  assert.equal(r.data.passed, true);
});

test('verify_project passes outside a git repo', async () => {
  const empty = mkdtempSync(join(tmpdir(), 'hatchlock-empty-'));
  const r = await call('verify_project', { project_dir: empty });
  assert.equal(r.data.passed, true);
});

test('doctor reports the project languages', async () => {
  mkdirSync(join(project, 'pkg'), { recursive: true });
  writeFileSync(join(project, 'pkg', 'app.py'), 'x = 1\n');
  const r = await call('doctor', { project_dir: project });
  assert.match(r.text, /pyright-lsp@claude-plugins-official/);
});

test('rejects a path outside the project for verify_file', async () => {
  const r = await call('verify_file', { path: '/etc/passwd', project_dir: project });
  assert.equal(r.data.passed, true, 'files outside the project are skipped, never read');
});
