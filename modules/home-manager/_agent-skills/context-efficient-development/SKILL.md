---
name: context-efficient-development
description: Reduce total tokens and tool calls per correctly completed coding task through progressive discovery, context reuse, scoped verification, and concise reporting. Use during repository investigation, implementation, debugging, and code review; especially when work spans large codebases or long sessions.
---
# Context-Efficient Development

Optimize **total effort per correct result**, not minimum tokens per step. Never sacrifice correctness, security, or required verification to save context.

## Work with a bounded information budget

1. Restate the concrete change and success criterion internally; do not produce a plan for trivial edits.
2. Locate the relevant code with filename searches, symbols, and narrow grep patterns before reading whole files.
3. Read the smallest coherent regions that reveal contracts, call sites, and invariants. Expand only when evidence demands it.
4. Reuse established findings. Do not reread unchanged files or repeat searches without a new question.
5. Prefer editing the existing path over exploring speculative alternatives. Stop investigation once enough evidence exists to act safely.
6. Verify with the narrowest meaningful build, assertion, or test first; broaden for cross-cutting changes or failures.
7. Report outcome, checks, and unresolved risks concisely. Do not narrate routine tool use.

## Context discipline

- Track which files and symbols have been examined and which assumptions remain unverified.
- Distinguish observations from guesses. Verify API signatures and semantics when uncertainty could cause rework.
- Read documentation selectively, using its index or headings; avoid loading entire reference collections.
- Preserve a compact checkpoint in long tasks: goal, modified files, key invariants, decisions, verification, next action. Do not create persistent notes unless useful or requested.
- Batch independent queries when it reduces overhead, but do not emit enormous unfiltered results.
- Avoid dumping full build logs: inspect relevant errors and preserve enough surrounding context to diagnose them.

## Change and verification scope

- Do not modify unrelated code simply because it was encountered.
- Do not skip compiler checks, safety checks, or regression coverage when needed.
- Prefer focused compilation and tests, then broader validation when integration risk warrants it.
- When a targeted check fails for an unrelated reason, state that precisely rather than claiming success.
- Avoid redundant unit tests; enforce invariants statically or dynamically where appropriate, and use exploratory testing for complex state spaces.

## Output contract

For ordinary changes, provide: what changed, what was verified, and any important caveat. For complex decisions, briefly explain the decisive evidence and tradeoff. Avoid repeated summaries, ceremonial plans, and verbose status messages.

## Anti-patterns

Do not optimize tokens by ignoring dependency boundaries, hiding failures, assuming unverified APIs, suppressing useful diagnostics, or truncating essential requirements. A short wrong answer is expensive.
