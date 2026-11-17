---
type: regex
pattern: "hatchlock-allow|@ts-expect-error|as any"
match: not_contains
target: {source: file, path: price.ts}
---
