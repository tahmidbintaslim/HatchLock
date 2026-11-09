---
name: architect
description: Designs lean, data-first software architectures, database schemas, API contracts, and Architecture Decision Records (ADRs) with explicit trade-off matrices. Use when planning new features, designing system architecture, evaluating tech stacks, modeling schemas, or refactoring module boundaries.
when_to_use: When the user asks to architect a system, design a feature or database schema, compare architectural options, write an ADR, decouple modules, or runs /polyglot:architect.
argument-hint: "[system, feature, or architectural decision]"
effort: high
---

# Polyglot Architect: Data-First System Design & Trade-Off Engine

Target architecture scope: **$ARGUMENTS**

## Step 1: Data Structures & State First ("Show Me Your Tables")
1. **Core Domain Schemas:** Define exact database tables (SQL DDL / Prisma / migrations) or memory structs first, including primary keys, foreign keys, and composite indexes.
2. **State Machine Invariants:** Enumerate valid state transitions (e.g., `PENDING -> PROCESSING -> COMPLETED | FAILED`) and explicitly forbid invalid transitions.
3. **I/O Boundary Contracts:** Define ingress/egress payload schemas before writing business functions.

## Step 2: Mandatory 3-Tier Trade-Off Matrix
Compare three concrete options before recommending one:
- **Option A (Karpathy Minimal Baseline):** Single module / in-process / existing DB table (~50-150 LOC, zero new infra, up to ~100 req/s).
- **Option B (Pragmatic Production — Default):** Modular monolith + Postgres + background worker/Redis (strict boundary separation, up to ~10,000 req/s).
- **Option C (High-Scale Distributed):** Dedicated service / event stream / ClickHouse or Kafka (50,000+ req/s, high operational overhead).

Always recommend **Option A** or **Option B** unless hard throughput or compliance numbers require **Option C**.

## Step 3: Non-Negotiable Guardrails
1. **Parse, Don't Validate:** Validate untrusted payloads strictly at the I/O boundary (Zod, Pydantic, Serde, FormRequests) and pass strongly typed domain structs internally.
2. **Anti-Lasagna Topology:** Maximum module nesting depth of 3. Never build pass-through `Controller -> ServiceInterface -> ServiceImpl -> RepositoryInterface -> RepositoryImpl` chains when `Handler -> Domain -> Query` suffices.
3. **Idempotency by Default:** Every network mutation or background job must specify an idempotency key, timeout, and retry/dead-letter strategy.
