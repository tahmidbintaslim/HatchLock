---
name: optimize
description: Optimizes application performance, LLM/AI pipelines, database queries, memory allocations, and hot-path algorithms using Andrej Karpathy's first-principles systems methodology. Use when profiling bottlenecks, reducing latency or token costs, eliminating N+1 queries, or speeding up slow code.
when_to_use: When the user asks to optimize code, reduce latency, speed up an endpoint or script, optimize LLM prompts or token usage, fix N+1 SQL queries, reduce memory footprint, or runs /polyglot:optimize.
argument-hint: "[file-path, endpoint, query, or LLM pipeline]"
effort: high
---

# Polyglot Optimize: First-Principles Systems & AI Performance

Apply Andrej Karpathy's `llm.c` and `nanoGPT` performance philosophy: **strip away opaque framework layers, respect the hardware and network hierarchy, measure before and after, and maximize throughput per line of code.**

Target scope (if specified): **$ARGUMENTS**

## Phase 1: Baseline Measurement & Bottleneck Isolation
1. **Classify the Bottleneck:** Determine whether the target is **I/O & Network Bound** (N+1 queries, sequential network calls), **LLM / Token Bound** (bloated prompts, broken prefix caching), **Memory Bound** ($O(N^2)$ copies, unstreamed payloads), or **CPU Bound** (linear scans, unvectorized loops).
2. **State the Baseline:** Document current Time Complexity $O(\cdot)$, Space Complexity $O(\cdot)$, and I/O round-trip count before modifying code.

## Phase 2: AI & LLM Systems Optimization (`nanoGPT` / `llm.c` Standard)
1. **Radical Framework De-Abstraction:** Replace multi-layer orchestration wrappers (heavy LangChain/LlamaIndex abstractions) with flat, debuggable 40-line native SDK calls where prompts, retries, and tool schemas are directly visible.
2. **KV-Cache & Prefix Caching Sympathy:** Place static system instructions, tool definitions, and reference context at the **exact start** of the prompt, and append dynamic per-request variables at the **very end** to maximize prefix cache hit rates.
3. **Concurrency & Streaming:** Execute independent LLM/embedding calls concurrently (`Promise.all`, `asyncio.gather`, `tokio::join!`) and stream user-facing responses to minimize Time-To-First-Token (TTFT).

## Phase 3: Database, Query & Backend Throughput
1. **Zero N+1 Tolerance:** Never run a SQL query, Redis call, or HTTP request inside a loop. Batch via `WHERE id = ANY($1)` / `IN (...)`, joins, or `DataLoader`.
2. **Narrow Projections & Keyset Pagination:** Select only required columns (never `SELECT *` on wide tables) and replace high-offset `OFFSET` queries with indexed cursor/keyset pagination.
3. **Push Compute to the Engine:** Execute aggregations (`COUNT`, `SUM`, window functions) in SQL rather than materializing thousands of rows in application memory.

## Phase 4: Memory, CPU & Algorithmic Sympathy
1. **Eliminate Accidental $O(N^2)$:** Convert `.find()`, `.includes()`, or `in list` inside loops into $O(1)$ `Map` / `Set` / `dict` / `HashSet` lookups.
2. **Vectorize & Pre-Allocate:** Use vectorized NumPy/PyTorch/Polars ops in Python; pre-allocate buffers (`Vec::with_capacity`, `make([]T, 0, n)`) in Rust/Go/C++; avoid multi-pass `.map().filter().reduce()` chains on large arrays in TypeScript.

## Phase 5: Required Output Format
Provide: (1) Root Cause & Line Numbers, (2) Before vs. After Complexity & Round-Trip Table, (3) Surgical Code Diff passing `verify-edit.sh`, and (4) Verification / Benchmark Command.
