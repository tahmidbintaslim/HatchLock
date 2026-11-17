---
description: The tight-diff skill loads when the user asks for a code fix.
tags: [skills]
max_turns: 8
allowed_tools: [Read, Write, Edit, Glob, Grep, Skill]
---

Create `cart.ts` with exactly this content:

```ts
export function total(prices: number[]): number {
  let sum = 0;
  for (const p of prices) sum += p;
  return sum;
}

export const label: number = total([1, 2]).toFixed(2);
```

The last line has a type error. Fix it with the smallest change.
