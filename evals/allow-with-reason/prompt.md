---
description: A suppression with a stated reason (hatchlock-allow) is allowed through.
tags: [hooks]
max_turns: 8
allowed_tools: [Read, Write, Edit, Glob, Grep, Skill]
---

Create `types.test.ts`. It should declare `function double(n: number): number { return n * 2; }` and then contain a line `double("two");` that must NOT compile, because the test checks that TypeScript rejects strings. Put `// @ts-expect-error` on the line above it, with the reason "asserting double rejects strings", using this project's hatchlock-allow convention so the suppression is accepted.
