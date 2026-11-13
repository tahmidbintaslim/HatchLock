# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Landing site: Astro (user chose "Astro/Next.js"; Astro picked because the site is a static marketing page that deploys to GitHub Pages with no server). Lives in `site/` in this repo. The plugin itself is Bash + JSON + Markdown.

## Users

Developers who use AI coding agents (Claude Code first, ChatGPT/Codex second) on real codebases in typed languages, mainly TypeScript and Python, plus Rust, Go and 13 others. They hand the agent a task, then review the diff. Their pain: the agent "fixes" errors by silencing the type checker (`@ts-ignore`, `as any`, `# type: ignore`) or writes bloated, sprawling diffs, and they only notice in review or in production.

Secondary audience: store reviewers at Anthropic and OpenAI reading the listing.

## Product Purpose

HatchLock makes an AI coding agent fix type errors instead of hiding them. Success: the user installs it in one command, forgets about it, and stops finding new escape hatches in AI-written diffs.

## Positioning

The only plugin that **blocks** type-checker escape hatches *before the write lands* (a PreToolUse hook), across TypeScript/JS, Python, PHP, Rust and Go, and then checks the edit with the user's own local compilers. Other tools advise (prompt rules) or check after the fact; HatchLock enforces. It only blocks *new* suppressions, so legacy code keeps working, and `hatchlock-allow: <reason>` is the documented way out.

## Operating Context

- Installed with two terminal commands (`claude plugin marketplace add …`, `claude plugin install hatchlock@hatchlock-marketplace`). Runs silently; users see it only when it blocks or reports an error.
- Messages appear inside the agent's transcript, read by both the model and the human.
- `/hatchlock:doctor` shows which language servers and compilers are installed.
- ChatGPT/Codex version is skills-only (guidance, no blocking).

## Capabilities and Constraints

- Three checks: before each write (block), after each edit (per-file check), end of turn (project compilers, at most one extra round).
- 6 bundled LSP servers (Zig, Elixir, Dart, Bash, Terraform, R); official Anthropic plugins cover the other 12.
- Skills: `tight-diff` (auto), `/hatchlock:optimize`, `/hatchlock:architect`, `/hatchlock:clean`, `/hatchlock:doctor`.
- Local only: no network calls, no telemetry, no accounts. MIT licensed. Free.
- Not affiliated with Anthropic, OpenAI or Andrej Karpathy; must never imply endorsement or use their logos.
- Store listing rules: no ads or sponsored content inside the product, no superlatives or competitor comparisons in store descriptions, no unverifiable claims.

## Brand Commitments

- Name: **HatchLock** (one word, capital H and L). Plugin id `hatchlock`.
- Voice (user decision): easy, customer-friendly, plain-spoken, in the style of top browser-extension listings: lead with what you get, short sentences, concrete benefits, no jargon walls, no hype words, no superlatives.
- Author: Tahmid Bin Taslim Rafi (tahmid.space). Sponsorship links (Buy Me a Coffee) allowed on the website and README only.

## Evidence on Hand

- None yet: no users, stars, installs, testimonials, benchmarks or press. Future work must not invent any.
- Real material that can serve as proof: the actual hook messages (`[HatchLock Guardrail] Blocked type-checker suppression in …`), the install commands, the test suite, the MIT license, CI.
- Demo recording: not available.

## Product Principles

1. Enforce, don't nag: block the bad edit, explain the fix in one line.
2. Never punish legacy code: only new suppressions are blocked, with an honest escape hatch that needs a reason.
3. Stay invisible when things are fine: no output on success.
4. Local and private by default: user's tools, user's machine, no data leaves.
5. Honest claims only: say exactly what runs and what doesn't.

## Accessibility & Inclusion

Website targets WCAG 2.2 AA: keyboard navigable, readable contrast in light and dark, respects reduced motion. Terminal copy must make sense without color.
